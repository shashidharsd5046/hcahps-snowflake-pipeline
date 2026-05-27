-- =============================================
-- HCAHPS Snowflake Pipeline - Staging Dynamic Tables
-- Script 2 of 4: Silver Layer (Cleaned & Normalized)
-- These tables auto-refresh when RAW_HCAHPS changes.
-- =============================================

USE WAREHOUSE HCAHPS_WH;
USE DATABASE HCAHPS_DW;

-- =============================================
-- DYNAMIC TABLE: Staging Hospitals (deduplicated)
-- From 325K raw rows -> ~4,792 unique hospitals
-- QUALIFY ROW_NUMBER picks the latest version
-- TARGET_LAG = DOWNSTREAM means: refresh only when
-- a downstream table needs fresh data
-- =============================================

CREATE OR REPLACE DYNAMIC TABLE HCAHPS_DW.STAGING.DT_STG_HOSPITALS
    TARGET_LAG = DOWNSTREAM
    WAREHOUSE = HCAHPS_WH
AS
SELECT
    facility_id,
    facility_name,
    address,
    city,
    state,
    zip_code,
    county_parish,
    telephone_number
FROM HCAHPS_DW.RAW.RAW_HCAHPS
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY facility_id
    ORDER BY _loaded_at DESC
) = 1;


-- =============================================
-- DYNAMIC TABLE: Staging Measures (classified)
-- From 325K raw rows -> 68 unique measures
-- Each gets a domain (Nurse Communication, etc.)
-- and type (PERCENT, LINEAR_SCORE, STAR_RATING)
-- =============================================

CREATE OR REPLACE DYNAMIC TABLE HCAHPS_DW.STAGING.DT_STG_MEASURES
    TARGET_LAG = DOWNSTREAM
    WAREHOUSE = HCAHPS_WH
AS
SELECT DISTINCT
    hcahps_measure_id   AS measure_id,
    hcahps_question     AS question_text,
    hcahps_answer_desc  AS answer_description,
    CASE
        WHEN hcahps_measure_id LIKE 'H_COMP_1%' OR hcahps_measure_id LIKE 'H_NURSE%'
            THEN 'Nurse Communication'
        WHEN hcahps_measure_id LIKE 'H_COMP_2%' OR hcahps_measure_id LIKE 'H_DOCTOR%'
            THEN 'Doctor Communication'
        WHEN hcahps_measure_id LIKE 'H_COMP_5%'
            THEN 'Staff Responsiveness'
        WHEN hcahps_measure_id LIKE 'H_COMP_6%' OR hcahps_measure_id LIKE 'H_MED_FOR%'
             OR hcahps_measure_id LIKE 'H_SIDE_EFFECTS%'
            THEN 'Medicine Communication'
        WHEN hcahps_measure_id LIKE 'H_CLEAN%'     THEN 'Cleanliness'
        WHEN hcahps_measure_id LIKE 'H_QUIET%'     THEN 'Quietness'
        WHEN hcahps_measure_id LIKE 'H_HSP_RATING%' THEN 'Overall Rating'
        WHEN hcahps_measure_id LIKE 'H_RECMND%'    THEN 'Recommendation'
        WHEN hcahps_measure_id LIKE 'H_DISCH%' OR hcahps_measure_id LIKE 'H_SYMPTOMS%'
            THEN 'Discharge Information'
        WHEN hcahps_measure_id = 'H_STAR_RATING'   THEN 'Overall Star Rating'
        ELSE 'Other'
    END AS measure_domain,
    CASE
        WHEN hcahps_measure_id LIKE '%LINEAR_SCORE' THEN 'LINEAR_SCORE'
        WHEN hcahps_measure_id LIKE '%STAR_RATING'  THEN 'STAR_RATING'
        ELSE 'PERCENT'
    END AS measure_type
FROM HCAHPS_DW.RAW.RAW_HCAHPS;


-- =============================================
-- DYNAMIC TABLE: Staging Survey Responses (cleaned)
-- Converts text -> proper data types (INT, DECIMAL, DATE)
-- TRY_CAST returns NULL instead of crashing on bad values
-- QUALIFY keeps only the latest version of each response
-- =============================================

CREATE OR REPLACE DYNAMIC TABLE HCAHPS_DW.STAGING.DT_STG_SURVEY_RESPONSES
    TARGET_LAG = DOWNSTREAM
    WAREHOUSE = HCAHPS_WH
AS
SELECT
    facility_id,
    hcahps_measure_id,
    TRY_CAST(star_rating AS INT)               AS star_rating,
    TRY_CAST(answer_percent AS DECIMAL(5,2))    AS answer_percent,
    TRY_CAST(linear_mean_value AS DECIMAL(5,2)) AS linear_mean_value,
    TRY_CAST(completed_surveys AS INT)          AS completed_surveys,
    TRY_CAST(response_rate_pct AS DECIMAL(5,2)) AS response_rate_pct,
    TRY_TO_DATE(start_date, 'MM/DD/YYYY')  AS survey_start_date,
    TRY_TO_DATE(end_date,   'MM/DD/YYYY')  AS survey_end_date,
    _loaded_at
FROM HCAHPS_DW.RAW.RAW_HCAHPS
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY facility_id, hcahps_measure_id
    ORDER BY _loaded_at DESC
) = 1;
