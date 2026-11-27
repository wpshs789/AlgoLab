<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true" %>
<%@ page import="com.algolab.i18n.I18n,com.algolab.auth.Auth,com.algolab.util.HtmlUtil" %>
<%
    response.setHeader("Cache-Control", "no-store");
    I18n msg = I18n.of(session);
    String next = Auth.next(request.getParameter("next"));
    if (Auth.current(session) != null) { response.sendRedirect(request.getContextPath() + "/" + next); return; }
    String error = (String) session.getAttribute("authError"); session.removeAttribute("authError");
    String notice = (String) session.getAttribute("authNotice"); session.removeAttribute("authNotice");
    String username = (String) session.getAttribute("authDraftUsername"); session.removeAttribute("authDraftUsername");
    String displayName = (String) session.getAttribute("authDraftName"); session.removeAttribute("authDraftName");
%>
<!DOCTYPE html>
<html lang="<%= msg.language() %>"><head>
    <meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
    <title>AlgoLab - <%= msg.t("auth.login") %></title>
    <link rel="stylesheet" href="<%= request.getContextPath() %>/resources/css/style.css?v=20261123i18n1">
    <link rel="stylesheet" href="<%= request.getContextPath() %>/resources/css/auth.css?v=login1">
</head><body>
<jsp:include page="menu.jsp" />
<main class="container auth-container">
    <div class="page-heading"><p class="eyebrow">ACCOUNT</p><h1><%= msg.t("auth.login") %></h1><p class="subtitle"><%= msg.t("auth.loginLead") %></p></div>
    <section class="panel auth-panel">
        <% if (error != null) { %><p class="auth-alert" role="alert"><%= HtmlUtil.escape(msg.t(error)) %></p><% } %>
        <% if (notice != null) { %><p class="auth-notice" role="status"><%= HtmlUtil.escape(msg.t(notice)) %></p><% } %>
        <form method="post" action="<%= request.getContextPath() %>/loginProcess.jsp" accept-charset="UTF-8">
            <input type="hidden" name="csrf" value="<%= Auth.token(session) %>">
            <input type="hidden" name="next" value="<%= next %>">
            <div class="form-group"><label for="username"><%= msg.t("auth.username") %></label>
                <input id="username" name="username" value="<%= HtmlUtil.escape(username) %>" autocomplete="username" required maxlength="30"  data-error-required="<%= msg.t("auth.usernameRequired") %>" data-error-invalid="<%= msg.t("auth.usernameRule") %>">
                
            </div>
            
            <div class="form-group"><label for="password"><%= msg.t("auth.password") %></label>
                <input type="password" id="password" name="password" autocomplete="current-password" required maxlength="128"  data-error-required="<%= msg.t("auth.passwordRequired") %>" data-error-invalid="<%= msg.t("auth.passwordRule") %>">
                
            </div>
            <button class="start-btn" type="submit"><%= msg.t("auth.login") %></button>
        </form>
        <p class="auth-footer"><%= msg.t("auth.signupHint") %> <a href="<%= request.getContextPath() %>/signup.jsp?next=<%= next %>"><%= msg.t("auth.signup") %></a></p>
    </section>
</main>
<script src="<%= request.getContextPath() %>/resources/js/form-validation.js?v=20261123i18nAudit1" defer></script>
</body></html>
