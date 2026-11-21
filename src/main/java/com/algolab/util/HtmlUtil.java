package com.algolab.util;

/** JSP에서 사용자 입력을 HTML로 출력할 때 사용하는 간단한 이스케이프 함수. */
public final class HtmlUtil {
    private HtmlUtil() { }

    public static String escape(String value) {
        if (value == null) return "";
        return value.replace("&", "&amp;")
                    .replace("<", "&lt;")
                    .replace(">", "&gt;")
                    .replace("\"", "&quot;")
                    .replace("'", "&#39;");
    }
}
