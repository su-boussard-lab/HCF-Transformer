-- e.g., covariate_id = ancestor_concept_id * 10000 + 90
-- For outpatient use between 1-90 after discharge start_day = 1 and end_day = 90
SELECT coh.subject_id AS row_id,
       cast(ca.ancestor_concept_id as bigint) * 10000 + @analysis_id AS covariate_id, 
       1 AS covariate_value
FROM (SELECT * FROM @cohort_table WHERE cohort_definition_id = @target_cohort_id) coh
JOIN @cdm_database_schema.drug_exposure de
  ON de.person_id = coh.subject_id
  AND DATEADD(d, @start_day, coh.cohort_end_date) <= de.drug_exposure_start_date
  AND DATEADD(d, @end_day, coh.cohort_end_date) >= de.drug_exposure_start_date
JOIN @cdm_database_schema.concept_ancestor ca
  ON de.drug_concept_id = ca.descendant_concept_id 
WHERE ca.ancestor_concept_id in (1103314, 1124957, 1110410, 1103640, 1102527, 1126658, 1174888, 1154029, 1201620)
group by coh.subject_id, ca.ancestor_concept_id
;