-- 1.1 overall_dataset_summary
WITH valid_events AS (
    SELECT
        id_request,
        moderator,
        team,
        request_time,
        start_time,
        finish_time
    FROM task_skellar_second
    WHERE id_request IS NOT NULL
      AND moderator IS NOT NULL
      AND team IS NOT NULL
      AND request_time IS NOT NULL
      AND start_time IS NOT NULL
      AND finish_time IS NOT NULL
      AND request_time <= start_time
      AND start_time <= finish_time
),
moderator_activity_raw AS (
    SELECT
        moderator,
        COUNT(DISTINCT id_request) AS total_requests,
        COUNT(DISTINCT DATE(request_time)) AS total_active_days
    FROM valid_events
    GROUP BY moderator
),
trainee_moderators_list AS (
    SELECT moderator AS trainee_moderator_id
    FROM moderator_activity_raw
    WHERE total_requests < 100 OR total_active_days < 7
),
events_with_trainee_flag AS (
    SELECT
        ve.*,
        CASE WHEN tml.trainee_moderator_id IS NOT NULL THEN 1 ELSE 0 END AS is_trainee_moderator
    FROM valid_events ve
    LEFT JOIN trainee_moderators_list tml ON ve.moderator = tml.trainee_moderator_id
)
SELECT
    COUNT(DISTINCT id_request) AS total_valid_requests,
    MIN(request_time)          AS data_start_time,
    MAX(finish_time)           AS data_end_time,
    COUNT(DISTINCT moderator)  AS unique_moderators
FROM events_with_trainee_flag;

---

-- 1.1.2 moderators_basic_scan
WITH valid_events AS (
    SELECT
        id_request,
        moderator,
        team,
        request_time,
        start_time,
        finish_time
    FROM task_skellar_second
    WHERE id_request IS NOT NULL
      AND moderator IS NOT NULL
      AND team IS NOT NULL
      AND request_time IS NOT NULL
      AND start_time IS NOT NULL
      AND finish_time IS NOT NULL
      AND request_time <= start_time
      AND start_time <= finish_time
),
moderator_activity_raw AS (
    SELECT
        moderator,
        COUNT(DISTINCT id_request) AS total_requests,
        COUNT(DISTINCT DATE(request_time)) AS total_active_days
    FROM valid_events
    GROUP BY moderator
),
trainee_moderators_list AS (
    SELECT moderator AS trainee_moderator_id
    FROM moderator_activity_raw
    WHERE total_requests < 100 OR total_active_days < 7
),
events_with_trainee_flag AS (
    SELECT
        ve.*,
        CASE WHEN tml.trainee_moderator_id IS NOT NULL THEN 1 ELSE 0 END AS is_trainee_moderator
    FROM valid_events ve
    LEFT JOIN trainee_moderators_list tml ON ve.moderator = tml.trainee_moderator_id
),
moderator_summary_base AS (
    SELECT
        moderator,
        MIN(team) AS team,
        COUNT(DISTINCT id_request) AS total_requests_handled,
        COUNT(DISTINCT DATE(request_time)) AS total_active_days
    FROM events_with_trainee_flag
    GROUP BY moderator
)
SELECT
    moderator,
    team,
    total_requests_handled,
    total_active_days,
    ROUND(total_requests_handled * 1.0 / NULLIF(total_active_days, 0), 2) AS avg_daily_requests_received,
    CASE
        WHEN total_active_days BETWEEN 0 AND 7  THEN '0-7 days active'
        WHEN total_active_days BETWEEN 8 AND 30 THEN '8-30 days active'
        ELSE '30+ days active'
    END AS active_days_category
FROM moderator_summary_base
ORDER BY total_requests_handled DESC;

---

-- 1.2 requests_by_team_distribution
WITH valid_events AS (
    SELECT *
    FROM task_skellar_second
    WHERE id_request IS NOT NULL
      AND moderator IS NOT NULL
      AND team IS NOT NULL
      AND request_time IS NOT NULL
      AND start_time IS NOT NULL
      AND finish_time IS NOT NULL
      AND request_time <= start_time
      AND start_time <= finish_time
),
moderator_activity_raw AS (
    SELECT moderator,
           COUNT(DISTINCT id_request) AS total_requests,
           COUNT(DISTINCT DATE(request_time)) AS total_active_days
    FROM valid_events
    GROUP BY moderator
),
trainee_moderators_list AS (
    SELECT moderator
    FROM moderator_activity_raw
    WHERE total_requests < 100 OR total_active_days < 7
),
events_with_trainee_flag AS (
    SELECT ve.*,
           CASE WHEN tml.moderator IS NOT NULL THEN 1 ELSE 0 END AS is_trainee_moderator
    FROM valid_events ve
    LEFT JOIN trainee_moderators_list tml ON ve.moderator = tml.moderator
)
SELECT
    team,
    COUNT(DISTINCT id_request) AS requests_count,
    ROUND(100.0 * COUNT(DISTINCT id_request) /
          (SELECT COUNT(DISTINCT id_request) FROM events_with_trainee_flag), 2) AS percentage
