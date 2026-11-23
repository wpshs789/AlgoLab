<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="com.algolab.i18n.I18n" %>
<%@ page import="java.util.Locale,com.algolab.benchmark.BenchmarkReport,com.algolab.benchmark.BenchmarkResult,com.algolab.benchmark.BenchmarkService,com.algolab.util.BenchmarkToken,com.algolab.util.HtmlUtil" %>
<% I18n msg = I18n.of(session); %>
<%
    request.setCharacterEncoding("UTF-8");
    BenchmarkReport report = (BenchmarkReport) session.getAttribute("pendingBenchmark");
    String error = null;
    String flash = (String) session.getAttribute("benchmarkError");
    session.removeAttribute("benchmarkError");
    String draftTitle = (String) session.getAttribute("benchmarkDraftTitle");
    if (draftTitle == null) draftTitle = "";
    String requestedSize = report == null ? "500" : String.valueOf(report.getArraySize());
    String pattern = report == null ? "random" : report.getPattern();
    String requestedRepeats = report == null ? "5" : String.valueOf(report.getRepetitions());

    if ("POST".equalsIgnoreCase(request.getMethod())) {
        requestedSize = request.getParameter("size");
        requestedRepeats = request.getParameter("repetitions");
        pattern = request.getParameter("pattern");
        session.removeAttribute("pendingBenchmark");
        report = null;
        try {
            if (requestedSize == null || !requestedSize.matches("[0-9]{1,5}")
                    || requestedRepeats == null || !requestedRepeats.matches("[0-9]{1,2}")) {
                throw new IllegalArgumentException(msg.t("err.benchArgs"));
            }
            int size = Integer.parseInt(requestedSize);
            int repeats = Integer.parseInt(requestedRepeats);
            report = BenchmarkService.measure(size, pattern, repeats);
            session.setAttribute("pendingBenchmark", report);
            session.removeAttribute("benchmarkDraftTitle");
            draftTitle = "";
        } catch (IllegalArgumentException ex) {
            error = msg.language().equals("en") ? msg.t("err.benchArgs") : ex.getMessage();
        } catch (Exception ex) {
            application.log("AlgoLab: 성능 비교 실행 실패", ex);
            error = msg.t("err.benchFailed");
        }
    }
    String csrf = BenchmarkToken.getOrCreate(session);
%>
<!DOCTYPE html>
<html lang="<%= msg.language() %>">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <title>AlgoLab - <%= msg.t("title.benchmark") %></title>
    <link rel="stylesheet" href="<%= request.getContextPath() %>/resources/css/style.css?v=20261123i18n1">
    <link rel="stylesheet" href="<%= request.getContextPath() %>/resources/css/benchmark.css?v=20261123i18n1">
