<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.Locale,com.algolab.benchmark.BenchmarkReport,com.algolab.benchmark.BenchmarkResult,com.algolab.benchmark.BenchmarkService,com.algolab.util.BenchmarkToken,com.algolab.util.HtmlUtil" %>
<%
    request.setCharacterEncoding("UTF-8");
    BenchmarkReport report = (BenchmarkReport) session.getAttribute("pendingBenchmark");
    String error = null;
    String flash = (String) session.getAttribute("benchmarkError");
    session.removeAttribute("benchmarkError");
    String draftTitle = (String) session.getAttribute("benchmarkDraftTitle");
    if (draftTitle == null) draftTitle = "";
    String requestedSize = report == null ? "500" : String.valueOf(report.getArraySize());
    String pattern = report == null ? "random" : report.getPattern();
    String requestedRepeats = report == null ? "5" : String.valueOf(report.getRepetitions());

    if ("POST".equalsIgnoreCase(request.getMethod())) {
        requestedSize = request.getParameter("size");
        requestedRepeats = request.getParameter("repetitions");
        pattern = request.getParameter("pattern");
        session.removeAttribute("pendingBenchmark");
        report = null;
        try {
            if (requestedSize == null || !requestedSize.matches("[0-9]{1,5}")
                    || requestedRepeats == null || !requestedRepeats.matches("[0-9]{1,2}")) {
                throw new IllegalArgumentException("배열 크기와 반복 횟수를 올바르게 입력해 주세요.");
            }
            int size = Integer.parseInt(requestedSize);
            int repeats = Integer.parseInt(requestedRepeats);
            report = BenchmarkService.measure(size, pattern, repeats);
            session.setAttribute("pendingBenchmark", report);
            session.removeAttribute("benchmarkDraftTitle");
            draftTitle = "";
        } catch (IllegalArgumentException ex) {
            error = ex.getMessage();
        } catch (Exception ex) {
            application.log("AlgoLab: 성능 비교 실행 실패", ex);
            error = "성능 비교를 실행하지 못했습니다. 입력값을 확인하고 다시 시도해 주세요.";
        }
    }
    String csrf = BenchmarkToken.getOrCreate(session);
%>
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <title>AlgoLab - 알고리즘 성능 비교</title>
    <link rel="stylesheet" href="<%= request.getContextPath() %>/resources/css/style.css?v=20261123bench1">
    <link rel="stylesheet" href="<%= request.getContextPath() %>/resources/css/benchmark.css?v=20261123bench1">
