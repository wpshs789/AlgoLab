<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="com.algolab.i18n.I18n,com.algolab.auth.Auth,com.algolab.auth.User" %>
<%@ page import="java.sql.SQLException,java.time.format.DateTimeFormatter" %>
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
    Experiment record = null;
    String error = null;
    try {
        long id = Long.parseLong(request.getParameter("id"));
        if (id <= 0) throw new NumberFormatException();
        record = new ExperimentDAO(application).findById(id, actor.id());
        if (record == null) error = msg.t("err.experimentNotFound");
    } catch (NumberFormatException ex) {
        error = msg.t("err.experimentBadId");
    } catch (SQLException ex) {
        application.log("AlgoLab: 실험 상세 SELECT 실패", ex);
        error = msg.t("err.experimentDb");
    }
    String deleteCsrf = ExperimentDeleteToken.getOrCreate(session);
    DateTimeFormatter dateFormat = DateTimeFormatter.ofPattern("yyyy.MM.dd HH:mm");
%>
<!DOCTYPE html>
<html lang="<%= msg.language() %>">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <title>AlgoLab - <%= msg.t("title.experiment") %></title>
    <link rel="stylesheet" href="<%= request.getContextPath() %>/resources/css/style.css?v=20261123i18n1">
    <link rel="stylesheet" href="<%= request.getContextPath() %>/resources/css/history.css">
    <link rel="stylesheet" href="<%= request.getContextPath() %>/resources/css/experiment.css">
    <link rel="stylesheet" href="<%= request.getContextPath() %>/resources/css/confirm-dialog.css?v=20261123dialog2">
    <link rel="stylesheet" href="<%= request.getContextPath() %>/resources/css/auth.css?v=login1">
</head>
<body>
    <jsp:include page="menu.jsp" />
    <main class="container experiment-container">
        <div class="page-heading">
            <p class="eyebrow">EXPERIMENT DETAIL</p>
            <h1><%= msg.t("experiment.heading") %></h1>
            <p class="subtitle"><%= msg.t("experiment.lead") %></p>
        </div>
        <% if (error != null) { %>
            <section class="panel experiment-panel"><h2><%= msg.t("common.loadFailed") %></h2>
                <p class="experiment-alert" role="alert"><%= HtmlUtil.escape(error) %></p>
                <a class="experiment-ghost" href="<%= request.getContextPath() %>/history.jsp"><%= msg.t("common.backList") %></a>
            </section>
        <% } else { %>
            <section class="panel experiment-panel">
                <div class="experiment-detail-head">
                    <h2><%= HtmlUtil.escape(record.getTitle()) %></h2>
                    <small class="record-owner"><%= msg.t("auth.author") %>: <%= HtmlUtil.escape(record.getOwnerName() == null ? msg.t("auth.legacy") : record.getOwnerName()) %></small>
                    <span>#<%= record.getId() %> · <%= record.getCreatedAt() == null ? "-" : dateFormat.format(record.getCreatedAt().toLocalDateTime()) %></span>
                </div>
                <div class="experiment-preview">
                    <div><span><%= msg.t("common.algorithm") %></span><strong><%= HtmlUtil.escape(record.getAlgorithmLabel()) %></strong></div>
                    <div><span><%= msg.t("common.arraySize") %></span><strong><%= record.getArraySize() %></strong></div>
                    <div><span><%= msg.t("common.comparisons") %></span><strong><%= record.getComparisons() %></strong></div>
                    <div><span><%= "insertion".equals(record.getAlgorithm()) ? msg.t("common.movements") : "merge".equals(record.getAlgorithm()) ? msg.t("common.mergeWrites") : msg.t("common.swaps") %></span><strong><%= record.getSwaps() %></strong></div>
                </div>
                <div class="experiment-section"><h3><%= msg.t("common.inputArray") %></h3>
                    <div class="experiment-code">[<%= HtmlUtil.escape(record.getInputArray()) %>]</div>
                </div>
                <div class="experiment-section"><h3><%= msg.t("common.memo") %></h3>
                    <div class="experiment-memo"><%= HtmlUtil.escape(record.getMemo().isEmpty() ? msg.t("experiment.noMemo") : record.getMemo()) %></div>
                </div>
                <div class="experiment-actions">
                    <a class="experiment-ghost" href="<%= request.getContextPath() %>/history.jsp"><%= msg.t("common.backShort") %></a>
                    <% if ("bubble".equals(record.getAlgorithm()) || "selection".equals(record.getAlgorithm())
                            || "insertion".equals(record.getAlgorithm()) || "merge".equals(record.getAlgorithm())
                            || "quick".equals(record.getAlgorithm())) { %>
                        <form action="<%= request.getContextPath() %>/visualizer.jsp" method="post">
                            <input type="hidden" name="algorithm" value="<%= HtmlUtil.escape(record.getAlgorithm()) %>">
                            <input type="hidden" name="numbers" value="<%= HtmlUtil.escape(record.getInputArray()) %>">
                            <button class="experiment-primary" type="submit"><%= msg.t("experiment.rerun") %></button>
                        </form>
                    <% } else { %>
                        <span class="experiment-hint"><%= msg.t("experiment.unsupported") %></span>
                    <% } %>
                    <% if (Auth.owns(session, record.getOwnerId())) { %>
                    <form method="post" action="<%= request.getContextPath() %>/deleteExperimentProcess.jsp"
                          data-confirm-message="<%= HtmlUtil.escape(msg.t("history.confirmDelete")) %>"
                                          data-confirm-ok="<%= HtmlUtil.escape(msg.t("common.delete")) %>"
                                          data-confirm-cancel="<%= HtmlUtil.escape(msg.t("common.cancel")) %>">
                        <input type="hidden" name="csrf" value="<%= deleteCsrf %>">
                        <input type="hidden" name="id" value="<%= record.getId() %>">
                        <button class="experiment-danger" type="submit"><%= msg.t("common.delete") %></button>
                    </form>
                    <% } %>
                </div>
                <% if (Auth.owns(session, record.getOwnerId())) { %><p class="experiment-deletion-note"><%= msg.t("experiment.deleteNote") %></p><% } %>
            </section>
        <% } %>
    </main>
<script src="<%= request.getContextPath() %>/resources/js/confirm-delete.js?v=20261123dialog2" defer></script>
</body>
</html>
