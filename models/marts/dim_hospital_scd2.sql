-- dim_hospital_scd2.sql
-- Gold Layer: SCD Type 2 hospital dimension
-- Tracks full history of hospital attribute changes over time
-- Uses LEAD() window function — no Streams/Tasks/MERGE needed

with all_versions as (
    select distinct
        facility_id,
        facility_name,
        address,
        city,
        state,
        zip_code,
        county_parish,
        telephone_number,
        min(_loaded_at) as first_seen_at
    from {{ source('raw', 'raw_hcahps') }}
    group by
        facility_id, facility_name, address, city, state,
        zip_code, county_parish, telephone_number
),

scd2 as (
    select
        md5(facility_id || '|' || to_char(first_seen_at))   as hospital_version_key,
        facility_id,
        facility_name,
        address,
        city,
        state,
        zip_code,
        county_parish,
        telephone_number,
        first_seen_at                                        as valid_from,
        coalesce(
            lead(first_seen_at) over (
                partition by facility_id
                order by first_seen_at
            ),
            '9999-12-31'::timestamp_ntz
        )                                                    as valid_to,
        case
            when lead(first_seen_at) over (
                partition by facility_id
                order by first_seen_at
            ) is null then true
            else false
        end                                                  as is_current
    from all_versions
)

select * from scd2
