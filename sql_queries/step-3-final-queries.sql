-- 3.1.1-daily-team-performance-summary
SELECT
    request_date AS report_date,
    team,
    COUNT(*) AS total_requests_daily,

    ROUND(AVG(wait_time_minutes), 2) AS avg_wait_time_minutes_daily,
    ROUND(STDDEV_SAMP(wait_time_minutes), 2) AS stddev_wait_time_minutes_daily,

    ROUND(100.0 * SUM(CASE WHEN wait_time_category = 'on_time'     THEN 1 ELSE 0 END) / COUNT(*), 2) AS percent_wait_on_time_daily,
    ROUND(100.0 * SUM(CASE WHEN wait_time_category = 'acceptable'  THEN 1 ELSE 0 END) / COUNT(*), 2) AS percent_wait_acceptable_daily,
    ROUND(100.0 * SUM(CASE WHEN wait_time_category = 'delayed'     THEN 1 ELSE 0 END) / COUNT(*), 2) AS percent_wait_delayed_daily,
    ROUND(100.0 * SUM(CASE WHEN wait_time_category = 'missed'      THEN 1 ELSE 0 END) / COUNT(*), 2) AS percent_wait_missed_daily,

    ROUND(AVG(handling_time_minutes), 2) AS avg_handling_time_minutes_daily,
    ROUND(STDDEV_SAMP(handling_time_minutes), 2) AS stddev_handling_time_minutes_daily,

    ROUND(100.0 * SUM(CASE WHEN handling_time_category = 'efficient'   THEN 1 ELSE 0 END) / COUNT(*), 2) AS percent_handling_efficient_daily,
    ROUND(100.0 * SUM(CASE WHEN handling_time_category = 'acceptable'  THEN 1 ELSE 0 END) / COUNT(*), 2) AS percent_handling_acceptable_daily,
    ROUND(100.0 * SUM(CASE WHEN handling_time_category = 'long'        THEN 1 ELSE 0 END) / COUNT(*), 2) AS percent_handling_long_daily,
    ROUND(100.0 * SUM(CASE WHEN handling_time_category = 'very_long'   THEN 1 ELSE 0 END) / COUNT(*), 2) AS percent_handling_very_long_daily
FROM events_enriched_experienced
GROUP BY request_date, team
ORDER BY request_date DESC, team;


-- 3.2.1-agent-performance-ranking-no-0-7-days
WITH agent_stats AS (
    SELECT
        moderator,
        team,
        COUNT(*) AS total_requests_handled,
        ROUND(AVG(handling_time_minutes), 2) AS avg_handling_time_minutes,
        ROUND(STDDEV_SAMP(handling_time_minutes), 2) AS stddev_handling_time_minutes,
        ROUND(100.0 * SUM(CASE WHEN handling_time_category = 'efficient' THEN 1 ELSE 0 END) / COUNT(*), 2) AS percent_handling_efficient,
        ROUND(100.0 * SUM(CASE WHEN handling_time_category = 'very_long' THEN 1 ELSE 0 END) / COUNT(*), 2) AS percent_handling_very_long,
        ROUND(100.0 * SUM(CASE WHEN wait_time_category = 'missed' THEN 1 ELSE 0 END) / COUNT(*), 2) AS percent_wait_missed_for_their_tickets,
        COUNT(DISTINCT request_date) AS total_active_days,
        COUNT(DISTINCT CONCAT(request_date, '-', request_hour)) AS total_active_hours
    FROM events_enriched_experienced
    GROUP BY moderator, team
)
SELECT
    moderator,
    team,
    total_requests_handled,
    avg_handling_time_minutes,
    stddev_handling_time_minutes,
    percent_handling_efficient,
    percent_handling_very_long,
    percent_wait_missed_for_their_tickets,
    RANK() OVER (PARTITION BY team ORDER BY avg_handling_time_minutes ASC) AS handling_time_rank_in_team,
    RANK() OVER (PARTITION BY team ORDER BY percent_wait_missed_for_their_tickets ASC) AS missed_wait_rank_in_team,
    total_active_days,
    total_active_hours
FROM agent_stats
ORDER BY team, handling_time_rank_in_team;


-- 3.2.2-agent-hourly-activity-no-07-days
SELECT
    moderator,
    team,
    start_hour,
    start_shift_category,
    COUNT(*) AS requests_started_in_hour,
    ROUND(AVG(handling_time_minutes), 2) AS avg_handling_time_in_hour
FROM events_enriched_experienced
GROUP BY moderator, team, start_hour, start_shift_category
ORDER BY moderator, start_hour;

-- 3.3.1-fde-calculation-summary
WITH daily_load AS (
    SELECT request_date, team, SUM(handling_time_minutes) AS daily_handling_minutes
    FROM events_enriched_experienced
    GROUP BY request_date, team
),
current_agents AS (
    SELECT team, COUNT(DISTINCT moderator) AS current_unique_active_agents
    FROM operators_overall_summary_experienced
    GROUP BY team
)
SELECT
    dl.team,
    COUNT(DISTINCT dl.request_date) AS data_period_days,
    ROUND(AVG(dl.daily_handling_minutes), 2) AS avg_daily_handling_load_minutes,
    ROUND(AVG(dl.daily_handling_minutes) / 420.0, 2) AS fde_needed_calculated,
    ca.current_unique_active_agents,
    ROUND(AVG(dl.daily_handling_minutes) / 420.0 - ca.current_unique_active_agents, 2) AS fde_difference