</head>
<body>
    <jsp:include page="menu.jsp" />
    <main class="container benchmark-container">
        <div class="page-heading">
            <p class="eyebrow">PERFORMANCE COMPARISON</p>
            <h1>정렬 알고리즘 성능 비교</h1>
            <p class="subtitle">동일한 배열로 5가지 정렬 알고리즘을 실행하고 비교 횟수, 원소 이동 및 실행 시간을 확인할 수 있습니다.</p>
        </div>

        <section class="panel benchmark-config" aria-labelledby="benchmarkConfigHeading">
            <div class="benchmark-section-title">
                <h2 id="benchmarkConfigHeading">비교 조건 설정</h2>
                <span class="benchmark-mini-tag">동일 입력 · 동일 조건</span>
            </div>
            <form method="post" action="<%= request.getContextPath() %>/benchmark.jsp" id="benchmarkForm">
                <div class="benchmark-form-grid">
                    <div class="form-group">
                        <label for="size">배열 크기</label>
                        <input type="number" name="size" id="size" min="10" max="5000" step="1" required
                            value="<%= HtmlUtil.escape(requestedSize == null ? "" : requestedSize) %>">
                        <p class="input-help">10~5,000개 (큰 배열은 실행 시간이 길어질 수 있습니다.)</p>
                    </div>
                    <div class="form-group">
                        <label for="pattern">입력 배열 형태</label>
                        <select name="pattern" id="pattern">
                            <option value="random" <%= "random".equals(pattern) ? "selected" : "" %>>무작위 배열</option>
                            <option value="ascending" <%= "ascending".equals(pattern) ? "selected" : "" %>>이미 정렬된 배열</option>
                            <option value="descending" <%= "descending".equals(pattern) ? "selected" : "" %>>역순 배열</option>
                            <option value="nearly" <%= "nearly".equals(pattern) ? "selected" : "" %>>거의 정렬된 배열</option>
                        </select>
                        <p class="input-help">모든 알고리즘은 같은 회차에서 동일한 배열을 사용합니다.</p>
                    </div>
                    <div class="form-group">
                        <label for="repetitions">측정 횟수</label>
                        <select name="repetitions" id="repetitions">
                            <% for (int c : new int[]{1,3,5,10}) { %>
                                <option value="<%= c %>" <%= String.valueOf(c).equals(requestedRepeats) ? "selected" : "" %>><%= c %>회</option>
                            <% } %>
                        </select>
                        <p class="input-help">각 알고리즘의 측정값을 평균으로 표시합니다.</p>
                    </div>
                </div>
                <button class="start-btn" type="submit" id="runBenchmarkButton">▶ 성능 비교 실행</button>
            </form>
        </section>

        <% if (error != null || flash != null) { %>
        <div class="benchmark-alert" role="alert"><%= HtmlUtil.escape(error != null ? error : flash) %></div>
        <% } %>

        <% if (report != null) { %>
            <section class="panel benchmark-results" aria-labelledby="resultHeading">
                <div class="benchmark-section-title benchmark-results-title">
                    <div>
                        <p class="eyebrow">BENCHMARK RESULTS</p>
                        <h2 id="resultHeading">성능 비교 결과</h2>
                    </div>
                    <span class="benchmark-mini-tag"><%= report.getArraySize() %>개 · <%= HtmlUtil.escape(report.getPatternLabel()) %> · <%= report.getRepetitions() %>회 평균</span>
                </div>
                <div class="benchmark-table-wrap">
                    <table class="benchmark-table">
                        <thead><tr>
                            <th scope="col">알고리즘</th>
                            <th scope="col">평균 시간복잡도</th>
                            <th scope="col">평균 비교 횟수</th>
                            <th scope="col">평균 교환·이동 횟수</th>
                            <th scope="col">평균 실행 시간 (ms)</th>
                        </tr></thead>
                        <tbody>
                        <% for (BenchmarkResult row : report.getResults()) { %>
                            <tr>
                                <th scope="row"><%= row.getLabel() %></th>
                                <td class="benchmark-muted"><%= row.getAverageComplexity() %></td>
                                <td><%= String.format(Locale.KOREA, "%,.1f", row.getAverageComparisons()) %></td>
                                <td><span title="<%= HtmlUtil.escape(row.getOperationLabel()) %>"><%= String.format(Locale.KOREA, "%,.1f", row.getAverageOperations()) %></span>
                                    <small><%= HtmlUtil.escape(row.getOperationLabel()) %></small></td>
                                <td class="benchmark-time"><%= String.format(Locale.KOREA, "%,.4f", row.getAverageMilliseconds()) %></td>
                            </tr>
                        <% } %>
                        </tbody>
                    </table>
                </div>
                <div class="benchmark-explain">
                    <p><strong>측정 방식</strong> · 배열 복사, 정답 검증, 시각화 단계 기록은 실행 시간에 포함되지 않습니다. JVM 예열 후 정렬 코드만 반복 측정합니다.</p>
                    <p><strong>지표 해석</strong> · 교환, Shift, 병합 배치는 서로 다른 연산이므로 값만으로 직접적인 우열을 단정할 수 없습니다. 실행 시간은 PC 상태와 JVM 최적화에 따라 달라집니다.</p>
                    <p><strong>Quick Sort 참고</strong> · 현재 구간의 마지막 원소를 Pivot으로 선택하는 Lomuto 분할 방식입니다. 정렬된 입력에서는 최악 O(n²)이 될 수 있습니다.</p>
                </div>
            </section>

            <section class="panel benchmark-save" aria-labelledby="benchmarkSaveHeading">
                <div>
                    <h2 id="benchmarkSaveHeading">비교 결과 저장</h2>
                    <p class="subtitle">측정 조건과 알고리즘별 평균 결과를 MySQL에 저장하고 실험 기록에서 다시 확인할 수 있습니다.</p>
                </div>
                <form action="<%= request.getContextPath() %>/saveBenchmarkProcess.jsp" method="post" class="benchmark-save-form">
                    <input type="hidden" name="csrf" value="<%= csrf %>">
                    <label for="benchmarkTitle">실험 제목</label>
                    <div class="benchmark-save-inputs">
                        <input type="text" name="title" id="benchmarkTitle" required maxlength="100" placeholder="예: 무작위 배열 500개 성능 비교"
                            value="<%= HtmlUtil.escape(draftTitle) %>">
                        <button type="submit" class="start-btn">결과 저장</button>
                    </div>
                    <p class="input-help">같은 제목의 성능 비교 기록은 중복 저장할 수 없습니다.</p>
                </form>
            </section>
        <% } else { %>
            <section class="panel benchmark-placeholder">
                <p class="eyebrow">READY TO COMPARE</p>
                <h2>측정 조건을 설정하고 성능 비교를 실행해 보세요.</h2>
                <p class="subtitle">배열을 정렬하는 모습은 <a href="<%= request.getContextPath() %>/index.jsp">정렬 시각화</a>에서 확인할 수 있습니다.</p>
            </section>
        <% } %>
        <div class="bottom-nav"><a class="back-link" href="<%= request.getContextPath() %>/index.jsp">← 메인으로 돌아가기</a></div>
    </main>
    <script>
    (function () {
        var form = document.getElementById('benchmarkForm');
        var button = document.getElementById('runBenchmarkButton');
        if (form && button) form.addEventListener('submit', function () {
            if (!form.checkValidity()) return;
            button.disabled = true;
            button.textContent = '측정 중...';
        });
    }());
    </script>
</body>
</html>
