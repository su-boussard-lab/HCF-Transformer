

# covariateSettings <- createCovariateSettings(
#   useDemographicsGender = TRUE,
#   useDemographicsAgeGroup = TRUE,
#   useDemographicsRace = TRUE, 
#   useDemographicsEthnicity = TRUE,
#   
#   useDrugGroupEraLongTerm = TRUE,
#   useConditionGroupEraLongTerm = TRUE,
#   
#   longTermStartDays = -180,
#   endDays = 0,
# )
# 
# covariateData <- getDbCovariateData(connectionDetails = connectionDetails,
#                                     oracleTempSchema = config$cdm$target_database_schema,
#                                     cdmDatabaseSchema = config$cdm$cdm_database_schema,
#                                     cohortDatabaseSchema = config$cdm$target_database_schema,
#                                     cohortTable = config$cdm$cohort_table,
#                                     cohortId = config$cdm$target_cohort_id,
#                                     covariateSettings = covariateSettings,
#                                     aggregated = TRUE)
# 
# result <- createTable1(covariateData)
# write.csv(result, file = './fs/table1.csv')


covariateSettingsDemo <- createCovariateSettings(
  useDemographicsGender = TRUE,
  useDemographicsAgeGroup = TRUE,
  useDemographicsRace = TRUE,
  useDemographicsEthnicity = TRUE,
  useDemographicsAge = TRUE
)

covariateSettingsCCI <- createCovariateSettings(
  useCharlsonIndex = TRUE,
  endDays = 0
)


# Covariate 1: All procedure types occur between the cohort_start_date and the cohort_end_date.
# To consider the procedures between the cohort_start_date and cohort_end_date, both starDay and endDay must be set to 0.
covariateSettings1 <- createManualCovariateSetting(analysisId = 1,
                                                   covariateName = "Surgery type during visit",
                                                   sql = "./src/sql/covariateSql/surgeryType2.sql",
                                                   domainId = "Procedure",
                                                   startDay = 0,
                                                   endDay = 0)

# Covariate 2: Length of hospitalization.
# starDay and endDay are added by cohort_start_date.
# starDay of -9999 means any time prior to cohort.
# the covariate considers all descendant ids for those included concept ids.
covariateSettings2 <- createManualCovariateSetting(analysisId = 2,
                                                    covariateName = "Length of hospitalization",
                                                    sql = "./src/sql/covariateSql/hospilalizationLength.sql",
                                                    domainId = "Visit",
                                                    startDay = 0,
                                                    endDay = 0)


# Covariate 3: the number of ER or ERIP visits prior to cohort start date. 
# starDay of -9999 equals to all prior events.
# starDay and endDay are added by cohort_start_date.
covariateSettings3 <- createManualCovariateSetting(analysisId = 3,
                                                   covariateName = "Prior ER visit count",
                                                   sql = "./src/sql/covariateSql/priorErCount.sql",
                                                   domainId = "Visit",
                                                   startDay = -9999,
                                                   endDay = -1)



# Covariate 4: The first A1C DCCT value any time prior cohort start date.
# starDay and endDay are added by cohort_start_date
covariateSettings4 <- createManualCovariateSetting(analysisId = 4,
                                                   covariateName = "Prior HbA1C percent",
                                                   sql = "./src/sql/covariateSql/a1c.sql",
                                                   domainId = "Measurment",
                                                   startDay = -9999,
                                                   endDay = 0)


# Covariate 5: The number of days from the first A1C DCCT to the cohort start date.
# if starDay and endDay are -9999, the day from cohort is considered as covariate value.
covariateSettings5 <- createManualCovariateSetting(analysisId = 5,
                                                   covariateName = "Prior HbA1C day from cohort",
                                                   sql = "./src/sql/covariateSql/a1c.sql",
                                                   domainId = "Measurment",
                                                   startDay = -9999,
                                                   endDay = -9999)



