package com.algolab.util;

import jakarta.servlet.http.Cookie;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

/** Remember the last successfully visualized algorithm for 30 days. */
public final class AlgorithmCookie {
    private static final String COOKIE_NAME = "algolabLastAlgorithm";
    private static final int MAX_AGE_SECONDS = 30 * 24 * 60 * 60;
    private AlgorithmCookie() {}

    public static boolean supported(String algorithm) {
        return "bubble".equals(algorithm) || "selection".equals(algorithm)
            || "insertion".equals(algorithm) || "merge".equals(algorithm)
            || "quick".equals(algorithm);
    }

    public static String lastAlgorithm(HttpServletRequest request) {
        Cookie[] cookies = request.getCookies();
        if (cookies != null) {
            for (Cookie cookie : cookies) {
                if (COOKIE_NAME.equals(cookie.getName()) && supported(cookie.getValue())) {
                    return cookie.getValue();
                }
            }
        }
        return "bubble";
    }

    public static void save(HttpServletRequest request, HttpServletResponse response, String algorithm) {
        if (!supported(algorithm)) return;
        Cookie cookie = new Cookie(COOKIE_NAME, algorithm);
        String path = request.getContextPath();
        cookie.setPath(path == null || path.isEmpty() ? "/" : path + "/");
        cookie.setMaxAge(MAX_AGE_SECONDS);
        cookie.setHttpOnly(true);
        cookie.setSecure(request.isSecure());
        cookie.setAttribute("SameSite", "Lax"); // Tomcat 10.1 / Servlet 6
        response.addCookie(cookie);
    }
}
