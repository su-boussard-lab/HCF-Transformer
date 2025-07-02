-- Conversion tables for glycated haemoglobin and glucose values from NIH
-- DCCT % = (0.0915 × mmol/mol) + 2.15%;
-- (mg/dL)=28.7×HbA1c(%)−46.7
-- (mmol/L)=1.59×HbA1c(%)−2.59
-- mg/dL= (µg/mL) / 10
-- 8840 milligram per deciliter
-- 9028 milligram per deciliter calculated
-- 8596 calculated
-- 8859 microgram per milliliter
-- 8713 gram per deciliter
-- 9579 millimole per mole
-- 8737 percent hemoglobin
-- 8554 percent
--create or replace table @target_database_schema.coh_a1c as
WITH person_a1c as (
SELECT person_id, measurement_concept_id, measurement_date, unit_concept_id, value_as_number,
case 
when (unit_concept_id = 8840 or unit_concept_id = 9028 or unit_concept_id = 8596) then (value_as_number + 46.7) / 28.7
when unit_concept_id = 8859 then (value_as_number/10 + 46.7) / 28.7
when unit_concept_id = 8713 then (value_as_number*1000 + 46.7) / 28.7
when unit_concept_id = 9579 then value_as_number * 0.0915 + 2.15
else value_as_number end a1c_dcct_percent
FROM @cdm_database_schema.measurement m
WHERE measurement_concept_id in (4184637,
                                3004410,
                                3005131,
                                3005673,
                                40762352,
                                3034639,
                                4197971,
                                3007263,
                                3003309)
and unit_concept_id in (8840, 9028, 8596, 8859, 8713, 9579, 8737, 8554)
), cohort as (SELECT * FROM @cohort_table WHERE cohort_definition_id = @target_cohort_id)
SELECT coh.subject_id AS row_id,
       @analysis_id AS covariate_id,
      {@start_day == -9999 & @end_day == -9999} ? {COALESCE(A.day_from_cohort, -1)} : {COALESCE(A.a1c_dcct_percent, -1)} AS covariate_value
FROM
(SELECT *
  FROM (
    SELECT coh.subject_id, coh.cohort_start_date, coh.cohort_end_date, pc.measurement_date, 
    DATEDIFF(DAY, pc.measurement_date, coh.cohort_start_date) day_from_cohort, pc.a1c_dcct_percent, 
    row_number() OVER (PARTITION BY coh.subject_id ORDER BY pc.measurement_date DESC) AS a1c_ordinal
    FROM cohort coh
    JOIN person_a1c pc
    ON coh.subject_id = pc.person_id and pc.measurement_date <= coh.cohort_start_date
  ) A WHERE A.a1c_ordinal = 1 {@start_day!= -9999} ? {and A.day_from_cohort <= (- @start_day)} ) A
RIGHT JOIN cohort coh on coh.subject_id = A.subject_id
;