# Covariate 6: Surgery year.
covariateSettings6 <- createManualCovariateSetting(analysisId = 6,
                                                    covariateName = "Surgery year",
                                                    sql = "./src/sql/covariateSql/surgeryYear.sql",
                                                    domainId = "Procedure",
                                                    startDay = 0,
                                                    endDay = 0)

# Covariate 7: Any prior nervous system disorder due to diabetes (ICD10 code = E13.4, omop standard id = 443730).
# starDay and endDay are added by cohort_start_date.
# starDay of -9999 means any time prior to cohort.
# the covariate considers all descendant ids for those included concept ids.
covariateSettings7 <- createManualCovariateSetting(analysisId = 7,
                                                   covariateName = "Any nervous system disorders due to diabetes prior to surgery (ICD10 E13.4)",
                                                   sql = "./src/sql/covariateSql/priorCondition.sql",
                                                   domainId = "Condition",
                                                   startDay = -9999,
                                                   endDay = 0,
                                                   includedConceptIds = c(443730))


# Covariate 8 and 9: Any prior gabapentin exposure.
# starDay and endDay are added by cohort_start_date.
# includedConceptIds shoud be ingredient ids because the covariate considers all descendant ids for those ingredient concept ids.
covariateSettings8 <- createManualCovariateSetting(analysisId = 8,
                                                    covariateName = "Any preoperative gabapentin use from -365 days to -31 days of admission",
                                                    sql = "./src/sql/covariateSql/priorIngredientDrugUse.sql",
                                                    domainId = "Drug",
                                                    startDay = -365,
                                                    endDay = -31,
                                                    includedConceptIds = c(797399))

covariateSettings9 <- createManualCovariateSetting(analysisId = 9,
                                                   covariateName = "Any preoperative gabapentin use from -30 days to -1 days of admission",
                                                   sql = "./src/sql/covariateSql/priorIngredientDrugUse.sql",
                                                   domainId = "Drug",
                                                   startDay = -30,
                                                   endDay = -1,
                                                   includedConceptIds = c(797399))


# Covariate 10: Any gabapentin exposure between cohort start and end dates.
# starDay and endDay are added by cohort_start_date and cohort_end_date, respectively.
covariateSettings10 <- createManualCovariateSetting(analysisId = 10,
                                                   covariateName = "Any inpatient gabapentin use",
                                                   sql = "./src/sql/covariateSql/inpatientDrugUse.sql",
                                                   domainId = "Drug",
                                                   startDay = 0,
                                                   endDay = 0,
                                                   includedConceptIds = c(797399))



# Covariate 11: Any prior tobacco use.
# starDay and endDay are added by cohort_start_date.
# starDay of -9999 means any time prior to cohort.
# the covariate considers all descendant ids for those included concept ids.
covariateSettings11 <- createManualCovariateSetting(analysisId = 11,
                                                   covariateName = "Any prior tobacco use",
                                                   sql = "./src/sql/covariateSql/priorObservation.sql",
                                                   domainId = "Observation",
                                                   startDay = -9999,
                                                   endDay = 0,
                                                   includedConceptIds = c(903654,903652, 4036084, 4005823, 4144271, 4038731, 4038735))


# Covariate 12: Any prior alcohol disorders including:
# Disorder caused by alcohol, such as dependence, abuse, intoxication, withdrawal, Alcohol myopathy, Fetal alcohol syndrome, Alcohol amnestic disorder, paranoia
# Aldehyde dehydrogenase inhibitor overdose and Alcohol induced hallucinations.
# starDay and endDay are added by cohort_start_date.
# starDay of -9999 means any time prior to cohort.
# the covariate considers all descendant ids for those included concept ids.
covariateSettings12 <- createManualCovariateSetting(analysisId = 12,
                                                   covariateName = "Prior alcohol disorders conditions",
                                                   sql = "./src/sql/covariateSql/priorCondition.sql",
                                                   domainId = "Condition",
                                                   startDay = -9999,
                                                   endDay = 0,
                                                   includedConceptIds = c(36714559, 3654404, 4214950))


