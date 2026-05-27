-- =============================================
-- HCAHPS Snowflake Pipeline - Analytics Dynamic Tables
-- Script 3 of 4: Gold Layer (Star Schema)
-- These tables auto-refresh when staging changes.
-- =============================================

USE WAREHOUSE HCAHPS_WH;
USE DATABASE HCAHPS_DW;

-- =============================================
-- DYNAMIC TABLE: Geography Dimension
-- Joins hospitals with the state-region lookup
-- =============================================

CREATE OR REPLACE DYNAMIC TABLE HCAHPS_DW.ANALYTICS.DT_DIM_GEOGRAPHY
    TARGET_LAG = DOWNSTREAM
    WAREHOUSE = HCAHPS_WH
AS
SELECT
    MD5(h.state || '|' || h.county_parish || '|' || h.zip_code) AS geo_key,
    h.state,
    COALESCE(s.state_name, h.state)  AS state_name,
    COALESCE(s.region, 'Unknown')    AS region,
    h.county_parish,
    h.zip_code
FROM (
    SELECT DISTINCT state, county_parish, zip_code
    FROM HCAHPS_DW.STAGING.DT_STG_HOSPITALS
) h
LEFT JOIN HCAHPS_DW.STAGING.STATE_REGIONS s ON h.state = s.state;


-- =============================================
-- DYNAMIC TABLE: Fact Survey Results (star schema)
-- Joins survey responses with all dimensions
-- Main fact table for analytics queries
-- TARGET_LAG = 5 minutes: auto-refresh within 5 min
-- =============================================

CREATE OR REPLACE DYNAMIC TABLE HCAHPS_DW.ANALYTICS.DT_FACT_SURVEY_RESULTS
    TARGET_LAG = '5 minutes'
    WAREHOUSE = HCAHPS_WH
AS
SELECT
    MD5(sr.facility_id || '|' || sr.hcahps_measure_id || '|' ||
        COALESCE(TO_CHAR(sr.survey_start_date), 'NULL'))    AS survey_result_key,
    MD5(h.facility_id)                                       AS hospital_key,
    MD5(sr.hcahps_measure_id)                                AS measure_key,
    TO_NUMBER(TO_CHAR(sr.survey_start_date, 'YYYYMMDD'))     AS date_key,
    MD5(h.state || '|' || h.county_parish || '|' || h.zip_code) AS geo_key,
    h.facility_id,
    h.facility_name,
    h.state,
    m.measure_id,
    m.measure_domain,
    m.measure_type,
    g.state_name,
    g.region,
    sr.star_rating,
    sr.answer_percent,
    sr.linear_mean_value,
    sr.completed_surveys,
    sr.response_rate_pct,
    sr.survey_start_date,
    sr.survey_end_date
FROM HCAHPS_DW.STAGING.DT_STG_SURVEY_RESPONSES sr
JOIN HCAHPS_DW.STAGING.DT_STG_HOSPITALS h
    ON sr.facility_id = h.facility_id
JOIN HCAHPS_DW.STAGING.DT_STG_MEASURES m
    ON sr.hcahps_measure_id = m.measure_id
LEFT JOIN HCAHPS_DW.ANALYTICS.DT_DIM_GEOGRAPHY g
    ON MD5(h.state || '|' || h.county_parish || '|' || h.zip_code) = g.geo_key;


-- =============================================
-- DYNAMIC TABLE: Hospital Scorecard (pivoted)
-- Pivots from 68 rows per hospital -> 1 row per hospital
-- with all key metrics as columns
-- The final business-ready table
-- =============================================

CREATE OR REPLACE DYNAMIC TABLE HCAHPS_DW.ANALYTICS.DT_HOSPITAL_SCORECARD
    TARGET_LAG = '5 minutes'
    WAREHOUSE = HCAHPS_WH
