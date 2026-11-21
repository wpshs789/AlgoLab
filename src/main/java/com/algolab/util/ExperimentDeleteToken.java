package com.algolab.util;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.util.Base64;

import jakarta.servlet.http.HttpSession;

/** 실험 삭제 POST 요청에 사용할 세션별 CSRF 토큰. (권한 인증은 별도 필요) */
public final class ExperimentDeleteToken {
    private static final String SESSION_KEY = "experimentDeleteCsrf";
    private static final SecureRandom RANDOM = new SecureRandom();

    private ExperimentDeleteToken() { }

    public static String getOrCreate(HttpSession session) {
        synchronized (session) {
            Object existing = session.getAttribute(SESSION_KEY);
            if (existing instanceof String && !((String) existing).isEmpty()) {
                return (String) existing;
            }
            byte[] bytes = new byte[32];
            RANDOM.nextBytes(bytes);
            String token = Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
            session.setAttribute(SESSION_KEY, token);
            return token;
        }
    }

    public static boolean isValid(HttpSession session, String supplied) {
        if (session == null || supplied == null) return false;
        Object expected = session.getAttribute(SESSION_KEY);
        return expected instanceof String
            && MessageDigest.isEqual(((String) expected).getBytes(StandardCharsets.UTF_8),
                                     supplied.getBytes(StandardCharsets.UTF_8));
    }
}
