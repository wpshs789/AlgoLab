<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="com.algolab.i18n.I18n" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Arrays" %>
<%@ page import="com.algolab.dto.SortStep" %>
<%@ page import="com.algolab.service.SortingService" %>
<%@ page import="com.algolab.service.ExperimentService" %>
<% I18n msg = I18n.of(session); %>
<%
    request.setCharacterEncoding("UTF-8");

    String algorithm = request.getParameter("algorithm");
    String numbers = request.getParameter("numbers");
    if ("GET".equalsIgnoreCase(request.getMethod()) && algorithm == null && numbers == null) {
        algorithm = (String) session.getAttribute("lastVizAlgorithm");
        numbers = (String) session.getAttribute("lastVizNumbers");
    }
    int[] inputArray = null;
    List<SortStep> steps = null;
    String error = null;
    // 다른 입력을 시도했다면 오래된 실험 기록이 저장되지 않도록 초기화한다.
    session.removeAttribute("pendingExperiment");

    try {
        if (numbers == null || numbers.trim().isEmpty()) {
            throw new IllegalArgumentException(msg.t("err.numbersRequired"));
        }
        String[] tokens = numbers.split(",", -1);
        if (tokens.length > 30) {
            throw new IllegalArgumentException(msg.t("err.numbersMax"));
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
        String normalizedNumbers = normalizedInput.substring(1, normalizedInput.length() - 1);
        session.setAttribute("lastNumbers", normalizedNumbers);
        session.setAttribute("lastVizAlgorithm", algorithm);
        session.setAttribute("lastVizNumbers", normalizedNumbers);
        com.algolab.util.AlgorithmCookie.save(request, response, algorithm);
    } catch (NumberFormatException ex) {
        error = msg.t("err.numbersFormat");
    } catch (IllegalArgumentException ex) {
        error = "지원하지 않는 알고리즘입니다.".equals(ex.getMessage()) ? msg.t("err.unsupported")
            : "숫자는 1~30개까지 입력할 수 있습니다.".equals(ex.getMessage()) ? msg.t("err.count") : ex.getMessage();
    }

    String algorithmLabel = "bubble".equals(algorithm) ? "Bubble Sort"
            : "selection".equals(algorithm) ? "Selection Sort"
            : "insertion".equals(algorithm) ? "Insertion Sort"
            : "merge".equals(algorithm) ? "Merge Sort"
            : "quick".equals(algorithm) ? "Quick Sort" : msg.t("viz.generic");
    String algorithmDescription = "bubble".equals(algorithm)
            ? msg.t("viz.descBubble")
            : "selection".equals(algorithm)
            ? msg.t("viz.descSelection")
            : "insertion".equals(algorithm)
            ? msg.t("viz.descInsertion")
            : "merge".equals(algorithm)
            ? msg.t("viz.descMerge")
            : "quick".equals(algorithm)
            ? msg.t("viz.descQuick")
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
<html lang="<%= msg.language() %>">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>AlgoLab - <%= msg.t("title.visualizer") %></title>
    <link rel="stylesheet" href="<%= request.getContextPath() %>/resources/css/style.css?v=20261123i18n1">
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
            <h1><%= msg.t("viz.heading") %></h1>
            <p class="subtitle"><%= msg.t("viz.lead") %></p>
        </div>

        <% if (error != null) { %>
            <section class="panel error-panel">
                <h2><%= msg.t("viz.error") %></h2>
                <p><%= error %></p>
                <a href="index.jsp" class="back-link"><%= msg.t("viz.retry") %></a>
            </section>
        <% } else { %>
            <section class="panel" id="vizRoot" data-algorithm="<%= algorithm %>">
                <div class="visualizer-header">
                    <div>
                        <p class="eyebrow">SELECTED ALGORITHM</p>
                        <h2><%= algorithmLabel %></h2>
                    </div>
                    <span class="badge"><%= "insertion".equals(algorithm) ? msg.t("viz.oneJump") : "merge".equals(algorithm) ? msg.t("viz.divideConquer") : "quick".equals(algorithm) ? msg.t("viz.partition") : "Sorting" %></span>
                </div>

                <p class="viz-description"><%= algorithmDescription %></p>
                <p class="viz-input"><%= msg.t("viz.original") %><strong id="originalValues"><%= Arrays.toString(inputArray) %></strong></p>
                <% if ("insertion".equals(algorithm)) { %>
                    <div class="viz-legend" aria-label="<%= msg.t("viz.insertionLegend") %>">
                        <span><i class="legend-key"></i><%= msg.t("viz.key") %></span>
                        <span><i class="legend-sorted"></i><%= msg.t("viz.sorted") %></span>
                        <span><i class="legend-shift"></i><%= msg.t("viz.shifted") %></span>
                        <span><i class="legend-hole"></i><%= msg.t("viz.hole") %></span>
                    </div>
                <% } %>
                <% if ("merge".equals(algorithm)) { %>
                    <div class="merge-legend" aria-label="<%= msg.t("viz.mergeLegend") %>">
                        <span><i class="merge-dot dot-current"></i><%= msg.t("viz.active") %></span>
                        <span><i class="merge-dot dot-ready"></i><%= msg.t("viz.ready") %></span>
                        <span><i class="merge-dot dot-split"></i><%= msg.t("viz.split") %></span>
                        <span><i class="merge-dot" style="background:#facc15"></i><%= msg.t("viz.comparing") %></span>
                    </div>
                <% } %>
                <% if ("quick".equals(algorithm)) { %>
                    <div class="quick-legend" aria-label="<%= msg.t("viz.quickLegend") %>">
                        <span><i class="quick-dot quick-dot-pivot"></i><%= msg.t("viz.pivot") %></span>
                        <span><i class="quick-dot quick-dot-scan"></i><%= msg.t("viz.comparingShort") %></span>
                        <span><i class="quick-dot quick-dot-left"></i><%= msg.t("viz.lessGroup") %></span>
                        <span><i class="quick-dot quick-dot-fixed"></i><%= msg.t("viz.fixed") %></span>
                    </div>
                    <div class="quick-summary" aria-label="<%= msg.t("viz.partitionInfo") %>">
                        <div><span><%= msg.t("viz.range") %></span><strong id="quickRange"><%= msg.t("viz.whole") %></strong></div>
                        <div><span><%= msg.t("viz.pivotVal") %></span><strong id="quickPivot"><%= msg.t("viz.before") %></strong></div>
                        <div><span><%= msg.t("viz.lessGroup") %></span><strong id="quickLeftGroup">-</strong></div>
                        <div><span><%= msg.t("viz.fixed") %></span><strong id="quickFixedCount"><%= msg.f("js.countUnit", 0) %></strong></div>
                    </div>
                    <p class="quick-caption"><%= msg.t("viz.quickCaption") %></p>
                <% } %>
                <p id="vizWarning" class="viz-warning" role="alert"></p>

                <% if ("merge".equals(algorithm)) { %>
                    <div class="merge-section-heading">
                        <h3><%= msg.t("viz.tree") %></h3>
                        <span><%= msg.t("viz.treeHint") %></span>
                    </div>
                    <div class="merge-tree-scroll" id="mergeTreeScroll" tabindex="0"
                         aria-label="<%= msg.t("viz.treeAria") %>">
                        <div class="merge-tree" id="mergeTree"></div>
                    </div>
                    <div class="merge-workbench" id="mergeWorkbench">
                        <div class="merge-workbench-head">
                            <h3><%= msg.t("viz.workbench") %></h3>
                            <span id="mergePhase"><%= msg.t("viz.mergeReady") %></span>
                        </div>
                        <div class="merge-lanes">
                            <div class="merge-lane"><span><%= msg.t("viz.leftArray") %></span><div id="mergeLeftValues" class="merge-bars" aria-label="<%= msg.t("viz.leftBars") %>"></div></div>
                            <div class="merge-lane"><span><%= msg.t("viz.rightArray") %></span><div id="mergeRightValues" class="merge-bars" aria-label="<%= msg.t("viz.rightBars") %>"></div></div>
                        </div>
                        <div class="merge-output-lane"><span><%= msg.t("viz.output") %></span><div id="mergeOutputValues" class="merge-bars" aria-label="<%= msg.t("viz.outputBars") %>"></div></div>
                        <p class="merge-graph-explain"><%= msg.t("viz.barsExplain") %></p>
                        <p id="mergeHint" class="merge-hint"><%= msg.t("viz.mergeHint") %></p>
                    </div>
                <% } else { %>
                    <div class="viz-stage">
                        <div class="viz-plot" id="vizPlot" role="img" aria-label="<%= msg.t("viz.barAria") %>"></div>
                    </div>
                <% } %>

                <p class="viz-current"><%= msg.t("viz.current") %><strong id="currentValues"><%= msg.t("viz.loading") %></strong></p>
                <div class="status-bar">
                    <span id="actionText" role="status" aria-live="polite"><%= msg.t("viz.initial") %></span>
                    <span id="stepText">0 / 0</span>
                </div>
                <div class="progress-track"><div id="progressBar" class="progress-fill"></div></div>
                <div class="controls">
                    <button type="button" id="prevBtn"><%= msg.t("viz.previous") %></button>
                    <button type="button" id="playBtn" class="primary-btn"><%= msg.t("viz.play") %></button>
                    <button type="button" id="nextBtn"><%= msg.t("viz.next") %></button>
                    <button type="button" id="resetBtn"><%= msg.t("viz.reset") %></button>
                </div>
                <div class="speed-control">
                    <label for="speed"><%= msg.t("viz.speed") %></label>
                    <select id="speed">
                        <option value="1200">0.5x</option>
                        <option value="600" selected>1x</option>
                        <option value="300">2x</option>
                        <option value="120">5x</option>
                    </select>
                </div>
            </section>
            <section class="stats-grid">
                <div class="stat-card"><p><%= msg.t("common.arraySize") %></p><h3><%= inputArray.length %></h3></div>
                <div class="stat-card"><p><%= msg.t("common.comparisons") %></p><h3 id="compareCount">0</h3></div>
                <div class="stat-card"><p><%= "insertion".equals(algorithm) ? msg.t("common.movements") : "merge".equals(algorithm) ? msg.t("common.mergeWrites") : msg.t("common.swaps") %></p><h3 id="swapCount">0</h3></div>
                <div class="stat-card"><p><%= msg.t("viz.step") %></p><h3 id="currentStep">0</h3></div>
            </section>
            <section class="save-callout panel">
                <div>
                    <h2><%= msg.t("viz.saveHeading") %></h2>
                    <p class="subtitle"><%= msg.t("viz.saveLead") %></p>
                </div>
                <a class="save-link" href="<%= request.getContextPath() %>/saveExperiment.jsp"><%= msg.t("viz.save") %></a>
            </section>
            <div class="bottom-nav"><a class="back-link" href="index.jsp"><%= msg.t("viz.back") %></a></div>

            <script id="sortData" type="application/json"><%= json.toString() %></script>
            <script id="inputData" type="application/json"><%= Arrays.toString(inputArray) %></script>

            <script>window.AL_I18N = <%= msg.clientJson() %>;</script>
            <% if ("merge".equals(algorithm)) { %>
                <script src="<%= request.getContextPath() %>/resources/js/mergesort.js?v=i18n-v1"></script>
            <% } else { %>
                <script src="<%= request.getContextPath() %>/resources/js/visualizer.js?v=i18n-v1"></script>
            <% } %>
        <% } %>
    </main>
</body>
</html>