AS
SELECT
    sr.facility_id,
    h.facility_name,
    h.city,
    h.state,
    g.state_name,
    g.region,
    MAX(CASE WHEN sr.hcahps_measure_id = 'H_STAR_RATING'
        THEN sr.star_rating END)                AS overall_star_rating,
    MAX(CASE WHEN sr.hcahps_measure_id = 'H_COMP_1_A_P'
        THEN sr.answer_percent END)             AS nurse_comm_always_pct,
    MAX(CASE WHEN sr.hcahps_measure_id = 'H_COMP_1_LINEAR_SCORE'
        THEN sr.linear_mean_value END)          AS nurse_comm_linear_score,
    MAX(CASE WHEN sr.hcahps_measure_id = 'H_COMP_1_STAR_RATING'
        THEN sr.star_rating END)                AS nurse_comm_star_rating,
    MAX(CASE WHEN sr.hcahps_measure_id = 'H_COMP_2_A_P'
        THEN sr.answer_percent END)             AS doctor_comm_always_pct,
    MAX(CASE WHEN sr.hcahps_measure_id = 'H_COMP_2_LINEAR_SCORE'
        THEN sr.linear_mean_value END)          AS doctor_comm_linear_score,
    MAX(CASE WHEN sr.hcahps_measure_id = 'H_COMP_2_STAR_RATING'
        THEN sr.star_rating END)                AS doctor_comm_star_rating,
    MAX(CASE WHEN sr.hcahps_measure_id = 'H_COMP_5_A_P'
        THEN sr.answer_percent END)             AS staff_responsive_always_pct,
    MAX(CASE WHEN sr.hcahps_measure_id = 'H_COMP_5_STAR_RATING'
        THEN sr.star_rating END)                AS staff_responsive_star_rating,
    MAX(CASE WHEN sr.hcahps_measure_id = 'H_COMP_6_Y_P'
        THEN sr.answer_percent END)             AS med_comm_yes_pct,
    MAX(CASE WHEN sr.hcahps_measure_id = 'H_COMP_6_STAR_RATING'
        THEN sr.star_rating END)                AS med_comm_star_rating,
    MAX(CASE WHEN sr.hcahps_measure_id = 'H_CLEAN_HSP_A_P'
        THEN sr.answer_percent END)             AS cleanliness_always_pct,
    MAX(CASE WHEN sr.hcahps_measure_id = 'H_CLEAN_STAR_RATING'
        THEN sr.star_rating END)                AS cleanliness_star_rating,
    MAX(CASE WHEN sr.hcahps_measure_id = 'H_QUIET_HSP_A_P'
        THEN sr.answer_percent END)             AS quietness_always_pct,
    MAX(CASE WHEN sr.hcahps_measure_id = 'H_QUIET_STAR_RATING'
        THEN sr.star_rating END)                AS quietness_star_rating,
    MAX(CASE WHEN sr.hcahps_measure_id = 'H_HSP_RATING_9_10'
        THEN sr.answer_percent END)             AS overall_rating_9_10_pct,
    MAX(CASE WHEN sr.hcahps_measure_id = 'H_HSP_RATING_STAR_RATING'
        THEN sr.star_rating END)                AS overall_rating_star,
    MAX(CASE WHEN sr.hcahps_measure_id = 'H_RECMND_DY'
        THEN sr.answer_percent END)             AS recommend_definitely_pct,
    MAX(CASE WHEN sr.hcahps_measure_id = 'H_RECMND_STAR_RATING'
        THEN sr.star_rating END)                AS recommend_star_rating,
    MAX(sr.completed_surveys)                   AS completed_surveys,
    MAX(sr.response_rate_pct)                   AS response_rate_pct,
    MIN(sr.survey_start_date)                   AS survey_start_date,
    MAX(sr.survey_end_date)                     AS survey_end_date
FROM HCAHPS_DW.STAGING.DT_STG_SURVEY_RESPONSES sr
JOIN HCAHPS_DW.STAGING.DT_STG_HOSPITALS h
    ON sr.facility_id = h.facility_id
LEFT JOIN HCAHPS_DW.ANALYTICS.DT_DIM_GEOGRAPHY g
    ON MD5(h.state || '|' || h.county_parish || '|' || h.zip_code) = g.geo_key
GROUP BY
    sr.facility_id, h.facility_name, h.city, h.state,
    g.state_name, g.region;
