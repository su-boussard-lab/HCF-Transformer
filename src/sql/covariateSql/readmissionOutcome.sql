SELECT subject_id AS row_id,
       @analysis_id AS covariate_id, 
       1 AS covariate_value
FROM (SELECT * FROM @cohort_table WHERE cohort_definition_id = @target_cohort_id) c
JOIN @cdm_database_schema.visit_occurrence vo
ON vo.person_id = c.subject_id
WHERE vo.visit_concept_id IN (9201, 262)
AND vo.visit_start_date <= DATEADD(d, @end_day, c.cohort_end_date)
AND vo.visit_start_date >= DATEADD(d, @start_day, c.cohort_end_date)
group by c.subject_id