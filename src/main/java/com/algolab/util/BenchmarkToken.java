package com.algolab.util;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.util.Base64;
import jakarta.servlet.http.HttpSession;

/** 성능 비교 결과 저장·삭제 POST 요청에 사용하는 세션별 CSRF 토큰. */
public final class BenchmarkToken {
    private static final String SESSION_KEY = "benchmarkCsrf";
    private static final SecureRandom RANDOM = new SecureRandom();

    private BenchmarkToken() { }

    public static String getOrCreate(HttpSession session) {
        synchronized (session) {
            Object existing = session.getAttribute(SESSION_KEY);
            if (existing instanceof String && !((String) existing).isEmpty()) return (String) existing;
            byte[] token = new byte[32];
            RANDOM.nextBytes(token);
            String value = Base64.getUrlEncoder().withoutPadding().encodeToString(token);
            session.setAttribute(SESSION_KEY, value);
            return value;
        }
    }

    public static boolean isValid(HttpSession session, String submitted) {
        if (session == null || submitted == null) return false;
        Object expected = session.getAttribute(SESSION_KEY);
        return expected instanceof String
            && MessageDigest.isEqual(((String) expected).getBytes(StandardCharsets.UTF_8),
                submitted.getBytes(StandardCharsets.UTF_8));
    }
}
