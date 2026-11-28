<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="com.algolab.i18n.I18n,com.algolab.auth.Auth,com.algolab.auth.User" %>
<%@ page import="java.util.List,java.util.ArrayList,java.sql.SQLException,java.time.format.DateTimeFormatter" %>
<%@ page import="com.algolab.benchmark.BenchmarkRecord,com.algolab.dao.BenchmarkDAO,com.algolab.util.BenchmarkToken" %>
<%@ page import="com.algolab.dao.ExperimentDAO,com.algolab.dto.Experiment,com.algolab.util.HtmlUtil,com.algolab.util.ExperimentDeleteToken" %>
<%
    response.setHeader("Cache-Control", "no-store");
    I18n msg = I18n.of(session);
    User actor = Auth.current(session);
    if (actor == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp?next=history.jsp");
        return;
    }
%>
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
        records = dao.search(keyword, algorithmFilter, order, actor.id());
        totalCount = dao.countAll(actor.id());
        algorithmCount = dao.countAlgorithms(actor.id());
    } catch (SQLException ex) {
        application.log("AlgoLab: 실험 기록 SELECT 실패", ex);
        dbError = msg.t("err.historyDb");
    }
    // 기존 시각화 기록과 독립된 성능 비교 기록도 불러옵니다.
    List<BenchmarkRecord> benchmarkRecords = new ArrayList<>();
    String benchmarkError = null;
    try {
        benchmarkRecords = new BenchmarkDAO(application).findRecent(100, actor.id());
    } catch (SQLException ex) {
        application.log("AlgoLab: 성능 비교 목록 조회 실패", ex);
        benchmarkError = msg.t("err.historyBenchmarkDb");
    }
    String deleteCsrf = ExperimentDeleteToken.getOrCreate(session);
    String benchmarkDeleteCsrf = BenchmarkToken.getOrCreate(session);
    String historyNotice = (String) session.getAttribute("historyNotice");
    String historyError = (String) session.getAttribute("historyError");
    session.removeAttribute("historyNotice");
    session.removeAttribute("historyError");
    DateTimeFormatter dateFormat = DateTimeFormatter.ofPattern("yyyy.MM.dd HH:mm");
%>
<!DOCTYPE html>
<html lang="<%= msg.language() %>">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <title>AlgoLab - <%= msg.t("title.history") %></title>
    <link rel="stylesheet" href="<%= request.getContextPath() %>/resources/css/style.css?v=20261123i18n1">
    <link rel="stylesheet" href="<%= request.getContextPath() %>/resources/css/history.css">
    <link rel="stylesheet" href="<%= request.getContextPath() %>/resources/css/benchmark.css?v=20261123i18n1">
    <link rel="stylesheet" href="<%= request.getContextPath() %>/resources/css/confirm-dialog.css?v=20261123dialog2">
    <link rel="stylesheet" href="<%= request.getContextPath() %>/resources/css/auth.css?v=login1">
