<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true" %>
<%@ page import="java.sql.SQLException" %>
<%@ page import="com.algolab.dao.ExperimentDAO,com.algolab.util.ExperimentDeleteToken" %>
<%
    // 삭제 요청은 POST만 처리합니다. GET 요청으로 DB가 변경되지 않도록 합니다.
    if (!"POST".equalsIgnoreCase(request.getMethod())) {
        response.sendError(405, "POST 요청만 허용됩니다.");
        return;
    }
    request.setCharacterEncoding("UTF-8");
    String submitted = request.getParameter("csrf");
    if (!ExperimentDeleteToken.isValid(session, submitted)) {
        response.sendError(403, "삭제 요청을 확인할 수 없습니다. 목록을 새로고침한 뒤 다시 시도해 주세요.");
        return;
    }

    String notice;
    boolean succeeded = false;
    try {
        long id = Long.parseLong(request.getParameter("id"));
        if (id <= 0) throw new NumberFormatException("invalid id");

        int removed = new ExperimentDAO(application).deleteById(id);
        if (removed == 1) {
            notice = "실험 기록이 삭제되었습니다.";
            succeeded = true;
        } else {
            notice = "해당 실험 기록을 찾을 수 없습니다. 이미 삭제되었을 수 있습니다.";
        }
    } catch (NumberFormatException ex) {
        notice = "올바르지 않은 실험 기록 번호입니다.";
    } catch (SQLException ex) {
        application.log("AlgoLab: 실험 기록 DELETE 실패", ex);
        notice = "실험 기록을 삭제하지 못했습니다. 데이터베이스 연결을 확인해 주세요.";
    }

    session.setAttribute(succeeded ? "historyNotice" : "historyError", notice);
    response.sendRedirect(request.getContextPath() + "/history.jsp");
%>
