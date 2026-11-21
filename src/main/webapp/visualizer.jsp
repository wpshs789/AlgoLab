<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Arrays" %>
<%@ page import="com.algolab.dto.SortStep" %>
<%@ page import="com.algolab.service.SortingService" %>
<%
    request.setCharacterEncoding("UTF-8");

    String algorithm = request.getParameter("algorithm");
    String numbers = request.getParameter("numbers");
    int[] inputArray = null;
    List<SortStep> steps = null;
    String error = null;

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
    } catch (NumberFormatException ex) {
        error = "쉼표(,)로 구분된 정수만 입력해주세요.";
    } catch (IllegalArgumentException ex) {
        error = ex.getMessage();
    }

    // action은 Java 구현에서 정해 둔 고정 문자열이고, array는 정수만 포함함.
    StringBuilder json = new StringBuilder("[");
    if (steps != null) {
        for (int i = 0; i < steps.size(); i++) {
            SortStep step = steps.get(i);
            if (i > 0) json.append(',');
            json.append("{\"array\":").append(Arrays.toString(step.getArray()));
            json.append(",\"index1\":").append(step.getIndex1());
            json.append(",\"index2\":").append(step.getIndex2());
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
    <link rel="stylesheet" href="<%= request.getContextPath() %>/resources/css/style.css?v=20261116a">


</head>
<body>
    <jsp:include page="menu.jsp" />
    <main class="container">
        <div class="page-heading">
            <p class="eyebrow">ALGORITHM VISUALIZER</p>
            <h1>정렬 알고리즘 시각화</h1>
            <p class="subtitle">알고리즘의 비교와 교환 과정을 단계별로 확인하세요.</p>
        </div>

        <% if (error != null) { %>
            <section class="panel error-panel">
                <h2>입력 오류</h2>
                <p><%= error %></p>
                <a href="index.jsp" class="back-link">← 다시 입력하기</a>
            </section>
        <% } else { %>
            <section class="panel" id="vizRoot">
                <div class="visualizer-header">
                    <div>
                        <p class="eyebrow">SELECTED ALGORITHM</p>
                        <h2>Bubble Sort</h2>
                    </div>
                    <span class="badge">Sorting</span>
                </div>

                <p class="viz-input">직접 입력한 배열: <strong id="originalValues"><%= Arrays.toString(inputArray) %></strong></p>
                <p id="vizWarning" class="viz-warning" role="alert"></p>

                <div class="viz-stage">
                    <div class="viz-plot" id="vizPlot" role="img" aria-label="정렬 단계를 나타내는 막대그래프"></div>
                </div>

                <p class="viz-current">현재 배열: <strong id="currentValues">불러오는 중…</strong></p>
                <div class="status-bar">
                    <span id="actionText">정렬 준비</span>
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
                <div class="stat-card"><p>교환 횟수</p><h3 id="swapCount">0</h3></div>
                <div class="stat-card"><p>현재 단계</p><h3 id="currentStep">0</h3></div>
            </section>
            <div class="bottom-nav"><a class="back-link" href="index.jsp">← 다른 배열 입력하기</a></div>

            <script id="sortData" type="application/json"><%= json.toString() %></script>
            <script id="inputData" type="application/json"><%= Arrays.toString(inputArray) %></script>

            <script src="<%= request.getContextPath() %>/resources/js/visualizer.js?v=20261116a"></script>
        <% } %>
    </main>
</body>
</html>
