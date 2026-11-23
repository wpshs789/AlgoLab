<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Arrays" %>
<%@ page import="com.algolab.dto.SortStep" %>
<%@ page import="com.algolab.service.SortingService" %>
<%@ page import="com.algolab.service.ExperimentService" %>
<%
    request.setCharacterEncoding("UTF-8");

    String algorithm = request.getParameter("algorithm");
    String numbers = request.getParameter("numbers");
    int[] inputArray = null;
    List<SortStep> steps = null;
    String error = null;
    // 다른 입력을 시도했다면 오래된 실험 기록이 저장되지 않도록 초기화한다.
    session.removeAttribute("pendingExperiment");

    try {
        if (numbers == null || numbers.trim().isEmpty()) {
            throw new IllegalArgumentException("숫자를 입력해주세요.");
        }
        String[] tokens = numbers.split(",", -1);
        if (tokens.length > 30) {
            throw new IllegalArgumentException("숫자는 최대 30개까지 입력할 수 있습니다.");
        }
        inputArray = new int[tokens.length];
        for (int i = 0; i < tokens.length; i++) {
            inputArray[i] = Integer.parseInt(tokens[i].trim());
        }
        steps = new SortingService().sort(algorithm, inputArray);
        // 비교/교환 횟수는 브라우저가 아닌 Java에서 집계해서 세션에 보관한다.
        session.setAttribute("pendingExperiment",
                ExperimentService.fromVisualization(algorithm, inputArray, steps));
        // 성공적으로 실행된 배열은 같은 세션의 메인 화면에 다시 표시한다.
        String normalizedInput = Arrays.toString(inputArray);
        session.setAttribute("lastNumbers", normalizedInput.substring(1, normalizedInput.length() - 1));
    } catch (NumberFormatException ex) {
        error = "쉼표(,)로 구분된 정수만 입력해주세요.";
    } catch (IllegalArgumentException ex) {
        error = ex.getMessage();
    }

    String algorithmLabel = "bubble".equals(algorithm) ? "Bubble Sort"
            : "selection".equals(algorithm) ? "Selection Sort"
            : "insertion".equals(algorithm) ? "Insertion Sort"
            : "merge".equals(algorithm) ? "Merge Sort"
            : "quick".equals(algorithm) ? "Quick Sort" : "정렬 알고리즘";
    String algorithmDescription = "bubble".equals(algorithm)
            ? "인접한 두 원소를 비교하고 필요한 경우 교환합니다."
            : "selection".equals(algorithm)
            ? "정렬되지 않은 구간에서 최솟값을 찾아 앞쪽에 배치합니다."
            : "insertion".equals(algorithm)
            ? "삽입할 원소(Key)를 선택한 다음, 다음 단계에서 최종 위치로 이동합니다. 비교·이동 횟수는 실제 알고리즘 연산을 기준으로 집계합니다."
            : "merge".equals(algorithm)
            ? "배열을 작은 구간으로 나누고 다시 병합합니다. 비교한 값을 막대그래프로 확인하고, 분할 트리의 부모 노드가 채워지는 과정을 관찰할 수 있습니다."
            : "quick".equals(algorithm)
            ? "현재 구간의 맨 오른쪽 값을 피벗(Pivot)으로 선택합니다. 피벗 이하의 원소를 왼쪽에 배치하고, 피벗의 위치를 확정한 다음 양쪽 구간을 재귀적으로 정렬합니다."
            : "";

    // action은 Java 구현에서 정해 둔 고정 문자열이고, array는 정수만 포함함.
    StringBuilder json = new StringBuilder("[");
    if (steps != null) {
        for (int i = 0; i < steps.size(); i++) {
            SortStep step = steps.get(i);
            if (i > 0) json.append(',');
            json.append("{\"array\":").append(Arrays.toString(step.getArray()));
            json.append(",\"index1\":").append(step.getIndex1());
            json.append(",\"index2\":").append(step.getIndex2());
            json.append(",\"keyValue\":").append(step.getKeyValue());
            json.append(",\"keyOrigin\":").append(step.getKeyOrigin());
            json.append(",\"holeIndex\":").append(step.getHoleIndex());
            json.append(",\"sortedEnd\":").append(step.getSortedEnd());
            if ("merge".equals(algorithm) || "quick".equals(algorithm)) {
                json.append(",\"left\":").append(step.getRangeLeft());
                json.append(",\"mid\":").append(step.getRangeMid());
                json.append(",\"right\":").append(step.getRangeRight());
                json.append(",\"depth\":").append(step.getDepth());
                json.append(",\"output\":").append(Arrays.toString(step.getMergeOutput()));
            }
            json.append(",\"action\":\"").append(step.getAction()).append("\"}");
        }
    }
    json.append(']');
