<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true" %>
<%@ page import="java.sql.SQLException,com.algolab.dao.BenchmarkDAO,com.algolab.util.BenchmarkToken" %>
<%
    String base = request.getContextPath();
    if (!"POST".equalsIgnoreCase(request.getMethod())) {
        response.sendRedirect(base + "/history.jsp");
        return;
    }
    request.setCharacterEncoding("UTF-8");
    if (!BenchmarkToken.isValid(session, request.getParameter("csrf"))) {
        session.setAttribute("historyError", "삭제 요청을 확인할 수 없습니다. 다시 시도해 주세요.");
        response.sendRedirect(base + "/history.jsp");
        return;
    }
    try {
        long id = Long.parseLong(request.getParameter("id"));
        int count = new BenchmarkDAO(application).deleteById(id);
        session.setAttribute(count > 0 ? "historyNotice" : "historyError",
            count > 0 ? "성능 비교 기록을 삭제했습니다." : "이미 삭제되었거나 존재하지 않는 성능 비교 기록입니다.");
    } catch (IllegalArgumentException ex) {
        session.setAttribute("historyError", "올바른 실험 번호가 아닙니다.");
    } catch (SQLException ex) {
        application.log("AlgoLab: 성능 비교 삭제 실패", ex);
        session.setAttribute("historyError", "성능 비교를 삭제하지 못했습니다. 데이터베이스 연결을 확인해 주세요.");
    }
    response.sendRedirect(base + "/history.jsp");
%>
