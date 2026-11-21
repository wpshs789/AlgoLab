-- AlgoLab MySQL 초기 테이블 생성. 노트북과 PC의 MySQL에서 각각 실행하세요.
-- 이 스크립트는 기존 기록을 삭제하지 않습니다.
CREATE DATABASE IF NOT EXISTS algolab
    CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE algolab;

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
    INDEX idx_experiments_algorithm (algorithm),
    INDEX idx_experiments_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 확인용
SHOW TABLES;
DESCRIBE experiments;
