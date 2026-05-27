-- fact_survey_results.sql
-- Gold Layer: Wide pivoted fact table (1 row per hospital)
-- Pivots 68 raw measure rows into ~25 clean metric columns per hospital

with responses as (
    select * from {{ ref('stg_survey_responses') }}
),

hospitals as (
    select * from {{ ref('stg_hospitals') }}
),

geography as (
    select * from {{ ref('dim_geography') }}
),

pivoted as (
    select
        md5(sr.facility_id)                                                 as hospital_key,
        to_number(to_char(min(sr.survey_start_date), 'YYYYMMDD'))           as date_key,
        md5(h.state || '|' || h.county_parish || '|' || h.zip_code)        as geo_key,
        sr.facility_id,
        h.facility_name,
        h.city,
        h.state,
        g.state_name,
        g.region,

        -- ── Overall Star Rating ──
        max(case when sr.hcahps_measure_id = 'H_STAR_RATING'
            then sr.star_rating end)                as overall_star_rating,

        -- ── Nurse Communication ──
        max(case when sr.hcahps_measure_id = 'H_COMP_1_A_P'
            then sr.answer_percent end)             as nurse_comm_always_pct,
        max(case when sr.hcahps_measure_id = 'H_COMP_1_U_P'
            then sr.answer_percent end)             as nurse_comm_usually_pct,
        max(case when sr.hcahps_measure_id = 'H_COMP_1_SN_P'
            then sr.answer_percent end)             as nurse_comm_sometimes_never_pct,
        max(case when sr.hcahps_measure_id = 'H_COMP_1_LINEAR_SCORE'
            then sr.linear_mean_value end)          as nurse_comm_linear_score,
        max(case when sr.hcahps_measure_id = 'H_COMP_1_STAR_RATING'
            then sr.star_rating end)                as nurse_comm_star_rating,

        -- ── Nurse Sub-Questions ──
        max(case when sr.hcahps_measure_id = 'H_NURSE_RESPECT_A_P'
            then sr.answer_percent end)             as nurse_respect_always_pct,
        max(case when sr.hcahps_measure_id = 'H_NURSE_RESPECT_U_P'
            then sr.answer_percent end)             as nurse_respect_usually_pct,
        max(case when sr.hcahps_measure_id = 'H_NURSE_RESPECT_SN_P'
            then sr.answer_percent end)             as nurse_respect_sometimes_never_pct,
        max(case when sr.hcahps_measure_id = 'H_NURSE_LISTEN_A_P'
            then sr.answer_percent end)             as nurse_listen_always_pct,
        max(case when sr.hcahps_measure_id = 'H_NURSE_LISTEN_U_P'
            then sr.answer_percent end)             as nurse_listen_usually_pct,
        max(case when sr.hcahps_measure_id = 'H_NURSE_LISTEN_SN_P'
            then sr.answer_percent end)             as nurse_listen_sometimes_never_pct,
        max(case when sr.hcahps_measure_id = 'H_NURSE_EXPLAIN_A_P'
            then sr.answer_percent end)             as nurse_explain_always_pct,
        max(case when sr.hcahps_measure_id = 'H_NURSE_EXPLAIN_U_P'
            then sr.answer_percent end)             as nurse_explain_usually_pct,
        max(case when sr.hcahps_measure_id = 'H_NURSE_EXPLAIN_SN_P'
            then sr.answer_percent end)             as nurse_explain_sometimes_never_pct,

        -- ── Doctor Communication ──
        max(case when sr.hcahps_measure_id = 'H_COMP_2_A_P'
            then sr.answer_percent end)             as doctor_comm_always_pct,
        max(case when sr.hcahps_measure_id = 'H_COMP_2_U_P'
            then sr.answer_percent end)             as doctor_comm_usually_pct,
        max(case when sr.hcahps_measure_id = 'H_COMP_2_SN_P'
            then sr.answer_percent end)             as doctor_comm_sometimes_never_pct,
        max(case when sr.hcahps_measure_id = 'H_COMP_2_LINEAR_SCORE'
            then sr.linear_mean_value end)          as doctor_comm_linear_score,
        max(case when sr.hcahps_measure_id = 'H_COMP_2_STAR_RATING'
            then sr.star_rating end)                as doctor_comm_star_rating,

        -- ── Doctor Sub-Questions ──
        max(case when sr.hcahps_measure_id = 'H_DOCTOR_RESPECT_A_P'
            then sr.answer_percent end)             as doctor_respect_always_pct,
        max(case when sr.hcahps_measure_id = 'H_DOCTOR_RESPECT_U_P'
            then sr.answer_percent end)             as doctor_respect_usually_pct,
        max(case when sr.hcahps_measure_id = 'H_DOCTOR_RESPECT_SN_P'
            then sr.answer_percent end)             as doctor_respect_sometimes_never_pct,
        max(case when sr.hcahps_measure_id = 'H_DOCTOR_LISTEN_A_P'
            then sr.answer_percent end)             as doctor_listen_always_pct,
        max(case when sr.hcahps_measure_id = 'H_DOCTOR_LISTEN_U_P'
            then sr.answer_percent end)             as doctor_listen_usually_pct,
        max(case when sr.hcahps_measure_id = 'H_DOCTOR_LISTEN_SN_P'
            then sr.answer_percent end)             as doctor_listen_sometimes_never_pct,
        max(case when sr.hcahps_measure_id = 'H_DOCTOR_EXPLAIN_A_P'
            then sr.answer_percent end)             as doctor_explain_always_pct,
        max(case when sr.hcahps_measure_id = 'H_DOCTOR_EXPLAIN_U_P'
            then sr.answer_percent end)             as doctor_explain_usually_pct,
        max(case when sr.hcahps_measure_id = 'H_DOCTOR_EXPLAIN_SN_P'
            then sr.answer_percent end)             as doctor_explain_sometimes_never_pct,

        -- ── Staff Responsiveness ──
        max(case when sr.hcahps_measure_id = 'H_COMP_5_A_P'
            then sr.answer_percent end)             as staff_responsive_always_pct,
        max(case when sr.hcahps_measure_id = 'H_COMP_5_U_P'
            then sr.answer_percent end)             as staff_responsive_usually_pct,
        max(case when sr.hcahps_measure_id = 'H_COMP_5_SN_P'
            then sr.answer_percent end)             as staff_responsive_sometimes_never_pct,
        max(case when sr.hcahps_measure_id = 'H_COMP_5_LINEAR_SCORE'
            then sr.linear_mean_value end)          as staff_responsive_linear_score,
        max(case when sr.hcahps_measure_id = 'H_COMP_5_STAR_RATING'
            then sr.star_rating end)                as staff_responsive_star_rating,

        -- ── Medicine Communication ──
        max(case when sr.hcahps_measure_id = 'H_COMP_6_Y_P'
            then sr.answer_percent end)             as med_comm_yes_pct,
        max(case when sr.hcahps_measure_id = 'H_COMP_6_N_P'
            then sr.answer_percent end)             as med_comm_no_pct,
        max(case when sr.hcahps_measure_id = 'H_COMP_6_LINEAR_SCORE'
            then sr.linear_mean_value end)          as med_comm_linear_score,
        max(case when sr.hcahps_measure_id = 'H_COMP_6_STAR_RATING'
            then sr.star_rating end)                as med_comm_star_rating,
        max(case when sr.hcahps_measure_id = 'H_MED_FOR_A_P'
            then sr.answer_percent end)             as med_purpose_always_pct,
        max(case when sr.hcahps_measure_id = 'H_MED_FOR_U_P'
            then sr.answer_percent end)             as med_purpose_usually_pct,
        max(case when sr.hcahps_measure_id = 'H_MED_FOR_SN_P'
            then sr.answer_percent end)             as med_purpose_sometimes_never_pct,
        max(case when sr.hcahps_measure_id = 'H_SIDE_EFFECTS_A_P'
            then sr.answer_percent end)             as side_effects_always_pct,
        max(case when sr.hcahps_measure_id = 'H_SIDE_EFFECTS_U_P'
            then sr.answer_percent end)             as side_effects_usually_pct,
        max(case when sr.hcahps_measure_id = 'H_SIDE_EFFECTS_SN_P'
            then sr.answer_percent end)             as side_effects_sometimes_never_pct,

        -- ── Cleanliness ──
        max(case when sr.hcahps_measure_id = 'H_CLEAN_HSP_A_P'
            then sr.answer_percent end)             as cleanliness_always_pct,
        max(case when sr.hcahps_measure_id = 'H_CLEAN_HSP_U_P'
            then sr.answer_percent end)             as cleanliness_usually_pct,
        max(case when sr.hcahps_measure_id = 'H_CLEAN_HSP_SN_P'
            then sr.answer_percent end)             as cleanliness_sometimes_never_pct,
        max(case when sr.hcahps_measure_id = 'H_CLEAN_LINEAR_SCORE'
            then sr.linear_mean_value end)          as cleanliness_linear_score,
        max(case when sr.hcahps_measure_id = 'H_CLEAN_STAR_RATING'
            then sr.star_rating end)                as cleanliness_star_rating,

        -- ── Quietness ──
        max(case when sr.hcahps_measure_id = 'H_QUIET_HSP_A_P'
            then sr.answer_percent end)             as quietness_always_pct,
        max(case when sr.hcahps_measure_id = 'H_QUIET_HSP_U_P'
            then sr.answer_percent end)             as quietness_usually_pct,
        max(case when sr.hcahps_measure_id = 'H_QUIET_HSP_SN_P'
            then sr.answer_percent end)             as quietness_sometimes_never_pct,
        max(case when sr.hcahps_measure_id = 'H_QUIET_LINEAR_SCORE'
            then sr.linear_mean_value end)          as quietness_linear_score,
        max(case when sr.hcahps_measure_id = 'H_QUIET_STAR_RATING'
            then sr.star_rating end)                as quietness_star_rating,

        -- ── Discharge Information ──
        max(case when sr.hcahps_measure_id = 'H_DISCH_A_P'
            then sr.answer_percent end)             as discharge_agree_pct,
        max(case when sr.hcahps_measure_id = 'H_DISCH_SN_P'
            then sr.answer_percent end)             as discharge_disagree_pct,
        max(case when sr.hcahps_measure_id = 'H_COMP_7_SA'
            then sr.answer_percent end)             as discharge_strongly_agree_pct,
        max(case when sr.hcahps_measure_id = 'H_COMP_7_D_SD'
            then sr.answer_percent end)             as discharge_disagree_strongly_pct,
        max(case when sr.hcahps_measure_id = 'H_COMP_7_LINEAR_SCORE'
            then sr.linear_mean_value end)          as discharge_linear_score,
        max(case when sr.hcahps_measure_id = 'H_COMP_7_STAR_RATING'
            then sr.star_rating end)                as discharge_star_rating,
        max(case when sr.hcahps_measure_id = 'H_SYMPTOMS_A_P'
            then sr.answer_percent end)             as symptoms_always_pct,
        max(case when sr.hcahps_measure_id = 'H_SYMPTOMS_U_P'
            then sr.answer_percent end)             as symptoms_usually_pct,
        max(case when sr.hcahps_measure_id = 'H_SYMPTOMS_SN_P'
            then sr.answer_percent end)             as symptoms_sometimes_never_pct,

        -- ── Overall Hospital Rating ──
        max(case when sr.hcahps_measure_id = 'H_HSP_RATING_9_10'
            then sr.answer_percent end)             as overall_rating_9_10_pct,
        max(case when sr.hcahps_measure_id = 'H_HSP_RATING_7_8'
            then sr.answer_percent end)             as overall_rating_7_8_pct,
        max(case when sr.hcahps_measure_id = 'H_HSP_RATING_0_6'
            then sr.answer_percent end)             as overall_rating_0_6_pct,
        max(case when sr.hcahps_measure_id = 'H_HSP_RATING_LINEAR_SCORE'
            then sr.linear_mean_value end)          as overall_rating_linear_score,
        max(case when sr.hcahps_measure_id = 'H_HSP_RATING_STAR_RATING'
            then sr.star_rating end)                as overall_rating_star,

        -- ── Recommendation ──
        max(case when sr.hcahps_measure_id = 'H_RECMND_DY'
            then sr.answer_percent end)             as recommend_definitely_pct,
        max(case when sr.hcahps_measure_id = 'H_RECMND_PY'
            then sr.answer_percent end)             as recommend_probably_pct,
        max(case when sr.hcahps_measure_id = 'H_RECMND_DN'
            then sr.answer_percent end)             as recommend_no_pct,
        max(case when sr.hcahps_measure_id = 'H_RECMND_LINEAR_SCORE'
            then sr.linear_mean_value end)          as recommend_linear_score,
        max(case when sr.hcahps_measure_id = 'H_RECMND_STAR_RATING'
            then sr.star_rating end)                as recommend_star_rating,

        -- ── Survey Metadata ──
        max(sr.completed_surveys)                   as completed_surveys,
        max(sr.response_rate_pct)                   as response_rate_pct,
        min(sr.survey_start_date)                   as survey_start_date,
        max(sr.survey_end_date)                     as survey_end_date

    from responses sr
    join hospitals h
        on sr.facility_id = h.facility_id
    left join geography g
        on md5(h.state || '|' || h.county_parish || '|' || h.zip_code) = g.geo_key
    group by
        sr.facility_id, h.facility_name, h.city, h.state,
        g.state_name, g.region, h.county_parish, h.zip_code
)

select * from pivoted
