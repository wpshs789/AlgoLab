-- 기존 AlgoLab experiments 테이블: 실험 제목 중복을 방지합니다.
-- 중요: 기존 데이터는 삭제하지 않지만, 이미 중복된 제목이 있다면
--       아래 ALTER TABLE이 실패합니다. 먼저 중복 기록을 삭제하거나 이름을 변경하세요.
USE algolab;

-- Step 1: 결과가 0행인지 확인합니다.
SELECT title, COUNT(*) AS duplicate_count
FROM experiments
GROUP BY title
HAVING COUNT(*) > 1;

-- Step 2: 중복 제목이 없다면 아래 명령을 실행합니다.
-- 주의: 한 번 적용한 뒤 다시 실행하면 이미 인덱스가 있다는 오류가 납니다.
ALTER TABLE experiments
    ADD CONSTRAINT uq_experiments_title UNIQUE (title);

-- Step 3: 제약조건 확인
SHOW INDEX FROM experiments WHERE Key_name = 'uq_experiments_title';
