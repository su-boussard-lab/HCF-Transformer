DELETE FROM @target_database_schema.@target_cohort_table WHERE cohort_definition_id = @outcome_cohort_id;

INSERT INTO @target_database_schema.@target_cohort_table (cohort_definition_id, subject_id, cohort_start_date, cohort_end_date)
SELECT @outcome_cohort_id as cohort_definition_id, subject_id, cohort_start_date, cohort_end_date 
FROM (
  SELECT coh.subject_id, coh.cohort_start_date, coh.cohort_end_date, 
  FROM @target_database_schema.@target_cohort_table coh
  JOIN @cdm_database_schema.visit_occurrence vo
    ON coh.subject_id = vo.person_id
      AND DATEADD(d, 1, coh.cohort_end_date) <= vo.visit_start_DATE 
      AND DATEADD(d, 30, coh.cohort_end_date) >= vo.visit_start_DATE
      AND cohort_definition_id = @target_cohort_id
      AND vo.visit_concept_id IN (9201, 262)
  GROUP BY coh.subject_id, coh.cohort_start_date, coh.cohort_end_date
);