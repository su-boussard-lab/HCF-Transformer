SELECT subject_id AS row_id,
       @analysis_id AS covariate_id, 
       DATEDIFF(DAY, cohort_start_date, cohort_end_date) AS covariate_value
FROM @cohort_table 
WHERE cohort_definition_id = @target_cohort_id
;
