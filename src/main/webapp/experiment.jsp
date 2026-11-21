<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.SQLException,java.time.format.DateTimeFormatter" %>
<%@ page import="com.algolab.dao.ExperimentDAO,com.algolab.dto.Experiment,com.algolab.util.HtmlUtil,com.algolab.util.ExperimentDeleteToken" %>
<%
    Experiment record = null;
    String error = null;
    try {
        long id = Long.parseLong(request.getParameter("id"));
        if (id <= 0) throw new NumberFormatException();
        record = new ExperimentDAO(application).findById(id);
        if (record == null) error = "해당 실험 기록을 찾을 수 없습니다.";
    } catch (NumberFormatException ex) {
        error = "실험 기록 번호가 올바르지 않습니다.";
    } catch (SQLException ex) {
        application.log("AlgoLab: 실험 상세 SELECT 실패", ex);
        error = "실험 기록을 조회할 수 없습니다. 데이터베이스 연결 상태를 확인해 주세요.";
    }
    String deleteCsrf = ExperimentDeleteToken.getOrCreate(session);
    DateTimeFormatter dateFormat = DateTimeFormatter.ofPattern("yyyy.MM.dd HH:mm");
%>
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <title>AlgoLab - 실험 상세</title>
    <link rel="stylesheet" href="<%= request.getContextPath() %>/resources/css/style.css">
    <link rel="stylesheet" href="<%= request.getContextPath() %>/resources/css/history.css">
    <link rel="stylesheet" href="<%= request.getContextPath() %>/resources/css/experiment.css">
</head>
<body>
    <jsp:include page="menu.jsp" />
    <main class="container experiment-container">
        <div class="page-heading">
            <p class="eyebrow">EXPERIMENT DETAIL</p>
            <h1>실험 상세</h1>
            <p class="subtitle">저장된 실험 조건과 정렬 결과를 확인할 수 있습니다.</p>
        </div>
        <% if (error != null) { %>
            <section class="panel experiment-panel"><h2>조회 실패</h2>
                <p class="experiment-alert" role="alert"><%= HtmlUtil.escape(error) %></p>
                <a class="experiment-ghost" href="<%= request.getContextPath() %>/history.jsp">목록으로 돌아가기</a>
            </section>
        <% } else { %>
            <section class="panel experiment-panel">
                <div class="experiment-detail-head">
                    <h2><%= HtmlUtil.escape(record.getTitle()) %></h2>
                    <span>#<%= record.getId() %> · <%= record.getCreatedAt() == null ? "-" : dateFormat.format(record.getCreatedAt().toLocalDateTime()) %></span>
                </div>
                <div class="experiment-preview">
                    <div><span>알고리즘</span><strong><%= HtmlUtil.escape(record.getAlgorithmLabel()) %></strong></div>
                    <div><span>배열 크기</span><strong><%= record.getArraySize() %></strong></div>
                    <div><span>비교 횟수</span><strong><%= record.getComparisons() %></strong></div>
                    <div><span>교환 횟수</span><strong><%= record.getSwaps() %></strong></div>
                </div>
                <div class="experiment-section"><h3>입력 배열</h3>
                    <div class="experiment-code">[<%= HtmlUtil.escape(record.getInputArray()) %>]</div>
                </div>
                <div class="experiment-section"><h3>실험 메모</h3>
                    <div class="experiment-memo"><%= HtmlUtil.escape(record.getMemo().isEmpty() ? "작성된 메모가 없습니다." : record.getMemo()) %></div>
                </div>
                <div class="experiment-actions">
                    <a class="experiment-ghost" href="<%= request.getContextPath() %>/history.jsp">← 목록</a>
                    <% if ("bubble".equals(record.getAlgorithm())) { %>
                        <form action="<%= request.getContextPath() %>/visualizer.jsp" method="post">
                            <input type="hidden" name="algorithm" value="bubble">
                            <input type="hidden" name="numbers" value="<%= HtmlUtil.escape(record.getInputArray()) %>">
                            <button class="experiment-primary" type="submit">↻ 이 배열로 다시 시각화</button>
                        </form>
                    <% } else { %>
                        <span class="experiment-hint">해당 알고리즘의 시각화 기능은 추후 지원될 예정입니다.</span>
                    <% } %>
                    <form method="post" action="<%= request.getContextPath() %>/deleteExperimentProcess.jsp"
                          onsubmit="return confirm('실험 기록을 삭제하시겠습니까? 삭제된 기록은 복구할 수 없습니다.');">
                        <input type="hidden" name="csrf" value="<%= deleteCsrf %>">
                        <input type="hidden" name="id" value="<%= record.getId() %>">
                        <button class="experiment-danger" type="submit">삭제</button>
                    </form>
                </div>
                <p class="experiment-deletion-note">삭제된 실험 기록은 복구할 수 없습니다.</p>
            </section>
        <% } %>
    </main>
</body>
</html>