# Covariate 13: Any prior anxiety disorders.
# starDay and endDay are added by cohort_start_date.
# starDay of -9999 means any time prior to cohort.
# the covariate considers all descendant ids for those included concept ids.
covariateSettings13 <- createManualCovariateSetting(analysisId = 13,
                                                    covariateName = "Prior anxiety disorder",
                                                    sql = "./src/sql/covariateSql/priorCondition.sql",
                                                    domainId = "Condition",
                                                    startDay = -9999,
                                                    endDay = 0,
                                                    includedConceptIds = c(441542))

# Covariate 14: Any prior depressive disorders.
# starDay and endDay are added by cohort_start_date.
# starDay of -9999 means any time prior to cohort.
# the covariate considers all descendant ids for those included concept ids.
covariateSettings14 <- createManualCovariateSetting(analysisId = 14,
                                                    covariateName = "Prior depressive disorder",
                                                    sql = "./src/sql/covariateSql/priorCondition.sql",
                                                    domainId = "Condition",
                                                    startDay = -9999,
                                                    endDay = 0,
                                                    includedConceptIds = c(440383))



# Covariate 15: Having any cancer diagnosis 1 year prior cohort start date.
# starDay and endDay are added by cohort_start_date
cancer_ids <- read.csv('./concepts/cancer-concept-ids.csv', header = F)
covariateSettings15 <- createManualCovariateSetting(analysisId = 15,
                                                    covariateName = "Prior cancer diagnosis",
                                                    sql = "./src/sql/covariateSql/cancerDiagnosis.sql",
                                                    domainId = "Condition",
                                                    startDay = -365,
                                                    endDay = 0,
                                                    includedConceptIds = cancer_ids[[1]])


# Covariate 16: Any prior diabetes diagnosis.
# starDay and endDay are added by cohort_start_date.
# starDay of -9999 means any time prior to cohort.
# the covariate considers all descendant ids for those included concept ids.
covariateSettings16 <- createManualCovariateSetting(analysisId = 16,
                                                    covariateName = "Prior diabetes diagnosis",
                                                    sql = "./src/sql/covariateSql/priorCondition.sql",
                                                    domainId = "Condition",
                                                    startDay = -9999,
                                                    endDay = 0,
                                                    includedConceptIds = c(201820))

# Covariate 17: Any prior chronic pain diagnosis.
# starDay and endDay are added by cohort_start_date and cohort_end_date, respectively.
# starDay of -9999 means any time prior to cohort.
# the covariate considers all descendant ids for those included concept ids.
covariateSettings17 <- createManualCovariateSetting(analysisId = 17,
                                                    covariateName = "Prior chronic pain diagnosis",
                                                    sql = "./src/sql/covariateSql/priorCondition.sql",
                                                    domainId = "Condition",
                                                    startDay = -9999,
                                                    endDay = 0,
                                                    includedConceptIds = c(436096))


# Covariate 18: Any prior last OAO diagnosis.
# starDay and endDay are added by cohort_start_date and cohort_end_date, respectively.
# starDay of -9999 means any time prior to cohort.
# the covariate considers all descendant ids for those included concept ids.
covariateSettings18 <- createManualCovariateSetting(analysisId = 18,
                                                    covariateName = "Prior opioid adverse outcome diagnosis",
                                                    sql = "./src/sql/covariateSql/priorCondition.sql",
                                                    domainId = "Condition",
                                                    startDay = -9999,
                                                    endDay = 0,
                                                    includedConceptIds = c(606805, 439223, 437158, 4230779, 4032799, 438120, 438130, 4099935))