FROM events_with_trainee_flag
GROUP BY team
ORDER BY requests_count DESC;

---

-- 1.3 team_average_time_metrics
WITH valid_events AS (
    SELECT *
    FROM task_skellar_second
    WHERE id_request IS NOT NULL
      AND moderator IS NOT NULL
      AND team IS NOT NULL
      AND request_time IS NOT NULL
      AND start_time IS NOT NULL
      AND finish_time IS NOT NULL
      AND request_time <= start_time
      AND start_time <= finish_time
),
moderator_activity_raw AS (
    SELECT moderator,
           COUNT(DISTINCT id_request) AS total_requests,
           COUNT(DISTINCT DATE(request_time)) AS total_active_days
    FROM valid_events
    GROUP BY moderator
),
trainee_moderators_list AS (
    SELECT moderator
    FROM moderator_activity_raw
    WHERE total_requests < 100 OR total_active_days < 7
),
events_with_trainee_flag AS (
    SELECT ve.*,
           CASE WHEN tml.moderator IS NOT NULL THEN 1 ELSE 0 END AS is_trainee_moderator
    FROM valid_events ve
    LEFT JOIN trainee_moderators_list tml ON ve.moderator = tml.moderator
)
SELECT
    team,
    -- Calculates the difference between when the request arrived and when processing started
    ROUND(AVG(TIMESTAMPDIFF(MINUTE, request_time, start_time)), 2)   AS avg_wait_time_minutes,
    -- Calculates the difference between when processing started and when it finished
    ROUND(AVG(TIMESTAMPDIFF(MINUTE, start_time, finish_time)), 2)    AS avg_handling_time_minutes
FROM events_with_trainee_flag
GROUP BY team
ORDER BY team;

---

-- 1.4 hourly_request_volume_by_team
-- NOTE: The original query 1.4 was not provided, but based on the overall structure and the following queries (1.5, 1.6), 
-- this query is designed to calculate request volume by the hour the request was made (`request_time`).
WITH valid_events AS (
    SELECT *
    FROM task_skellar_second
    WHERE id_request IS NOT NULL
      AND moderator IS NOT NULL
      AND team IS NOT NULL
      AND request_time IS NOT NULL
      AND start_time IS NOT NULL
      AND finish_time IS NOT NULL
      AND request_time <= start_time
      AND start_time <= finish_time
),
moderator_activity_raw AS (
    SELECT moderator,
           COUNT(DISTINCT id_request) AS total_requests,
           COUNT(DISTINCT DATE(request_time)) AS total_active_days
    FROM valid_events
    GROUP BY moderator
),
trainee_moderators_list AS (
    SELECT moderator
    FROM moderator_activity_raw
    WHERE total_requests < 100 OR total_active_days < 7
),
events_with_trainee_flag AS (
    SELECT ve.*,
           CASE WHEN tml.moderator IS NOT NULL THEN 1 ELSE 0 END AS is_trainee_moderator
    FROM valid_events ve
    LEFT JOIN trainee_moderators_list tml ON ve.moderator = tml.moderator
)
SELECT
    team,
    HOUR(request_time) AS hour_of_day,
    COUNT(DISTINCT id_request) AS request_volume_in_hour
FROM events_with_trainee_flag
GROUP BY team, hour_of_day
ORDER BY team, hour_of_day;

---

-- 1.5 hourly_agent_activity_by_team
-- NOTE: This query calculates moderator activity based on the hour the moderator *started* processing the request (`start_time`).
WITH valid_events AS (
    SELECT *
    FROM task_skellar_second
    WHERE id_request IS NOT NULL
      AND moderator IS NOT NULL
      AND team IS NOT NULL
      AND request_time IS NOT NULL
      AND start_time IS NOT NULL
      AND finish_time IS NOT NULL
      AND request_time <= start_time
      AND start_time <= finish_time
),
moderator_activity_raw AS (
    SELECT moderator,
           COUNT(DISTINCT id_request) AS total_requests,
           COUNT(DISTINCT DATE(request_time)) AS total_active_days
    FROM valid_events
    GROUP BY moderator
),
trainee_moderators_list AS (
    SELECT moderator
    FROM moderator_activity_raw
    WHERE total_requests < 100 OR total_active_days < 7
),
events_with_trainee_flag AS (
    SELECT ve.*,
           CASE WHEN tml.moderator IS NOT NULL THEN 1 ELSE 0 END AS is_trainee_moderator
    FROM valid_events ve
    LEFT JOIN trainee_moderators_list tml ON ve.moderator = tml.moderator
)
SELECT
    team,
    HOUR(start_time) AS hour_of_day,
    CASE
        WHEN HOUR(start_time) BETWEEN 2 AND 9  THEN 'Night Shift (02:00-09:59)'
        WHEN HOUR(start_time) BETWEEN 10 AND 17 THEN 'Day Shift (10:00-17:59)'
        ELSE 'Evening Shift (18:00-01:59)'
    END AS shift_category,
    COUNT(DISTINCT id_request) AS activity_in_hour