FROM daily_load dl
JOIN current_agents ca USING (team)
GROUP BY dl.team, ca.current_unique_active_agents;

-- 3.3.2-daily-load-vs-quality-no-0-7-days
SELECT
    request_date AS report_date,
    team,
    COUNT(*) AS total_requests_daily,
    COUNT(DISTINCT moderator) AS active_moderators_daily,
    ROUND(AVG(wait_time_minutes), 2) AS avg_wait_time_minutes_daily,
    ROUND(100.0 * SUM(CASE WHEN wait_time_category = 'missed' THEN 1 ELSE 0 END) / COUNT(*), 2) AS percent_wait_missed_daily,
    ROUND(100.0 * SUM(CASE WHEN handling_time_category = 'very_long' THEN 1 ELSE 0 END) / COUNT(*), 2) AS percent_handling_very_long_daily
FROM events_enriched_experienced
GROUP BY request_date, team
ORDER BY report_date DESC, team;

-- 3.4.1-hourly-load-and-quality-by-team
WITH hourly_active AS (
    SELECT request_date, team, request_hour, COUNT(DISTINCT moderator) AS active_moderators
    FROM events_enriched_experienced
    GROUP BY request_date, team, request_hour
)
SELECT
    e.team,
    e.request_hour AS hour_of_day,
    e.request_shift_category AS shift_category,
    COUNT(*) AS total_requests_hourly,
    ROUND(AVG(e.wait_time_minutes), 2) AS avg_wait_time_minutes_hourly,
    ROUND(STDDEV_SAMP(e.wait_time_minutes), 2) AS stddev_wait_time_minutes_hourly,
    ROUND(100.0 * SUM(CASE WHEN e.wait_time_category = 'missed' THEN 1 ELSE 0 END) / COUNT(*), 2) AS percent_wait_missed_hourly,
    ROUND(AVG(a.active_moderators), 2) AS active_moderators_hourly
FROM events_enriched_experienced e
LEFT JOIN hourly_active a ON e.request_date = a.request_date
                        AND e.team = a.team
                        AND e.request_hour = a.request_hour
GROUP BY e.team, e.request_hour, e.request_shift_category
ORDER BY e.team, e.request_hour;

-- 3.5.1-team-consolidation-comparison
WITH daily_stats AS (
    SELECT request_date, team,
           SUM(handling_time_minutes) AS daily_minutes,
           COUNT(DISTINCT moderator) AS daily_agents
    FROM events_enriched_experienced
    GROUP BY request_date, team
),
combined_daily AS (
    SELECT request_date, 'Combined' AS team,
           SUM(handling_time_minutes) AS daily_minutes,
           COUNT(DISTINCT moderator) AS daily_agents
    FROM events_enriched_experienced
    GROUP BY request_date
),
all_daily AS (SELECT * FROM daily_stats UNION ALL SELECT * FROM combined_daily),

team_metrics AS (
    SELECT team AS entity,
           COUNT(*) AS total_requests,
           ROUND(AVG(wait_time_minutes), 2) AS avg_wait_time_overall,
           ROUND(STDDEV_SAMP(wait_time_minutes), 2) AS stddev_wait_time_overall,
           ROUND(100.0 * SUM(CASE WHEN wait_time_category = 'missed' THEN 1 ELSE 0 END) / COUNT(*), 2) AS percent_wait_missed_overall,
           ROUND(AVG(handling_time_minutes), 2) AS avg_handling_time_overall
    FROM events_enriched_experienced
    GROUP BY team
),
combined_metrics AS (
    SELECT 'Combined' AS entity,
           COUNT(*) AS total_requests,
           ROUND(AVG(wait_time_minutes), 2) AS avg_wait_time_overall,
           ROUND(STDDEV_SAMP(wait_time_minutes), 2) AS stddev_wait_time_overall,
           ROUND(100.0 * SUM(CASE WHEN wait_time_category = 'missed' THEN 1 ELSE 0 END) / COUNT(*), 2) AS percent_wait_missed_overall,
           ROUND(AVG(handling_time_minutes), 2) AS avg_handling_time_overall
    FROM events_enriched_experienced
)
SELECT
    m.entity,
    m.total_requests,
    m.avg_wait_time_overall,
    m.stddev_wait_time_overall,
    m.percent_wait_missed_overall,
    m.avg_handling_time_overall,
    ROUND(AVG(d.daily_minutes) / 420.0, 2) AS fde_needed_calculated,
    ROUND(AVG(d.daily_agents), 1) AS avg_daily_active_agents
FROM (SELECT * FROM team_metrics UNION ALL SELECT * FROM combined_metrics) m
LEFT JOIN all_daily d ON m.entity = d.team
GROUP BY m.entity, m.total_requests, m.avg_wait_time_overall, m.stddev_wait_time_overall,
         m.percent_wait_missed_overall, m.avg_handling_time_overall
ORDER BY CASE WHEN entity = 'Retail' THEN 1 WHEN entity = 'Wholesale' THEN 2 ELSE 3 END;



