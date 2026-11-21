package com.algolab.util;

import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.Properties;

import jakarta.servlet.ServletContext;

/**
 * JSP/Servlet에서 공통으로 사용하는 JDBC 연결 클래스.
 * 접속 정보는 Git에 올리지 않는 WEB-INF/db.properties에서 읽는다.
 */
public final class DBConnection {

    private static final String CONFIG_FILE = "/WEB-INF/db.properties";

    private DBConnection() {
    }

    public static Connection getConnection(ServletContext application) throws SQLException {
        Properties config = new Properties();

        try (InputStream input = application.getResourceAsStream(CONFIG_FILE)) {
            if (input == null) {
                throw new SQLException("DB 설정 파일이 없습니다: " + CONFIG_FILE
                        + " (db.properties.example을 복사해 생성하세요.)");
            }
            config.load(new InputStreamReader(input, StandardCharsets.UTF_8));
        } catch (IOException e) {
            throw new SQLException("DB 설정 파일 읽기에 실패했습니다.", e);
        }

        String url = config.getProperty("db.url", "").trim();
        String user = config.getProperty("db.user", "").trim();
        String password = config.getProperty("db.password");

        if (url.isEmpty() || user.isEmpty() || password == null || "CHANGE_ME".equals(password)) {
            throw new SQLException("WEB-INF/db.properties의 db.url, db.user, db.password를 설정하세요.");
        }

        // 강의자료 16장: JDBC 드라이버 로딩 -> DriverManager로 연결 생성.
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
        } catch (ClassNotFoundException e) {
            throw new SQLException("MySQL Connector/J를 찾지 못했습니다. "
                    + "mysql-connector-j-*.jar를 WEB-INF/lib에 추가하세요.", e);
        }

        return DriverManager.getConnection(url, user, password);
    }
}