# Covariate 19: Any prior hypertension diagnosis.
# starDay and endDay are added by cohort_start_date and cohort_end_date, respectively.
# starDay of -9999 means any time prior to cohort.
# the covariate considers all descendant ids for those included concept ids.
covariateSettings19 <- createManualCovariateSetting(analysisId = 19,
                                                    covariateName = "Prior hypertension diagnosis (ICD10 I10.9)",
                                                    sql = "./src/sql/covariateSql/priorCondition.sql",
                                                    domainId = "Condition",
                                                    startDay = -9999,
                                                    endDay = 0,
                                                    includedConceptIds = c(320128))

# Covariate 20: Any prior Neuropathy diagnosis.
# starDay and endDay are added by cohort_start_date and cohort_end_date, respectively.
# starDay of -9999 means any time prior to cohort.
# the covariate considers all descendant ids for those included concept ids.
covariateSettings20 <- createManualCovariateSetting(analysisId = 20,
                                                    covariateName = "Prior neuropathy diagnosis (ICD10 G60.9)",
                                                    sql = "./src/sql/covariateSql/priorCondition.sql",
                                                    domainId = "Condition",
                                                    startDay = -9999,
                                                    endDay = 0,
                                                    includedConceptIds = c(4301699))

# Covariate 21: Any prior nephropathy diagnosis.
# starDay and endDay are added by cohort_start_date and cohort_end_date, respectively.
# starDay of -9999 means any time prior to cohort.
# the covariate considers all descendant ids for those included concept ids.
covariateSettings21 <- createManualCovariateSetting(analysisId = 21,
                                                    covariateName = "Prior nephropathy diagnosis (ICD10 N14.2)",
                                                    sql = "./src/sql/covariateSql/priorCondition.sql",
                                                    domainId = "Condition",
                                                    startDay = -9999,
                                                    endDay = 0,
                                                    includedConceptIds = c(4126119))


# Covariate 22: Any prior retinopathy diagnosis.
# starDay and endDay are added by cohort_start_date and cohort_end_date, respectively.
# starDay of -9999 means any time prior to cohort.
# the covariate considers all descendant ids for those included concept ids.
covariateSettings22 <- createManualCovariateSetting(analysisId = 22,
                                                    covariateName = "Prior retinopathy diagnosis (ICD10 H35.00)",
                                                    sql = "./src/sql/covariateSql/priorCondition.sql",
                                                    domainId = "Condition",
                                                    startDay = -9999,
                                                    endDay = 0,
                                                    includedConceptIds = c(378416))


# Covariate 23: Any prior COPD diagnosis.
# starDay and endDay are added by cohort_start_date and cohort_end_date, respectively.
# starDay of -9999 means any time prior to cohort.
# the covariate considers all descendant ids for those included concept ids.
covariateSettings23 <- createManualCovariateSetting(analysisId = 23,
                                                    covariateName = "Prior COPD diagnosis (ICD10 J44.9)",
                                                    sql = "./src/sql/covariateSql/priorCondition.sql",
                                                    domainId = "Condition",
                                                    startDay = -9999,
                                                    endDay = 0,
                                                    includedConceptIds = c(255573))


# Covariate 24: Any prior lipid disorder diagnosis.
# starDay and endDay are added by cohort_start_date and cohort_end_date, respectively.
# starDay of -9999 means any time prior to cohort.
# the covariate considers all descendant ids for those included concept ids.
covariateSettings24 <- createManualCovariateSetting(analysisId = 24,
                                                    covariateName = "Prior lipid disorder diagnosis (ICD10 E75.6, E78.5, E78.00, E78.6, E78.1)",
                                                    sql = "./src/sql/covariateSql/priorCondition.sql",
                                                    domainId = "Condition",
                                                    startDay = -9999,
                                                    endDay = 0,
                                                    includedConceptIds = c(4027782, 432867,437827,435516,440360))



