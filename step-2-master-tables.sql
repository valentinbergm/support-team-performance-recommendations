CREATE TABLE events_enriched_experienced AS
WITH valid_events AS (
    SELECT id_request, moderator, team, request_time, start_time, finish_time
    FROM task_skellar_second
    WHERE id_request   IS NOT NULL AND moderator   IS NOT NULL AND team IS NOT NULL
      AND request_time IS NOT NULL AND start_time   IS NOT NULL AND finish_time IS NOT NULL
      AND request_time <= start_time AND start_time <= finish_time
),
moderator_activity_raw AS (
    SELECT moderator,
           COUNT(DISTINCT id_request)          AS total_requests,
           COUNT(DISTINCT DATE(request_time))  AS total_active_days
    FROM valid_events
    GROUP BY moderator
),
new_moderators_list AS (
    SELECT moderator
    FROM moderator_activity_raw
    WHERE total_requests < 100 OR total_active_days < 7
),
events_with_new_moderator_flag AS (
    SELECT ve.*,
           CASE WHEN nml.moderator IS NOT NULL THEN 1 ELSE 0 END AS is_new_moderator
    FROM valid_events ve
    LEFT JOIN new_moderators_list nml ON ve.moderator = nml.moderator
)
SELECT
    id_request,
    moderator,
    team,
    request_time,
    start_time,
    finish_time,
    DATE(request_time)                                          AS request_date,
    MONTH(request_time)                                         AS request_month,
    WEEK(request_time, 0)                                       AS request_week,
    DAYOFWEEK(request_time)                                     AS request_day_of_week,
    CASE WHEN DAYOFWEEK(request_time) IN (1,7) THEN 1 ELSE 0 END AS is_weekend,
    HOUR(request_time)                                          AS request_hour,
    CASE
        WHEN HOUR(request_time) BETWEEN 2 AND 9   THEN 'Night Shift (02:00-09:59)'
        WHEN HOUR(request_time) BETWEEN 10 AND 17 THEN 'Day Shift (10:00-17:59)'
        ELSE 'Evening Shift (18:00-01:59)'
    END                                                         AS request_shift_category,
    HOUR(start_time)                                            AS start_hour,
    CASE
        WHEN HOUR(start_time) BETWEEN 2 AND 9     THEN 'Night Shift (02:00-09:59)'
        WHEN HOUR(start_time) BETWEEN 10 AND 17  THEN 'Day Shift (10:00-17:59)'
        ELSE 'Evening Shift (18:00-01

:59)'
    END                                                         AS start_shift_category,
    TIMESTAMPDIFF(MINUTE, request_time, start_time)            AS wait_time_minutes,
    CASE
        WHEN TIMESTAMPDIFF(MINUTE, request_time, start_time) <= 15   THEN 'on_time'
        WHEN TIMESTAMPDIFF(MINUTE, request_time, start_time) <= 45   THEN 'acceptable'
        WHEN TIMESTAMPDIFF(MINUTE, request_time, start_time) <= 120  THEN 'delayed'
        ELSE 'missed'
    END                                                         AS wait_time_category,
    TIMESTAMPDIFF(MINUTE, start_time, finish_time)              AS handling_time_minutes,
    CASE
        WHEN TIMESTAMPDIFF(MINUTE, start_time, finish_time) <= 5    THEN 'efficient'
        WHEN TIMESTAMPDIFF(MINUTE, start_time, finish_time) <= 15   THEN 'acceptable'
        WHEN TIMESTAMPDIFF(MINUTE, start_time, finish_time) <= 30   THEN 'long'
        ELSE 'very_long'
    END                                                         AS handling_time_category,
    is_new_moderator
FROM events_with_new_moderator_flag
WHERE is_new_moderator = 0;

CREATE TABLE events_enriched_new AS
WITH valid_events AS (
    SELECT id_request, moderator, team, request_time, start_time, finish_time
    FROM task_skellar_second
    WHERE id_request   IS NOT NULL AND moderator   IS NOT NULL AND team IS NOT NULL
      AND request_time IS NOT NULL AND start_time   IS NOT NULL AND finish_time IS NOT NULL
      AND request_time <= start_time AND start_time <= finish_time
),
moderator_activity_raw AS (
    SELECT moderator,
           COUNT(DISTINCT id_request)          AS total_requests,
           COUNT(DISTINCT DATE(request_time))  AS total_active_days
    FROM valid_events
    GROUP BY moderator
),
new_moderators_list AS (
    SELECT moderator
    FROM moderator_activity_raw
    WHERE total_requests < 100 OR total_active_days < 7
),
events_with_new_moderator_flag AS (
    SELECT ve.*,
           CASE WHEN nml.moderator IS NOT NULL THEN 1 ELSE 0 END AS is_new_moderator
    FROM valid_events ve
    LEFT JOIN new_moderators_list nml ON ve.moderator = nml.moderator
)
SELECT
    id_request,
    moderator,
    team,
    request_time,
    start_time,
    finish_time,
    DATE(request_time)                                          AS request_date,
    MONTH(request_time)                                         AS request_month,
    WEEK(request_time, 0)                                       AS request_week,
    DAYOFWEEK(request_time)                                     AS request_day_of_week,
    CASE WHEN DAYOFWEEK(request_time) IN (1,7) THEN 1 ELSE 0 END AS is_weekend,
    HOUR(request_time)                                          AS request_hour,
    CASE
        WHEN HOUR(request_time) BETWEEN 2 AND 9   THEN 'Night Shift (02:00-09:59)'
        WHEN HOUR(request_time) BETWEEN 10 AND 17 THEN 'Day Shift (10:00-17:59)'
        ELSE 'Evening Shift (18:00-01:59)'
    END                                                         AS request_shift_category,
    HOUR(start_time)                                            AS start_hour,
    CASE
        WHEN HOUR(start_time) BETWEEN 2 AND 9     THEN 'Night Shift (02:00-09:59)'
        WHEN HOUR(start_time) BETWEEN 10 AND 17  THEN 'Day Shift (10:00-17:59)'
        ELSE 'Evening Shift (18:00-01:59)'
    END                                                         AS start_shift_category,
    TIMESTAMPDIFF(MINUTE, request_time, start_time)            AS wait_time_minutes,
    CASE
        WHEN TIMESTAMPDIFF(MINUTE, request_time, start_time) <= 15   THEN 'on_time'
        WHEN TIMESTAMPDIFF(MINUTE, request_time, start_time) <= 45   THEN 'acceptable'
        WHEN TIMESTAMPDIFF(MINUTE, request_time, start_time) <= 120  THEN 'delayed'
        ELSE 'missed'
    END                                                         AS wait_time_category,
    TIMESTAMPDIFF(MINUTE, start_time, finish_time)              AS handling_time_minutes,
    CASE
        WHEN TIMESTAMPDIFF(MINUTE, start_time, finish_time) <= 5    THEN 'efficient'
        WHEN TIMESTAMPDIFF(MINUTE, start_time, finish_time) <= 15   THEN 'acceptable'
        WHEN TIMESTAMPDIFF(MINUTE, start_time, finish_time) <= 30   THEN 'long'
        ELSE 'very_long'
    END                                                         AS handling_time_category,
    is_new_moderator
