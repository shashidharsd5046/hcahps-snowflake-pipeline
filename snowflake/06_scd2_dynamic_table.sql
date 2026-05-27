-- =============================================
-- BONUS: SCD Type 2 using Dynamic Tables
-- Tracks full history of hospital changes using
-- LEAD() window function — no Streams/Tasks/MERGE needed
-- =============================================

USE WAREHOUSE HCAHPS_WH;
USE DATABASE HCAHPS_DW;

-- SCD2 version of hospital dimension
-- Keeps every version of each hospital with valid_from/valid_to dates

CREATE OR REPLACE DYNAMIC TABLE HCAHPS_DW.ANALYTICS.DT_DIM_HOSPITAL_SCD2
    TARGET_LAG = '5 minutes'
    WAREHOUSE = HCAHPS_WH
AS
WITH all_versions AS (
    SELECT DISTINCT
        facility_id,
        facility_name,
        address,
        city,
        state,
        zip_code,
        county_parish,
        telephone_number,
        MIN(_loaded_at) AS first_seen_at
    FROM HCAHPS_DW.RAW.RAW_HCAHPS
    GROUP BY facility_id, facility_name, address, city, state,
             zip_code, county_parish, telephone_number
)

SELECT
    MD5(facility_id || '|' || TO_CHAR(first_seen_at)) AS hospital_version_key,
    facility_id,
    facility_name,
    address,
    city,
    state,
    zip_code,
    county_parish,
    telephone_number,
    first_seen_at AS valid_from,
    COALESCE(
        LEAD(first_seen_at) OVER (
            PARTITION BY facility_id
            ORDER BY first_seen_at
        ),
        '9999-12-31'::TIMESTAMP_NTZ
    ) AS valid_to,
    CASE
        WHEN LEAD(first_seen_at) OVER (
            PARTITION BY facility_id
            ORDER BY first_seen_at
        ) IS NULL THEN TRUE
        ELSE FALSE
    END AS is_current
FROM all_versions;
