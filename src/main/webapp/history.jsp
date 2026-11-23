<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.List,java.util.ArrayList,java.sql.SQLException,java.time.format.DateTimeFormatter" %>
<%@ page import="com.algolab.benchmark.BenchmarkRecord,com.algolab.dao.BenchmarkDAO,com.algolab.util.BenchmarkToken" %>
<%@ page import="com.algolab.dao.ExperimentDAO,com.algolab.dto.Experiment,com.algolab.util.HtmlUtil,com.algolab.util.ExperimentDeleteToken" %>
<%
    request.setCharacterEncoding("UTF-8");
    String keyword = request.getParameter("keyword");
    if (keyword == null) keyword = "";
    keyword = keyword.trim();
    if (keyword.length() > 100) keyword = keyword.substring(0, 100);

    String algorithmFilter = request.getParameter("algorithm");
    if (!"bubble".equals(algorithmFilter) && !"selection".equals(algorithmFilter)
        && !"insertion".equals(algorithmFilter) && !"merge".equals(algorithmFilter)
        && !"quick".equals(algorithmFilter)) {
        algorithmFilter = "all";
    }
    String order = "oldest".equals(request.getParameter("order")) ? "oldest" : "latest";

    List<Experiment> records = new ArrayList<>();
    long totalCount = 0;
    int algorithmCount = 0;
    String dbError = null;
    try {
        ExperimentDAO dao = new ExperimentDAO(application);
        records = dao.search(keyword, algorithmFilter, order);
        totalCount = dao.countAll();
        algorithmCount = dao.countAlgorithms();
    } catch (SQLException ex) {
        application.log("AlgoLab: 실험 기록 SELECT 실패", ex);
        dbError = "실험 기록을 불러오지 못했습니다. 데이터베이스 연결과 테이블 생성 상태를 확인해 주세요.";
    }
    // 기존 시각화 기록과 독립된 성능 비교 기록도 불러옵니다.
    List<BenchmarkRecord> benchmarkRecords = new ArrayList<>();
    String benchmarkError = null;
    try {
        benchmarkRecords = new BenchmarkDAO(application).findRecent(100);
    } catch (SQLException ex) {
        application.log("AlgoLab: 성능 비교 목록 조회 실패", ex);
        benchmarkError = "성능 비교 기록을 불러오지 못했습니다. database/benchmark_schema.sql 실행 여부를 확인해 주세요.";
    }
    String deleteCsrf = ExperimentDeleteToken.getOrCreate(session);
    String historyNotice = (String) session.getAttribute("historyNotice");
    String historyError = (String) session.getAttribute("historyError");
    session.removeAttribute("historyNotice");
    session.removeAttribute("historyError");
    DateTimeFormatter dateFormat = DateTimeFormatter.ofPattern("yyyy.MM.dd HH:mm");
%>
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <title>AlgoLab - 실험 기록</title>
    <link rel="stylesheet" href="<%= request.getContextPath() %>/resources/css/style.css?v=20261123bench1">
    <link rel="stylesheet" href="<%= request.getContextPath() %>/resources/css/history.css">
    <link rel="stylesheet" href="<%= request.getContextPath() %>/resources/css/benchmark.css?v=20261123bench1">