# Covariate 25: Any prior thyroid disorder diagnosis.
# starDay and endDay are added by cohort_start_date and cohort_end_date, respectively.
# starDay of -9999 means any time prior to cohort.
# the covariate considers all descendant ids for those included concept ids.
covariateSettings25 <- createManualCovariateSetting(analysisId = 25,
                                                    covariateName = "Prior thyroid disorder diagnosis (ICD10 E07.9)",
                                                    sql = "./src/sql/covariateSql/priorCondition.sql",
                                                    domainId = "Condition",
                                                    startDay = -9999,
                                                    endDay = 0,
                                                    includedConceptIds = c(141253))

# Covariate 26: Any prior liver disease diagnosis.
# starDay and endDay are added by cohort_start_date and cohort_end_date, respectively.
# starDay of -9999 means any time prior to cohort.
# the covariate considers all descendant ids for those included concept ids.
covariateSettings26 <- createManualCovariateSetting(analysisId = 26,
                                                    covariateName = "Prior liver disease diagnosis (ICD10 K76.9)",
                                                    sql = "./src/sql/covariateSql/priorCondition.sql",
                                                    domainId = "Condition",
                                                    startDay = -9999,
                                                    endDay = 0,
                                                    includedConceptIds = c(194984))

# Covariate 27: Any prior obesity observation.
# starDay and endDay are added by cohort_start_date.
# starDay of -9999 means any time prior to cohort.
# the covariate considers all descendant ids for those included concept ids.
covariateSettings27 <- createManualCovariateSetting(analysisId = 27,
                                                    covariateName = "Any prior obesity observation (binary)",
                                                    sql = "./src/sql/covariateSql/priorObservation.sql",
                                                    domainId = "Observation",
                                                    startDay = -365,
                                                    endDay = 0,
                                                    includedConceptIds = c(4215968))


# Covariate 28: Prior last ALT value U/L.
# starDay and endDay are added by cohort_start_date
covariateSettings28 <- createManualCovariateSetting(analysisId = 28,
                                                   covariateName = "Prior last ALT value U/L using LOINC group codes LG5272-2 and LP382703-9",
                                                   sql = "./src/sql/covariateSql/lft.sql",
                                                   domainId = "Measurment",
                                                   startDay = -9999,
                                                   endDay = 0,
                                                   includedConceptIds = c(40652525, 37047736))

# Covariate 29: Prior last ALT days from cohort start.
# starDay and endDay are added by cohort_start_date
covariateSettings29 <- createManualCovariateSetting(analysisId = 29,
                                                    covariateName = "Prior last ALT days from cohort start using LOINC group codes LG5272-2 and LP382703-9",
                                                    sql = "./src/sql/covariateSql/lft.sql",
                                                    domainId = "Measurment",
                                                    startDay = -9999,
                                                    endDay = -9999,
                                                    includedConceptIds = c(40652525, 37047736))


# Covariate 30: Prior last AST value U/L.
# starDay and endDay are added by cohort_start_date
covariateSettings30 <- createManualCovariateSetting(analysisId = 30,
                                                    covariateName = "Prior last AST value U/L using LOINC group codes LG6033-7 and LP382836-7",
                                                    sql = "./src/sql/covariateSql/lft.sql",
                                                    domainId = "Measurment",
                                                    startDay = -9999,
                                                    endDay = 0,
                                                    includedConceptIds = c(40652640, 37059000))

# Covariate 31: Prior last AST days from cohort start.
# starDay and endDay are added by cohort_start_date
covariateSettings31 <- createManualCovariateSetting(analysisId = 31,
                                                    covariateName = "Prior last AST days from cohort start using LOINC group codes LG6033-7 and LP382836-7",
                                                    sql = "./src/sql/covariateSql/lft.sql",
                                                    domainId = "Measurment",
                                                    startDay = -9999,
                                                    endDay = -9999,
                                                    includedConceptIds = c(40652640, 37059000))


