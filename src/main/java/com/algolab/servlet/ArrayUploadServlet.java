package com.algolab.servlet;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import jakarta.servlet.http.Part;

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
        session.removeAttribute("uploadNotice");
        session.removeAttribute("uploadError");

        try {
            String contentType = request.getContentType();
            if (contentType == null ||
                    !contentType.toLowerCase(Locale.ROOT).startsWith("multipart/form-data")) {
                throw new IllegalArgumentException("파일 업로드 형식이 올바르지 않습니다.");
            }

            Part part = request.getPart("arrayFile");
            if (part == null || part.getSize() == 0) {
                throw new IllegalArgumentException("TXT 또는 CSV 파일을 선택해주세요.");
            }

            String name = part.getSubmittedFileName();
            if (name == null) {
                throw new IllegalArgumentException("파일 이름을 확인할 수 없습니다.");
            }
            String lowered = name.toLowerCase(Locale.ROOT);
            if (!lowered.endsWith(".txt") && !lowered.endsWith(".csv")) {
                throw new IllegalArgumentException(".txt 또는 .csv 파일만 사용할 수 있습니다.");
            }
            if (part.getSize() > 16 * 1024) {
                throw new IllegalArgumentException("파일 크기는 16KB 이하여야 합니다.");
            }

            String content;
            try (java.io.InputStream stream = part.getInputStream()) {
                content = new String(stream.readAllBytes(), StandardCharsets.UTF_8);
            }
            // UTF-8 BOM이 포함된 TXT/CSV 파일도 허용한다.
            if (content.startsWith("\uFEFF")) {
                content = content.substring(1);
            }

            String normalized = normalizeNumbers(content);
            session.setAttribute("lastNumbers", normalized);
            session.setAttribute("uploadNotice", "배열을 불러왔습니다. 숫자를 확인한 뒤 시각화를 시작하세요.");
        } catch (IllegalStateException ex) {
            // @MultipartConfig의 최대 업로드 크기 초과 등
            session.setAttribute("uploadError", "파일이 너무 큽니다. 16KB 이하의 파일을 선택해주세요.");
        } catch (IllegalArgumentException ex) {
            session.setAttribute("uploadError", ex.getMessage());
        }

        response.sendRedirect(request.getContextPath() + "/index.jsp");
    }

    private String normalizeNumbers(String content) {
        if (content == null || content.trim().isEmpty()) {
            throw new IllegalArgumentException("파일이 비어 있습니다. 정수를 입력해주세요.");
        }

        // 쉼표/공백/줄바꿈으로 구분된 한 열 또는 한 행의 정수들을 허용한다.
        String[] tokens = content.trim().split("[,\\s]+");
        if (tokens.length < 1 || tokens.length > MAX_COUNT) {
            throw new IllegalArgumentException("배열은 정수 1~30개로 구성해야 합니다.");
        }

        StringJoiner result = new StringJoiner(", ");
        for (String token : tokens) {
            try {
                result.add(Integer.toString(Integer.parseInt(token)));
            } catch (NumberFormatException ex) {
                throw new IllegalArgumentException("파일에는 쉼표, 공백, 줄바꿈으로 구분된 정수만 넣어주세요.");
            }
        }
        return result.toString();
    }
}
