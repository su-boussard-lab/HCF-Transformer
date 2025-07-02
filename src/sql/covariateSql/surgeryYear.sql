SELECT subject_id AS row_id,
       @analysis_id AS covariate_id, 
       YEAR(cohort_start_date) AS covariate_value
FROM @cohort_table 
WHERE cohort_definition_id = @target_cohort_id
;
