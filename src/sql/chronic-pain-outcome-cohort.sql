DELETE FROM @target_database_schema.@target_cohort_table WHERE cohort_definition_id = @outcome_cohort_id;
  
WITH chronic_pain_concept_set (concept_id) as
(
  SELECT DISTINCT I.concept_id 
  FROM
  (
    SELECT concept_id FROM @vocabulary_database_schema.concept 
      WHERE concept_id = 436096
    UNION ALL
    SELECT c.concept_id 
    FROM @vocabulary_database_schema.concept c
    JOIN `@vocabulary_database_schema.concept_ancestor ca 
      ON c.concept_id = ca.descendant_concept_id
    AND ca.ancestor_concept_id = 436096
    AND c.invalid_reason is null
  ) I
)
INSERT INTO @target_database_schema.@target_cohort_table (cohort_definition_id, subject_id, cohort_start_date, cohort_end_date)
SELECT @outcome_cohort_id as cohort_definition_id, subject_id, cohort_start_date, cohort_end_date 
FROM (
  SELECT coh.subject_id, coh.cohort_start_date, coh.cohort_end_date, 
  FROM @target_database_schema.@target_cohort_table coh
  JOIN @cdm_database_schema.condition_occurrence co
    ON coh.subject_id = de.person_id
      AND DATEADD(d, 91, coh.cohort_end_date) < co.condition_start_DATE 
      AND DATEADD(d, 365, coh.cohort_end_date) >= co.condition_start_DATE
      AND cohort_definition_id = @target_cohort_id
  JOIN chronic_pain_concept_set cs
    ON cs.concept_id = co.condition_concept_id
  GROUP BY coh.subject_id, coh.cohort_start_date, coh.cohort_end_date
);

