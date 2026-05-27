-- test_star_rating_range.sql
-- Custom test: Verify star ratings are between 1 and 5
-- This test PASSES if zero rows are returned (no violations)

select
    facility_id,
    overall_star_rating
from {{ ref('fact_survey_results') }}
where overall_star_rating is not null
  and (overall_star_rating < 1 or overall_star_rating > 5)
