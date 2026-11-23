<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="com.algolab.i18n.I18n" %>
<% I18n msg = I18n.of(session); %>
<header class="header">
    <a class="logo" href="<%= request.getContextPath() %>/index.jsp">AlgoLab<span>.</span></a>
    <nav aria-label="<%= msg.t("nav.aria") %>">
        <a href="<%= request.getContextPath() %>/index.jsp">Home</a>
        <a href="<%= request.getContextPath() %>/benchmark.jsp"><%= msg.t("nav.benchmark") %></a>
        <a href="<%= request.getContextPath() %>/history.jsp"><%= msg.t("nav.history") %></a>
    </nav>
    <div class="language-switch" role="group" aria-label="<%= msg.t("nav.language") %>">
        <a href="<%= request.getContextPath() %>/language.jsp?lang=ko&amp;next=<%= java.net.URLEncoder.encode(request.getRequestURI() + (request.getQueryString() == null ? "" : "?" + request.getQueryString()), java.nio.charset.StandardCharsets.UTF_8) %>"
           class="<%= "ko".equals(msg.language()) ? "active" : "" %>" lang="ko" <%= "ko".equals(msg.language()) ? "aria-current=\"true\"" : "" %>>한국어</a>
        <span aria-hidden="true">|</span>
        <a href="<%= request.getContextPath() %>/language.jsp?lang=en&amp;next=<%= java.net.URLEncoder.encode(request.getRequestURI() + (request.getQueryString() == null ? "" : "?" + request.getQueryString()), java.nio.charset.StandardCharsets.UTF_8) %>"
           class="<%= "en".equals(msg.language()) ? "active" : "" %>" lang="en" <%= "en".equals(msg.language()) ? "aria-current=\"true\"" : "" %>>English</a>
    </div>
</header>
