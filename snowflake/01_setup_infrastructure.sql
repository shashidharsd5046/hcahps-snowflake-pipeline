-- =============================================
-- HCAHPS Snowflake Pipeline - Infrastructure Setup
-- Script 1 of 4: Database, Schemas, Warehouse, Stage, Raw Table
-- =============================================

USE ROLE ACCOUNTADMIN;

-- Warehouse (XS = cheapest, auto-suspend after 1 min idle)
CREATE WAREHOUSE IF NOT EXISTS HCAHPS_WH
    WAREHOUSE_SIZE = 'X-SMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE;

-- Database
CREATE DATABASE IF NOT EXISTS HCAHPS_DW;

-- Schemas (Bronze -> Silver -> Gold)
CREATE SCHEMA IF NOT EXISTS HCAHPS_DW.RAW;         -- Bronze: raw CSV as-is
CREATE SCHEMA IF NOT EXISTS HCAHPS_DW.STAGING;      -- Silver: cleaned & normalized
CREATE SCHEMA IF NOT EXISTS HCAHPS_DW.ANALYTICS;    -- Gold: star schema for reporting

USE WAREHOUSE HCAHPS_WH;
USE DATABASE HCAHPS_DW;

-- =============================================
-- FILE FORMAT — tells Snowflake how to read the CSV
-- =============================================

CREATE OR REPLACE FILE FORMAT HCAHPS_DW.RAW.CSV_FORMAT
    TYPE = 'CSV'
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    SKIP_HEADER = 1
    NULL_IF = ('Not Available', 'Not Applicable', '')
    EMPTY_FIELD_AS_NULL = TRUE
    ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE;

-- =============================================
-- INTERNAL STAGE — the folder where you upload CSVs
-- =============================================

CREATE OR REPLACE STAGE HCAHPS_DW.RAW.HCAHPS_STAGE
    FILE_FORMAT = HCAHPS_DW.RAW.CSV_FORMAT;

-- =============================================
-- RAW LANDING TABLE (regular table — not dynamic)
-- This is the only table you manually load into.
-- =============================================

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

-- =============================================
-- SNOWPIPE — automatically ingests data from stage into raw table
-- =============================================

CREATE OR REPLACE PIPE HCAHPS_DW.RAW.HCAHPS_PIPE
    AUTO_INGEST = FALSE  -- False because it's an internal stage
AS
COPY INTO HCAHPS_DW.RAW.RAW_HCAHPS
FROM @HCAHPS_DW.RAW.HCAHPS_STAGE
FILE_FORMAT = (FORMAT_NAME = HCAHPS_DW.RAW.CSV_FORMAT);

-- =============================================
-- STATE-REGION LOOKUP TABLE
-- =============================================

CREATE OR REPLACE TABLE HCAHPS_DW.STAGING.STATE_REGIONS (
    state       VARCHAR(5),
    state_name  VARCHAR(50),
    region      VARCHAR(30)
);

INSERT INTO HCAHPS_DW.STAGING.STATE_REGIONS VALUES
('AL','Alabama','Southeast'),('AK','Alaska','West'),('AZ','Arizona','West'),
('AR','Arkansas','Southeast'),('CA','California','West'),('CO','Colorado','West'),
('CT','Connecticut','Northeast'),('DE','Delaware','Northeast'),('DC','District of Columbia','Northeast'),
('FL','Florida','Southeast'),('GA','Georgia','Southeast'),('HI','Hawaii','West'),
('ID','Idaho','West'),('IL','Illinois','Midwest'),('IN','Indiana','Midwest'),
('IA','Iowa','Midwest'),('KS','Kansas','Midwest'),('KY','Kentucky','Southeast'),
('LA','Louisiana','Southeast'),('ME','Maine','Northeast'),('MD','Maryland','Northeast'),
('MA','Massachusetts','Northeast'),('MI','Michigan','Midwest'),('MN','Minnesota','Midwest'),
('MS','Mississippi','Southeast'),('MO','Missouri','Midwest'),('MT','Montana','West'),
('NE','Nebraska','Midwest'),('NV','Nevada','West'),('NH','New Hampshire','Northeast'),
('NJ','New Jersey','Northeast'),('NM','New Mexico','West'),('NY','New York','Northeast'),
('NC','North Carolina','Southeast'),('ND','North Dakota','Midwest'),('OH','Ohio','Midwest'),
('OK','Oklahoma','Southeast'),('OR','Oregon','West'),('PA','Pennsylvania','Northeast'),
('RI','Rhode Island','Northeast'),('SC','South Carolina','Southeast'),('SD','South Dakota','Midwest'),
('TN','Tennessee','Southeast'),('TX','Texas','Southeast'),('UT','Utah','West'),
('VT','Vermont','Northeast'),('VA','Virginia','Southeast'),('WA','Washington','West'),
('WV','West Virginia','Southeast'),('WI','Wisconsin','Midwest'),('WY','Wyoming','West'),
('GU','Guam','Territory'),('PR','Puerto Rico','Territory'),('VI','Virgin Islands','Territory'),
('AS','American Samoa','Territory'),('MP','Northern Mariana Islands','Territory');
