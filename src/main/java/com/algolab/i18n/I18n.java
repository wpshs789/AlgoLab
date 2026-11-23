package com.algolab.i18n;

import jakarta.servlet.http.HttpSession;
import java.util.Locale;
import java.util.ResourceBundle;

/** Session-based Korean/English messages loaded from UTF-8 ResourceBundle files (Java 17+). */
public final class I18n {
    private static final String BASE = "com.algolab.i18n.messages";
    private final ResourceBundle messages;
    private final String language;

    private I18n(String language) {
        this.language = "en".equals(language) ? "en" : "ko";
        this.messages = ResourceBundle.getBundle(BASE, Locale.forLanguageTag(this.language));
    }

    public static I18n of(HttpSession session) {
        Object value = session == null ? null : session.getAttribute("algolabLanguage");
        return new I18n(value instanceof String ? (String) value : "ko");
    }

    public static boolean isSupported(String language) {
        return "ko".equals(language) || "en".equals(language);
    }

    public String language() { return language; }
    public String t(String key) { return messages.getString(key); }

    public String f(String key, Object... args) {
        String value = t(key);
        for (int n = 0; n < args.length; n++) {
            value = value.replace("{" + n + "}", String.valueOf(args[n]));
        }
        return value;
    }

    /** JSON messages for the external visualization JavaScript. */
    public String clientJson() {
        StringBuilder out = new StringBuilder("{");
        boolean first = true;
        for (String key : messages.keySet()) {
            if (!key.startsWith("js.")) continue;
            if (!first) out.append(',');
            first = false;
            out.append('"').append(jsonEscape(key)).append("\":\"")
                    .append(jsonEscape(messages.getString(key))).append('"');
        }
        return out.append('}').toString();
    }

    private static String jsonEscape(String s) {
        StringBuilder b = new StringBuilder();
        for (int i = 0; i < s.length(); i++) {
            char c = s.charAt(i);
            switch (c) {
                case '\\': b.append("\\\\"); break;
                case '"': b.append("\\\""); break;
                case '\r': b.append("\\r"); break;
                case '\n': b.append("\\n"); break;
                case '\t': b.append("\\t"); break;
                case '<': b.append("\\u003c"); break;
                case '>': b.append("\\u003e"); break;
                case '&': b.append("\\u0026"); break;
                case '\u2028': b.append("\\u2028"); break;
                case '\u2029': b.append("\\u2029"); break;
                default: b.append(c);
            }
        }
        return b.toString();
    }
}