# Covariate -30: the number of prior opioid exposure.
# starDay and endDay are added by cohort_start_date.
# starDay of -9999 means any time prior to cohort.
# includedConceptIds shoud be ingredient ids because the covariate considers all descendant ids for those ingredient concept ids.
covariateSettings_30 <- createManualCovariateSetting(analysisId = -30,
                                                    covariateName = "Prior opioid use from -365 days to -31 days (binary)",
                                                    sql = "./src/sql/covariateSql/priorIngredientDrugUse.sql",
                                                    domainId = "Drug",
                                                    startDay = -365,
                                                    endDay = -31,
                                                    includedConceptIds = c(1103314, 1124957, 1110410, 1103640, 1102527, 1126658, 1174888, 1154029, 1201620)
                                                    )

# Covariate -10: 30-day prior opioid exposure.
# starDay and endDay are added by cohort_start_date.
# starDay of -9999 means any time prior to cohort.
# includedConceptIds shoud be ingredient ids because the covariate considers all descendant ids for those ingredient concept ids.
covariateSettings_10 <- createManualCovariateSetting(analysisId = -10,
                                                     covariateName = "Prior opioid use from -30 days to -1 days of admission date (binary)",
                                                     sql = "./src/sql/covariateSql/priorIngredientDrugUse.sql",
                                                     domainId = "Drug",
                                                     startDay = -30,
                                                     endDay = -1,
                                                     includedConceptIds = c(1103314, 1124957, 1110410, 1103640, 1102527, 1126658, 1174888, 1154029, 1201620)
)

# Covariate 0: Opioid exposure between cohort start and end dates.
# starDay and endDay are added by cohort_start_date and cohort_end_date, respectively.
covariateSettings0 <- createManualCovariateSetting(analysisId = 0,
                                                   covariateName = "Inpatient opioid use (binary)",
                                                   sql = "./src/sql/covariateSql/inpatientDrugUse.sql",
                                                   domainId = "Drug",
                                                   startDay = 0,
                                                   endDay = 0,
                                                   includedConceptIds = c(1103314, 1124957, 1110410, 1103640, 1102527, 1126658, 1174888, 1154029, 1201620))


# Covariate 90: Opioid exposure after cohort end date.
# starDay and endDay are added by cohort_end_date respectively.
covariateSettings90 <- createManualCovariateSetting(analysisId = 90,
                                                   covariateName = "Outpatient opioid use from 2 days to 90 days after discharge (binary)",
                                                   sql = "./src/sql/covariateSql/outpatientOpioidUse.sql",
                                                   domainId = "Drug",
                                                   startDay = 2,
                                                   endDay = 90)

# Covariate 91: Discharge opioid use.
# starDay and endDay are added by cohort_end_date respectively.
covariateSettings91 <- createManualCovariateSetting(analysisId = 91,
                                                    covariateName = "Discharge opioid use (binary)",
                                                    sql = "./src/sql/covariateSql/dischargeOpioidUse.sql",
                                                    domainId = "Drug",
                                                    startDay = -1,
                                                    endDay = 1)

# Covariate 92: the number of opioid exposure after discharge without discharge prescription.
# starDay and endDay are not used.
# covariateSettings91 <- createManualCovariateSetting(analysisId = 92,
#                                                     covariateName = "After discharge opioid use without discharge rx",
#                                                     sql = "./src/sql/covariateSql/dischargeOpioidUse2.sql",
#                                                     domainId = "Drug",
#                                                     startDay = 1,
#                                                     endDay = 90)


# Covariate 365: Opioid exposure after cohort end date.
# starDay and endDay are added by cohort_end_date respectively.
covariateSettings365 <- createManualCovariateSetting(analysisId = 365,
                                                     covariateName = "Prolonged opioid use until a year (binary)",
                                                     sql = "./src/sql/covariateSql/outpatientOpioidUse.sql",
                                                     domainId = "Drug",
                                                     startDay = 91,
                                                     endDay = 365)


covariateSettingsReadmision <- createManualCovariateSetting(analysisId = 100,
                                                     covariateName = "30-day readmision after discharge (binary)",
                                                     sql = "./src/sql/covariateSql/readmissionOutcome.sql",
                                                     domainId = "Visit",
                                                     startDay = 1,
                                                     endDay = 30)


