<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true" %>
<%@ page import="com.algolab.i18n.I18n" %>
<%@ page import="java.sql.SQLException" %>
<%@ page import="com.algolab.dao.ExperimentDAO,com.algolab.util.ExperimentDeleteToken" %>
<% I18n msg = I18n.of(session); %>
<%
    // 삭제 요청은 POST만 처리합니다. GET 요청으로 DB가 변경되지 않도록 합니다.
    if (!"POST".equalsIgnoreCase(request.getMethod())) {
        response.sendError(405, msg.t("err.postOnly"));
        return;
    }
    request.setCharacterEncoding("UTF-8");
    String submitted = request.getParameter("csrf");
    if (!ExperimentDeleteToken.isValid(session, submitted)) {
        response.sendError(403, msg.t("err.deleteToken"));
        return;
    }

    String notice;
    boolean succeeded = false;
    try {
        long id = Long.parseLong(request.getParameter("id"));
        if (id <= 0) throw new NumberFormatException("invalid id");

        int removed = new ExperimentDAO(application).deleteById(id);
        if (removed == 1) {
            notice = msg.t("notice.deleted");
            succeeded = true;
        } else {
            notice = msg.t("err.alreadyDeleted");
        }
    } catch (NumberFormatException ex) {
        notice = msg.t("err.badExperimentId");
    } catch (SQLException ex) {
        application.log("AlgoLab: 실험 기록 DELETE 실패", ex);
        notice = msg.t("err.deleteDb");
    }

    session.setAttribute(succeeded ? "historyNotice" : "historyError", notice);
    response.sendRedirect(request.getContextPath() + "/history.jsp");
%>
