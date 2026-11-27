-- AlgoLab MySQL 초기 테이블 생성. 노트북과 PC의 MySQL에서 각각 실행하세요.
-- 이 스크립트는 기존 기록을 삭제하지 않습니다.
CREATE DATABASE IF NOT EXISTS algolab
    CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE algolab;

CREATE TABLE IF NOT EXISTS users (
    id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(30) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    display_name VARCHAR(50) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_users_username UNIQUE (username)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


CREATE TABLE IF NOT EXISTS experiments (
    id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    experiment_type VARCHAR(20) NOT NULL DEFAULT 'VISUALIZATION',
    title VARCHAR(100) NOT NULL,
    algorithm VARCHAR(30) NOT NULL,
    input_array TEXT NOT NULL,
    array_size INT NOT NULL,
    comparisons BIGINT NOT NULL DEFAULT 0,
    swaps BIGINT NOT NULL DEFAULT 0,
    memo TEXT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    user_id BIGINT NULL,
    CONSTRAINT fk_experiment_user FOREIGN KEY (user_id) REFERENCES users(id),
    CONSTRAINT uq_experiments_owner_title UNIQUE (user_id, title),
    INDEX idx_experiments_algorithm (algorithm),
    INDEX idx_experiments_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 성능 비교 기능을 처음 설치하는 경우 아래 테이블도 필요합니다.
-- 기존 설치는 필요한 경우 migration_login.sql, 이후 migration_private_records.sql을 사용하세요.
CREATE TABLE IF NOT EXISTS benchmark_runs (
    id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(100) NOT NULL,
    array_size INT NOT NULL,
    input_pattern VARCHAR(20) NOT NULL,
    repetitions INT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    user_id BIGINT NULL,
    CONSTRAINT fk_benchmark_user FOREIGN KEY (user_id) REFERENCES users(id),
    CONSTRAINT uq_benchmark_runs_owner_title UNIQUE (user_id, title)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS benchmark_results (
    run_id BIGINT NOT NULL,
    algorithm VARCHAR(30) NOT NULL,
    avg_time_ns DOUBLE NOT NULL,
    avg_comparisons DOUBLE NOT NULL,
    avg_operations DOUBLE NOT NULL,
    PRIMARY KEY (run_id, algorithm),
    CONSTRAINT fk_benchmark_result_run FOREIGN KEY (run_id)
        REFERENCES benchmark_runs(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 생성 확인용
SHOW TABLES;
DESCRIBE experiments;
DESCRIBE benchmark_runs;
DESCRIBE benchmark_results;
