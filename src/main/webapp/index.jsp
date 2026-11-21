<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>AlgoLab - 알고리즘 시각화</title>
    <link rel="stylesheet" href="<%= request.getContextPath() %>/resources/css/style.css?v=20261116a">
</head>
<body>
    <jsp:include page="menu.jsp" />
    <main class="container">
        <div class="page-heading">
            <p class="eyebrow">ALGORITHM LABORATORY</p>
            <h1>알고리즘 시각화 학습 플랫폼</h1>
            <p class="subtitle">직접 배열을 입력하고 정렬 과정을 확인해 보세요.</p>
        </div>
        <section class="panel input-panel">
            <h2>알고리즘 실행</h2>
            <form action="visualizer.jsp" method="post">
                <div class="form-group">
                    <label for="algorithm">알고리즘 선택</label>
                    <select name="algorithm" id="algorithm">
                        <option value="bubble">Bubble Sort</option>
                    </select>
                </div>
                <div class="form-group">
                    <label for="numbers">숫자 배열 입력</label>
                    <input type="text" id="numbers" name="numbers" value="5, 3, 1, 4, 2"
                           placeholder="예: 5, 3, 1, 4, 2" required>
                    <p class="input-help">쉼표(,)로 구분된 정수 1~30개를 입력하세요.</p>
                </div>
                <button type="submit" class="start-btn">▶ 시각화 시작</button>
            </form>
        </section>
    </main>
</body>
</html>
