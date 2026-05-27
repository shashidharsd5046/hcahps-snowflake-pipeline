-- stg_measures.sql
-- Silver Layer: Distinct survey measures with domain classification
-- From 325K raw rows → 68 unique measures
-- Each measure gets a domain label and a type label

with source as (
    select * from {{ source('raw', 'raw_hcahps') }}
),

classified as (
    select distinct
        hcahps_measure_id       as measure_id,
        hcahps_question         as question_text,
        hcahps_answer_desc      as answer_description,

        -- Classify which domain this measure belongs to
        case
            when hcahps_measure_id like 'H_COMP_1%' or hcahps_measure_id like 'H_NURSE%'
                then 'Nurse Communication'
            when hcahps_measure_id like 'H_COMP_2%' or hcahps_measure_id like 'H_DOCTOR%'
                then 'Doctor Communication'
            when hcahps_measure_id like 'H_COMP_5%'
                then 'Staff Responsiveness'
            when hcahps_measure_id like 'H_COMP_6%' or hcahps_measure_id like 'H_MED_FOR%'
                 or hcahps_measure_id like 'H_SIDE_EFFECTS%'
                then 'Medicine Communication'
            when hcahps_measure_id like 'H_CLEAN%'      then 'Cleanliness'
            when hcahps_measure_id like 'H_QUIET%'      then 'Quietness'
            when hcahps_measure_id like 'H_HSP_RATING%' then 'Overall Rating'
            when hcahps_measure_id like 'H_RECMND%'     then 'Recommendation'
            when hcahps_measure_id like 'H_DISCH%' or hcahps_measure_id like 'H_SYMPTOMS%'
                then 'Discharge Information'
            when hcahps_measure_id = 'H_STAR_RATING'    then 'Overall Star Rating'
            else 'Other'
        end as measure_domain,

        -- Classify what type of value this measure holds
        case
            when hcahps_measure_id like '%LINEAR_SCORE' then 'LINEAR_SCORE'
            when hcahps_measure_id like '%STAR_RATING'  then 'STAR_RATING'
            else 'PERCENT'
        end as measure_type

    from source
)

select * from classified
