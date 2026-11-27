<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="com.algolab.i18n.I18n,com.algolab.auth.Auth,com.algolab.auth.User" %>
<%@ page import="java.security.SecureRandom,java.util.Base64" %>
<%@ page import="com.algolab.dto.Experiment,com.algolab.util.HtmlUtil" %>
<% response.setHeader("Cache-Control", "no-store"); I18n msg = I18n.of(session); %>
<%
    if (Auth.current(session) == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp?next=saveExperiment.jsp");
        return;
    }
%>
<%
    Experiment pending = (Experiment) session.getAttribute("pendingExperiment");
    String saveError = (String) session.getAttribute("saveError");
    String saveDraftTitle = (String) session.getAttribute("saveDraftTitle");
    String saveDraftMemo = (String) session.getAttribute("saveDraftMemo");
    session.removeAttribute("saveError");
    session.removeAttribute("saveDraftTitle");
    session.removeAttribute("saveDraftMemo");
    if (saveDraftTitle == null) saveDraftTitle = "";
    if (saveDraftMemo == null) saveDraftMemo = "";
    String csrf = "";
    if (pending != null) {
        byte[] nonce = new byte[24];
        new SecureRandom().nextBytes(nonce);
        csrf = Base64.getUrlEncoder().withoutPadding().encodeToString(nonce);
        session.setAttribute("saveExperimentCsrf", csrf);
    }
%>
<!DOCTYPE html>
<html lang="<%= msg.language() %>">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <title>AlgoLab - <%= msg.t("title.save") %></title>
    <link rel="stylesheet" href="<%= request.getContextPath() %>/resources/css/style.css?v=20261123i18n1">
    <link rel="stylesheet" href="<%= request.getContextPath() %>/resources/css/history.css">
    <link rel="stylesheet" href="<%= request.getContextPath() %>/resources/css/experiment.css">
    <link rel="stylesheet" href="<%= request.getContextPath() %>/resources/css/auth.css?v=login1">
</head>
<body>
    <jsp:include page="menu.jsp" />
    <main class="container experiment-container">
        <div class="page-heading">
            <p class="eyebrow">SAVE EXPERIMENT</p>
            <h1><%= msg.t("save.heading") %></h1>
            <p class="subtitle"><%= msg.t("save.lead") %></p>
        </div>
        <% if (pending == null) { %>
            <section class="panel experiment-panel">
                <h2><%= msg.t("save.empty") %></h2>
                <p class="subtitle"><%= msg.t("save.emptyHelp") %></p>
                <a class="save-link" href="<%= request.getContextPath() %>/index.jsp"><%= msg.t("save.run") %></a>
            </section>
        <% } else { %>
            <section class="panel experiment-panel">
                <% if (saveError != null) { %><p class="experiment-alert" role="alert"><%= HtmlUtil.escape(saveError) %></p><% } %>
                <div class="experiment-preview">
                    <div><span><%= msg.t("common.algorithm") %></span><strong><%= HtmlUtil.escape(pending.getAlgorithmLabel()) %></strong></div>
                    <div><span><%= msg.t("common.arraySize") %></span><strong><%= pending.getArraySize() %></strong></div>
                    <div><span><%= msg.t("common.comparisons") %></span><strong><%= pending.getComparisons() %></strong></div>
                    <div><span><%= "insertion".equals(pending.getAlgorithm()) ? msg.t("common.movements") : "merge".equals(pending.getAlgorithm()) ? msg.t("common.mergeWrites") : msg.t("common.swaps") %></span><strong><%= pending.getSwaps() %></strong></div>
                </div>
                <p class="experiment-array"><span><%= msg.t("common.inputArray") %></span> [<%= HtmlUtil.escape(pending.getInputArray()) %>]</p>
                <form method="post" action="<%= request.getContextPath() %>/saveExperimentProcess.jsp" class="experiment-form">
                    <input type="hidden" name="csrf" value="<%= csrf %>">
                    <div class="experiment-field">
                        <label for="title"><%= msg.t("common.title") %> <span><%= msg.t("save.titleInfo") %></span></label>
                        <input id="title" name="title" type="text" maxlength="100" placeholder="<%= msg.t("save.titleExample") %>" value="<%= HtmlUtil.escape(saveDraftTitle) %>" required
                               data-error-required="<%= msg.t("validation.experimentTitleRequired") %>"
                               data-error-invalid="<%= msg.t("validation.invalid") %>">
                        <p class="experiment-hint"><%= msg.t("save.unique") %></p>
                    </div>
                    <div class="experiment-field">
                        <label for="memo"><%= msg.t("common.memo") %> <span><%= msg.t("save.memoInfo") %></span></label>
                        <textarea id="memo" name="memo" maxlength="2000" rows="6" placeholder="<%= msg.t("save.memoPlaceholder") %>"><%= HtmlUtil.escape(saveDraftMemo) %></textarea>
                    </div>
                    <p class="experiment-hint"><%= msg.t("save.readonly") %></p>
                    <div class="experiment-actions">
                        <a class="experiment-ghost" href="<%= request.getContextPath() %>/index.jsp"><%= msg.t("common.cancel") %></a>
                        <button class="experiment-primary" type="submit"><%= msg.t("save.submit") %></button>
                    </div>
                </form>
            </section>
        <% } %>
    </main>
    <script src="<%= request.getContextPath() %>/resources/js/form-validation.js?v=20261123i18nAudit1" defer></script>
</body>
</html>