FROM events_with_trainee_flag
GROUP BY team, hour_of_day
ORDER BY team, hour_of_day;

---

-- 1.6 request_volume_by_shift_and_team
-- NOTE: This calculates request volume based on when the request was *made* (`request_time`).
WITH valid_events AS (
    SELECT *
    FROM task_skellar_second
    WHERE id_request IS NOT NULL
      AND moderator IS NOT NULL
      AND team IS NOT NULL
      AND request_time IS NOT NULL
      AND start_time IS NOT NULL
      AND finish_time IS NOT NULL
      AND request_time <= start_time
      AND start_time <= finish_time
),
moderator_activity_raw AS (
    SELECT moderator,
           COUNT(DISTINCT id_request) AS total_requests,
           COUNT(DISTINCT DATE(request_time)) AS total_active_days
    FROM valid_events
    GROUP BY moderator
),
trainee_moderators_list AS (
    SELECT moderator
    FROM moderator_activity_raw
    WHERE total_requests < 100 OR total_active_days < 7
),
events_with_trainee_flag AS (
    SELECT ve.*,
           CASE WHEN tml.moderator IS NOT NULL THEN 1 ELSE 0 END AS is_trainee_moderator
    FROM valid_events ve
    LEFT JOIN trainee_moderators_list tml ON ve.moderator = tml.moderator
),
shifted AS (
    SELECT *,
           CASE
               WHEN HOUR(request_time) BETWEEN 2 AND 9  THEN 'Night Shift (02:00-09:59)'
               WHEN HOUR(request_time) BETWEEN 10 AND 17 THEN 'Day Shift (10:00-17:59)'
               ELSE 'Evening Shift (18:00-01:59)'
           END AS shift_category
    FROM events_with_trainee_flag
)
SELECT
    team,
    shift_category,
    COUNT(*) AS requests_in_shift,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY team), 2) AS percentage
FROM shifted
GROUP BY team, shift_category
ORDER BY team,
         CASE shift_category
             WHEN 'Night Shift (02:00-09:59)' THEN 1
             WHEN 'Day Shift (10:00-17:59)' THEN 2
             ELSE 3
         END;

---

-- 1.7 agent_activity_by_shift_and_team
-- NOTE: This calculates moderator activity based on when the request was *started* (`start_time`).
WITH valid_events AS (
    SELECT *
    FROM task_skellar_second
    WHERE id_request IS NOT NULL
      AND moderator IS NOT NULL
      AND team IS NOT NULL
      AND request_time IS NOT NULL
      AND start_time IS NOT NULL
      AND finish_time IS NOT NULL
      AND request_time <= start_time
      AND start_time <= finish_time
),
moderator_activity_raw AS (
    SELECT moderator,
           COUNT(DISTINCT id_request) AS total_requests,
           COUNT(DISTINCT DATE(request_time)) AS total_active_days
    FROM valid_events
    GROUP BY moderator
),
trainee_moderators_list AS (
    SELECT moderator
    FROM moderator_activity_raw
    WHERE total_requests < 100 OR total_active_days < 7
),
events_with_trainee_flag AS (
    SELECT ve.*,
           CASE WHEN tml.moderator IS NOT NULL THEN 1 ELSE 0 END AS is_trainee_moderator
    FROM valid_events ve
    LEFT JOIN trainee_moderators_list tml ON ve.moderator = tml.moderator
),
shifted AS (
    SELECT *,
           CASE
               WHEN HOUR(start_time) BETWEEN 2 AND 9  THEN 'Night Shift (02:00-09:59)'
               WHEN HOUR(start_time) BETWEEN 10 AND 17 THEN 'Day Shift (10:00-17:59)'
               ELSE 'Evening Shift (18:00-01:59)'
           END AS shift_category
    FROM events_with_trainee_flag
)
SELECT
    team,
    shift_category,
    COUNT(*) AS activity_in_shift,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY team), 2) AS percentage
FROM shifted
GROUP BY team, shift_category
ORDER BY team,
         CASE shift_category
             WHEN 'Night Shift (02:00-09:59)' THEN 1
             WHEN 'Day Shift (10:00-17:59)' THEN 2
             ELSE 3
         END;