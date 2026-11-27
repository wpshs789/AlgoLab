<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true" %>
<%@ page import="com.algolab.auth.Auth,com.algolab.auth.User,com.algolab.dao.UserDAO,com.algolab.i18n.I18n,java.sql.SQLException" %>
<%
    response.setHeader("Cache-Control", "no-store");
    if (!"POST".equals(request.getMethod())) { response.sendError(405); return; }
    request.setCharacterEncoding("UTF-8");
    String base = request.getContextPath();
    String next = Auth.next(request.getParameter("next"));
    if (Auth.current(session) != null) { response.sendRedirect(base + "/" + next); return; }
    if (!Auth.valid(session, request.getParameter("csrf"))) { response.sendError(403, I18n.of(session).t("auth.expired")); return; }
    String username = request.getParameter("username");
    username = username == null ? "" : username.trim();
    String password = request.getParameter("password");
    String error = null;
    session.setAttribute("authDraftUsername", username.length() <= 30 ? username : "");
    if (!username.matches("[A-Za-z0-9_]{4,30}") || password == null || password.length() > 128 || password.isEmpty()) error = "auth.badLogin";
    else {
        try {
            User user = new UserDAO(application).authenticate(username, password);
            if (user == null) error = "auth.badLogin";
            else {
                Auth.login(request, user);
                session.removeAttribute("authDraftUsername");
                response.sendRedirect(base + "/" + next);
                return;
            }
        } catch (SQLException ex) { application.log("AlgoLab: login failed", ex); error = "auth.dbError"; }
    }
    session.setAttribute("authError", error);
    response.sendRedirect(base + "/login.jsp?next=" + next);
%>
