package com.algolab.dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.List;

import com.algolab.benchmark.BenchmarkRecord;
import com.algolab.benchmark.BenchmarkReport;
import com.algolab.benchmark.BenchmarkResult;
import com.algolab.util.DBConnection;
import jakarta.servlet.ServletContext;

/** 성능 비교 실험을 별도 테이블에 저장하는 JDBC DAO. */
public final class BenchmarkDAO {
    private final ServletContext application;

    public BenchmarkDAO(ServletContext application) { this.application = application; }

    public boolean existsByTitle(String title, long ownerId) throws SQLException {
        try (Connection conn = DBConnection.getConnection(application);
             PreparedStatement ps = conn.prepareStatement("SELECT 1 FROM benchmark_runs WHERE title = ? AND user_id = ? LIMIT 1")) {
            ps.setString(1, title);
            ps.setLong(2, ownerId);
            try (ResultSet rs = ps.executeQuery()) { return rs.next(); }
        }
    }

    /** 하나의 성능 비교와 다섯 결과를 한 트랜잭션으로 저장합니다. */
    public long insert(String title, BenchmarkReport report, long ownerId) throws SQLException {
        if (ownerId <= 0 || title == null || title.isBlank() || title.length() > 100 || report == null) {
            throw new IllegalArgumentException("성능 비교 저장 정보가 올바르지 않습니다.");
        }
        try (Connection conn = DBConnection.getConnection(application)) {
            conn.setAutoCommit(false);
            try {
                long id;
                try (PreparedStatement ps = conn.prepareStatement(
                    "INSERT INTO benchmark_runs (title, array_size, input_pattern, repetitions, user_id) VALUES (?, ?, ?, ?, ?)",
                    Statement.RETURN_GENERATED_KEYS)) {
                    ps.setString(1, title);
                    ps.setInt(2, report.getArraySize());
                    ps.setString(3, report.getPattern());
                    ps.setInt(4, report.getRepetitions());
                    ps.setLong(5, ownerId);
                    if (ps.executeUpdate() != 1) throw new SQLException("성능 비교 저장에 실패했습니다.");
                    try (ResultSet keys = ps.getGeneratedKeys()) {
                        if (!keys.next()) throw new SQLException("저장 ID를 찾지 못했습니다.");
                        id = keys.getLong(1);
                    }
                }
                try (PreparedStatement ps = conn.prepareStatement(
                    "INSERT INTO benchmark_results (run_id, algorithm, avg_time_ns, avg_comparisons, avg_operations) "
                    + "VALUES (?, ?, ?, ?, ?)")) {
                    for (BenchmarkResult row : report.getResults()) {
                        ps.setLong(1, id);
                        ps.setString(2, row.getAlgorithm());
                        ps.setDouble(3, row.getAverageNanoseconds());
                        ps.setDouble(4, row.getAverageComparisons());
                        ps.setDouble(5, row.getAverageOperations());
                        ps.addBatch();
                    }
                    int[] written = ps.executeBatch();
                    if (written.length != 5) throw new SQLException("5종 정렬 결과를 모두 저장하지 못했습니다.");
                }
                conn.commit();
                return id;
            } catch (SQLException | RuntimeException ex) {
                try { conn.rollback(); } catch (SQLException rollbackError) { ex.addSuppressed(rollbackError); }
                throw ex;
            } finally {
                try { conn.setAutoCommit(true); } catch (SQLException ignored) { }
            }
        }
    }

    public List<BenchmarkRecord> findRecent(int limit, long ownerId) throws SQLException {
        List<BenchmarkRecord> records = new ArrayList<>();
        int boundedLimit = Math.max(1, Math.min(limit, 100));
        try (Connection conn = DBConnection.getConnection(application);
             PreparedStatement ps = conn.prepareStatement(
                "SELECT id, title, array_size, input_pattern, repetitions, created_at, user_id, (SELECT display_name FROM users WHERE users.id = benchmark_runs.user_id) AS owner_name "
                + "FROM benchmark_runs WHERE user_id = ? ORDER BY id DESC LIMIT ?")) {
            ps.setLong(1, ownerId);
            ps.setInt(2, boundedLimit);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    // 목록에는 메타데이터만 사용합니다. 상세는 findById에서 5개 결과를 읽습니다.
                    records.add(new BenchmarkRecord(rs.getLong("id"), rs.getString("title"),
                        rs.getTimestamp("created_at"),
                        new BenchmarkReport(rs.getInt("array_size"), rs.getString("input_pattern"),
                            rs.getInt("repetitions"), emptyRows()), rs.getLong("user_id"), rs.getString("owner_name")));
                }
            }
        }
        return records;
    }

    private static List<BenchmarkResult> emptyRows() {
        List<BenchmarkResult> rows = new ArrayList<>();
        for (String algorithm : new String[]{"bubble", "selection", "insertion", "merge", "quick"}) {
            rows.add(new BenchmarkResult(algorithm, 0, 0, 0));
        }
        return rows;
    }

    public BenchmarkRecord findById(long id, long requestedOwnerId) throws SQLException {
        if (id < 1) return null;
        try (Connection conn = DBConnection.getConnection(application)) {
            String title;
            Timestamp created;
            int size, repeats;
            String pattern;
            long ownerId; String ownerName;
            try (PreparedStatement ps = conn.prepareStatement(
                "SELECT title, array_size, input_pattern, repetitions, created_at, user_id, (SELECT display_name FROM users WHERE users.id = benchmark_runs.user_id) AS owner_name FROM benchmark_runs WHERE id = ? AND user_id = ?")) {
                ps.setLong(1, id);
                ps.setLong(2, requestedOwnerId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (!rs.next()) return null;
                    title = rs.getString("title");
                    size = rs.getInt("array_size");
                    pattern = rs.getString("input_pattern");
                    repeats = rs.getInt("repetitions");
                    created = rs.getTimestamp("created_at");
                    ownerId = rs.getLong("user_id"); ownerName = rs.getString("owner_name");
                }
            }
            List<BenchmarkResult> rows = new ArrayList<>();
            try (PreparedStatement ps = conn.prepareStatement(
                "SELECT algorithm, avg_time_ns, avg_comparisons, avg_operations "
                + "FROM benchmark_results WHERE run_id = ? AND EXISTS (SELECT 1 FROM benchmark_runs WHERE id = benchmark_results.run_id AND user_id = ?) "
                + "ORDER BY FIELD(algorithm, 'bubble', 'selection', 'insertion', 'merge', 'quick')")) {
                ps.setLong(1, id);
                ps.setLong(2, requestedOwnerId);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        rows.add(new BenchmarkResult(rs.getString("algorithm"),
                            rs.getDouble("avg_time_ns"),
                            rs.getDouble("avg_comparisons"), rs.getDouble("avg_operations")));
                    }
                }
            }
            if (rows.size() != 5) throw new SQLException("저장된 성능 비교 결과에 누락된 알고리즘이 있습니다.");
            return new BenchmarkRecord(id, title, created, new BenchmarkReport(size, pattern, repeats, rows), ownerId, ownerName);
        }
    }

    public int deleteById(long id, long ownerId) throws SQLException {
        if (id <= 0) throw new IllegalArgumentException("올바른 실험 번호가 아닙니다.");
        try (Connection conn = DBConnection.getConnection(application);
             PreparedStatement ps = conn.prepareStatement("DELETE FROM benchmark_runs WHERE id = ? AND user_id = ?")) {
            ps.setLong(1, id);
            ps.setLong(2, ownerId);
            return ps.executeUpdate(); // 외래키 ON DELETE CASCADE로 결과도 함께 제거
        }
    }
}
