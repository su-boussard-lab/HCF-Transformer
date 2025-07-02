-- e.g., covariate_id = ancestor_concept_id * 1000 + 0
-- For inpatient use start_day = 0 and end_day = 0
SELECT coh.subject_id AS row_id,
       cast(ca.ancestor_concept_id as bigint) * 10000 + @analysis_id AS covariate_id, 
       1 AS covariate_value
FROM (SELECT * FROM @cohort_table WHERE cohort_definition_id = @target_cohort_id) coh
JOIN @cdm_database_schema.drug_exposure de
  ON de.person_id = coh.subject_id
  AND de.drug_exposure_start_date <= DATEADD(d, @end_day, coh.cohort_end_date) 
  AND de.drug_exposure_start_date >= DATEADD(d, @start_day, coh.cohort_start_date)
  AND de.drug_exposure_end_date <= coh.cohort_end_date
JOIN @cdm_database_schema.concept_ancestor ca
  ON de.drug_concept_id = ca.descendant_concept_id 
WHERE ca.ancestor_concept_id in (@included_concept_ids)
group by coh.subject_id, ca.ancestor_concept_id
;