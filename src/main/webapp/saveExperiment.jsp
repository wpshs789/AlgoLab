<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.security.SecureRandom,java.util.Base64" %>
<%@ page import="com.algolab.dto.Experiment,com.algolab.util.HtmlUtil" %>
<%
    Experiment pending = (Experiment) session.getAttribute("pendingExperiment");
    String saveError = (String) session.getAttribute("saveError");
    String saveDraftTitle = (String) session.getAttribute("saveDraftTitle");
    String saveDraftMemo = (String) session.getAttribute("saveDraftMemo");
    session.removeAttribute("saveError");
    session.removeAttribute("saveDraftTitle");
    session.removeAttribute("saveDraftMemo");
    if (saveDraftTitle == null) saveDraftTitle = "";
    if (saveDraftMemo == null) saveDraftMemo = "";
    String csrf = "";
    if (pending != null) {
        byte[] nonce = new byte[24];
        new SecureRandom().nextBytes(nonce);
        csrf = Base64.getUrlEncoder().withoutPadding().encodeToString(nonce);
        session.setAttribute("saveExperimentCsrf", csrf);
    }
%>
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <title>AlgoLab - 실험 기록 저장</title>
    <link rel="stylesheet" href="<%= request.getContextPath() %>/resources/css/style.css">
    <link rel="stylesheet" href="<%= request.getContextPath() %>/resources/css/history.css">
    <link rel="stylesheet" href="<%= request.getContextPath() %>/resources/css/experiment.css">
</head>
<body>
    <jsp:include page="menu.jsp" />
    <main class="container experiment-container">
        <div class="page-heading">
            <p class="eyebrow">SAVE EXPERIMENT</p>
            <h1>실험 기록 저장</h1>
            <p class="subtitle">시각화 결과를 실험 기록으로 저장할 수 있습니다.</p>
        </div>
        <% if (pending == null) { %>
            <section class="panel experiment-panel">
                <h2>저장할 실험이 없습니다.</h2>
                <p class="subtitle">메인 페이지에서 정렬을 실행한 후 다시 시도해 주세요. 이미 저장한 실험은 중복 저장할 수 없습니다.</p>
                <a class="save-link" href="<%= request.getContextPath() %>/index.jsp">정렬 실행하기</a>
            </section>
        <% } else { %>
            <section class="panel experiment-panel">
                <% if (saveError != null) { %><p class="experiment-alert" role="alert"><%= HtmlUtil.escape(saveError) %></p><% } %>
                <div class="experiment-preview">
                    <div><span>알고리즘</span><strong><%= HtmlUtil.escape(pending.getAlgorithmLabel()) %></strong></div>
                    <div><span>배열 크기</span><strong><%= pending.getArraySize() %></strong></div>
                    <div><span>비교 횟수</span><strong><%= pending.getComparisons() %></strong></div>
                    <div><span><%= "insertion".equals(pending.getAlgorithm()) ? "이동 횟수" : "교환 횟수" %></span><strong><%= pending.getSwaps() %></strong></div>
                </div>
                <p class="experiment-array"><span>입력 배열</span> [<%= HtmlUtil.escape(pending.getInputArray()) %>]</p>
                <form method="post" action="<%= request.getContextPath() %>/saveExperimentProcess.jsp" class="experiment-form">
                    <input type="hidden" name="csrf" value="<%= csrf %>">
                    <div class="experiment-field">
                        <label for="title">실험 제목 <span>(필수, 100자 이내)</span></label>
                        <input id="title" name="title" type="text" maxlength="100" placeholder="예: 역순 배열에서 버블 정렬" value="<%= HtmlUtil.escape(saveDraftTitle) %>" required>
                        <p class="experiment-hint">이미 등록된 실험 제목은 사용할 수 없습니다.</p>
                    </div>
                    <div class="experiment-field">
                        <label for="memo">실험 메모 <span>(2,000자 이내)</span></label>
                        <textarea id="memo" name="memo" maxlength="2000" rows="6" placeholder="이번 실험에서 관찰한 내용을 입력해 주세요."><%= HtmlUtil.escape(saveDraftMemo) %></textarea>
                    </div>
                    <p class="experiment-hint">배열과 연산 횟수는 서버에서 계산하므로 직접 수정할 수 없습니다. 현재 저장된 기록은 로그인 없이 조회할 수 있습니다.</p>
                    <div class="experiment-actions">
                        <a class="experiment-ghost" href="<%= request.getContextPath() %>/index.jsp">취소</a>
                        <button class="experiment-primary" type="submit">실험 기록 저장하기</button>
                    </div>
                </form>
            </section>
        <% } %>
    </main>
</body>
</html>
