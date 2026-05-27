-- =============================================
-- dbt Project - Snowflake Infrastructure Setup
-- Run this ONCE to prepare Snowflake for Snowpipe and dbt
-- =============================================

USE ROLE ACCOUNTADMIN;

-- 1. Create Warehouse
CREATE WAREHOUSE IF NOT EXISTS HCAHPS_WH
    WAREHOUSE_SIZE = 'X-SMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE;

-- 2. Create Database
CREATE DATABASE IF NOT EXISTS HCAHPS_DW;

-- 3. Create Schemas
CREATE SCHEMA IF NOT EXISTS HCAHPS_DW.RAW;         -- For Snowpipe
CREATE SCHEMA IF NOT EXISTS HCAHPS_DW.STAGING;      -- For dbt views
CREATE SCHEMA IF NOT EXISTS HCAHPS_DW.MARTS;    -- For dbt tables

USE WAREHOUSE HCAHPS_WH;
USE DATABASE HCAHPS_DW;
USE SCHEMA RAW;

-- 4. Create File Format for CSVs
CREATE OR REPLACE FILE FORMAT HCAHPS_DW.RAW.CSV_FORMAT
    TYPE = 'CSV'
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    SKIP_HEADER = 1
    NULL_IF = ('Not Available', 'Not Applicable', '')
    EMPTY_FIELD_AS_NULL = TRUE
    ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE;

-- 5. Create Internal Stage
CREATE OR REPLACE STAGE HCAHPS_DW.RAW.HCAHPS_STAGE
    FILE_FORMAT = HCAHPS_DW.RAW.CSV_FORMAT;

-- 6. Create Raw Landing Table
CREATE OR REPLACE TABLE HCAHPS_DW.RAW.RAW_HCAHPS (
    facility_id             VARCHAR(10),
    facility_name           VARCHAR(200),
    address                 VARCHAR(300),
    city                    VARCHAR(100),
    state                   VARCHAR(5),
    zip_code                VARCHAR(10),
    county_parish           VARCHAR(100),
    telephone_number        VARCHAR(20),
    hcahps_measure_id       VARCHAR(50),
    hcahps_question         VARCHAR(500),
    hcahps_answer_desc      VARCHAR(500),
    star_rating             VARCHAR(20),
    star_rating_footnote    VARCHAR(50),
    answer_percent          VARCHAR(20),
    answer_percent_footnote VARCHAR(50),
    linear_mean_value       VARCHAR(20),
    completed_surveys       VARCHAR(20),
    completed_surveys_fn    VARCHAR(50),
    response_rate_pct       VARCHAR(20),
    response_rate_pct_fn    VARCHAR(50),
    start_date              VARCHAR(20),
    end_date                VARCHAR(20),
    _loaded_at              TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- 7. Create Snowpipe
CREATE OR REPLACE PIPE HCAHPS_DW.RAW.HCAHPS_PIPE
    AUTO_INGEST = FALSE  -- False for internal stages
AS
COPY INTO HCAHPS_DW.RAW.RAW_HCAHPS
FROM @HCAHPS_DW.RAW.HCAHPS_STAGE
FILE_FORMAT = (FORMAT_NAME = HCAHPS_DW.RAW.CSV_FORMAT);
