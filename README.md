# 🔄 HCAHPS dbt Project

This is the **dbt (data build tool)** implementation of the HCAHPS ELT pipeline, designed to run transformations on Snowflake.

## 📁 Project Structure

```
.
├── README.md
├── setup/                       # Snowflake infrastructure
│   └── 01_snowpipe_infrastructure.sql  # Database, Snowpipe, Stage
├── dbt_project.yml              # Project configuration
├── profiles.yml                 # Snowflake connection (use env vars)
├── packages.yml                 # dbt packages (dbt_utils)
├── models/
│   ├── staging/                 # 🥈 Silver Layer (views)
│   │   ├── sources.yml          # Raw source definition
│   │   ├── schema.yml           # Tests & documentation
│   │   ├── stg_hospitals.sql    # Deduplicated hospitals
│   │   ├── stg_measures.sql     # Classified survey measures
│   │   └── stg_survey_responses.sql  # Cleaned responses
│   └── marts/                   # 🥇 Gold Layer (tables)
│       ├── schema.yml           # Tests & documentation
│       ├── dim_geography.sql    # State-region dimension
│       ├── dim_hospital_scd2.sql # SCD Type 2 history
│       └── fact_survey_results.sql  # Wide pivoted fact (all 68 measures)
├── seeds/
│   └── state_regions.csv        # US state-to-region lookup
├── tests/
│   ├── test_star_rating_range.sql
│   ├── test_answer_percent_range.sql
│   └── test_hospital_count.sql
├── macros/
│   └── generate_surrogate_key.sql
├── snapshots/
└── analyses/
```

## 🚀 Quick Start

### Prerequisites
- Python 3.8+
- dbt-snowflake: `pip install dbt-snowflake`
- Snowflake account with HCAHPS_DW database

### Setup

1. **Set environment variables:**
```bash
export SNOWFLAKE_ACCOUNT="your-account"
export SNOWFLAKE_USER="your-user"
export SNOWFLAKE_PASSWORD="your-password"
```

2. **Install dependencies:**
```bash
cd dbt/
dbt deps
```

3. **Load seed data:**
```bash
dbt seed
```

4. **Run all models:**
```bash
dbt run
```

5. **Run tests:**
```bash
dbt test
```

6. **Generate documentation:**
```bash
dbt docs generate
dbt docs serve
```

## 📊 DAG (Directed Acyclic Graph)

```
raw_hcahps (source)
    ├── stg_hospitals ─────────┬──► dim_geography ──┐
    ├── stg_measures           │                    │
    └── stg_survey_responses ──┴──► fact_survey_results
                                    (wide: all 68 measures)
    └──────────────────────────────► dim_hospital_scd2
```

## 🧪 Tests

| Test | What It Validates |
|------|-------------------|
| `stg_hospitals.facility_id` | Unique + not null |
| `stg_measures.measure_type` | Only PERCENT, LINEAR_SCORE, STAR_RATING |
| `fact_survey_results.facility_id` | Unique + not null (1 row per hospital) |
| `test_star_rating_range` | Star ratings between 1-5 |
| `test_answer_percent_range` | Percentages between 0-100 |
| `test_hospital_count` | At least 4,000 hospitals in fact table |
