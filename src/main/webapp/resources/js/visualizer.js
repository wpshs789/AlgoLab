(() => {
                    "use strict";
                    const root = document.getElementById("vizRoot");
                    if (!root) return;
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

                    function fail(message) {
                        warning.textContent = message;
                        warning.classList.add("visible");
                        for (const button of [playBtn, prevBtn, nextBtn, resetBtn]) button.disabled = true;
                    }

                    let steps, original;
                    try {
                        steps = JSON.parse(document.getElementById("sortData").textContent);
                        original = JSON.parse(document.getElementById("inputData").textContent);
                    } catch (e) {
                        fail("Java에서 전달한 정렬 데이터를 읽을 수 없습니다. " + e.message);
                        return;
                    }
                    if (!Array.isArray(steps) || steps.length === 0 ||
                        !Array.isArray(original) || original.length === 0 ||
                        steps.some(s => !s || !Array.isArray(s.array) || s.array.length !== original.length)) {
                        fail("정렬 단계 데이터의 형식이 잘못되었습니다.");
                        return;
                    }
                    if (steps[0].array.some((v, i) => v !== original[i])) {
                        fail("시각화 데이터가 입력 배열과 일치하지 않습니다. 페이지를 새로고침하거나 관리자에게 문의해 주세요.");
                        return;
                    }

                    const count = original.length;
                    const max = Math.max(0, ...original);
                    const min = Math.min(0, ...original);
                    const range = Math.max(1, max - min);
                    const baseline = -min / range * 100;
                    plot.style.minWidth = `${Math.max(0, count * 48)}px`;
                    const zeroLine = document.createElement("div");
                    zeroLine.className = "viz-zero";
                    zeroLine.style.bottom = `${baseline}%`;
                    plot.appendChild(zeroLine);

                    const views = original.map((value, i) => {
                        const slot = document.createElement("div");
                        slot.className = "viz-slot";
                        slot.style.left = `${i / count * 100}%`;
                        slot.style.width = `${100 / count}%`;
                        const bar = document.createElement("div");
                        bar.className = "viz-bar";
                        const valueLabel = document.createElement("span");
                        valueLabel.className = "viz-value";
                        slot.append(bar, valueLabel);
                        plot.appendChild(slot);
                        return { slot, bar, valueLabel };
                    });

                    // 각 원소의 정체성은 swap 기록으로 추적하고, 실제 숫자는 각 step.array에서 가져온다.
                    const orders = [];
                    const order = Array.from({ length: count }, (_, i) => i);
                    const compares = [];
                    const swaps = [];
                    let numCompares = 0, numSwaps = 0;
                    for (const step of steps) {
                        if (step.action === "swap") {
                            const a = step.index1, b = step.index2;
                            if (!Number.isInteger(a) || !Number.isInteger(b) ||
                                a < 0 || b < 0 || a >= count || b >= count) {
                                fail("정렬 과정의 swap 인덱스가 잘못되었습니다.");
                                return;
                            }
                            [order[a], order[b]] = [order[b], order[a]];
                            numSwaps++;
                        }
                        if (step.action === "compare") numCompares++;
                        orders.push([...order]);
                        compares.push(numCompares);
                        swaps.push(numSwaps);
                    }

                    let index = 0;
                    let timer = null;
                    function pause() {
                        if (timer !== null) clearInterval(timer);
                        timer = null;
                        playBtn.textContent = "▶ 재생";
                    }
                    function setSpeed() {
                        const wait = Number(speed.value) || 600;
                        plot.style.setProperty("--viz-motion", `${Math.min(480, Math.round(wait * 0.78))}ms`);
                    }
                    function explain(step) {
                        if (step.action === "initial") return "초기 배열 — 재생을 눌러 시작하세요";
                        if (step.action === "complete") return "정렬 완료!";
                        if (step.action === "compare") return `${step.index1 + 1}번째와 ${step.index2 + 1}번째 원소 비교`;
                        if (step.action === "swap") return `${step.index1 + 1}번째와 ${step.index2 + 1}번째 원소 교환`;
                        return step.action || "실행 중";
                    }
                    function render() {
                        const step = steps[index];
                        const orderNow = orders[index];
                        // 핵심: 자리의 번호(1,2,3...)가 아니라 현재 실제 배열의 숫자로 갱신.
                        for (let position = 0; position < count; position++) {
                            const view = views[orderNow[position]];
                            const value = step.array[position];
                            const h = Math.abs(value) / range * 100;
                            view.slot.style.left = `${position / count * 100}%`;
                            view.bar.style.height = value === 0 ? "3px" : `${h}%`;
                            view.bar.style.bottom = `${value < 0 ? baseline - h : baseline}%`;
                            view.bar.classList.toggle("negative", value < 0);
                            view.valueLabel.textContent = String(value);
                            view.slot.setAttribute("aria-label", `${position + 1}번째 원소: ${value}`);
                            const highlight = position === step.index1 || position === step.index2;
                            view.slot.classList.toggle("comparing", highlight && step.action === "compare");
                            view.slot.classList.toggle("swapping", highlight && step.action === "swap");
                        }
                        currentValues.textContent = `[${step.array.join(", ")}]`;
                        actionText.textContent = explain(step);
                        stepText.textContent = `${index} / ${steps.length - 1}`;
                        currentStep.textContent = index;
                        compareCount.textContent = compares[index];
                        swapCount.textContent = swaps[index];
                        progressBar.style.width = `${index / Math.max(1, steps.length - 1) * 100}%`;
                        prevBtn.disabled = index === 0;
                        nextBtn.disabled = index === steps.length - 1;
                    }
                    function next() {
                        if (index < steps.length - 1) {
                            index++;
                            render();
                        }
                        if (index === steps.length - 1) pause();
                    }
                    function restartTimer() {
                        if (timer !== null) clearInterval(timer);
                        timer = setInterval(next, Number(speed.value) || 600);
                    }
                    playBtn.addEventListener("click", () => {
                        if (timer !== null) { pause(); return; }
                        if (index === steps.length - 1) { index = 0; render(); }
                        playBtn.textContent = "⏸ 일시정지";
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
                    setSpeed();
                    render();
                })();
