package com.algolab.dao;
import java.sql.*;
import jakarta.servlet.ServletContext;
import com.algolab.auth.User;
import com.algolab.auth.Passwords;
import com.algolab.util.DBConnection;

public final class UserDAO {
    private final ServletContext application;
    public UserDAO(ServletContext application) { this.application = application; }
    public boolean exists(String username) throws SQLException {
        try (Connection c = DBConnection.getConnection(application);
             PreparedStatement p = c.prepareStatement("SELECT 1 FROM users WHERE username = ?")) {
            p.setString(1, username);
            try (ResultSet r = p.executeQuery()) { return r.next(); }
        }
    }
    public void insert(String username, String password, String displayName) throws SQLException {
        String hash = Passwords.hash(password);
        try (Connection c = DBConnection.getConnection(application);
             PreparedStatement p = c.prepareStatement("INSERT INTO users (username,password_hash,display_name) VALUES (?,?,?)")) {
            p.setString(1, username); p.setString(2, hash); p.setString(3, displayName);
            p.executeUpdate();
        }
    }
    public User authenticate(String username, String password) throws SQLException {
        User user = null;
        String hash = null;
        try (Connection c = DBConnection.getConnection(application);
             PreparedStatement p = c.prepareStatement("SELECT id,username,display_name,password_hash FROM users WHERE username = ?")) {
            p.setString(1, username);
            try (ResultSet r = p.executeQuery()) {
                if (r.next()) {
                    user = new User(r.getLong("id"), r.getString("username"), r.getString("display_name"));
                    hash = r.getString("password_hash");
                }
            }
        }
        // 없는 계정도 동일한 해시 연산 비용을 사용합니다.
        if (hash == null) hash = "pbkdf2-sha256$600000$AAAAAAAAAAAAAAAAAAAAAA==$AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
        return Passwords.verify(password, hash) ? user : null;
    }
}
