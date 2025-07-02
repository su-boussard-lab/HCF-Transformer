-- e.g., covariate_id = ancestor_concept_id * 10000 + 90
-- For outpatient use between 1-90 after discharge start_day = 1 and end_day = 90

WITH opioid_drugs (person_id, drug_concept_id, ancestor_concept_id, drug_exposure_start_date, drug_exposure_end_date, DAYS_SUPPLY, QUANTITY) as (
SELECT de.person_id, de.drug_concept_id, ca.ancestor_concept_id, de.drug_exposure_start_date, de.drug_exposure_end_date,
       de.DAYS_SUPPLY, de.QUANTITY
FROM @cdm_database_schema.drug_exposure de
JOIN @cdm_database_schema.concept_ancestor ca
  ON de.drug_concept_id = ca.descendant_concept_id
  AND ca.ancestor_concept_id in (1103314, 1124957, 1110410, 1103640, 1102527, 1126658, 1174888, 1154029, 1201620)
)
SELECT coh.subject_id AS row_id,
       cast(de.ancestor_concept_id as bigint) * 10000 + @analysis_id AS covariate_id, 
       count(*) AS covariate_value
FROM (SELECT * FROM @cohort_table WHERE cohort_definition_id = @target_cohort_id) coh
JOIN opioid_drugs de
  ON de.person_id = coh.subject_id
  AND de.drug_exposure_start_date >= DATEADD(DAY, @start_day, coh.cohort_end_date)
  AND de.drug_exposure_start_date <= DATEADD(DAY, @end_day, coh.cohort_end_date)
LEFT JOIN opioid_drugs de2
  ON de2.person_id = coh.subject_id
  AND coh.cohort_end_date = de2.drug_exposure_start_date
  AND coh.cohort_end_date < de2.drug_exposure_end_date
  AND de2.DAYS_SUPPLY > 1 AND de2.QUANTITY > 1
WHERE de2.person_id is null
GROUP BY coh.subject_id, de.ancestor_concept_id
;