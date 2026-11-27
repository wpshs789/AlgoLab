<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true" %>
<%@ page import="com.algolab.auth.Auth,com.algolab.i18n.I18n" %>
<%
    if (!"POST".equals(request.getMethod())) { response.sendError(405); return; }
    if (Auth.current(session) == null || !Auth.valid(session, request.getParameter("csrf"))) { response.sendError(403); return; }
    String language = I18n.of(session).language();
    session.invalidate();
    request.getSession(true).setAttribute("algolabLanguage", language);
    response.sendRedirect(request.getContextPath() + "/index.jsp");
%>
