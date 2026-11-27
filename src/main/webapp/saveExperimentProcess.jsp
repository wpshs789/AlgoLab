<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true" %>
<%@ page import="com.algolab.i18n.I18n,com.algolab.auth.Auth,com.algolab.auth.User" %>
<%@ page import="java.sql.SQLException,java.nio.charset.StandardCharsets,java.security.MessageDigest" %>
<%@ page import="com.algolab.dto.Experiment,com.algolab.dao.ExperimentDAO" %>
<% I18n msg = I18n.of(session); %>
<%
    User actor = Auth.current(session);
    if (actor == null) { response.sendError(403, msg.t("auth.required")); return; }
%>
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
        session.setAttribute("saveError", msg.t("err.saveExpired"));
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
        session.setAttribute("saveError", msg.t("err.saveFields"));
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
        // 동시에 저장되는 요청은 DB의 UNIQUE(user_id, title) 제약조건이 최종적으로 막는다.
        if (dao.existsByTitle(title, actor.id())) {
            session.setAttribute("saveError", msg.t("err.saveDuplicate"));
            response.sendRedirect(contextPath + "/saveExperiment.jsp");
            return;
        }

        long id = dao.insert(pending, actor.id());
        session.removeAttribute("pendingExperiment");
        session.removeAttribute("saveExperimentCsrf");
        session.removeAttribute("saveDraftTitle");
        session.removeAttribute("saveDraftMemo");
        response.sendRedirect(contextPath + "/experiment.jsp?id=" + id);
    } catch (SQLException ex) {
        if (ex.getErrorCode() == 1062) {
            // MySQL의 UNIQUE(user_id, title) 제약조건에 걸린 경우입니다.
            session.setAttribute("saveError", msg.t("err.saveDuplicate"));
        } else {
            application.log("AlgoLab: 실험 기록 INSERT 실패", ex);
            session.setAttribute("saveError", msg.t("err.saveDb"));
        }
        response.sendRedirect(contextPath + "/saveExperiment.jsp");
    }
%>
