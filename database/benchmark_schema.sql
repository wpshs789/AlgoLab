-- [성능 비교 기능 추가] 기존 experiments 테이블과 기록은 변경하지 않습니다.
-- MySQL Workbench에서 기존 algolab DB에 대해 한 번만 실행하세요.
USE algolab;

CREATE TABLE IF NOT EXISTS benchmark_runs (
    id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(100) NOT NULL,
    array_size INT NOT NULL,
    input_pattern VARCHAR(20) NOT NULL,
    repetitions INT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_benchmark_runs_title UNIQUE (title)
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

SHOW TABLES;
DESCRIBE benchmark_runs;
DESCRIBE benchmark_results;
