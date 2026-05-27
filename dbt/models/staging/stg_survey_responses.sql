-- stg_survey_responses.sql
-- Silver Layer: Cleaned and type-cast survey responses
-- TRY_CAST returns NULL instead of crashing on bad values
-- QUALIFY keeps only the latest version of each response

with source as (
    select * from {{ source('raw', 'raw_hcahps') }}
),

cleaned as (
    select
        facility_id,
        hcahps_measure_id,

        -- Convert text to numbers safely
        try_cast(star_rating as int)                as star_rating,
        try_cast(answer_percent as decimal(5,2))     as answer_percent,
        try_cast(linear_mean_value as decimal(5,2))  as linear_mean_value,
        try_cast(completed_surveys as int)           as completed_surveys,
        try_cast(response_rate_pct as decimal(5,2))  as response_rate_pct,

        -- Convert text dates to proper DATE type
        try_to_date(start_date, 'MM/DD/YYYY')   as survey_start_date,
        try_to_date(end_date,   'MM/DD/YYYY')   as survey_end_date,

        _loaded_at

    from source
    qualify row_number() over (
        partition by facility_id, hcahps_measure_id
        order by _loaded_at desc
    ) = 1
)

select * from cleaned
