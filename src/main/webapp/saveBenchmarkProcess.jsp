<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true" %>
<%@ page import="java.sql.SQLException,com.algolab.benchmark.BenchmarkReport,com.algolab.dao.BenchmarkDAO,com.algolab.util.BenchmarkToken" %>
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
        session.setAttribute("benchmarkError", "저장할 결과가 없거나 요청이 만료되었습니다. 성능 비교를 다시 실행해 주세요.");
        response.sendRedirect(base + "/benchmark.jsp");
        return;
    }
    if (title.isEmpty() || title.length() > 100) {
        session.setAttribute("benchmarkError", "제목을 1~100자로 입력해 주세요.");
        response.sendRedirect(base + "/benchmark.jsp");
        return;
    }
    try {
        BenchmarkDAO dao = new BenchmarkDAO(application);
        if (dao.existsByTitle(title)) {
            session.setAttribute("benchmarkError", "이미 사용 중인 성능 비교 제목입니다. 다른 제목을 입력해 주세요.");
            response.sendRedirect(base + "/benchmark.jsp");
            return;
        }
        long savedId = dao.insert(title, pending);
        session.removeAttribute("pendingBenchmark");
        session.removeAttribute("benchmarkDraftTitle");
        response.sendRedirect(base + "/benchmarkDetail.jsp?id=" + savedId);
    } catch (SQLException ex) {
        if (ex.getErrorCode() == 1062) {
            session.setAttribute("benchmarkError", "이미 사용 중인 성능 비교 제목입니다. 다른 제목을 입력해 주세요.");
        } else {
            application.log("AlgoLab: 성능 비교 저장 실패", ex);
            session.setAttribute("benchmarkError", "성능 비교를 저장하지 못했습니다. database/benchmark_schema.sql 실행 여부와 DB 연결을 확인해 주세요.");
        }
        response.sendRedirect(base + "/benchmark.jsp");
    }
%>
