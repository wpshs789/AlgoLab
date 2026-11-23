package com.algolab.servlet;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import jakarta.servlet.http.Part;
import com.algolab.i18n.I18n;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.Locale;
import java.util.StringJoiner;

/**
 * TXT/CSV 파일에 적힌 정수를 읽고 검증하여 메인 JSP 입력창에 전달한다.
 * 파일은 디스크/DB에 저장하지 않는다. 최대 30개 정수만 세션에 저장한다.
 * Tomcat 10.1 이상: jakarta.servlet 기반.
 */
@WebServlet("/upload-array")
@MultipartConfig(fileSizeThreshold = 0, maxFileSize = 16 * 1024, maxRequestSize = 32 * 1024)
public class ArrayUploadServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private static final int MAX_COUNT = 30;

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");
        HttpSession session = request.getSession();
        I18n msg = I18n.of(session);
        session.removeAttribute("uploadNotice");
        session.removeAttribute("uploadError");

        try {
            String contentType = request.getContentType();
            if (contentType == null ||
                    !contentType.toLowerCase(Locale.ROOT).startsWith("multipart/form-data")) {
                throw new IllegalArgumentException(msg.t("upload.format"));
            }

            Part part = request.getPart("arrayFile");
            if (part == null || part.getSize() == 0) {
                throw new IllegalArgumentException(msg.t("upload.choose"));
            }

            String name = part.getSubmittedFileName();
            if (name == null) {
                throw new IllegalArgumentException(msg.t("upload.name"));
            }
            String lowered = name.toLowerCase(Locale.ROOT);
            if (!lowered.endsWith(".txt") && !lowered.endsWith(".csv")) {
                throw new IllegalArgumentException(msg.t("upload.ext"));
            }
            if (part.getSize() > 16 * 1024) {
                throw new IllegalArgumentException(msg.t("upload.size"));
            }

            String content;
            try (java.io.InputStream stream = part.getInputStream()) {
                content = new String(stream.readAllBytes(), StandardCharsets.UTF_8);
            }
            // UTF-8 BOM이 포함된 TXT/CSV 파일도 허용한다.
            if (content.startsWith("\uFEFF")) {
                content = content.substring(1);
            }

            String normalized = normalizeNumbers(content, msg);
            session.setAttribute("lastNumbers", normalized);
            session.setAttribute("uploadNotice", msg.t("upload.success"));
        } catch (IllegalStateException ex) {
            // @MultipartConfig의 최대 업로드 크기 초과 등
            session.setAttribute("uploadError", msg.t("upload.tooLarge"));
        } catch (IllegalArgumentException ex) {
            session.setAttribute("uploadError", ex.getMessage());
        }

        response.sendRedirect(request.getContextPath() + "/index.jsp");
    }

    private String normalizeNumbers(String content, I18n msg) {
        if (content == null || content.trim().isEmpty()) {
            throw new IllegalArgumentException(msg.t("upload.empty"));
        }

        // 쉼표/공백/줄바꿈으로 구분된 한 열 또는 한 행의 정수들을 허용한다.
        String[] tokens = content.trim().split("[,\\s]+");
        if (tokens.length < 1 || tokens.length > MAX_COUNT) {
            throw new IllegalArgumentException(msg.t("upload.count"));
        }

        StringJoiner result = new StringJoiner(", ");
        for (String token : tokens) {
            try {
                result.add(Integer.toString(Integer.parseInt(token)));
            } catch (NumberFormatException ex) {
                throw new IllegalArgumentException(msg.t("upload.integers"));
            }
        }
        return result.toString();
    }
}
