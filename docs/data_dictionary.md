# HCAHPS Data Dictionary

## Source Data: HCAHPS-Hospital.csv

**Source:** [CMS Hospital Compare](https://data.cms.gov/provider-data/topics/hospitals)

**Survey:** Hospital Consumer Assessment of Healthcare Providers and Systems (HCAHPS)

### Raw Columns

| Column | Type | Description |
|--------|------|-------------|
| Facility ID | VARCHAR(10) | CMS Certification Number (CCN) |
| Facility Name | VARCHAR(200) | Hospital name |
| Address | VARCHAR(300) | Street address |
| City/Town | VARCHAR(100) | City |
| State | VARCHAR(5) | US state/territory code |
| ZIP Code | VARCHAR(10) | Postal code |
| County/Parish | VARCHAR(100) | County name |
| Telephone Number | VARCHAR(20) | Hospital phone |
| HCAHPS Measure ID | VARCHAR(50) | Survey question code |
| HCAHPS Question | VARCHAR(500) | Full question text |
| HCAHPS Answer Description | VARCHAR(500) | Answer label |
| Patient Survey Star Rating | VARCHAR(20) | 1-5 or Not Applicable/Available |
| HCAHPS Answer Percent | VARCHAR(20) | % giving this answer |
| HCAHPS Linear Mean Value | VARCHAR(20) | Score 0-100 |
| Number of Completed Surveys | VARCHAR(20) | Sample size |
| Survey Response Rate Percent | VARCHAR(20) | Response rate |
| Start Date | VARCHAR(20) | Survey period start |
| End Date | VARCHAR(20) | Survey period end |

### Survey Domains (10 Total)

| Domain | Measure Prefix |
|--------|---------------|
| Nurse Communication | H_COMP_1, H_NURSE_* |
| Doctor Communication | H_COMP_2, H_DOCTOR_* |
| Staff Responsiveness | H_COMP_5 |
| Medicine Communication | H_COMP_6, H_MED_FOR_*, H_SIDE_EFFECTS_* |
| Discharge Information | H_DISCH_*, H_SYMPTOMS_* |
| Cleanliness | H_CLEAN_* |
| Quietness | H_QUIET_* |
| Overall Rating | H_HSP_RATING_* |
| Recommendation | H_RECMND_* |
| Overall Star Rating | H_STAR_RATING |
