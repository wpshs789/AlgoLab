<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="com.algolab.i18n.I18n" %>
<%@ page import="java.sql.SQLException,java.util.Locale,java.time.format.DateTimeFormatter,com.algolab.benchmark.BenchmarkRecord,com.algolab.benchmark.BenchmarkReport,com.algolab.benchmark.BenchmarkResult,com.algolab.dao.BenchmarkDAO,com.algolab.util.BenchmarkToken,com.algolab.util.HtmlUtil" %>
<% I18n msg = I18n.of(session); %>
<%
    BenchmarkRecord saved = null;
    String loadError = null;
    try {
        long id = Long.parseLong(request.getParameter("id"));
        saved = new BenchmarkDAO(application).findById(id);
    } catch (NumberFormatException ex) {
        loadError = msg.t("err.invalidId");
    } catch (SQLException ex) {
        application.log("AlgoLab: 성능 비교 상세 조회 실패", ex);
        loadError = msg.t("err.benchmarkDb");
    }
    if (saved == null && loadError == null) loadError = msg.t("err.benchmarkNotFound");
    String csrf = BenchmarkToken.getOrCreate(session);
    DateTimeFormatter dateFormat = DateTimeFormatter.ofPattern("yyyy.MM.dd HH:mm");
%>
<!DOCTYPE html><html lang="<%= msg.language() %>"><head>
    <meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
    <title>AlgoLab - <%= msg.t("title.benchmarkDetail") %></title>
    <link rel="stylesheet" href="<%= request.getContextPath() %>/resources/css/style.css?v=20261123i18n1">
    <link rel="stylesheet" href="<%= request.getContextPath() %>/resources/css/benchmark.css?v=20261123i18n1">
</head><body>
<jsp:include page="menu.jsp" />
<main class="container benchmark-container">
    <div class="page-heading"><p class="eyebrow">SAVED BENCHMARK</p><h1><%= msg.t("benchmarkDetail.heading") %></h1>
        <p class="subtitle"><%= msg.t("benchmarkDetail.lead") %></p></div>
    <% if (loadError != null) { %>
        <section class="panel error-panel"><h2><%= msg.t("common.loadError") %></h2><p><%= HtmlUtil.escape(loadError) %></p>
            <a class="back-link" href="<%= request.getContextPath() %>/history.jsp"><%= msg.t("benchmarkDetail.backHistory") %></a></section>
    <% } else { BenchmarkReport r = saved.getReport(); %>
        <section class="panel benchmark-results">
            <div class="benchmark-section-title benchmark-results-title">
                <div><p class="eyebrow">EXPERIMENT #<%= saved.getId() %></p><h2><%= HtmlUtil.escape(saved.getTitle()) %></h2></div>
                <span class="benchmark-mini-tag"><%= saved.getCreatedAt() == null ? "-" : dateFormat.format(saved.getCreatedAt().toLocalDateTime()) %></span>
            </div>
            <p class="benchmark-detail-meta"><%= msg.f("benchmarkDetail.meta", r.getArraySize(), msg.t("pattern." + r.getPattern()), r.getRepetitions()) %></p>
            <div class="benchmark-table-wrap"><table class="benchmark-table">
                <thead><tr><th><%= msg.t("common.algorithm") %></th><th><%= msg.t("benchmark.complexity") %></th><th><%= msg.t("benchmark.avgCompares") %></th><th><%= msg.t("benchmark.avgMoves") %></th><th><%= msg.t("benchmark.avgTime") %></th></tr></thead>
                <tbody>
                <% for (BenchmarkResult row : r.getResults()) { %>
                <tr><th scope="row"><%= row.getLabel() %></th>
                    <td class="benchmark-muted"><%= row.getAverageComplexity() %></td>
                    <td><%= String.format(Locale.KOREA, "%,.1f", row.getAverageComparisons()) %></td>
                    <td><%= String.format(Locale.KOREA, "%,.1f", row.getAverageOperations()) %><small><%= msg.t("operation." + ("insertion".equals(row.getAlgorithm()) ? "insertion" : "merge".equals(row.getAlgorithm()) ? "merge" : "standard")) %></small></td>
                    <td class="benchmark-time"><%= String.format(Locale.KOREA, "%,.4f", row.getAverageMilliseconds()) %></td></tr>
                <% } %>
                </tbody>
            </table></div>
            <div class="benchmark-explain"><p><%= msg.t("benchmarkDetail.explain") %></p></div>
        </section>
        <div class="benchmark-detail-actions">
            <a class="benchmark-link" href="<%= request.getContextPath() %>/history.jsp"><%= msg.t("common.backShort") %></a>
            <a class="benchmark-link" href="<%= request.getContextPath() %>/benchmark.jsp"><%= msg.t("benchmarkDetail.new") %></a>
            <form method="post" action="<%= request.getContextPath() %>/deleteBenchmarkProcess.jsp"
                data-confirm-message="<%= HtmlUtil.escape(msg.t("benchmarkDetail.confirm")) %>"
                                          data-confirm-ok="<%= HtmlUtil.escape(msg.t("common.delete")) %>"
                                          data-confirm-cancel="<%= HtmlUtil.escape(msg.t("common.cancel")) %>">
                <input type="hidden" name="csrf" value="<%= csrf %>">
                <input type="hidden" name="id" value="<%= saved.getId() %>">
                <button type="submit" class="benchmark-delete"><%= msg.t("common.delete") %></button>
            </form>
        </div>
    <% } %>
</main><script src="<%= request.getContextPath() %>/resources/js/confirm-delete.js?v=20261123i18nAudit1" defer></script></body></html>
