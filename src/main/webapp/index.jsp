<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%
    // 파일 업로드 또는 직전 실행에서 저장한 숫자 배열을 기본 입력값으로 표시한다.
    // lastNumbers에는 서버가 검증하고 정규화한 정수 문자열만 저장한다.
    String lastNumbers = (String) session.getAttribute("lastNumbers");
    if (lastNumbers == null || lastNumbers.isEmpty()) {
        lastNumbers = "5, 3, 1, 4, 2";
    }
    String uploadNotice = (String) session.getAttribute("uploadNotice");
    String uploadError = (String) session.getAttribute("uploadError");
    session.removeAttribute("uploadNotice");
    session.removeAttribute("uploadError");
%>
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>AlgoLab - 알고리즘 시각화</title>
    <link rel="stylesheet" href="<%= request.getContextPath() %>/resources/css/style.css?v=20261122navfix">
</head>
<body>
    <jsp:include page="menu.jsp" />
    <main class="container">
        <div class="page-heading">
            <p class="eyebrow">ALGORITHM LABORATORY</p>
            <h1>알고리즘 시각화 학습 플랫폼</h1>
            <p class="subtitle">배열을 입력하고 버블·선택·삽입·병합·퀵 정렬의 동작 과정을 단계별로 확인할 수 있습니다.</p>
        </div>
        <section class="panel input-panel">
            <h2>알고리즘 실행</h2>
            <form action="visualizer.jsp" method="post">
                <div class="form-group">
                    <label for="algorithm">알고리즘 선택</label>
                    <select name="algorithm" id="algorithm">
                        <option value="bubble">Bubble Sort</option>
                        <option value="selection">Selection Sort</option>
                        <option value="insertion">Insertion Sort</option>
                        <option value="merge">Merge Sort</option>
                        <option value="quick">Quick Sort</option>
                    </select>
                </div>
                <div class="form-group">
                    <label for="numbers">숫자 배열 입력</label>
                    <input type="text" id="numbers" name="numbers" value="<%= lastNumbers %>"
                           placeholder="예: 5, 3, 1, 4, 2" required>
                    <p class="input-help">쉼표(,)로 구분된 정수 1~30개를 입력하세요.</p>
                </div>
                <button type="submit" class="start-btn">▶ 시각화 시작</button>
            </form>
        </section>
        <section class="panel upload-panel">
            <h2>배열 파일 불러오기</h2>
            <p class="subtitle upload-desc">TXT 또는 CSV 파일에 적힌 정수를 읽어 위 입력창에 채웁니다. 내용을 확인하거나 수정한 뒤 시각화를 시작하세요.</p>

            <% if (uploadNotice != null) { %>
                <p class="upload-message success" role="status"><%= uploadNotice %></p>
            <% } %>
            <% if (uploadError != null) { %>
                <p class="upload-message error" role="alert"><%= uploadError %></p>
            <% } %>

            <form action="<%= request.getContextPath() %>/upload-array"
                  method="post" enctype="multipart/form-data">
                <div class="form-group">
                    <label for="arrayFile">배열 파일 선택</label>
                    <input type="file" id="arrayFile" name="arrayFile"
                           accept=".txt,.csv,text/plain,text/csv" required>
                    <p class="input-help">예: 5,3,1,4,2 또는 줄바꿈으로 구분한 숫자. 정수 1~30개, 최대 16KB. CSV 헤더는 지원하지 않습니다.</p>
                </div>
                <button type="submit" class="start-btn upload-btn">↥ 파일에서 불러오기</button>
            </form>
        </section>
    </main>
</body>
</html>
