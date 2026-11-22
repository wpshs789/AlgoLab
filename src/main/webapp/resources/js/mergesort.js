(() => {
    "use strict";

    const root = document.getElementById("vizRoot");
    if (!root || root.dataset.algorithm !== "merge") return;
    root.dataset.jsVersion = "merge-bars-v2";

    const byId = (id) => document.getElementById(id);
    const tree = byId("mergeTree");
    const treeScroll = byId("mergeTreeScroll");
    const leftBox = byId("mergeLeftValues");
    const rightBox = byId("mergeRightValues");
    const outputBox = byId("mergeOutputValues");
    const phase = byId("mergePhase");
    const hint = byId("mergeHint");
    const actionText = byId("actionText");
    const stepText = byId("stepText");
    const currentValues = byId("currentValues");
    const progressBar = byId("progressBar");
    const compareCount = byId("compareCount");
    const operationCount = byId("swapCount");
    const currentStep = byId("currentStep");
    const prevBtn = byId("prevBtn");
    const nextBtn = byId("nextBtn");
    const playBtn = byId("playBtn");
    const resetBtn = byId("resetBtn");
    const speed = byId("speed");
    const warning = byId("vizWarning");

    function fail(message) {
        warning.textContent = message;
        warning.classList.add("visible");
        [prevBtn, nextBtn, playBtn, resetBtn].forEach(button => { button.disabled = true; });
    }

    let steps, original;
    try {
        steps = JSON.parse(byId("sortData").textContent);
        original = JSON.parse(byId("inputData").textContent);
    } catch (e) {
        fail("병합 정렬 데이터를 불러오지 못했습니다.");
        return;
    }
    if (!Array.isArray(steps) || !steps.length ||
        !Array.isArray(original) || original.length < 1 || original.length > 30 ||
        !original.every(Number.isInteger) ||
        steps.some(step => !step || !Array.isArray(step.array) || step.array.length !== original.length ||
            !Array.isArray(step.output) || !["initial", "mergeSplit", "mergeLeaf", "compare", "mergeTake", "mergeDone", "complete"].includes(step.action)) ||
        original.some((value, i) => value !== steps[0].array[i])) {
        fail("병합 정렬 단계 데이터가 올바르지 않습니다.");
        return;
    }

    const n = original.length;
    const columnWidth = 64;
    // 3개 병합 막대그래프에 동일한 높이 기준을 적용하여 실제 크기를 비교합니다.
    const minimum = Math.min(...original);
    const maximum = Math.max(...original);
    function barHeight(value) {
        // 모든 값이 같거나 음수여도 막대 높이가 사라지지 않게 합니다.
        return maximum === minimum ? 64 : 24 + 78 * (value - minimum) / (maximum - minimum);
    }
    const levelHeight = 102;
    const nodes = new Map();
    const edges = [];
    const nodeKey = (l, r) => `${l}-${r}`;
    let maxDepth = 0;

    function makeNode(l, r, depth, parentKey = null) {
        maxDepth = Math.max(maxDepth, depth);
        const key = nodeKey(l, r);
        const node = {
            key, l, r, depth,
            base: original.slice(l, r + 1),
            values: original.slice(l, r + 1),
            visible: parentKey === null,
            done: false,
            element: null,
            labelElement: null,
            listElement: null
        };
        nodes.set(key, node);
        if (parentKey !== null) edges.push({ from: parentKey, to: key, element: null });
        if (l < r) {
            const mid = l + Math.floor((r - l) / 2);
            makeNode(l, mid, depth + 1, key);
            makeNode(mid + 1, r, depth + 1, key);
        }
    }
    makeNode(0, n - 1, 0);

    // 30개까지의 원소를 배열 구간 길이에 맞춰 배치하여 분할 트리를 표현합니다.
    // 값이 긴 경우에는 트리 내부만 가로로 스크롤합니다.
    const width = Math.max(620, n * columnWidth);
    const height = (maxDepth + 1) * levelHeight - 12;
    tree.style.width = `${width}px`;
    tree.style.height = `${height}px`;
    const svg = document.createElementNS("http://www.w3.org/2000/svg", "svg");
    svg.classList.add("merge-edges");
    svg.setAttribute("viewBox", `0 0 ${width} ${height}`);
    svg.setAttribute("aria-hidden", "true");
    tree.appendChild(svg);

    for (const edge of edges) {
        const from = nodes.get(edge.from);
        const to = nodes.get(edge.to);
        const line = document.createElementNS("http://www.w3.org/2000/svg", "line");
        line.setAttribute("x1", String((from.l + from.r + 1) * width / (2 * n)));
        line.setAttribute("y1", String(from.depth * levelHeight + 72));
        line.setAttribute("x2", String((to.l + to.r + 1) * width / (2 * n)));
        line.setAttribute("y2", String(to.depth * levelHeight + 3));
        svg.appendChild(line);
        edge.element = line;
    }

    for (const node of nodes.values()) {
        const box = document.createElement("div");
        box.className = "merge-node";
        box.style.left = `${node.l / n * 100}%`;
        box.style.width = `${(node.r - node.l + 1) / n * 100}%`;
        box.style.top = `${node.depth * levelHeight}px`;
        box.hidden = true;
        const label = document.createElement("div");
        label.className = "merge-node-label";
        const list = document.createElement("div");
        list.className = "merge-node-values";
        box.append(label, list);
        tree.appendChild(box);
        node.element = box;
        node.labelElement = label;
        node.listElement = list;
    }

    // 기존의 숫자 칩 대신 크기를 보여주는 막대그래프를 그립니다.
    // 세 영역은 같은 스케일을 사용하며, 빈자리는 점선 슬롯으로 표현합니다.
    function renderBars(container, values, options = {}) {
        const { activeIndex = -1, consumedCount = 0, capacity = values.length, output = false } = options;
        container.replaceChildren();
        if (!values.length && capacity === 0) {
            const empty = document.createElement("span");
            empty.className = "merge-empty";
            empty.textContent = "병합이 시작되면 표시됩니다.";
            container.appendChild(empty);
            return;
        }
        const fragment = document.createDocumentFragment();
        for (let index = 0; index < capacity; index++) {
            const value = values[index];
            const slot = document.createElement("div");
            slot.className = "merge-bar-slot";
            if (index >= values.length) {
                slot.classList.add("is-vacant");
                slot.setAttribute("aria-label", `${index + 1}번째 빈자리`);
                const placeholder = document.createElement("div");
                placeholder.className = "merge-bar-placeholder";
                slot.appendChild(placeholder);
            } else {
                if (index === activeIndex) slot.classList.add(output ? "is-new" : "is-compared");
                else if (index < consumedCount && !output) slot.classList.add("is-consumed");
                else if (output) slot.classList.add("is-placed");
                slot.setAttribute("aria-label", `${index + 1}번째 값 ${value}`);
                const bar = document.createElement("div");
                bar.className = "merge-bar";
                bar.style.height = `${barHeight(value)}px`;
                const label = document.createElement("span");
                label.className = "merge-bar-value";
                label.textContent = String(value);
                slot.append(bar, label);
            }
            fragment.appendChild(slot);
        }
        container.appendChild(fragment);
    }

    const snapshots = [];
    let comparisons = 0;
    let writes = 0;
    const state = new Map();
    for (const node of nodes.values()) {
        state.set(node.key, { visible: node.key === nodeKey(0, n - 1), done: false, values: node.base, partial: null });
    }
    const byRange = (l, r) => state.get(nodeKey(l, r));
    let mergeTracker = null;


    // 각 시점의 트리 상태를 저장하므로 '이전'을 눌러도 분할/병합이 정확히 되돌아갑니다.
    for (const step of steps) {
        if (step.action !== "initial" && step.action !== "complete") {
            if (![step.left, step.right, step.depth].every(Number.isInteger) ||
                step.left < 0 || step.right >= n || step.right < step.left ||
                !nodes.has(nodeKey(step.left, step.right))) {
                fail("분할 구간 정보가 올바르지 않습니다.");
                return;
            }
            const current = byRange(step.left, step.right);
            current.visible = true;
            if (step.action === "mergeSplit") {
                if (step.mid < step.left || step.mid >= step.right) {
                    fail("분할 기준이 올바르지 않습니다.");
                    return;
                }
                byRange(step.left, step.mid).visible = true;
                byRange(step.mid + 1, step.right).visible = true;
            } else if (step.action === "mergeLeaf") {
                current.done = true;
            } else if (["compare", "mergeTake", "mergeDone"].includes(step.action)) {
                // 병합이 끝날 때까지 원본 배열은 그대로입니다. 부모 노드에는
                // 임시 배열의 확정된 앞부분만 즉시 표시합니다.
                const key = nodeKey(step.left, step.right);
                if (!mergeTracker || mergeTracker.key !== key) {
                    mergeTracker = { key, usedLeft: 0, usedRight: 0 };
                }
                if (step.action === "mergeTake") {
                    if (step.index1 <= step.mid) mergeTracker.usedLeft++;
                    else mergeTracker.usedRight++;
                }
                if (step.action === "mergeDone") {
                    current.done = true;
                    current.values = step.array.slice(step.left, step.right + 1);
                    current.partial = null;
                } else {
                    current.partial = step.output.slice();
                }
            }
            if (step.action === "compare") comparisons++;
            if (step.action === "mergeTake") writes++;
        }
        snapshots.push({
            comparisons, writes,
            tracker: mergeTracker ? { ...mergeTracker } : null,
            tree: new Map([...state].map(([key, value]) => [key, { ...value }]))
        });
    }

    let cursor = 0;
    let timer = null;

    function pause() {
        if (timer !== null) clearInterval(timer);
        timer = null;
        playBtn.textContent = "▶ 재생";
    }

    function describe(step) {
        if (step.action === "initial") return "전체 배열에서 시작합니다. 다음을 눌러 분할 과정을 확인하세요.";
        if (step.action === "complete") return "병합 정렬이 완료되었습니다. 모든 구간이 정렬되었습니다.";
        const span = `${step.left + 1}~${step.right + 1}번째`;
        if (step.action === "mergeSplit") {
            return `${span} 구간을 ${step.left + 1}~${step.mid + 1}번째와 ${step.mid + 2}~${step.right + 1}번째 구간으로 분할합니다.`;
        }
        if (step.action === "mergeLeaf") return `${step.left + 1}번째 원소는 길이가 1이므로 이미 정렬된 구간입니다.`;
        if (step.action === "compare") {
            return `${step.array[step.index1]}과 ${step.array[step.index2]}을 비교합니다. 작은 값을 병합 결과에 먼저 배치합니다.`;
        }
        if (step.action === "mergeTake") {
            const value = step.output[step.output.length - 1];
            const side = step.index1 <= step.mid ? "왼쪽" : "오른쪽";
            return `${side} 구간에서 ${value}을 선택해 결과 그래프와 부모 노드의 ${step.output.length}번째 칸에 배치합니다.`;
        }
        if (step.action === "mergeDone") return `${span} 구간의 병합이 완료되었습니다. 부모 노드가 정렬된 배열로 확정되었습니다.`;
        return "병합 정렬 진행 중";
    }

    function isMergingStep(step) {
        return ["compare", "mergeTake", "mergeDone"].includes(step.action);
    }

    function render() {
        const step = steps[cursor];
        const snapshot = snapshots[cursor];
        const activeKey = step.left >= 0 ? nodeKey(step.left, step.right) : null;

        for (const node of nodes.values()) {
            const st = snapshot.tree.get(node.key);
            node.element.hidden = !st.visible;
            if (!st.visible) continue;
            node.element.classList.toggle("is-ready", st.done);
            node.element.classList.toggle("is-current", node.key === activeKey);
            node.element.classList.toggle("is-partitioned", !st.done && node.key !== activeKey);
            node.labelElement.textContent = node.l === node.r
                ? `${node.l + 1}번` : `${node.l + 1}–${node.r + 1}번`;
            node.listElement.replaceChildren();
            const partial = st.partial;
            const displayValues = partial === null ? st.values : partial;
            const isParentMerging = node.key === activeKey && partial !== null;
            const tracker = snapshot.tracker;
            const isChildOfActiveMerge = isMergingStep(step) &&
                (node.key === nodeKey(step.left, step.mid) || node.key === nodeKey(step.mid + 1, step.right));
            const isLeftChild = isChildOfActiveMerge && node.key === nodeKey(step.left, step.mid);
            const used = isChildOfActiveMerge && tracker
                ? (isLeftChild ? tracker.usedLeft : tracker.usedRight) : 0;
            const highlightedSource = isChildOfActiveMerge && ["compare", "mergeTake"].includes(step.action)
                ? (step.action === "compare"
                    ? (isLeftChild ? step.index1 - step.left : step.index2 - step.mid - 1)
                    : (isLeftChild && step.index1 <= step.mid ? step.index1 - step.left
                    : !isLeftChild && step.index1 > step.mid ? step.index1 - step.mid - 1 : -1))
                : -1;
            for (let index = 0; index < node.r - node.l + 1; index++) {
                const pill = document.createElement("span");
                pill.className = "merge-node-pill";
                if (index >= displayValues.length) {
                    pill.classList.add("is-vacant");
                    pill.textContent = "·";
                } else {
                    pill.textContent = String(displayValues[index]);
                    if (isParentMerging) {
                        pill.classList.add("is-placed");
                        if (step.action === "mergeTake" && index === displayValues.length - 1) {
                            pill.classList.add("is-new");
                        }
                    }
                    if (isChildOfActiveMerge) {
                        if (index < used) pill.classList.add("is-consumed");
                        if (index === highlightedSource) pill.classList.add("is-compared");
                    }
                }
                node.listElement.appendChild(pill);
            }
            node.element.classList.toggle("is-merging", isParentMerging);
            node.element.setAttribute("aria-label", `${node.l + 1}부터 ${node.r + 1}까지: ${displayValues.join(", ")}${partial !== null ? " (병합 중)" : ""}`);
        }
        for (const edge of edges) {
            const from = snapshot.tree.get(edge.from);
            const to = snapshot.tree.get(edge.to);
            edge.element.classList.toggle("is-visible", from.visible && to.visible);
        }

        const isMerging = isMergingStep(step);
        if (isMerging) {
            const left = step.action === "mergeDone"
                ? snapshot.tree.get(nodeKey(step.left, step.mid)).values
                : step.array.slice(step.left, step.mid + 1);
            const right = step.action === "mergeDone"
                ? snapshot.tree.get(nodeKey(step.mid + 1, step.right)).values
                : step.array.slice(step.mid + 1, step.right + 1);
            const leftActive = step.action === "compare" ? step.index1 - step.left
                : step.action === "mergeTake" && step.index1 <= step.mid ? step.index1 - step.left : -1;
            const rightActive = step.action === "compare" ? step.index2 - step.mid - 1
                : step.action === "mergeTake" && step.index1 > step.mid ? step.index1 - step.mid - 1 : -1;
            const tracker = snapshot.tracker;
            const usedLeft = tracker ? tracker.usedLeft : 0;
            const usedRight = tracker ? tracker.usedRight : 0;
            renderBars(leftBox, left, { activeIndex: leftActive, consumedCount: usedLeft });
            renderBars(rightBox, right, { activeIndex: rightActive, consumedCount: usedRight });
            renderBars(outputBox, step.output, {
                capacity: step.right - step.left + 1,
                output: true,
                activeIndex: step.action === "mergeTake" ? step.output.length - 1 : -1
            });
            phase.textContent = step.action === "mergeDone" ? "병합 완료" : "병합 중";
            hint.textContent = step.action === "mergeDone"
                ? "부모 노드에 정렬된 구간이 완성되었습니다. 다음 단계에서는 더 큰 구간을 병합합니다."
                : "노란 막대를 비교하고, 선택된 원소가 위쪽 트리의 빈자리와 아래쪽 결과 그래프에 차례대로 채워집니다.";
        } else {
            renderBars(leftBox, []);
            renderBars(rightBox, []);
            if (step.action === "complete") {
                renderBars(outputBox, step.array, { output: true, capacity: n });
            } else {
                renderBars(outputBox, []);
            }
            phase.textContent = step.action === "complete" ? "정렬 완료" : "분할 중";
            hint.textContent = step.action === "mergeLeaf"
                ? "원소가 하나인 구간은 정렬되어 있습니다. 다음 단계에서는 작은 구간부터 병합합니다."
                : step.action === "complete"
                ? "가장 위의 부모 노드와 병합 결과 막대그래프에서 정렬된 배열을 확인할 수 있습니다."
                : "트리에서 분할 과정을 확인하세요. 병합이 시작되면 부모 노드의 칸이 하나씩 채워집니다.";
        }

        currentValues.textContent = isMerging && step.action !== "mergeDone"
            ? `[${step.array.join(", ")}]  (현재 병합 결과: [${step.output.join(", ")}])`
            : `[${step.array.join(", ")}]`;
        actionText.textContent = describe(step);
        stepText.textContent = `${cursor} / ${steps.length - 1}`;
        currentStep.textContent = String(cursor);
        compareCount.textContent = String(snapshot.comparisons);
        operationCount.textContent = String(snapshot.writes);
        progressBar.style.width = `${cursor / Math.max(1, steps.length - 1) * 100}%`;
        prevBtn.disabled = cursor === 0;
        nextBtn.disabled = cursor === steps.length - 1;
        const active = activeKey ? nodes.get(activeKey) : null;
        if (active) {
            const center = (active.l + active.r + 1) * width / (2 * n);
            const viewLeft = treeScroll.scrollLeft;
            const viewWidth = treeScroll.clientWidth;
            if (center < viewLeft + 55 || center > viewLeft + viewWidth - 55) {
                treeScroll.scrollLeft = Math.max(0, center - viewWidth / 2);
            }
        }
    }

    function next() {
        if (cursor < steps.length - 1) {
            cursor++;
            render();
        }
        if (cursor >= steps.length - 1) pause();
    }

    function restartTimer() {
        if (timer !== null) clearInterval(timer);
        timer = setInterval(next, Number(speed.value) || 600);
    }

    nextBtn.addEventListener("click", () => { pause(); next(); });
    prevBtn.addEventListener("click", () => { pause(); if (cursor > 0) cursor--; render(); });
    resetBtn.addEventListener("click", () => { pause(); cursor = 0; render(); treeScroll.scrollLeft = 0; });
    playBtn.addEventListener("click", () => {
        if (timer !== null) { pause(); return; }
        if (cursor === steps.length - 1) { cursor = 0; render(); }
        playBtn.textContent = "⏸ 일시정지";
        restartTimer();
    });
    speed.addEventListener("change", () => { if (timer !== null) restartTimer(); });
    document.addEventListener("visibilitychange", () => { if (document.hidden) pause(); });

    render();
})();
