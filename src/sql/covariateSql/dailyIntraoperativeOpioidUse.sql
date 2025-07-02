select 
  coh.subject_id row_id,
  ca.ancestor_concept_id * 10000 + date_diff(de.drug_exposure_start_date, coh.cohort_start_date, DAY) covariate_id, 
  count(*) value
  --date_diff(de.drug_exposure_start_date , coh.cohort_start_date, DAY) start_day,
  --ca.ancestor_concept_id opioid_concept_id
FROM
  (SELECT * FROM @cohort_table where cohort_definition_id = 2) coh
join @cdm_database_schema.drug_exposure de
  on coh.subject_id = de.person_id 
  and de.drug_exposure_start_date >= coh.cohort_start_date and de.drug_exposure_start_date <= coh.cohort_end_date
join @cdm_database_schema.concept_ancestor ca
  on de.drug_concept_id = ca.descendant_concept_id
where ca.ancestor_concept_id in (1103314, 1124957, 1110410, 1103640, 1102527, 1126658, 1174888, 1154029, 1201620)
group by coh.subject_id, coh.cohort_start_date, ca.ancestor_concept_id, de.drug_exposure_start_date