covariateSettingsAdverse <- createManualCovariateSetting(analysisId = 101,
                                                            covariateName = "Opioid adverse outcome within 1 day to 365 days after discharge (binary)",
                                                            sql = "./src/sql/covariateSql/postConditionOutcome.sql",
                                                            domainId = "Condition",
                                                            startDay = 1,
                                                            endDay = 365,
                                                            includedConceptIds = c(606805, 439223, 437158, 4230779, 4032799, 438120, 438130, 4099935))

covariateSettingsChronic <- createManualCovariateSetting(analysisId = 102,
                                                     covariateName = "Chronic pain outcome within 90 days to 365 days after discharge (binary)",
                                                     sql = "./src/sql/covariateSql/postConditionOutcome.sql",
                                                     domainId = "Condition",
                                                     startDay = 91,
                                                     endDay = 365,
                                                     includedConceptIds = c(436096))

connection <- connect(connectionDetails)

covariateData <- FeatureExtraction::getDbCovariateData(connection = connection,
                                    cdmDatabaseSchema = cdmDatabaseSchema,
                                    cohortDatabaseSchema = targetDatabaseSchema,
                                    cohortTable = cohortTable,
                                    cohortId = cohortId,
                                    rowIdField = "subject_id",
                                    covariateSettings = list(
                                      covariateSettingsDemo,
                                      covariateSettingsCCI,
                                      covariateSettings1,
                                      covariateSettings2,
                                      covariateSettings3,
                                      covariateSettings4,
                                      covariateSettings5,
                                      covariateSettings6,
                                      covariateSettings7,
                                      covariateSettings8,
                                      covariateSettings9,
                                      covariateSettings10,
                                      covariateSettings11,
                                      covariateSettings12,
                                      covariateSettings13,
                                      covariateSettings14,
                                      covariateSettings15,
                                      covariateSettings16,
                                      covariateSettings17,
                                      covariateSettings18,
                                      covariateSettings19,
                                      covariateSettings20,
                                      covariateSettings21,
                                      covariateSettings22,
                                      covariateSettings23,
                                      covariateSettings24,
                                      covariateSettings25,
                                      covariateSettings26,
                                      covariateSettings27,
                                      covariateSettings28,
                                      covariateSettings29,
                                      covariateSettings30,
                                      covariateSettings31,
                                      covariateSettings_30,
                                      covariateSettings_10,
                                      covariateSettings0,
                                      covariateSettings90,
                                      covariateSettings91,
                                      covariateSettings365,
                                      covariateSettingsReadmision,
                                      covariateSettingsAdverse,
                                      covariateSettingsChronic))
# covariateSettings91,
# covariateSettings90,
# covariateSettings4,
# covariateSettings5,
# covariateSettings16


# covariateSettingsDemo,
# covariateSettingsCCI,
# covariateSettings1,
# covariateSettings2,
# covariateSettings3,
# covariateSettings4,
# covariateSettings5,
# covariateSettings6,
# covariateSettings7,
# covariateSettings8,
# covariateSettings9,
# covariateSettings10,
# covariateSettings11,
# covariateSettings12,
# covariateSettings13,
# covariateSettings14,
# covariateSettings15,
# covariateSettings16,
# covariateSettings17,
# covariateSettings18,
# covariateSettings30,
# covariateSettings0,
# covariateSettings90,
# covariateSettings365,
# covariateSettingsReadmision,
# covariateSettingsAdverse,
# covariateSettingsChronic

dataset = generateInputatMatrix(covariateData)
#write.csv(dataset, file = "./results/covariateData.csv", row.names = T)

Andromeda::saveAndromeda(covariateData, fileName = "./results/covariateData_V2")
covariateData <- Andromeda::loadAndromeda("./results/covariateData_V2")

disconnect(connection)



