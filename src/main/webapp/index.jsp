<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="com.algolab.i18n.I18n" %>
<% response.setHeader("Cache-Control", "no-store"); I18n msg = I18n.of(session); %>
<%
    // 파일 업로드 또는 직전 실행에서 저장한 숫자 배열을 기본 입력값으로 표시한다.
    // lastNumbers에는 서버가 검증하고 정규화한 정수 문자열만 저장한다.
    String lastNumbers = (String) session.getAttribute("lastNumbers");
    if (lastNumbers == null || lastNumbers.isEmpty()) {
        lastNumbers = "5, 3, 1, 4, 2";
    }
    String preferredAlgorithm = com.algolab.util.AlgorithmCookie.lastAlgorithm(request);
    String uploadNotice = (String) session.getAttribute("uploadNotice");
    String uploadError = (String) session.getAttribute("uploadError");
    session.removeAttribute("uploadNotice");
    session.removeAttribute("uploadError");
%>
<!DOCTYPE html>
<html lang="<%= msg.language() %>">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>AlgoLab - <%= msg.t("title.index") %></title>
    <link rel="stylesheet" href="<%= request.getContextPath() %>/resources/css/style.css?v=20261123filepicker2">
    <link rel="stylesheet" href="<%= request.getContextPath() %>/resources/css/auth.css?v=login1">
</head>
<body>
    <jsp:include page="menu.jsp" />
    <main class="container">
        <div class="page-heading">
            <p class="eyebrow">ALGORITHM LABORATORY</p>
            <h1><%= msg.t("index.heading") %></h1>
            <p class="subtitle"><%= msg.t("index.lead") %></p>
        </div>
        <section class="panel input-panel">
            <h2><%= msg.t("index.run") %></h2>
            <form action="visualizer.jsp" method="post">
                <div class="form-group">
                    <label for="algorithm"><%= msg.t("common.chooseAlgorithm") %></label>
                    <select name="algorithm" id="algorithm">
                        <option value="bubble" <%= "bubble".equals(preferredAlgorithm) ? "selected" : "" %>>Bubble Sort</option>
                        <option value="selection" <%= "selection".equals(preferredAlgorithm) ? "selected" : "" %>>Selection Sort</option>
                        <option value="insertion" <%= "insertion".equals(preferredAlgorithm) ? "selected" : "" %>>Insertion Sort</option>
                        <option value="merge" <%= "merge".equals(preferredAlgorithm) ? "selected" : "" %>>Merge Sort</option>
                        <option value="quick" <%= "quick".equals(preferredAlgorithm) ? "selected" : "" %>>Quick Sort</option>
                    </select>
                </div>
                <div class="form-group">
                    <label for="numbers"><%= msg.t("index.numbers") %></label>
                    <input type="text" id="numbers" name="numbers" value="<%= lastNumbers %>"
                           placeholder="<%= msg.t("index.example") %>" required
                           data-error-required="<%= msg.t("validation.arrayRequired") %>"
                           data-error-invalid="<%= msg.t("validation.invalid") %>">
                    <p class="input-help"><%= msg.t("index.numbersHelp") %></p>
                </div>
                <button type="submit" class="start-btn"><%= msg.t("index.start") %></button>
            </form>
        </section>
        <section class="panel upload-panel">
            <h2><%= msg.t("index.upload") %></h2>
            <p class="subtitle upload-desc"><%= msg.t("index.uploadLead") %></p>

            <% if (uploadNotice != null) { %>
                <p class="upload-message success" role="status"><%= uploadNotice %></p>
            <% } %>
            <% if (uploadError != null) { %>
                <p class="upload-message error" role="alert"><%= uploadError %></p>
            <% } %>

            <form id="arrayUploadForm" action="<%= request.getContextPath() %>/upload-array"
                  method="post" enctype="multipart/form-data"
                  data-file-required="<%= com.algolab.util.HtmlUtil.escape(msg.t("upload.choose")) %>"
                  novalidate>
                <div class="form-group">
                    <label for="arrayFile"><%= msg.t("index.chooseFile") %></label>
                    <%-- 브라우저 기본 파일 입력 UI의 '파일 선택/선택된 파일 없음'은 OS 언어를 따르므로
                         실제 input은 유지하되 사용자에게는 사이트 언어에 맞춘 UI를 보여줍니다. --%>
                    <input type="file" id="arrayFile" name="arrayFile"
                           class="file-input-visually-hidden" tabindex="-1"
                           accept=".txt,.csv,text/plain,text/csv"
                           aria-describedby="arrayFileName">
                    <div class="file-picker" role="group" aria-label="<%= msg.t("index.chooseFile") %>">
                        <button type="button" id="chooseArrayFile" class="file-choose-btn">
                            <%= msg.t("index.fileButton") %>
                        </button>
                        <span id="arrayFileName" class="file-selected-name" aria-live="polite">
                            <%= msg.t("index.noFileSelected") %>
                        </span>
                    </div>
                    <p id="arrayFileError" class="upload-message error" role="alert" hidden></p>
                    <p class="input-help"><%= msg.t("index.uploadHelp") %></p>
                </div>
                <button type="submit" class="start-btn upload-btn"><%= msg.t("index.loadFile") %></button>
            </form>
        </section>

        <section class="panel benchmark-home-callout">
            <div><p class="eyebrow">PERFORMANCE COMPARISON</p>
                <h2><%= msg.t("index.performance") %></h2>
                <p class="subtitle"><%= msg.t("index.performanceLead") %></p></div>
            <a class="save-link" href="<%= request.getContextPath() %>/benchmark.jsp"><%= msg.t("index.goPerformance") %></a>
        </section>
    </main>
    <script src="<%= request.getContextPath() %>/resources/js/form-validation.js?v=20261123i18nAudit1" defer></script>
    <script>
        // 파일 입력은 서버 전송에 그대로 사용하고, 표시 문구만 사이트 언어에 맞게 구성합니다.
        (function () {
            "use strict";
            const form = document.getElementById('arrayUploadForm');
            const fileInput = document.getElementById('arrayFile');
            const chooseButton = document.getElementById('chooseArrayFile');
            const fileName = document.getElementById('arrayFileName');
            const error = document.getElementById('arrayFileError');
            if (!form || !fileInput || !chooseButton || !fileName || !error) return;
            const emptyText = fileName.textContent.trim();

            chooseButton.addEventListener('click', function () {
                fileInput.click();
            });

            fileInput.addEventListener('change', function () {
                const selected = fileInput.files && fileInput.files[0];
                fileName.textContent = selected ? selected.name : emptyText;
                error.hidden = true;
                error.textContent = '';
            });

            form.addEventListener('submit', function (event) {
                if (!fileInput.files || fileInput.files.length === 0) {
                    event.preventDefault();
                    error.textContent = form.dataset.fileRequired || 'Select a file.';
                    error.hidden = false;
                    chooseButton.focus();
                }
            });
        })();
    </script>
</body>
</html>
