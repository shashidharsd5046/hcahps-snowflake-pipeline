-- =============================================
-- HCAHPS Snowflake Pipeline - Monitoring & Analytics
-- Monitoring queries + sample analytics
-- =============================================

USE WAREHOUSE HCAHPS_WH;
USE DATABASE HCAHPS_DW;

-- =============================================
-- PIPELINE MONITORING
-- =============================================

-- Check Dynamic Table refresh history
SELECT
    NAME,
    SCHEMA_NAME,
    REFRESH_ACTION,
    REFRESH_TRIGGER,
    STATE,
    STATE_MESSAGE,
    REFRESH_START_TIME,
    REFRESH_END_TIME,
    DATEDIFF('second', REFRESH_START_TIME, REFRESH_END_TIME) AS duration_seconds
FROM TABLE(INFORMATION_SCHEMA.DYNAMIC_TABLE_REFRESH_HISTORY())
ORDER BY REFRESH_START_TIME DESC
LIMIT 20;

-- Check Dynamic Table lag status
SELECT
    NAME,
    SCHEMA_NAME,
    TARGET_LAG,
    SCHEDULING_STATE,
    DATA_TIMESTAMP,
    DATEDIFF('minute', DATA_TIMESTAMP, CURRENT_TIMESTAMP()) AS lag_minutes
FROM TABLE(INFORMATION_SCHEMA.DYNAMIC_TABLES())
ORDER BY NAME;

-- =============================================
-- SAMPLE ANALYTICS QUERIES
-- =============================================

-- Top 10 five-star hospitals
SELECT
    facility_name, city, state, region,
    overall_star_rating,
    nurse_comm_always_pct,
    doctor_comm_always_pct,
    recommend_definitely_pct,
    completed_surveys
FROM HCAHPS_DW.ANALYTICS.DT_HOSPITAL_SCORECARD
WHERE overall_star_rating = 5
ORDER BY recommend_definitely_pct DESC NULLS LAST
LIMIT 10;

-- Average scores by region
SELECT
    region,
    COUNT(*) AS hospital_count,
    ROUND(AVG(overall_star_rating), 2) AS avg_star_rating,
    ROUND(AVG(nurse_comm_always_pct), 1) AS avg_nurse_pct,
    ROUND(AVG(doctor_comm_always_pct), 1) AS avg_doctor_pct,
    ROUND(AVG(cleanliness_always_pct), 1) AS avg_clean_pct,
    ROUND(AVG(recommend_definitely_pct), 1) AS avg_recommend_pct
FROM HCAHPS_DW.ANALYTICS.DT_HOSPITAL_SCORECARD
WHERE overall_star_rating IS NOT NULL
GROUP BY region
ORDER BY avg_star_rating DESC;

-- Star rating distribution
SELECT
    overall_star_rating,
    COUNT(*) AS hospital_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) AS pct
FROM HCAHPS_DW.ANALYTICS.DT_HOSPITAL_SCORECARD
WHERE overall_star_rating IS NOT NULL
GROUP BY overall_star_rating
ORDER BY overall_star_rating;

-- State rankings
SELECT
    state,
    state_name,
    region,
    COUNT(*) AS hospitals,
    ROUND(AVG(overall_star_rating), 2) AS avg_stars,
    ROUND(AVG(recommend_definitely_pct), 1) AS avg_recommend_pct
FROM HCAHPS_DW.ANALYTICS.DT_HOSPITAL_SCORECARD
WHERE overall_star_rating IS NOT NULL
GROUP BY state, state_name, region
ORDER BY avg_stars DESC;
