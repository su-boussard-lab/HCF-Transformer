SELECT subject_id AS row_id,
       CASE WHEN prtype.type = 'PartialExcBone' THEN 1001
       WHEN prtype.type = 'SpinalFusion' THEN 1002
       WHEN prtype.type = 'TreatFracDisHipFemur' THEN 1003
       WHEN prtype.type = 'TreatFracDisLowExtremity' THEN 1004 
       WHEN prtype.type = 'CABG' THEN 1005
       WHEN prtype.type = 'ColorecResect' THEN 1006
       WHEN prtype.type = 'Appendectomy' THEN 1007
       WHEN prtype.type = 'cholecystectomy' THEN 1008
       WHEN prtype.type = 'InguinHerniaRepair' THEN 1009 
       WHEN prtype.type = 'HysterecAbVag' THEN 1010
       WHEN prtype.type = 'OophorectomyUniBi' THEN 1011
       WHEN prtype.type = 'laminectomy' THEN 1012
       WHEN prtype.type = 'KneeReplacement' THEN 1013 
       WHEN prtype.type = 'thoracotomy' THEN 1014
       WHEN prtype.type = 'mastectomy' THEN 1015
       WHEN prtype.type = 'OtherHand' THEN 1016
       WHEN prtype.type = 'DistalRadFrac' THEN 1017 
       WHEN prtype.type = 'ExciLysisPeriAdhesions' THEN 1018 
       WHEN prtype.type = 'prostatectomy' THEN 1019
       Else 1000 END * 10000 + @analysis_id AS covariate_id, 
       1 AS covariate_value
FROM (SELECT * FROM @cohort_table WHERE cohort_definition_id = @target_cohort_id) c
JOIN @cdm_database_schema.procedure_occurrence pr
ON pr.person_id = c.subject_id
JOIN @target_database_schema.surgery_code_concept_ids prtype
ON pr.procedure_concept_id = prtype.standard_concept_id AND prtype.standard_concept_id is not NULL
AND (pr.procedure_date >= DATEADD(d, @start_day, c.cohort_start_date) AND pr.procedure_date <= DATEADD(d, @end_day, c.cohort_end_date))
group by c.subject_id, prtype.type
;