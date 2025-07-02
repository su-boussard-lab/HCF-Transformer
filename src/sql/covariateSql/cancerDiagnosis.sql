-- 699 concept ids mapped from cancerous ICD10 codes
SELECT subject_id AS row_id,
       @analysis_id AS covariate_id,
       1 AS covariate_value
FROM (SELECT * FROM @cohort_table WHERE cohort_definition_id = @target_cohort_id) c
JOIN @cdm_database_schema.condition_occurrence co
  ON co.person_id = c.subject_id
  AND co.condition_start_date >= DATEADD(d, @start_day, c.cohort_start_date) AND co.condition_start_date <= DATEADD(d, @end_day, c.cohort_start_date)
WHERE co.condition_concept_id IN (@included_concept_ids)
GROUP BY c.subject_id
;


