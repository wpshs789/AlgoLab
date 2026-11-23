<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true" %>
<%@ page import="com.algolab.i18n.I18n" %>
<%@ page import="java.sql.SQLException,com.algolab.benchmark.BenchmarkReport,com.algolab.dao.BenchmarkDAO,com.algolab.util.BenchmarkToken" %>
<% I18n msg = I18n.of(session); %>
<%
    String base = request.getContextPath();
    if (!"POST".equalsIgnoreCase(request.getMethod())) {
        response.sendRedirect(base + "/benchmark.jsp");
        return;
    }
    request.setCharacterEncoding("UTF-8");
    BenchmarkReport pending = (BenchmarkReport) session.getAttribute("pendingBenchmark");
    String title = request.getParameter("title");
    title = title == null ? "" : title.trim();
    session.setAttribute("benchmarkDraftTitle", title);

    if (pending == null || !BenchmarkToken.isValid(session, request.getParameter("csrf"))) {
        session.setAttribute("benchmarkError", msg.t("err.benchExpired"));
        response.sendRedirect(base + "/benchmark.jsp");
        return;
    }
    if (title.isEmpty() || title.length() > 100) {
        session.setAttribute("benchmarkError", msg.t("err.benchTitle"));
        response.sendRedirect(base + "/benchmark.jsp");
        return;
    }
    try {
        BenchmarkDAO dao = new BenchmarkDAO(application);
        if (dao.existsByTitle(title)) {
            session.setAttribute("benchmarkError", msg.t("err.benchDuplicate"));
            response.sendRedirect(base + "/benchmark.jsp");
            return;
        }
        long savedId = dao.insert(title, pending);
        session.removeAttribute("pendingBenchmark");
        session.removeAttribute("benchmarkDraftTitle");
        response.sendRedirect(base + "/benchmarkDetail.jsp?id=" + savedId);
    } catch (SQLException ex) {
        if (ex.getErrorCode() == 1062) {
            session.setAttribute("benchmarkError", msg.t("err.benchDuplicate"));
        } else {
            application.log("AlgoLab: 성능 비교 저장 실패", ex);
            session.setAttribute("benchmarkError", msg.t("err.benchSaveDb"));
        }
        response.sendRedirect(base + "/benchmark.jsp");
    }
%>