</head>
<body>
    <jsp:include page="menu.jsp" />
    <main class="container history-container">
        <div class="history-heading">
            <div class="page-heading">
                <p class="eyebrow">EXPERIMENT LOG</p>
                <h1><%= msg.t("history.heading") %></h1>
                <p class="subtitle"><%= msg.t("history.lead") %></p>
            </div>
            <a href="<%= request.getContextPath() %>/index.jsp" class="history-main-action"><%= msg.t("history.new") %></a>
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
        <section class="history-summary" aria-label="<%= msg.t("history.summaryAria") %>">
            <div class="history-summary-card"><p><%= msg.t("history.visualizationCount") %></p><strong><%= totalCount %><span><%= msg.t("common.records") %></span></strong></div>
            <div class="history-summary-card"><p><%= msg.t("history.sortCount") %></p><strong><%= algorithmCount %><span><%= msg.t("common.types") %></span></strong></div>
            <div class="history-summary-card"><p><%= msg.t("history.management") %></p><strong class="history-status-text"><%= dbError == null ? msg.t("history.dbConnected") : msg.t("history.dbDisconnected") %></strong></div>
        </section>
        <section class="panel history-board" aria-labelledby="boardHeading">
            <div class="history-board-heading">
                <div>
                    <p class="eyebrow">EXPERIMENTS</p>
                    <h2 id="boardHeading"><%= msg.t("history.list") %></h2>
                </div>
                <span class="history-count"><%= msg.f("history.max", records.size()) %></span>
            </div>
            <form method="get" action="<%= request.getContextPath() %>/history.jsp" class="history-search" role="search">
                <div class="history-field history-keyword">
                    <label for="historyKeyword"><%= msg.t("history.searchTitle") %></label>
                    <input type="search" id="historyKeyword" name="keyword" maxlength="100"
                           placeholder="<%= msg.t("history.searchPlaceholder") %>" value="<%= HtmlUtil.escape(keyword) %>">
                </div>
                <div class="history-field">
                    <label for="historyAlgorithm"><%= msg.t("common.algorithm") %></label>
                    <select id="historyAlgorithm" name="algorithm">
                        <option value="all" <%= "all".equals(algorithmFilter) ? "selected" : "" %>><%= msg.t("history.all") %></option>
                        <option value="bubble" <%= "bubble".equals(algorithmFilter) ? "selected" : "" %>>Bubble Sort</option>
                        <option value="selection" <%= "selection".equals(algorithmFilter) ? "selected" : "" %>>Selection Sort</option>
                        <option value="insertion" <%= "insertion".equals(algorithmFilter) ? "selected" : "" %>>Insertion Sort</option>
                        <option value="merge" <%= "merge".equals(algorithmFilter) ? "selected" : "" %>>Merge Sort</option>
                        <option value="quick" <%= "quick".equals(algorithmFilter) ? "selected" : "" %>>Quick Sort</option>
                    </select>
                </div>
                <div class="history-field">
                    <label for="historyOrder"><%= msg.t("history.order") %></label>
                    <select id="historyOrder" name="order">
                        <option value="latest" <%= "latest".equals(order) ? "selected" : "" %>><%= msg.t("history.latest") %></option>
                        <option value="oldest" <%= "oldest".equals(order) ? "selected" : "" %>><%= msg.t("history.oldest") %></option>
                    </select>
                </div>
                <button type="submit" class="history-search-btn"><%= msg.t("history.search") %></button>
            </form>
            <div class="history-table-scroll">
                <table class="history-table">
                    <thead>
                        <tr>
                            <th scope="col"><%= msg.t("common.id") %></th><th scope="col"><%= msg.t("common.title") %></th><th scope="col"><%= msg.t("common.algorithm") %></th>
                            <th scope="col"><%= msg.t("common.arraySize") %></th><th scope="col"><%= msg.t("common.comparisons") %></th><th scope="col"><%= msg.t("history.operations") %></th><th scope="col"><%= msg.t("history.created") %></th><th scope="col"><%= msg.t("history.manage") %></th>
                        </tr>
                    </thead>
                    <tbody>
                        <% if (dbError == null && records.isEmpty()) { %>
                            <tr><td colspan="8" class="history-empty"><%= msg.t("history.noRows") %></td></tr>
                        <% } else if (dbError != null) { %>
                            <tr><td colspan="8" class="history-empty"><%= msg.t("history.retryDb") %></td></tr>
                        <% } else { for (Experiment record : records) { %>
                            <tr>
                                <td class="history-id">#<%= record.getId() %></td>
                                <td class="history-title-cell"><a class="history-title-link" href="<%= request.getContextPath() %>/experiment.jsp?id=<%= record.getId() %>"><%= HtmlUtil.escape(record.getTitle()) %></a><small class="record-owner"><%= msg.t("auth.author") %>: <%= HtmlUtil.escape(record.getOwnerName() == null ? msg.t("auth.legacy") : record.getOwnerName()) %></small></td>
                                <td><span class="history-algo history-algo-<%= HtmlUtil.escape(record.getAlgorithm()) %>"><%= HtmlUtil.escape(record.getAlgorithmLabel()) %></span></td>
                                <td class="history-number"><%= record.getArraySize() %></td>
                                <td class="history-number"><%= record.getComparisons() %></td>
                                <td class="history-number" title="<%= "insertion".equals(record.getAlgorithm()) ? msg.t("common.movements") : "merge".equals(record.getAlgorithm()) ? msg.t("common.mergeWrites") : msg.t("common.swaps") %>"><%= record.getSwaps() %></td>
                                <td class="history-date"><%= record.getCreatedAt() == null ? "-" : dateFormat.format(record.getCreatedAt().toLocalDateTime()) %></td>
                                <td class="history-manage">
                                    <% if (Auth.owns(session, record.getOwnerId())) { %>
                                    <form method="post" action="<%= request.getContextPath() %>/deleteExperimentProcess.jsp"
                                          data-confirm-message="<%= HtmlUtil.escape(msg.t("history.confirmDelete")) %>"
                                          data-confirm-ok="<%= HtmlUtil.escape(msg.t("common.delete")) %>"
                                          data-confirm-cancel="<%= HtmlUtil.escape(msg.t("common.cancel")) %>">
                                        <input type="hidden" name="csrf" value="<%= deleteCsrf %>">
                                        <input type="hidden" name="id" value="<%= record.getId() %>">
                                        <button class="history-delete-button" type="submit" aria-label="<%= HtmlUtil.escape(msg.f("history.deleteLabel", record.getTitle())) %>"><%= msg.t("common.delete") %></button>
                                    </form>
                                    <% } else { %><span class="record-owner">—</span><% } %>
                                </td>
                            </tr>
                        <% } } %>
                    </tbody>
                </table>
            </div>
            <p class="history-footer-note"><%= msg.t("history.separate") %></p>
        </section>

        <section class="panel benchmark-history-panel" aria-labelledby="savedBenchmarksHeading">
            <div class="benchmark-history-head">
                <div><p class="eyebrow">BENCHMARK LOG</p><h2 id="savedBenchmarksHeading"><%= msg.t("history.benchHeading") %></h2>
                    <p class="subtitle"><%= msg.t("history.benchLead") %></p></div>
                <a class="history-main-action" href="<%= request.getContextPath() %>/benchmark.jsp"><%= msg.t("history.newBenchmark") %></a>
            </div>
            <% if (benchmarkError != null) { %><div class="history-notice" role="alert"><%= HtmlUtil.escape(benchmarkError) %></div><% } %>
            <div class="benchmark-table-wrap"><table class="benchmark-history-table">
                <thead><tr><th><%= msg.t("common.id") %></th><th><%= msg.t("common.title") %></th><th><%= msg.t("common.arraySize") %></th><th><%= msg.t("history.pattern") %></th><th><%= msg.t("benchmark.repetitions") %></th><th><%= msg.t("history.savedDate") %></th><th scope="col"><%= msg.t("history.manage") %></th></tr></thead>
                <tbody>
                <% if (benchmarkRecords.isEmpty()) { %>
                    <tr><td class="benchmark-history-empty" colspan="7"><%= benchmarkError == null ? msg.t("history.noBenchmark") : msg.t("history.checkBenchmark") %></td></tr>
                <% } else { for (BenchmarkRecord record : benchmarkRecords) { %>
                    <tr><td>#<%= record.getId() %></td>
                        <td><a href="<%= request.getContextPath() %>/benchmarkDetail.jsp?id=<%= record.getId() %>"><%= HtmlUtil.escape(record.getTitle()) %></a><small class="record-owner"><%= msg.t("auth.author") %>: <%= HtmlUtil.escape(record.getOwnerName() == null ? msg.t("auth.legacy") : record.getOwnerName()) %></small></td>
                        <td><%= record.getReport().getArraySize() %><%= msg.t("common.items") %></td>
                        <td><%= msg.t("pattern." + record.getReport().getPattern()) %></td>
                        <td><%= record.getReport().getRepetitions() %><%= msg.t("common.repetitions") %></td>
                        <td><%= record.getCreatedAt() == null ? "-" : dateFormat.format(record.getCreatedAt().toLocalDateTime()) %></td>
                        <td class="history-manage">
                            <% if (Auth.owns(session, record.getOwnerId())) { %>
                            <form method="post" action="<%= request.getContextPath() %>/deleteBenchmarkProcess.jsp"
                                  data-confirm-message="<%= HtmlUtil.escape(msg.t("benchmarkDetail.confirm")) %>"
                                  data-confirm-ok="<%= HtmlUtil.escape(msg.t("common.delete")) %>"
                                  data-confirm-cancel="<%= HtmlUtil.escape(msg.t("common.cancel")) %>">
                                <input type="hidden" name="csrf" value="<%= benchmarkDeleteCsrf %>">
                                <input type="hidden" name="id" value="<%= record.getId() %>">
                                <button class="history-delete-button" type="submit" aria-label="<%= HtmlUtil.escape(msg.f("history.deleteLabel", record.getTitle())) %>"><%= msg.t("common.delete") %></button>
                            </form>
                            <% } else { %><span class="record-owner">—</span><% } %>
                        </td></tr>
                <% } } %>
                </tbody>
            </table></div>
        </section>
        <div class="bottom-nav"><a class="back-link" href="<%= request.getContextPath() %>/index.jsp"><%= msg.t("common.backHome") %></a></div>
    </main>
<script src="<%= request.getContextPath() %>/resources/js/confirm-delete.js?v=20261123dialog2" defer></script>
</body>
</html>