FROM events_with_new_moderator_flag
WHERE is_new_moderator = 1;

CREATE TABLE operators_overall_summary_experienced AS
SELECT
    moderator,
    MIN(team) AS team,
    COUNT(*) AS total_requests_handled,
    ROUND(AVG(handling_time_minutes), 2) AS avg_handling_time_minutes,
    SUM(CASE WHEN wait_time_category = 'on_time'    THEN 1 ELSE 0 END) AS count_wait_on_time,
    SUM(CASE WHEN wait_time_category = 'acceptable' THEN 1 ELSE 0 END) AS count_wait_acceptable,
    SUM(CASE WHEN wait_time_category = 'delayed'    THEN 1 ELSE 0 END) AS count_wait_delayed,
    SUM(CASE WHEN wait_time_category = 'missed'     THEN 1 ELSE 0 END) AS count_wait_missed,
    ROUND(100.0 * SUM(CASE WHEN wait_time_category = 'on_time'    THEN 1 ELSE 0 END) / COUNT(*), 2) AS percent_wait_on_time,
    ROUND(100.0 * SUM(CASE WHEN wait_time_category = 'acceptable' THEN 1 ELSE 0 END) / COUNT(*), 2) AS percent_wait_acceptable,
    ROUND(100.0 * SUM(CASE WHEN wait_time_category = 'missed'     THEN 1 ELSE 0 END) / COUNT(*), 2) AS percent_wait_missed,
    SUM(CASE WHEN handling_time_category = 'efficient' THEN 1 ELSE 0 END) AS count_handling_efficient,
    SUM(CASE WHEN handling_time_category = 'very_long' THEN 1 ELSE 0 END) AS count_handling_very_long,
    ROUND(AVG(wait_time_minutes), 2) AS avg_wait_time_for_their_tickets,
    COUNT(DISTINCT request_date) AS total_active_days,
    COUNT(DISTINCT CONCAT(request_date, '-', request_hour)) AS total_active_hours,
    0 AS is_new_moderator
FROM events_enriched_experienced
GROUP BY moderator
ORDER BY total_requests_handled DESC;


CREATE TABLE operators_overall_summary_new AS
SELECT
    moderator,
    MIN(team) AS team,
    COUNT(*) AS total_requests_handled,
    ROUND(AVG(handling_time_minutes), 2) AS avg_handling_time_minutes,
    SUM(CASE WHEN wait_time_category = 'on_time'    THEN 1 ELSE 0 END) AS count_wait_on_time,
    SUM(CASE WHEN wait_time_category = 'acceptable' THEN 1 ELSE 0 END) AS count_wait_acceptable,
    SUM(CASE WHEN wait_time_category = 'delayed'    THEN 1 ELSE 0 END) AS count_wait_delayed,
    SUM(CASE WHEN wait_time_category = 'missed'     THEN 1 ELSE 0 END) AS count_wait_missed,
    ROUND(100.0 * SUM(CASE WHEN wait_time_category = 'on_time'    THEN 1 ELSE 0 END) / COUNT(*), 2) AS percent_wait_on_time,
    ROUND(100.0 * SUM(CASE WHEN wait_time_category = 'acceptable' THEN 1 ELSE 0 END) / COUNT(*), 2) AS percent_wait_acceptable,
    ROUND(100.0 * SUM(CASE WHEN wait_time_category = 'missed'     THEN 1 ELSE 0 END) / COUNT(*), 2) AS percent_wait_missed,
    SUM(CASE WHEN handling_time_category = 'efficient' THEN 1 ELSE 0 END) AS count_handling_efficient,
    SUM(CASE WHEN handling_time_category = 'very_long' THEN 1 ELSE 0 END) AS count_handling_very_long,
    ROUND(AVG(wait_time_minutes), 2) AS avg_wait_time_for_their_tickets,
    COUNT(DISTINCT request_date) AS total_active_days,
    COUNT(DISTINCT CONCAT(request_date, '-', request_hour)) AS total_active_hours,
    1 AS is_new_moderator
FROM events_enriched_new
GROUP BY moderator
ORDER BY total_requests_handled DESC;