%>
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>AlgoLab - 정렬 시각화</title>
    <link rel="stylesheet" href="<%= request.getContextPath() %>/resources/css/style.css?v=20261123bench1">
    <% if ("merge".equals(algorithm)) { %>
        <link rel="stylesheet" href="<%= request.getContextPath() %>/resources/css/mergesort.css?v=merge-bars-v2">
    <% } %>
    <% if ("quick".equals(algorithm)) { %>
        <link rel="stylesheet" href="<%= request.getContextPath() %>/resources/css/quicksort.css?v=quick-v1">
    <% } %>
</head>
<body>
    <jsp:include page="menu.jsp" />
    <main class="container">
        <div class="page-heading">
            <p class="eyebrow">ALGORITHM VISUALIZER</p>
            <h1>정렬 알고리즘 시각화</h1>
            <p class="subtitle">정렬 과정의 비교·교환·이동 단계를 시각적으로 확인할 수 있습니다.</p>
        </div>

        <% if (error != null) { %>
            <section class="panel error-panel">
                <h2>입력 오류</h2>
                <p><%= error %></p>
                <a href="index.jsp" class="back-link">← 다시 입력하기</a>
            </section>
        <% } else { %>
            <section class="panel" id="vizRoot" data-algorithm="<%= algorithm %>">
                <div class="visualizer-header">
                    <div>
                        <p class="eyebrow">SELECTED ALGORITHM</p>
                        <h2><%= algorithmLabel %></h2>
                    </div>
                    <span class="badge"><%= "insertion".equals(algorithm) ? "한 번에 삽입" : "merge".equals(algorithm) ? "분할 · 병합" : "quick".equals(algorithm) ? "피벗 · 분할" : "Sorting" %></span>
                </div>

                <p class="viz-description"><%= algorithmDescription %></p>
                <p class="viz-input">입력 배열: <strong id="originalValues"><%= Arrays.toString(inputArray) %></strong></p>
                <% if ("insertion".equals(algorithm)) { %>
                    <div class="viz-legend" aria-label="삽입 정렬 색상 안내">
                        <span><i class="legend-key"></i>삽입할 값</span>
                        <span><i class="legend-sorted"></i>정렬된 구간</span>
                        <span><i class="legend-shift"></i>한 번에 밀리는 원소</span>
                        <span><i class="legend-hole"></i>빈자리</span>
                    </div>
                <% } %>
                <% if ("merge".equals(algorithm)) { %>
                    <div class="merge-legend" aria-label="병합 정렬 색상 안내">
                        <span><i class="merge-dot dot-current"></i>진행 중인 구간</span>
                        <span><i class="merge-dot dot-ready"></i>정렬 완료된 구간</span>
                        <span><i class="merge-dot dot-split"></i>분할된 구간</span>
                        <span><i class="merge-dot" style="background:#facc15"></i>비교 중인 값</span>
                    </div>
                <% } %>
                <% if ("quick".equals(algorithm)) { %>
                    <div class="quick-legend" aria-label="퀵 정렬 색상 안내">
                        <span><i class="quick-dot quick-dot-pivot"></i>피벗(P)</span>
                        <span><i class="quick-dot quick-dot-scan"></i>비교 중</span>
                        <span><i class="quick-dot quick-dot-left"></i>피벗 이하 그룹</span>
                        <span><i class="quick-dot quick-dot-fixed"></i>위치 확정</span>
                    </div>
                    <div class="quick-summary" aria-label="현재 분할 정보">
                        <div><span>현재 구간</span><strong id="quickRange">전체 배열</strong></div>
                        <div><span>피벗 값</span><strong id="quickPivot">선택 전</strong></div>
                        <div><span>피벗 이하 그룹</span><strong id="quickLeftGroup">-</strong></div>
                        <div><span>위치 확정</span><strong id="quickFixedCount">0개</strong></div>
                    </div>
                    <p class="quick-caption">맨 오른쪽 원소를 피벗으로 선택합니다. 노란색 원소와 비교해 작은 값을 왼쪽으로 모으고, 피벗의 위치를 확정합니다.</p>
                <% } %>
                <p id="vizWarning" class="viz-warning" role="alert"></p>

                <% if ("merge".equals(algorithm)) { %>
                    <div class="merge-section-heading">
                        <h3>분할 · 병합 트리</h3>
                        <span>병합 중 부모 노드가 한 칸씩 채워집니다. 좌우 스크롤 가능</span>
                    </div>
                    <div class="merge-tree-scroll" id="mergeTreeScroll" tabindex="0"
                         aria-label="병합 정렬 분할 트리. 좌우로 스크롤할 수 있습니다.">
                        <div class="merge-tree" id="mergeTree"></div>
                    </div>
                    <div class="merge-workbench" id="mergeWorkbench">
                        <div class="merge-workbench-head">
                            <h3>병합 작업 공간</h3>
                            <span id="mergePhase">분할 준비</span>
                        </div>
                        <div class="merge-lanes">
                            <div class="merge-lane"><span>왼쪽 부분 배열</span><div id="mergeLeftValues" class="merge-bars" aria-label="왼쪽 부분 배열 막대그래프"></div></div>
                            <div class="merge-lane"><span>오른쪽 부분 배열</span><div id="mergeRightValues" class="merge-bars" aria-label="오른쪽 부분 배열 막대그래프"></div></div>
                        </div>
                        <div class="merge-output-lane"><span>병합 결과 (임시 배열) · 왼쪽부터 한 칸씩 채워집니다</span><div id="mergeOutputValues" class="merge-bars" aria-label="임시 병합 결과 막대그래프"></div></div>
                        <p class="merge-graph-explain">막대 높이는 입력값의 크기를 상대적으로 나타냅니다. 노란색은 비교 중인 값, 흐린 막대는 이미 배치한 값, 초록색은 방금 배치한 값입니다.</p>
                        <p id="mergeHint" class="merge-hint">작은 배열로 나눈 뒤, 병합 과정에서 위쪽 트리와 아래쪽 그래프가 함께 갱신됩니다.</p>
                    </div>
                <% } else { %>
                    <div class="viz-stage">
                        <div class="viz-plot" id="vizPlot" role="img" aria-label="정렬 단계를 나타내는 막대그래프"></div>
                    </div>
                <% } %>

                <p class="viz-current">현재 배열: <strong id="currentValues">불러오는 중…</strong></p>
                <div class="status-bar">
                    <span id="actionText" role="status" aria-live="polite">정렬 준비</span>
                    <span id="stepText">0 / 0</span>
                </div>
                <div class="progress-track"><div id="progressBar" class="progress-fill"></div></div>
                <div class="controls">
                    <button type="button" id="prevBtn">◀ 이전</button>
                    <button type="button" id="playBtn" class="primary-btn">▶ 재생</button>
                    <button type="button" id="nextBtn">다음 ▶</button>
                    <button type="button" id="resetBtn">↺ 처음으로</button>
                </div>
                <div class="speed-control">
                    <label for="speed">재생 속도</label>
                    <select id="speed">
                        <option value="1200">0.5x</option>
                        <option value="600" selected>1x</option>
                        <option value="300">2x</option>
                        <option value="120">5x</option>
                    </select>
                </div>
            </section>
            <section class="stats-grid">
                <div class="stat-card"><p>배열 크기</p><h3><%= inputArray.length %></h3></div>
                <div class="stat-card"><p>비교 횟수</p><h3 id="compareCount">0</h3></div>
                <div class="stat-card"><p><%= "insertion".equals(algorithm) ? "이동 횟수" : "merge".equals(algorithm) ? "병합 배치 횟수" : "교환 횟수" %></p><h3 id="swapCount">0</h3></div>
                <div class="stat-card"><p>현재 단계</p><h3 id="currentStep">0</h3></div>
            </section>
            <section class="save-callout panel">
                <div>
                    <h2>실험 결과를 저장하시겠습니까?</h2>
                    <p class="subtitle">입력 배열과 서버에서 계산한 비교 및 교환·이동 횟수를 실험 기록에 저장할 수 있습니다.</p>
                </div>
                <a class="save-link" href="<%= request.getContextPath() %>/saveExperiment.jsp">✎ 실험 기록 저장</a>
            </section>
            <div class="bottom-nav"><a class="back-link" href="index.jsp">← 다른 배열 입력하기</a></div>

            <script id="sortData" type="application/json"><%= json.toString() %></script>
            <script id="inputData" type="application/json"><%= Arrays.toString(inputArray) %></script>

            <% if ("merge".equals(algorithm)) { %>
                <script src="<%= request.getContextPath() %>/resources/js/mergesort.js?v=merge-bars-v2"></script>
            <% } else { %>
                <script src="<%= request.getContextPath() %>/resources/js/visualizer.js?v=quick-v1"></script>
            <% } %>
        <% } %>
    </main>
</body>
</html>