</head>
<body>
    <jsp:include page="menu.jsp" />
    <main class="container benchmark-container">
        <div class="page-heading">
            <p class="eyebrow">PERFORMANCE COMPARISON</p>
            <h1><%= msg.t("benchmark.heading") %></h1>
            <p class="subtitle"><%= msg.t("benchmark.lead") %></p>
        </div>

        <section class="panel benchmark-config" aria-labelledby="benchmarkConfigHeading">
            <div class="benchmark-section-title">
                <h2 id="benchmarkConfigHeading"><%= msg.t("benchmark.setup") %></h2>
                <span class="benchmark-mini-tag"><%= msg.t("benchmark.same") %></span>
            </div>
            <form method="post" action="<%= request.getContextPath() %>/benchmark.jsp" id="benchmarkForm">
                <div class="benchmark-form-grid">
                    <div class="form-group">
                        <label for="size"><%= msg.t("common.arraySize") %></label>
                        <input type="number" name="size" id="size" min="10" max="5000" step="1" required
                            data-error-required="<%= msg.t("validation.sizeRequired") %>"
                            data-error-range="<%= msg.t("validation.sizeRange") %>"
                            data-error-number="<%= msg.t("validation.sizeInteger") %>"
                            data-error-invalid="<%= msg.t("validation.invalid") %>"
                            value="<%= HtmlUtil.escape(requestedSize == null ? "" : requestedSize) %>">
                        <p class="input-help"><%= msg.t("benchmark.sizeHelp") %></p>
                    </div>
                    <div class="form-group">
                        <label for="pattern"><%= msg.t("benchmark.pattern") %></label>
                        <select name="pattern" id="pattern">
                            <option value="random" <%= "random".equals(pattern) ? "selected" : "" %>><%= msg.t("benchmark.random") %></option>
                            <option value="ascending" <%= "ascending".equals(pattern) ? "selected" : "" %>><%= msg.t("benchmark.ascending") %></option>
                            <option value="descending" <%= "descending".equals(pattern) ? "selected" : "" %>><%= msg.t("benchmark.descending") %></option>
                            <option value="nearly" <%= "nearly".equals(pattern) ? "selected" : "" %>><%= msg.t("benchmark.nearly") %></option>
                        </select>
                        <p class="input-help"><%= msg.t("benchmark.sameHelp") %></p>
                    </div>
                    <div class="form-group">
                        <label for="repetitions"><%= msg.t("benchmark.repetitions") %></label>
                        <select name="repetitions" id="repetitions">
                            <% for (int c : new int[]{1,3,5,10}) { %>
                                <option value="<%= c %>" <%= String.valueOf(c).equals(requestedRepeats) ? "selected" : "" %>><%= c %><%= msg.t("common.times") %></option>
                            <% } %>
                        </select>
                        <p class="input-help"><%= msg.t("benchmark.repeatHelp") %></p>
                    </div>
                </div>
                <button class="start-btn" type="submit" id="runBenchmarkButton"><%= msg.t("benchmark.run") %></button>
            </form>
        </section>

        <% if (error != null || flash != null) { %>
        <div class="benchmark-alert" role="alert"><%= HtmlUtil.escape(error != null ? error : flash) %></div>
        <% } %>

        <% if (report != null) { %>
            <section class="panel benchmark-results" aria-labelledby="resultHeading">
                <div class="benchmark-section-title benchmark-results-title">
                    <div>
                        <p class="eyebrow">BENCHMARK RESULTS</p>
                        <h2 id="resultHeading"><%= msg.t("benchmark.results") %></h2>
                    </div>
                    <span class="benchmark-mini-tag"><%= msg.f("benchmark.summary", report.getArraySize(), msg.t("pattern." + report.getPattern()), report.getRepetitions()) %></span>
                </div>
                <div class="benchmark-table-wrap">
                    <table class="benchmark-table">
                        <thead><tr>
                            <th scope="col"><%= msg.t("common.algorithm") %></th>
                            <th scope="col"><%= msg.t("benchmark.complexity") %></th>
                            <th scope="col"><%= msg.t("benchmark.avgCompares") %></th>
                            <th scope="col"><%= msg.t("benchmark.avgMoves") %></th>
                            <th scope="col"><%= msg.t("benchmark.avgTime") %></th>
                        </tr></thead>
                        <tbody>
                        <% for (BenchmarkResult row : report.getResults()) { %>
                            <tr>
                                <th scope="row"><%= row.getLabel() %></th>
                                <td class="benchmark-muted"><%= row.getAverageComplexity() %></td>
                                <td><%= String.format(Locale.KOREA, "%,.1f", row.getAverageComparisons()) %></td>
                                <td><span title="<%= msg.t("operation." + ("insertion".equals(row.getAlgorithm()) ? "insertion" : "merge".equals(row.getAlgorithm()) ? "merge" : "standard")) %>"><%= String.format(Locale.KOREA, "%,.1f", row.getAverageOperations()) %></span>
                                    <small><%= msg.t("operation." + ("insertion".equals(row.getAlgorithm()) ? "insertion" : "merge".equals(row.getAlgorithm()) ? "merge" : "standard")) %></small></td>
                                <td class="benchmark-time"><%= String.format(Locale.KOREA, "%,.4f", row.getAverageMilliseconds()) %></td>
                            </tr>
                        <% } %>
                        </tbody>
                    </table>
                </div>
                <div class="benchmark-explain">
                    <p><strong><%= msg.t("benchmark.method") %></strong> · <%= msg.t("benchmark.methodExplain") %></p>
                    <p><strong><%= msg.t("benchmark.interpret") %></strong> · <%= msg.t("benchmark.interpretExplain") %></p>
                    <p><strong><%= msg.t("benchmark.quickNote") %></strong> · <%= msg.t("benchmark.quickExplain") %></p>
                </div>
            </section>

            <section class="panel benchmark-save" aria-labelledby="benchmarkSaveHeading">
                <div>
                    <h2 id="benchmarkSaveHeading"><%= msg.t("benchmark.saveHeading") %></h2>
                    <p class="subtitle"><%= msg.t("benchmark.saveLead") %></p>
                </div>
                <form action="<%= request.getContextPath() %>/saveBenchmarkProcess.jsp" method="post" class="benchmark-save-form">
                    <input type="hidden" name="csrf" value="<%= csrf %>">
                    <label for="benchmarkTitle"><%= msg.t("common.title") %></label>
                    <div class="benchmark-save-inputs">
                        <input type="text" name="title" id="benchmarkTitle" required maxlength="100"
                            data-error-required="<%= msg.t("validation.benchmarkTitleRequired") %>"
                            data-error-invalid="<%= msg.t("validation.invalid") %>"
                            placeholder="<%= msg.t("benchmark.titleExample") %>"
                            value="<%= HtmlUtil.escape(draftTitle) %>">
                        <button type="submit" class="start-btn"><%= msg.t("benchmark.save") %></button>
                    </div>
                    <p class="input-help"><%= msg.t("benchmark.duplicateHint") %></p>
                </form>
            </section>
        <% } else { %>
            <section class="panel benchmark-placeholder">
                <p class="eyebrow">READY TO COMPARE</p>
                <h2><%= msg.t("benchmark.placeholder") %></h2>
                <p class="subtitle"><%= msg.t("benchmark.visualizationPrefix") %> <a href="<%= request.getContextPath() %>/index.jsp"><%= msg.t("benchmark.visualization") %></a><%= msg.t("benchmark.visualizationSuffix") %></p>
            </section>
        <% } %>
        <div class="bottom-nav"><a class="back-link" href="<%= request.getContextPath() %>/index.jsp"><%= msg.t("common.backHome") %></a></div>
    </main>
    <script src="<%= request.getContextPath() %>/resources/js/form-validation.js?v=20261123i18nAudit1" defer></script>
    <script>
    (function () {
        var form = document.getElementById('benchmarkForm');
        var button = document.getElementById('runBenchmarkButton');
        if (form && button) form.addEventListener('submit', function () {
            if (!form.checkValidity()) return;
            button.disabled = true;
            button.textContent = '<%= msg.t("benchmark.measuring") %>';
        });
    }());
    </script>
</body>
</html>
