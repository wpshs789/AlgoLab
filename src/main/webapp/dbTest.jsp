<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.Connection, java.sql.PreparedStatement, java.sql.ResultSet" %>
<%@ page import="com.algolab.util.DBConnection" %>
<%!
    private String html(String value) {
        if (value == null) return "";
        return value.replace("&", "&amp;").replace("<", "&lt;")
                    .replace(">", "&gt;").replace("\"", "&quot;")
                    .replace("'", "&#39;");
    }
%>
<%
    // 개발 중 연결 확인용 페이지. 배포/최종 제출 전에는 삭제하거나 접근을 제한한다.
    boolean connected = false;
    String databaseName = "";
    String mysqlVersion = "";
    String errorMessage = "";

    try (Connection conn = DBConnection.getConnection(application);
         PreparedStatement pstmt = conn.prepareStatement("SELECT DATABASE(), VERSION()");
         ResultSet rs = pstmt.executeQuery()) {
        if (rs.next()) {
            databaseName = rs.getString(1);
            mysqlVersion = rs.getString(2);
            connected = true;
        }
    } catch (Exception e) {
        errorMessage = e.getMessage();
        application.log("AlgoLab DB connection test failed", e);
    }
%>
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>AlgoLab - DB 연결 테스트</title>
    <style>
        body { background: #101827; color: #e8edf7; font-family: sans-serif; margin: 0; padding: 48px 20px; }
        main { max-width: 660px; margin: auto; padding: 28px; border: 1px solid #34415a; border-radius: 14px; background: #192337; }
        h1 { margin-top: 0; }
        .ok { color: #6ee7b7; } .fail { color: #fda4af; }
        .message { padding: 16px; border-radius: 8px; background: #0f1726; overflow-wrap: anywhere; line-height: 1.7; }
        a { color: #9ac6ff; }
    </style>
</head>
<body>
<main>
    <h1>AlgoLab · JDBC 연결 테스트</h1>
    <% if (connected) { %>
        <h2 class="ok">연결 성공!</h2>
        <p class="message">데이터베이스: <strong><%= html(databaseName) %></strong><br>
        MySQL 버전: <%= html(mysqlVersion) %></p>
    <% } else { %>
        <h2 class="fail">연결 실패</h2>
        <p class="message"><%= html(errorMessage) %></p>
        <p>설정 파일, MySQL 서버 실행 상태와 JDBC 드라이버 경로를 확인해 주세요.</p>
    <% } %>
    <p><a href="<%= request.getContextPath() %>/index.jsp">메인으로 돌아가기</a></p>
</main>
</body>
</html>
