-- e.g., covariate_id = ancestor_concept_id * 10000 + 90
-- For prior use between -365 to -30 of cohort start date start_day = -365 and end_day = -31
SELECT coh.subject_id AS row_id,
       @analysis_id AS covariate_id, 
       1 AS covariate_value
FROM (SELECT * FROM @cohort_table WHERE cohort_definition_id = @target_cohort_id) coh
JOIN @cdm_database_schema.condition_occurrence co
  ON co.person_id = coh.subject_id
  AND co.condition_start_date <= DATEADD(d, @end_day, coh.cohort_end_date) 
  {@start_day != -9999} ? {AND co.condition_start_date >= DATEADD(d, @start_day, coh.cohort_start_date)}
JOIN @cdm_database_schema.concept_ancestor ca
  ON co.condition_concept_id = ca.descendant_concept_id AND ca.ancestor_concept_id in (@included_concept_ids)
group by coh.subject_id
;