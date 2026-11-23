<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.SQLException,java.util.Locale,java.time.format.DateTimeFormatter,com.algolab.benchmark.BenchmarkRecord,com.algolab.benchmark.BenchmarkReport,com.algolab.benchmark.BenchmarkResult,com.algolab.dao.BenchmarkDAO,com.algolab.util.BenchmarkToken,com.algolab.util.HtmlUtil" %>
<%
    BenchmarkRecord saved = null;
    String loadError = null;
    try {
        long id = Long.parseLong(request.getParameter("id"));
        saved = new BenchmarkDAO(application).findById(id);
    } catch (NumberFormatException ex) {
        loadError = "올바른 실험 번호가 아닙니다.";
    } catch (SQLException ex) {
        application.log("AlgoLab: 성능 비교 상세 조회 실패", ex);
        loadError = "저장된 성능 비교 결과를 불러오지 못했습니다. DB 연결을 확인해 주세요.";
    }
    if (saved == null && loadError == null) loadError = "해당 성능 비교 기록이 없습니다.";
    String csrf = BenchmarkToken.getOrCreate(session);
    DateTimeFormatter dateFormat = DateTimeFormatter.ofPattern("yyyy.MM.dd HH:mm");
%>
<!DOCTYPE html><html lang="ko"><head>
    <meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
    <title>AlgoLab - 성능 비교 상세</title>
    <link rel="stylesheet" href="<%= request.getContextPath() %>/resources/css/style.css?v=20261123bench1">
    <link rel="stylesheet" href="<%= request.getContextPath() %>/resources/css/benchmark.css?v=20261123bench1">
</head><body>
<jsp:include page="menu.jsp" />
<main class="container benchmark-container">
    <div class="page-heading"><p class="eyebrow">SAVED BENCHMARK</p><h1>성능 비교 상세</h1>
        <p class="subtitle">MySQL에 저장된 측정 조건과 결과를 확인할 수 있습니다.</p></div>
    <% if (loadError != null) { %>
        <section class="panel error-panel"><h2>조회 오류</h2><p><%= HtmlUtil.escape(loadError) %></p>
            <a class="back-link" href="<%= request.getContextPath() %>/history.jsp">실험 기록으로 돌아가기</a></section>
    <% } else { BenchmarkReport r = saved.getReport(); %>
        <section class="panel benchmark-results">
            <div class="benchmark-section-title benchmark-results-title">
                <div><p class="eyebrow">EXPERIMENT #<%= saved.getId() %></p><h2><%= HtmlUtil.escape(saved.getTitle()) %></h2></div>
                <span class="benchmark-mini-tag"><%= saved.getCreatedAt() == null ? "-" : dateFormat.format(saved.getCreatedAt().toLocalDateTime()) %></span>
            </div>
            <p class="benchmark-detail-meta">배열 크기 <strong><%= r.getArraySize() %></strong>개 · <strong><%= HtmlUtil.escape(r.getPatternLabel()) %></strong> · <strong><%= r.getRepetitions() %></strong>회 평균</p>
            <div class="benchmark-table-wrap"><table class="benchmark-table">
                <thead><tr><th>알고리즘</th><th>평균 시간복잡도</th><th>평균 비교 횟수</th><th>평균 교환·이동 횟수</th><th>평균 실행 시간 (ms)</th></tr></thead>
                <tbody>
                <% for (BenchmarkResult row : r.getResults()) { %>
                <tr><th scope="row"><%= row.getLabel() %></th>
                    <td class="benchmark-muted"><%= row.getAverageComplexity() %></td>
                    <td><%= String.format(Locale.KOREA, "%,.1f", row.getAverageComparisons()) %></td>
                    <td><%= String.format(Locale.KOREA, "%,.1f", row.getAverageOperations()) %><small><%= HtmlUtil.escape(row.getOperationLabel()) %></small></td>
                    <td class="benchmark-time"><%= String.format(Locale.KOREA, "%,.4f", row.getAverageMilliseconds()) %></td></tr>
                <% } %>
                </tbody>
            </table></div>
            <div class="benchmark-explain"><p>실행 시간은 저장 당시 측정된 값이며, PC/JVM 환경에 따라 달라집니다. 교환·이동 횟수는 알고리즘마다 계산 기준이 다릅니다.</p></div>
        </section>
        <div class="benchmark-detail-actions">
            <a class="benchmark-link" href="<%= request.getContextPath() %>/history.jsp">← 목록</a>
            <a class="benchmark-link" href="<%= request.getContextPath() %>/benchmark.jsp">새로 비교하기</a>
            <form method="post" action="<%= request.getContextPath() %>/deleteBenchmarkProcess.jsp"
                onsubmit="return confirm('성능 비교 기록을 삭제하시겠습니까? 삭제된 기록은 복구할 수 없습니다.');">
                <input type="hidden" name="csrf" value="<%= csrf %>">
                <input type="hidden" name="id" value="<%= saved.getId() %>">
                <button type="submit" class="benchmark-delete">삭제</button>
            </form>
        </div>
    <% } %>
</main></body></html>
