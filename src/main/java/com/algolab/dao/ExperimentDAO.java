package com.algolab.dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;

import com.algolab.dto.Experiment;
import com.algolab.util.DBConnection;
import jakarta.servlet.ServletContext;

/** JDBC로 실험 기록을 등록하고 조회하는 DAO. SQL 인수는 PreparedStatement로 바인딩한다. */
public class ExperimentDAO {
    private final ServletContext application;

    public ExperimentDAO(ServletContext application) {
        this.application = application;
    }

    /** 실험 제목 중복 여부를 JDBC로 확인한다. 최종 중복 방지는 DB UNIQUE 제약조건이 담당한다. */
    public boolean existsByTitle(String title) throws SQLException {
        String sql = "SELECT 1 FROM experiments WHERE title = ? LIMIT 1";
        try (Connection conn = DBConnection.getConnection(application);
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setString(1, title);
            try (ResultSet rs = pstmt.executeQuery()) {
                return rs.next();
            }
        }
    }

    public long insert(Experiment experiment) throws SQLException {
        String sql = "INSERT INTO experiments "
            + "(experiment_type, title, algorithm, input_array, array_size, comparisons, swaps, memo) "
            + "VALUES (?, ?, ?, ?, ?, ?, ?, ?)";
        try (Connection conn = DBConnection.getConnection(application);
             PreparedStatement pstmt = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            pstmt.setString(1, experiment.getExperimentType());
            pstmt.setString(2, experiment.getTitle());
            pstmt.setString(3, experiment.getAlgorithm());
            pstmt.setString(4, experiment.getInputArray());
            pstmt.setInt(5, experiment.getArraySize());
            pstmt.setLong(6, experiment.getComparisons());
            pstmt.setLong(7, experiment.getSwaps());
            pstmt.setString(8, experiment.getMemo());
            int count = pstmt.executeUpdate();
            if (count != 1) throw new SQLException("실험 기록을 저장하지 못했습니다.");
            try (ResultSet keys = pstmt.getGeneratedKeys()) {
                if (keys.next()) return keys.getLong(1);
            }
            throw new SQLException("저장된 실험의 번호를 가져오지 못했습니다.");
        }
    }

    public Experiment findById(long id) throws SQLException {
        String sql = "SELECT id, experiment_type, title, algorithm, input_array, array_size, "
                   + "comparisons, swaps, memo, created_at FROM experiments WHERE id = ?";
        try (Connection conn = DBConnection.getConnection(application);
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setLong(1, id);
            try (ResultSet rs = pstmt.executeQuery()) {
                return rs.next() ? mapRow(rs) : null;
            }
        }
    }

    /** 최신 200건까지 표시. 키워드 검색의 %와 _는 문자 그대로 취급한다. */
    public List<Experiment> search(String keyword, String algorithm, String order) throws SQLException {
        StringBuilder sql = new StringBuilder("SELECT id, experiment_type, title, algorithm, "
            + "input_array, array_size, comparisons, swaps, memo, created_at FROM experiments WHERE 1=1");
        boolean hasKeyword = keyword != null && !keyword.isBlank();
        boolean hasAlgorithm = algorithm != null && !"all".equals(algorithm);
        if (hasKeyword) sql.append(" AND title LIKE ? ESCAPE '!'");
        if (hasAlgorithm) sql.append(" AND algorithm = ?");
        sql.append(" ORDER BY id ").append("oldest".equals(order) ? "ASC" : "DESC").append(" LIMIT 200");

        List<Experiment> result = new ArrayList<>();
        try (Connection conn = DBConnection.getConnection(application);
             PreparedStatement pstmt = conn.prepareStatement(sql.toString())) {
            int index = 1;
            if (hasKeyword) {
                String escaped = keyword.replace("!", "!!").replace("%", "!%").replace("_", "!_");
                pstmt.setString(index++, "%" + escaped + "%");
            }
            if (hasAlgorithm) pstmt.setString(index++, algorithm);
            try (ResultSet rs = pstmt.executeQuery()) {
                while (rs.next()) result.add(mapRow(rs));
            }
        }
        return result;
    }

    /** 지정한 ID의 실험 기록을 삭제한다. 반환값은 삭제된 행 수(0 또는 1)다. */
    public int deleteById(long id) throws SQLException {
        if (id <= 0) throw new IllegalArgumentException("올바른 실험 번호가 아닙니다.");
        String sql = "DELETE FROM experiments WHERE id = ?";
        try (Connection conn = DBConnection.getConnection(application);
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setLong(1, id);
            return pstmt.executeUpdate();
        }
    }

    public long countAll() throws SQLException {
        try (Connection conn = DBConnection.getConnection(application);
             PreparedStatement pstmt = conn.prepareStatement("SELECT COUNT(*) FROM experiments");
             ResultSet rs = pstmt.executeQuery()) {
            rs.next();
            return rs.getLong(1);
        }
    }

    public int countAlgorithms() throws SQLException {
        try (Connection conn = DBConnection.getConnection(application);
             PreparedStatement pstmt = conn.prepareStatement("SELECT COUNT(DISTINCT algorithm) FROM experiments");
             ResultSet rs = pstmt.executeQuery()) {
            rs.next();
            return rs.getInt(1);
        }
    }

    private Experiment mapRow(ResultSet rs) throws SQLException {
        Experiment e = new Experiment();
        e.setId(rs.getLong("id"));
        e.setExperimentType(rs.getString("experiment_type"));
        e.setTitle(rs.getString("title"));
        e.setAlgorithm(rs.getString("algorithm"));
        e.setInputArray(rs.getString("input_array"));
        e.setArraySize(rs.getInt("array_size"));
        e.setComparisons(rs.getLong("comparisons"));
        e.setSwaps(rs.getLong("swaps"));
        e.setMemo(rs.getString("memo"));
        e.setCreatedAt(rs.getTimestamp("created_at"));
        return e;
    }
}
