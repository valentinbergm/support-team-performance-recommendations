-- Step 0: Data Cleaning & Initial Scan

-- 0.1 Describe the source table (Check current table structure and data types)
DESCRIBE task_skellar_second;

-- 0.2 Fix data types
-- Convert time columns to proper DATETIME and team to VARCHAR(50)
ALTER TABLE task_skellar_second
    MODIFY COLUMN request_time DATETIME,
    MODIFY COLUMN start_time   DATETIME,
    MODIFY COLUMN finish_time  DATETIME,
    MODIFY COLUMN team VARCHAR(50);

-- Verify changes (Optional: for verification after ALTER)
DESCRIBE task_skellar_second;

-- 0.3 Detect and remove extra spaces in team
-- Check for spaces
SELECT DISTINCT team,
       LENGTH(team)          AS original_len,
       LENGTH(TRIM(team))    AS trimmed_len
FROM task_skellar_second
WHERE team IS NOT NULL AND team != TRIM(team);

-- Clean (Run this UPDATE only if the check above shows issues)
UPDATE task_skellar_second
SET team = TRIM(team)
WHERE team IS NOT NULL;

-- 0.4 Count NULLs in critical columns
SELECT 'NULLs in moderator'    AS field, COUNT(*) AS count_issues FROM task_skellar_second WHERE moderator IS NULL
UNION ALL
SELECT 'NULLs in id_request'   AS field, COUNT(*) FROM task_skellar_second WHERE id_request IS NULL
UNION ALL
SELECT 'NULLs in team'         AS field, COUNT(*) FROM task_skellar_second WHERE team IS NULL
UNION ALL
SELECT 'NULLs in request_time' AS field, COUNT(*) FROM task_skellar_second WHERE request_time IS NULL
UNION ALL
SELECT 'NULLs in start_time'   AS field, COUNT(*) FROM task_skellar_second WHERE start_time IS NULL
UNION ALL
SELECT 'NULLs in finish_time'  AS field, COUNT(*) FROM task_skellar_second WHERE finish_time IS NULL;

-- 0.5 Time logic validation
SELECT 'request_time > start_time' AS issue, COUNT(*) AS count_issues FROM task_skellar_second WHERE request_time > start_time
UNION ALL
SELECT 'start_time > finish_time'  AS issue, COUNT(*) FROM task_skellar_second WHERE start_time > finish_time;

-- 0.6 Check for duplicate id_request (Counts the number of *extra* rows for duplicated IDs)
SELECT
    'Duplicate id_request' AS issue,
    COUNT(*) - COUNT(DISTINCT id_request) AS count_issues
FROM task_skellar_second;

-- 0.7 Final count of clean, unique records
-- NOTE: This final query uses the full cleaning logic (NULL checks and time validation) 
-- that will be used for subsequent analysis.
WITH valid_events AS (
    SELECT
        id_request,
        moderator,
        team,
        request_time,
        start_time,
        finish_time
    FROM task_skellar_second
    WHERE id_request   IS NOT NULL
      AND moderator    IS NOT NULL
      AND team         IS NOT NULL -- Fixed typo: team was accidentally repeated here
      AND request_time IS NOT NULL
      AND start_time   IS NOT NULL
      AND finish_time  IS NOT NULL
      AND request_time <= start_time -- Request must arrive before or at start time
      AND start_time   <= finish_time -- Start time must be before or at finish time
)
SELECT
    'Total valid and unique records after full cleaning' AS description,
    COUNT(DISTINCT id_request) AS valid_unique_records
FROM valid_events;
