-- test_answer_percent_range.sql
-- Custom test: Verify answer percentages are between 0 and 100
-- This test PASSES if zero rows are returned (no violations)

select
    facility_id,
    nurse_comm_always_pct,
    doctor_comm_always_pct,
    cleanliness_always_pct
from {{ ref('fact_survey_results') }}
where (nurse_comm_always_pct is not null and (nurse_comm_always_pct < 0 or nurse_comm_always_pct > 100))
   or (doctor_comm_always_pct is not null and (doctor_comm_always_pct < 0 or doctor_comm_always_pct > 100))
   or (cleanliness_always_pct is not null and (cleanliness_always_pct < 0 or cleanliness_always_pct > 100))
