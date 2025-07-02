
SELECT coh.subject_id AS row_id,
       @analysis_id AS covariate_id,
       {@is_first == 1} ? {
       CASE 
	     WHEN DATEDIFF(DAY, MIN(co.CONDITION_START_DATE), coh.cohort_start_date) >= 0 
	     THEN DATEDIFF(DAY, MIN(co.CONDITION_START_DATE), coh.cohort_start_date) + 1  
	     ELSE DATEDIFF(DAY, MIN(co.CONDITION_START_DATE), coh.cohort_start_date)
	     END} : {
	     CASE 
	     WHEN DATEDIFF(DAY, MAX(co.CONDITION_START_DATE), coh.cohort_start_date) >= 0 
	     THEN DATEDIFF(DAY, MAX(co.CONDITION_START_DATE), coh.cohort_start_date) + 1  
	     ELSE DATEDIFF(DAY, MAX(co.CONDITION_START_DATE), coh.cohort_start_date)
	     END
	     } 
	     AS covariate_value
FROM (SELECT * FROM @cohort_table WHERE cohort_definition_id = @target_cohort_id) coh
JOIN @cdm_database_schema.condition_occurrence co
  ON co.person_id = coh.subject_id
  AND co.condition_start_date <= DATEADD(d, @end_day, coh.cohort_end_date) 
  {@start_day != -9999} ? {AND co.condition_start_date >= DATEADD(d, @start_day, coh.cohort_start_date)}
JOIN @cdm_database_schema.concept_ancestor ca
  ON co.condition_concept_id = ca.descendant_concept_id AND ca.ancestor_concept_id in (@included_concept_ids)
group by coh.subject_id, coh.cohort_start_date
;