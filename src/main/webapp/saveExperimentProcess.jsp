<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true" %>
<%@ page import="java.sql.SQLException,java.nio.charset.StandardCharsets,java.security.MessageDigest" %>
<%@ page import="com.algolab.dto.Experiment,com.algolab.dao.ExperimentDAO" %>
<%
    // 이 페이지는 화면이 아니라 POST 처리만 담당하며, 성공 후 PRG 방식으로 이동한다.
    String contextPath = request.getContextPath();
    if (!"POST".equalsIgnoreCase(request.getMethod())) {
        response.sendRedirect(contextPath + "/saveExperiment.jsp");
        return;
    }
    request.setCharacterEncoding("UTF-8");
    Experiment pending = (Experiment) session.getAttribute("pendingExperiment");
    String expected = (String) session.getAttribute("saveExperimentCsrf");
    String submitted = request.getParameter("csrf");

    if (pending == null || expected == null || submitted == null
        || !MessageDigest.isEqual(expected.getBytes(StandardCharsets.UTF_8),
                                  submitted.getBytes(StandardCharsets.UTF_8))) {
        session.setAttribute("saveError", "저장 요청이 만료되었습니다. 저장 화면을 다시 열어 주세요.");
        response.sendRedirect(contextPath + "/saveExperiment.jsp");
        return;
    }

    String title = request.getParameter("title");
    String memo = request.getParameter("memo");
    title = title == null ? "" : title.trim();
    memo = memo == null ? "" : memo.trim();

    // 실패 후 입력한 제목과 메모가 사라지지 않도록 세션에 임시 보관합니다.
    session.setAttribute("saveDraftTitle", title);
    session.setAttribute("saveDraftMemo", memo);

    if (title.isEmpty() || title.length() > 100 || memo.length() > 2000) {
        session.setAttribute("saveError", "제목은 1~100자, 메모는 2,000자 이내로 입력해 주세요.");
        response.sendRedirect(contextPath + "/saveExperiment.jsp");
        return;
    }

    // 클라이언트의 hidden 필드에 실험 지표를 싣지 않는다.
    // 시각화 페이지가 Java에서 계산하여 보관한 값만 DB에 저장한다.
    pending.setTitle(title);
    pending.setMemo(memo);
    try {
        ExperimentDAO dao = new ExperimentDAO(application);

        // Java에서 먼저 중복을 확인하여 사용자에게 이해하기 쉬운 메시지를 보여준다.
        // 동시에 저장되는 요청은 DB의 UNIQUE(title) 제약조건이 최종적으로 막는다.
        if (dao.existsByTitle(title)) {
            session.setAttribute("saveError", "이미 사용 중인 실험 제목입니다. 다른 제목을 입력해 주세요.");
            response.sendRedirect(contextPath + "/saveExperiment.jsp");
            return;
        }

        long id = dao.insert(pending);
        session.removeAttribute("pendingExperiment");
        session.removeAttribute("saveExperimentCsrf");
        session.removeAttribute("saveDraftTitle");
        session.removeAttribute("saveDraftMemo");
        response.sendRedirect(contextPath + "/experiment.jsp?id=" + id);
    } catch (SQLException ex) {
        if (ex.getErrorCode() == 1062) {
            // MySQL의 UNIQUE(title) 제약조건에 걸린 경우입니다.
            session.setAttribute("saveError", "이미 사용 중인 실험 제목입니다. 다른 제목을 입력해 주세요.");
        } else {
            application.log("AlgoLab: 실험 기록 INSERT 실패", ex);
            session.setAttribute("saveError", "실험 기록을 저장하지 못했습니다. 데이터베이스 연결과 테이블 생성 상태를 확인해 주세요.");
        }
        response.sendRedirect(contextPath + "/saveExperiment.jsp");
    }
%>
