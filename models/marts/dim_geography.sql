-- dim_geography.sql
-- Gold Layer: Geography dimension with state-region classification

with hospitals as (
    select distinct
        state,
        county_parish,
        zip_code
    from {{ ref('stg_hospitals') }}
),

state_regions as (
    select * from {{ ref('state_regions') }}
),

final as (
    select
        md5(h.state || '|' || h.county_parish || '|' || h.zip_code)  as geo_key,
        h.state,
        coalesce(s.state_name, h.state)     as state_name,
        coalesce(s.region, 'Unknown')       as region,
        h.county_parish,
        h.zip_code
    from hospitals h
    left join state_regions s on h.state = s.state
)

select * from final
