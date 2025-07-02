library(SqlRender)
library(DatabaseConnector)
library(FeatureExtraction)
library(Andromeda)
source("./src/generateCohorts.R")
source("./src/defineFeatures.R")
source("./src/transformCovariateData.R")

vocabularyDatabaseSchema <- "`som-rit-phi-starr-prod.starr_omop_cdm5_confidential_lite_2024_06_02`"
cdmDatabaseSchema <- "`som-rit-phi-starr-prod.starr_omop_cdm5_confidential_lite_2024_06_02`"
targetDatabaseSchema <- "`som-nero-phi-boussard.bn_opioid_treatment`"
dbms = 'bigquery'

cohortTable  <- "cohort20240602"
cohortId <- 11

cohortDatabaseSchemaTable <- paste(targetDatabaseSchema, cohortTable, sep = ".")

projectId = "som-nero-phi-boussard"
defaultDataset <- "bn_opioid_treatment"
credentials <- "/Users/behzadn/.config/gcloud/application_default_credentials.json"
driverPath <- "/Users/behzadn/SimbaJDBCDriverforGoogleBigQuery42_1.2.22.1026"

connectionString <- BQJdbcConnectionStringR::createBQConnectionString(projectId = projectId,
                                             defaultDataset = defaultDataset,
                                             authType = 2,
                                             jsonCredentialsPath = credentials)

connectionDetails <- DatabaseConnector::createConnectionDetails(dbms=dbms,
                                                                connectionString=connectionString,
                                                                user="",
                                                                password="",
                                                                pathToDriver = driverPath)



#-----run the feature extraction---------

#createCohortTableQuery()
generateTargetCohort(targetSql = "./src/sql/target-cohort-optimized.sql")
generateOutcomeCohort(outcomeSql = "./src/sql/pou-outcome-cohort.sql", outcomeId = 2)
generateOutcomeCohort(outcomeSql = "./src/sql/readmission-outcome-cohort.sql", outcomeId = 3)
generateOutcomeCohort(outcomeSql = "./src/sql/oao-outcome-cohort.sql", outcomeId = 4)
generateOutcomeCohort(outcomeSql = "./src/sql/chronic-pain-outcome-cohort.sql", outcomeId = 5)





