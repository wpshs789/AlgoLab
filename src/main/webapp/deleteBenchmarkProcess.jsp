<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true" %>
<%@ page import="com.algolab.i18n.I18n" %>
<%@ page import="java.sql.SQLException,com.algolab.dao.BenchmarkDAO,com.algolab.util.BenchmarkToken" %>
<% I18n msg = I18n.of(session); %>
<%
    String base = request.getContextPath();
    if (!"POST".equalsIgnoreCase(request.getMethod())) {
        response.sendRedirect(base + "/history.jsp");
        return;
    }
    request.setCharacterEncoding("UTF-8");
    if (!BenchmarkToken.isValid(session, request.getParameter("csrf"))) {
        session.setAttribute("historyError", msg.t("err.benchDeleteToken"));
        response.sendRedirect(base + "/history.jsp");
        return;
    }
    try {
        long id = Long.parseLong(request.getParameter("id"));
        int count = new BenchmarkDAO(application).deleteById(id);
        session.setAttribute(count > 0 ? "historyNotice" : "historyError",
            count > 0 ? msg.t("notice.benchDeleted") : msg.t("err.benchAlreadyDeleted"));
    } catch (IllegalArgumentException ex) {
        session.setAttribute("historyError", msg.t("err.invalidId"));
    } catch (SQLException ex) {
        application.log("AlgoLab: 성능 비교 삭제 실패", ex);
        session.setAttribute("historyError", msg.t("err.benchDeleteDb"));
    }
    response.sendRedirect(base + "/history.jsp");
%>
