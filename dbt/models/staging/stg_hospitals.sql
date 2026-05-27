-- stg_hospitals.sql
-- Silver Layer: Deduplicated hospital dimension
-- From 325K raw rows → ~4,792 unique hospitals
-- QUALIFY ROW_NUMBER picks the latest version of each hospital

with source as (
    select * from {{ source('raw', 'raw_hcahps') }}
),

deduplicated as (
    select
        facility_id,
        facility_name,
        address,
        city,
        state,
        zip_code,
        county_parish,
        telephone_number
    from source
    qualify row_number() over (
        partition by facility_id
        order by _loaded_at desc
    ) = 1
)

select * from deduplicated
