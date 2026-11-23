(() => {
    "use strict";

    const root = document.getElementById("vizRoot");
    if (!root) return;

    const messages = window.AL_I18N || {};
    const t = (key, ...args) => {
        let value = Object.prototype.hasOwnProperty.call(messages, key) ? messages[key] : key;
        args.forEach((arg, n) => { value = value.replaceAll("{" + n + "}", String(arg)); });
        return value;
    };
    const plot = document.getElementById("vizPlot");
    const warning = document.getElementById("vizWarning");
    const playBtn = document.getElementById("playBtn");
    const prevBtn = document.getElementById("prevBtn");
    const nextBtn = document.getElementById("nextBtn");
    const resetBtn = document.getElementById("resetBtn");
    const speed = document.getElementById("speed");
    const actionText = document.getElementById("actionText");
    const stepText = document.getElementById("stepText");
    const currentValues = document.getElementById("currentValues");
    const progressBar = document.getElementById("progressBar");
    const compareCount = document.getElementById("compareCount");
    const swapCount = document.getElementById("swapCount");
    const currentStep = document.getElementById("currentStep");
    const isInsertion = root.dataset.algorithm === "insertion";
    const isQuick = root.dataset.algorithm === "quick";
    // 배포 확인용 버전: 브라우저 콘솔에서 document.getElementById("vizRoot").dataset.jsVersion 로 조회 가능합니다.
    root.dataset.jsVersion = isQuick ? "quick-v1" : "insertion-one-jump-v2";

    function fail(message) {
        warning.textContent = message;
        warning.classList.add("visible");
        [playBtn, prevBtn, nextBtn, resetBtn].forEach(button => { button.disabled = true; });
    }

    let steps, original;
    try {
        steps = JSON.parse(document.getElementById("sortData").textContent);
        original = JSON.parse(document.getElementById("inputData").textContent);
    } catch (e) {
        fail(t("js.jsonParse") + e.message);
        return;
    }

    if (!Array.isArray(steps) || steps.length === 0 ||
        !Array.isArray(original) || original.length === 0 ||
        steps.some(s => !s || !Array.isArray(s.array) || s.array.length !== original.length)) {
        fail(t("js.invalidSteps"));
        return;
    }
    if (steps[0].array.some((v, i) => v !== original[i])) {
        fail(t("js.dataMismatch"));
        return;
    }

    const count = original.length;
    const max = Math.max(0, ...original);
    const min = Math.min(0, ...original);
    const range = Math.max(1, max - min);
    const baseline = -min / range * 100;
    plot.style.minWidth = `${count * 48}px`;

    const zeroLine = document.createElement("div");
    zeroLine.className = "viz-zero";
    zeroLine.style.bottom = `${baseline}%`;
    plot.appendChild(zeroLine);

    // 퀵 정렬은 현재 재귀 구간에 옅은 경계를 표시합니다.
    let quickBand = null;
    if (isQuick) {
        plot.parentElement.classList.add("quick-mode");
        quickBand = document.createElement("div");
        quickBand.className = "quick-range-band";
        quickBand.hidden = true;
        plot.appendChild(quickBand);
    }

    // 각 원소에 고유 DOM 요소를 부여합니다. shift 때는 DOM 자체가 오른쪽으로 움직입니다.
    const views = original.map((_, i) => {
        const slot = document.createElement("div");
        slot.className = "viz-slot";
        slot.style.left = `${i / count * 100}%`;
        slot.style.width = `${100 / count}%`;
        const bar = document.createElement("div");
        bar.className = "viz-bar";
        const valueLabel = document.createElement("span");
        valueLabel.className = "viz-value";
        slot.append(bar, valueLabel);
        if (isQuick) {
            const marker = document.createElement("span");
            marker.className = "quick-pivot-marker";
            marker.textContent = "P";
            marker.setAttribute("aria-label", t("js.pivot"));
            marker.hidden = true;
            slot.appendChild(marker);
        }
        plot.appendChild(slot);
        return { slot, bar, valueLabel };
    });

    let hole = null;
    let keyToken = null;
    let keyNumber = null;
    if (isInsertion) {
        plot.parentElement.classList.add("insertion-mode");
        hole = document.createElement("div");
        hole.className = "viz-hole";
        const holeText = document.createElement("span");
        holeText.textContent = t("js.emptySlot");
        hole.appendChild(holeText);
        hole.hidden = true;
        plot.appendChild(hole);

        keyToken = document.createElement("div");
        keyToken.className = "viz-key-token";
        const keyCaption = document.createElement("span");
        keyCaption.textContent = t("js.keyToken");
        keyNumber = document.createElement("strong");
        keyToken.append(keyCaption, keyNumber);
        keyToken.hidden = true;
        plot.appendChild(keyToken);
    }

    // [위치] -> [원소 ID]. pick 시 key를 꺼내 빈자리를 만들고,
    // shift 시 원소 ID를 오른쪽으로 실제 이동시키며, insert 시 key ID를 넣습니다.
    // 이렇게 해야 배열 값만 바꾸었을 때와 달리 '밀려나는' 움직임을 볼 수 있습니다.
    const orders = [];
    const carriedIds = [];
    const compares = [];
    const operations = [];
    const quickFixed = []; // 각 단계까지 최종 위치가 확정된 피벗/1원소 구간
    const fixedIndices = new Set();
    const order = Array.from({ length: count }, (_, i) => i);
    let carried = null;
    let numCompares = 0;
    let numOperations = 0;

    for (const step of steps) {
        const a = step.index1, b = step.index2;
        if (step.action === "swap" || (isQuick && step.action === "swapPivot")) {
            if (!validIndex(a) || !validIndex(b)) {
                fail(t("js.swapIndex"));
                return;
            }
            [order[a], order[b]] = [order[b], order[a]];
            numOperations++;
        } else if (isInsertion && step.action === "pick") {
            if (!validIndex(a) || carried !== null || order[a] === null || step.holeIndex !== a) {
                fail(t("js.pickIndex"));
                return;
            }
            carried = order[a];
            order[a] = null;
        } else if (isInsertion && step.action === "shift") {
            if (!validIndex(a) || !validIndex(b) || carried === null ||
                order[a] === null || order[b] !== null || step.holeIndex !== a) {
                fail(t("js.shiftIndex"));
                return;
            }
            order[b] = order[a];
            order[a] = null;
            numOperations++;
        } else if (isInsertion && step.action === "insert") {
            if (!validIndex(a) || carried === null || order[a] !== null || step.holeIndex !== -1) {
                fail(t("js.insertIndex"));
                return;
            }
            order[a] = carried;
            carried = null;
        }

        if (step.action === "compare") numCompares++;
        if (isQuick) {
            if (step.action === "quickPlaced" || step.action === "quickSingle") {
                if (!validIndex(step.index1) || fixedIndices.has(step.index1)) {
                    fail(t("js.quickFixed"));
                    return;
                }
                fixedIndices.add(step.index1);
            }
            for (let pos = 0; pos < count; pos++) {
                if (original[order[pos]] !== step.array[pos]) {
                    fail(t("js.quickSwap"));
                    return;
                }
            }
            if (step.action === "complete" && fixedIndices.size !== count) {
                fail(t("js.quickIncomplete"));
                return;
            }
            quickFixed.push(new Set(fixedIndices));
        }
        if (isInsertion) {
            // 빈자리 이외의 각 막대가 실제 원래 값과 일치하는지 확인합니다.
            for (let pos = 0; pos < count; pos++) {
                const id = order[pos];
                if (id !== null && original[id] !== step.array[pos]) {
                    fail(t("js.insertionArray"));
                    return;
                }
            }
            if ((carried === null) !== (step.holeIndex === -1) ||
                (carried !== null && original[carried] !== step.keyValue)) {
                fail(t("js.insertionHole"));
                return;
            }
        }
        orders.push([...order]);
        carriedIds.push(carried);
        compares.push(numCompares);
        operations.push(numOperations);
    }

    function validIndex(value) {
        return Number.isInteger(value) && value >= 0 && value < count;
    }

    // 학습용 화면에서는 삽입 정렬 한 회전을 'Key 선택 → 최종 위치에 삽입'으로 표시합니다.
    // Java가 생성한 모든 compare/shift 단계는 그대로 유지하고, 화면 단계만 묶습니다.
    // 따라서 보이지 않는 중간 단계의 비교·이동 횟수도 정확하게 누적됩니다.
    const visibleSteps = isInsertion
        ? steps.map((step, i) => ({ action: step.action, i }))
            .filter(item => ["initial", "pick", "insert", "complete"].includes(item.action))
            .map(item => item.i)
        : steps.map((_, i) => i);

    // 삽입 정렬에서는 반드시 pick 다음에 insert가 화면 단계로 와야 합니다.
    if (isInsertion) {
        for (let i = 1; i < visibleSteps.length - 1; i += 2) {
            if (steps[visibleSteps[i]].action !== "pick" ||
                !steps[visibleSteps[i + 1]] || steps[visibleSteps[i + 1]].action !== "insert") {
                fail(t("js.insertionGroup"));
                return;
            }
        }
    }

    let index = 0; // 사용자에게 보이는 단계 번호
    let timer = null;
    let landingTimer = null;
    const prefersReducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)");

    function motionDuration() {
        return prefersReducedMotion.matches ? 0 : Math.min(480, Math.round((Number(speed.value) || 600) * 0.78));
    }

    function cancelLanding() {
        if (landingTimer !== null) {
            clearTimeout(landingTimer);
            landingTimer = null;
        }
    }

    function pause() {
        if (timer !== null) clearInterval(timer);
        timer = null;
        playBtn.textContent = t("js.play");
    }

    function setSpeed() {
        plot.style.setProperty("--viz-motion", `${motionDuration()}ms`);
    }

    function explain(step) {
        if (step.action === "initial") return isInsertion ? t("js.insertionInitial") : t("js.initial");
        if (isQuick) {
            if (step.action === "quickStart") return t("js.quickStart", step.left + 1, step.right + 1, step.array[step.right]);
            if (step.action === "compare") return t("js.quickCompare", step.index1 + 1, step.array[step.index1], step.array[step.right]);
            if (step.action === "quickKeep") return t("js.quickKeep", step.array[step.index1]);
            if (step.action === "quickSkip") return t("js.quickSkip", step.array[step.index1]);
            if (step.action === "swap") return t("js.quickSwapExplain", step.index1 + 1, step.index2 + 1);
            if (step.action === "swapPivot") return t("js.quickSwapPivot", step.array[step.index1], step.index1 + 1);
            if (step.action === "quickPlaced") return t("js.quickPlaced", step.array[step.index1], step.index1 + 1);
            if (step.action === "quickSingle") return t("js.quickSingle", step.index1 + 1, step.array[step.index1]);
        }
        if (step.action === "complete") return t("js.sorted");
        if (step.action === "pick") return t("js.pick", step.index1 + 1, step.keyValue);
        if (step.action === "compare" && isInsertion) return t("js.keyCompare", step.index1 + 1, step.array[step.index1], step.keyValue);
        if (step.action === "shift") return t("js.shift", step.index1 + 1, step.array[step.index2], step.index2 + 1);
        if (step.action === "insert" && isInsertion) {
            const moved = step.keyOrigin - step.index1;
            return moved > 0 ? t("js.insert", step.keyValue, step.index1 + 1, moved) : t("js.already", step.keyValue);
        }
        if (step.action === "compare") return t("js.compare", step.index1 + 1, step.index2 + 1);
        if (step.action === "swap") return t("js.swap", step.index1 + 1, step.index2 + 1);
        if (step.action === "select") return t("js.select", step.index2 + 1);
        if (step.action === "fixed") return t("js.fixed", step.index1 + 1);
        return step.action || t("js.running");
    }

    function placeKeyAt(holeIndex) {
        // 첫/끝 원소에서도 key 배지가 잘리지 않도록 안전한 위치에 표시합니다.
        const center = (holeIndex + 0.5) * plot.clientWidth / count;
        keyToken.style.left = `${Math.max(58, Math.min(plot.clientWidth - 58, center))}px`;
    }

    function render(animateLanding = false) {
        cancelLanding();
        const rawIndex = visibleSteps[index];
        const step = steps[rawIndex];
        const orderNow = orders[rawIndex];
        const visibleIds = new Set();
        const landing = animateLanding && step.action === "insert" &&
            steps[visibleSteps[index - 1]]?.action === "pick" &&
            step.index1 !== steps[visibleSteps[index - 1]].index1 &&
            motionDuration() > 0;
        const enteringId = landing ? carriedIds[visibleSteps[index - 1]] : null;

        // 현재 분할의 피벗은 기존에 고른 맨 오른쪽 원소이며,
        // 피벗을 교환한 후에는 확정된 위치(index1)에 있습니다.
        const activeQuick = isQuick && Number.isInteger(step.left) &&
            step.left >= 0 && step.right >= step.left && step.right < count;
        const pivotPos = activeQuick ?
            (["swapPivot", "quickPlaced", "quickSingle"].includes(step.action) ? step.index1 : step.right) : -1;
        const fixedNow = isQuick ? quickFixed[rawIndex] : null;

        if (isQuick) {
            quickBand.hidden = !activeQuick;
            if (activeQuick) {
                quickBand.style.left = `${step.left / count * 100}%`;
                quickBand.style.width = `${(step.right - step.left + 1) / count * 100}%`;
            }
        }
        for (let pos = 0; pos < count; pos++) {
            const id = orderNow[pos];
            if (id === null) continue;
            visibleIds.add(id);
            const view = views[id];
            const value = step.array[pos];
            const height = Math.abs(value) / range * 100;
            // Key는 이동 애니메이션이 끝날 때까지 위쪽 배지로만 보여줍니다.
            view.slot.hidden = landing && id === enteringId;
            view.slot.style.left = `${pos / count * 100}%`;
            view.bar.style.height = value === 0 ? "3px" : `${height}%`;
            view.bar.style.bottom = `${value < 0 ? baseline - height : baseline}%`;
            view.bar.classList.toggle("negative", value < 0);
            view.valueLabel.textContent = String(value);
            view.slot.setAttribute("aria-label", t("js.slotAria", pos + 1, value));
            view.slot.classList.toggle("sorted", isInsertion && pos <= step.sortedEnd);
            view.slot.classList.toggle("comparing", step.action === "compare" &&
                (pos === step.index1 || (!isInsertion && pos === step.index2)));
            view.slot.classList.toggle("swapping", step.action === "swap" &&
                (pos === step.index1 || pos === step.index2));
            view.slot.classList.toggle("shifting",
                (step.action === "shift" && pos === step.index2) ||
                (landing && pos > step.index1 && pos <= step.keyOrigin));
            view.slot.classList.toggle("selected", step.action === "select" && pos === step.index2);
            view.slot.classList.toggle("fixed", step.action === "fixed" && pos === step.index1);
            view.slot.classList.toggle("inserted", step.action === "insert" && pos === step.index1);
            if (isQuick) {
                const fixed = fixedNow.has(pos);
                view.slot.classList.toggle("quick-outside", activeQuick &&
                    (pos < step.left || pos > step.right) && !fixed);
                view.slot.classList.toggle("quick-left", activeQuick && !fixed &&
                    pos >= step.left && pos <= step.mid && pos !== pivotPos);
                view.slot.classList.toggle("quick-pivot", activeQuick && pos === pivotPos &&
                    step.action !== "quickSingle" && step.action !== "quickPlaced");
                view.slot.classList.toggle("quick-scan", activeQuick &&
                    ["compare", "quickKeep", "quickSkip"].includes(step.action) && pos === step.index1);
                view.slot.classList.toggle("quick-moving", activeQuick &&
                    ["swap", "swapPivot"].includes(step.action) &&
                    (pos === step.index1 || pos === step.index2));
                view.slot.classList.toggle("quick-fixed", fixed);
                view.slot.querySelector(".quick-pivot-marker").hidden = pos !== pivotPos;
            }
        }
        for (let id = 0; id < count; id++) {
            if (!visibleIds.has(id)) views[id].slot.hidden = true;
        }

        if (isInsertion) {
            const carrying = carriedIds[rawIndex] !== null;
            hole.hidden = !carrying && !landing;
            keyToken.hidden = !carrying && !landing;
            if (carrying || landing) {
                const target = landing ? step.index1 : step.holeIndex;
                hole.style.left = `${target / count * 100}%`;
                hole.style.width = `${100 / count}%`;
                keyNumber.textContent = String(step.keyValue);
                keyToken.title = t("js.keyTitle", step.keyValue);
                placeKeyAt(target);
            }
            const drawnHole = landing ? step.index1 : step.holeIndex;
            currentValues.textContent = `[${step.array.map((value, pos) =>
                pos === drawnHole ? "□" : String(value)).join(", ")}]`;
            if (landing) {
                // 하나의 다음 클릭으로 Key는 최종 위치까지, 밀린 막대는 각자 한 칸씩 이동합니다.
                // 1회 클릭 = 1회 이동 연산이라는 뜻은 아닙니다.
                const finish = () => {
                    views[enteringId].slot.hidden = false;
                    for (let pos = step.index1 + 1; pos <= step.keyOrigin; pos++) {
                        views[orderNow[pos]].slot.classList.remove("shifting");
                    }
                    hole.hidden = true;
                    keyToken.hidden = true;
                    currentValues.textContent = `[${step.array.join(", ")}]`;
                    landingTimer = null;
                };
                landingTimer = setTimeout(finish, motionDuration() + 20);
            }
        } else {
            currentValues.textContent = `[${step.array.join(", ")}]`;
        }

        if (isQuick) {
            const rangeLabel = document.getElementById("quickRange");
            const pivotLabel = document.getElementById("quickPivot");
            const leftLabel = document.getElementById("quickLeftGroup");
            rangeLabel.textContent = activeQuick ? t("js.quickRange", step.left + 1, step.right + 1) : t("js.whole");
            pivotLabel.textContent = activeQuick ? t("js.quickPivotLabel", step.array[pivotPos], pivotPos + 1) :
                (step.action === "complete" ? t("js.completeShort") : t("js.notSelected"));
            const leftLength = activeQuick ? Math.max(0, step.mid - step.left + 1 -
                (["quickPlaced", "quickSingle"].includes(step.action) ? 1 : 0)) : 0;
            leftLabel.textContent = activeQuick ? t("js.countUnit", leftLength) : "-";
            document.getElementById("quickFixedCount").textContent = t("js.fixedCount", fixedNow.size, count);
        }

        actionText.textContent = explain(step);
        stepText.textContent = `${index} / ${visibleSteps.length - 1}`;
        currentStep.textContent = String(index);
        compareCount.textContent = String(compares[rawIndex]);
        swapCount.textContent = String(operations[rawIndex]);
        progressBar.style.width = `${index / Math.max(1, visibleSteps.length - 1) * 100}%`;
        prevBtn.disabled = index === 0;
        nextBtn.disabled = index === visibleSteps.length - 1;
    }

    function next() {
        if (index < visibleSteps.length - 1) {
            const previousStep = steps[visibleSteps[index]];
            index++;
            const current = steps[visibleSteps[index]];
            render(isInsertion && previousStep.action === "pick" && current.action === "insert");
        }
        if (index === visibleSteps.length - 1) pause();
    }

    function restartTimer() {
        if (timer !== null) clearInterval(timer);
        timer = setInterval(next, Number(speed.value) || 600);
    }

    playBtn.addEventListener("click", () => {
        if (timer !== null) { pause(); return; }
        if (index === visibleSteps.length - 1) { index = 0; render(); }
        playBtn.textContent = t("js.pause");
        restartTimer();
    });
    prevBtn.addEventListener("click", () => { pause(); if (index > 0) index--; render(); });
    nextBtn.addEventListener("click", () => { pause(); next(); });
    resetBtn.addEventListener("click", () => { pause(); index = 0; render(); });
    speed.addEventListener("change", () => {
        setSpeed();
        if (timer !== null) restartTimer();
    });
    document.addEventListener("visibilitychange", () => { if (document.hidden) pause(); });
    window.addEventListener("resize", () => {
        if (isInsertion) {
            const step = steps[visibleSteps[index]];
            if (carriedIds[visibleSteps[index]] !== null) placeKeyAt(step.holeIndex);
        }
    });

    setSpeed();
    render();
})();
