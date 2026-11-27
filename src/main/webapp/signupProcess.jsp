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
    String displayName = request.getParameter("displayName");
    displayName = displayName == null ? "" : displayName.trim();
    session.setAttribute("authDraftName", displayName.length() <= 50 ? displayName : "");
    if (!username.matches("[A-Za-z0-9_]{4,30}")) error = "auth.usernameRule";
    else if (displayName.isBlank() || displayName.length() > 50 || displayName.codePoints().anyMatch(Character::isISOControl)) error = "auth.nameRequired";
    else if (password == null || password.length() < 8 || password.length() > 128 || password.isBlank()) error = "auth.passwordRule";
    else {
        try {
            UserDAO dao = new UserDAO(application);
            if (dao.exists(username)) error = "auth.duplicate";
            else {
                dao.insert(username, password, displayName);
                session.removeAttribute("authDraftName");
                session.removeAttribute("authCsrf");
                session.setAttribute("authNotice", "auth.registered");
                response.sendRedirect(base + "/login.jsp?next=" + next);
                return;
            }
        } catch (SQLException ex) {
            if (ex.getErrorCode() == 1062) error = "auth.duplicate";
            else { application.log("AlgoLab: signup failed", ex); error = "auth.dbError"; }
        }
    }
    session.setAttribute("authError", error);
    response.sendRedirect(base + "/signup.jsp?next=" + next);
%>
