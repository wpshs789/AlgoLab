package com.algolab.auth;
import jakarta.servlet.http.HttpSession;
import jakarta.servlet.http.HttpServletRequest;
import java.security.SecureRandom;
import java.security.MessageDigest;
import java.util.Base64;
import java.nio.charset.StandardCharsets;

public final class Auth {
    private static final SecureRandom RANDOM = new SecureRandom();
    private Auth() { }
    public static User current(HttpSession session) {
        Object value = session.getAttribute("authUser");
        return value instanceof User u ? u : null;
    }
    public static boolean owns(HttpSession session, long ownerId) {
        User u = current(session);
        return u != null && ownerId > 0 && u.id() == ownerId;
    }
    public static String token(HttpSession session) {
        synchronized (session) {
            String token = (String) session.getAttribute("authCsrf");
            if (token == null) {
                byte[] bytes = new byte[32]; RANDOM.nextBytes(bytes);
                token = Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
                session.setAttribute("authCsrf", token);
            }
            return token;
        }
    }
    public static boolean valid(HttpSession session, String submitted) {
        String expected = (String) session.getAttribute("authCsrf");
        return expected != null && submitted != null && MessageDigest.isEqual(
            expected.getBytes(StandardCharsets.UTF_8), submitted.getBytes(StandardCharsets.UTF_8));
    }
    public static void login(HttpServletRequest request, User user) {
        HttpSession session = request.getSession();
        request.changeSessionId(); // 세션 고정 공격 방지, 게스트의 미저장 실험은 유지
        for (String key : new String[]{"authCsrf", "saveExperimentCsrf", "benchmarkCsrf", "experimentDeleteCsrf"})
            session.removeAttribute(key);
        session.setAttribute("authUser", user);
    }
    public static String next(String value) {
        return "saveExperiment.jsp".equals(value) || "benchmark.jsp".equals(value) || "history.jsp".equals(value) ? value : "index.jsp";
    }
}
