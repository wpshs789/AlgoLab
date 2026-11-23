<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<header class="header">
    <a class="logo" href="<%= request.getContextPath() %>/index.jsp">AlgoLab<span>.</span></a>
    <nav aria-label="주 메뉴">
        <a href="<%= request.getContextPath() %>/index.jsp">Home</a>
        <a href="<%= request.getContextPath() %>/benchmark.jsp">성능 비교</a>
        <a href="<%= request.getContextPath() %>/history.jsp">실험 기록</a>
    </nav>
</header>
