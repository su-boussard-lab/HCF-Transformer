library(SqlRender)
library(DatabaseConnector)
library(FeatureExtraction)
library(Andromeda)
source("./src/generateCohorts.R")
source("./src/defineFeatures.R")
source("./src/transformCovariateData.R")


vocabularyDatabaseSchema <- "ORD_Curtin_202003006D.OMOPV5"
cdmDatabaseSchema <- "ORD_Curtin_202003006D.OMOPV5"
targetDatabaseSchema <- "ORD_Curtin_202003006D.porpoise"
cohortTable = "cohort_opioid_treatment"
cohortId <- 1
dbms = 'sql server'


getSqlServerConnectionDetails <- function(){
  driverPath <- 'P:\\ORD_Curtin_202003006D\\Behzad\\sqljdbc_10.2.3.0_enu\\sqljdbc_10.2\\enu'
  #driverPath <- 'P:\\ORD_Curtin_202003006D\\Behzad\\sqljdbc_11.2.0.0_enu\\sqljdbc_11.2\\enu'
  connectionString <- 'jdbc:sqlserver://vhacdwRB03.vha.med.va.gov;trustServerCertificate=true;encrypt=true;integratedSecurity=true'
  connectionDetails <- DatabaseConnector::createConnectionDetails(dbms="sql server",
                                                                  connectionString= connectionString,
                                                                  pathToDriver = driverPath)
  return(connectionDetails)
}


# Creates a connectionDetails object to connect to the VA SQL Server. This object will be used in the following functions.
connectionDetails <- getSqlServerConnectionDetails()

# Generates the surgical cohort in the VA database. Before running, ensure the connectionDetails object has been created.
generateTargetCohort(targetSql = "./src/sql/target-cohort-optimized.sql")

# Extracts all features and creates the project's overall data set in the format of an Andromeda object.
# Andromeda is an OHDSI package that manages storing and loading big data sets.
runFeatureExtraction(fileName = "./results/covariateData_V2")