</head>
<body>
    <jsp:include page="menu.jsp" />
    <main class="container history-container">
        <div class="history-heading">
            <div class="page-heading">
                <p class="eyebrow">EXPERIMENT LOG</p>
                <h1>실험 기록</h1>
                <p class="subtitle">저장된 정렬 실험을 검색하고 다시 실행할 수 있습니다.</p>
            </div>
            <a href="<%= request.getContextPath() %>/index.jsp" class="history-main-action">+ 새로운 실험</a>
        </div>
        <% if (historyNotice != null) { %>
            <div class="history-notice history-notice-success" role="status"><span><%= HtmlUtil.escape(historyNotice) %></span></div>
        <% } %>
        <% if (historyError != null) { %>
            <div class="history-notice history-notice-error" role="alert"><span><%= HtmlUtil.escape(historyError) %></span></div>
        <% } %>
        <% if (dbError != null) { %>
            <div class="history-notice" role="alert"><span><%= HtmlUtil.escape(dbError) %></span></div>
        <% } %>
        <section class="history-summary" aria-label="실험 기록 요약">
            <div class="history-summary-card"><p>시각화 기록</p><strong><%= totalCount %><span> 건</span></strong></div>
            <div class="history-summary-card"><p>시각화 알고리즘</p><strong><%= algorithmCount %><span> 종류</span></strong></div>
            <div class="history-summary-card"><p>기록 관리</p><strong class="history-status-text"><%= dbError == null ? "MySQL 연결" : "연결 확인 필요" %></strong></div>
        </section>
        <section class="panel history-board" aria-labelledby="boardHeading">
            <div class="history-board-heading">
                <div>
                    <p class="eyebrow">EXPERIMENTS</p>
                    <h2 id="boardHeading">실험 목록</h2>
                </div>
                <span class="history-count">최대 200건 · <%= records.size() %>건 표시</span>
            </div>
            <form method="get" action="<%= request.getContextPath() %>/history.jsp" class="history-search" role="search">
                <div class="history-field history-keyword">
                    <label for="historyKeyword">제목 검색</label>
                    <input type="search" id="historyKeyword" name="keyword" maxlength="100"
                           placeholder="실험 제목을 검색하세요" value="<%= HtmlUtil.escape(keyword) %>">
                </div>
                <div class="history-field">
                    <label for="historyAlgorithm">알고리즘</label>
                    <select id="historyAlgorithm" name="algorithm">
                        <option value="all" <%= "all".equals(algorithmFilter) ? "selected" : "" %>>전체</option>
                        <option value="bubble" <%= "bubble".equals(algorithmFilter) ? "selected" : "" %>>Bubble Sort</option>
                        <option value="selection" <%= "selection".equals(algorithmFilter) ? "selected" : "" %>>Selection Sort</option>
                        <option value="insertion" <%= "insertion".equals(algorithmFilter) ? "selected" : "" %>>Insertion Sort</option>
                        <option value="merge" <%= "merge".equals(algorithmFilter) ? "selected" : "" %>>Merge Sort</option>
                        <option value="quick" <%= "quick".equals(algorithmFilter) ? "selected" : "" %>>Quick Sort</option>
                    </select>
                </div>
                <div class="history-field">
                    <label for="historyOrder">정렬</label>
                    <select id="historyOrder" name="order">
                        <option value="latest" <%= "latest".equals(order) ? "selected" : "" %>>최신순</option>
                        <option value="oldest" <%= "oldest".equals(order) ? "selected" : "" %>>오래된순</option>
                    </select>
                </div>
                <button type="submit" class="history-search-btn">검색</button>
            </form>
            <div class="history-table-scroll">
                <table class="history-table">
                    <thead>
                        <tr>
                            <th scope="col">번호</th><th scope="col">실험 제목</th><th scope="col">알고리즘</th>
                            <th scope="col">배열 크기</th><th scope="col">비교 횟수</th><th scope="col">교환·이동 횟수</th><th scope="col">작성일</th><th scope="col">관리</th>
                        </tr>
                    </thead>
                    <tbody>
                        <% if (dbError == null && records.isEmpty()) { %>
                            <tr><td colspan="8" class="history-empty">등록된 실험이 없거나 검색 조건에 맞는 기록이 없습니다.</td></tr>
                        <% } else if (dbError != null) { %>
                            <tr><td colspan="8" class="history-empty">데이터베이스 연결을 확인한 후 새로고침해 주세요.</td></tr>
                        <% } else { for (Experiment record : records) { %>
                            <tr>
                                <td class="history-id">#<%= record.getId() %></td>
                                <td class="history-title-cell"><a class="history-title-link" href="<%= request.getContextPath() %>/experiment.jsp?id=<%= record.getId() %>"><%= HtmlUtil.escape(record.getTitle()) %></a></td>
                                <td><span class="history-algo history-algo-<%= HtmlUtil.escape(record.getAlgorithm()) %>"><%= HtmlUtil.escape(record.getAlgorithmLabel()) %></span></td>
                                <td class="history-number"><%= record.getArraySize() %></td>
                                <td class="history-number"><%= record.getComparisons() %></td>
                                <td class="history-number" title="<%= "insertion".equals(record.getAlgorithm()) ? "이동 횟수" : "merge".equals(record.getAlgorithm()) ? "병합 배치 횟수" : "교환 횟수" %>"><%= record.getSwaps() %></td>
                                <td class="history-date"><%= record.getCreatedAt() == null ? "-" : dateFormat.format(record.getCreatedAt().toLocalDateTime()) %></td>
                                <td class="history-manage">
                                    <form method="post" action="<%= request.getContextPath() %>/deleteExperimentProcess.jsp"
                                          onsubmit="return confirm('실험 기록을 삭제하시겠습니까? 삭제된 기록은 복구할 수 없습니다.');">
                                        <input type="hidden" name="csrf" value="<%= deleteCsrf %>">
                                        <input type="hidden" name="id" value="<%= record.getId() %>">
                                        <button class="history-delete-button" type="submit" aria-label="<%= HtmlUtil.escape(record.getTitle()) %> 삭제">삭제</button>
                                    </form>
                                </td>
                            </tr>
                        <% } } %>
                    </tbody>
                </table>
            </div>
            <p class="history-footer-note">시각화 실험과 성능 비교 실험은 별도로 관리됩니다. 성능 비교 기록은 아래에서 확인할 수 있습니다.</p>
        </section>

        <section class="panel benchmark-history-panel" aria-labelledby="savedBenchmarksHeading">
            <div class="benchmark-history-head">
                <div><p class="eyebrow">BENCHMARK LOG</p><h2 id="savedBenchmarksHeading">성능 비교 기록</h2>
                    <p class="subtitle">같은 조건에서 실행한 5가지 정렬 알고리즘의 측정 결과를 확인합니다.</p></div>
                <a class="history-main-action" href="<%= request.getContextPath() %>/benchmark.jsp">+ 성능 비교</a>
            </div>
            <% if (benchmarkError != null) { %><div class="history-notice" role="alert"><%= HtmlUtil.escape(benchmarkError) %></div><% } %>
            <div class="benchmark-table-wrap"><table class="benchmark-history-table">
                <thead><tr><th>번호</th><th>실험 제목</th><th>배열 크기</th><th>배열 형태</th><th>측정 횟수</th><th>저장 일시</th></tr></thead>
                <tbody>
                <% if (benchmarkRecords.isEmpty()) { %>
                    <tr><td class="benchmark-history-empty" colspan="6"><%= benchmarkError == null ? "저장된 성능 비교 기록이 없습니다." : "성능 비교 데이터베이스를 확인해 주세요." %></td></tr>
                <% } else { for (BenchmarkRecord record : benchmarkRecords) { %>
                    <tr><td>#<%= record.getId() %></td>
                        <td><a href="<%= request.getContextPath() %>/benchmarkDetail.jsp?id=<%= record.getId() %>"><%= HtmlUtil.escape(record.getTitle()) %></a></td>
                        <td><%= record.getReport().getArraySize() %>개</td>
                        <td><%= HtmlUtil.escape(record.getReport().getPatternLabel()) %></td>
                        <td><%= record.getReport().getRepetitions() %>회</td>
                        <td><%= record.getCreatedAt() == null ? "-" : dateFormat.format(record.getCreatedAt().toLocalDateTime()) %></td></tr>
                <% } } %>
                </tbody>
            </table></div>
        </section>
        <div class="bottom-nav"><a class="back-link" href="<%= request.getContextPath() %>/index.jsp">← 메인으로 돌아가기</a></div>
    </main>
</body>
</html>
