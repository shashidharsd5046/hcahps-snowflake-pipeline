-- test_hospital_count.sql
-- Custom test: Verify we have the expected number of hospitals (~4,792)
-- This test PASSES if zero rows are returned (no violations)

with hospital_count as (
    select count(*) as cnt
    from {{ ref('fact_survey_results') }}
)
select cnt
from hospital_count
where cnt < 4000
