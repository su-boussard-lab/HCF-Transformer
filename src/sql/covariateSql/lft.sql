-- Liver Function Test (LFTs) 
WITH lft as (
SELECT person_id, measurement_concept_id, measurement_date, unit_concept_id, value_as_number
FROM @cdm_database_schema.measurement me
JOIN @cdm_database_schema.concept_ancestor ca
on me.MEASUREMENT_CONCEPT_ID = ca.DESCENDANT_CONCEPT_ID
WHERE ca.ANCESTOR_CONCEPT_ID in (@included_concept_ids)  
and UNIT_CONCEPT_ID = 8645 -- U/L
), cohort as (SELECT * FROM @cohort_table WHERE cohort_definition_id = @target_cohort_id)
SELECT coh.subject_id AS row_id,
       @analysis_id AS covariate_id,
      {@start_day == -9999 & @end_day == -9999} ? {A.day_from_cohort} : {A.value_as_number} AS covariate_value
FROM
(SELECT *
  FROM (
    SELECT coh.subject_id, coh.cohort_start_date, coh.cohort_end_date, l.measurement_date, 
    DATEDIFF(DAY, l.measurement_date, coh.cohort_start_date) day_from_cohort, l.value_as_number, 
    row_number() OVER (PARTITION BY coh.subject_id ORDER BY l.measurement_date DESC) AS lft_ordinal
    FROM cohort coh
    JOIN lft l
    ON coh.subject_id = l.person_id and l.measurement_date <= coh.cohort_start_date
  ) A WHERE A.lft_ordinal = 1 {@start_day!= -9999} ? {and A.day_from_cohort <= (- @start_day)}
) A
RIGHT JOIN cohort coh on coh.subject_id = A.subject_id
;


