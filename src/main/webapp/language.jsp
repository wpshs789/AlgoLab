<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true" %>
<%@ page import="com.algolab.i18n.I18n" %>
<%
    String language = request.getParameter("lang");
    if (I18n.isSupported(language)) session.setAttribute("algolabLanguage", language);
    String next = request.getParameter("next");
    String base = request.getContextPath();
    String target = base + "/index.jsp";
    if (next != null && next.startsWith(base + "/")
            && !next.contains("\\") && !next.contains("//")
            && !next.contains("\r") && !next.contains("\n")) {
        // Restrict the redirect to known read-only page paths.
        String relative = next.substring(base.length());
        String path = relative.split("\\?", 2)[0];
        if (path.matches("/(index|visualizer|benchmark|history|experiment|benchmarkDetail|saveExperiment|login|signup|dbTest)\\.jsp")) {
            target = next;
        }
    }
    response.sendRedirect(response.encodeRedirectURL(target));
%>
