

createManualCovariateSetting <- function(analysisId = 1,
                                         covariateName = "Prior ER visit count",
                                         sql = "./src/sql/covariateSql/priorErCount.sql",
                                         domainId = "Visit",
                                         startDay = -9999,
                                         endDay = -30,
                                         isFirst = 1,
                                         includedConceptIds = NULL) {
  
  covariateSettings <- list(analysisId = analysisId,
                            sql = sql,
                            covariateName = covariateName,
                            domainId = domainId,
                            includedConceptIds = includedConceptIds,
                            startDay = startDay,
                            endDay = endDay,
                            isFirst= isFirst)
  
  attr(covariateSettings, "fun") <- "getDbManualCovariateData"
  class(covariateSettings) <- "covariateSettings"
  return(covariateSettings)
}



getDbManualCovariateData <- function(connection,
                                    oracleTempSchema = NULL,
                                    cdmDatabaseSchema,
                                    cohortDatabaseSchema,
                                    cohortTable,
                                    cohortId = 1,
                                    cdmVersion = "5",
                                    rowIdField = "subject_id",
                                    covariateSettings,
                                    aggregated = FALSE) {
  
  analysisId <- covariateSettings$analysisId
  covariateName <- covariateSettings$covariateName
  domainId <- covariateSettings$domainId
  startDay = covariateSettings$startDay
  endDay = covariateSettings$endDay
  includedConceptIds <- covariateSettings$includedConceptIds
  isFirst <- covariateSettings$isFirst
  
  
  writeLines(paste("Constructing", covariateName,  "covariates"))
  
  if (aggregated)
    stop("Aggregation not supported")

  sql <- readSql(covariateSettings$sql)
  
  if (is.null(includedConceptIds)){
    sql <- render(sql,
                  target_database_schema = targetDatabaseSchema,
                  cdm_database_schema = cdmDatabaseSchema,
                  cohort_table = cohortTable,
                  target_cohort_id = cohortId,
                  analysis_id = analysisId,
                  start_day = startDay,
                  end_day = endDay,
                  is_first = isFirst
    )
  } else {
    sql <- render(sql,
                  target_database_schema = targetDatabaseSchema,
                  cdm_database_schema = cdmDatabaseSchema,
                  cohort_table = cohortTable,
                  target_cohort_id = cohortId,
                  included_concept_ids = paste(includedConceptIds, collapse = ', '),
                  analysis_id = analysisId,
                  start_day = startDay,
                  end_day = endDay,
                  is_first = isFirst
    )
  }

  sql <- translate(sql = sql, targetDialect = dbms)

  # Retrieve the covariate:
  # covariates <- querySql(connection, sql)
  covariateData <- Andromeda::andromeda()
  DatabaseConnector::querySqlToAndromeda(connection = connection, 
                                         sql = sql, 
                                         andromeda = covariateData, 
                                         andromedaTableName = "covariates",
                                         snakeCaseToCamelCase = TRUE)
  
  covariates <- as.data.frame(covariateData$covariates)
  
  # Construct covariate reference:
  covariateRef <- data.frame(covariateId = unique(covariates$covariateId),
                             covariateName = covariateName,
                             analysisId = analysisId,
                             conceptId = (unique(covariates$covariateId) - analysisId) / 10000
                             )
  
  # Construct analysis reference:
  analysisRef <- data.frame(analysisId = analysisId,
                            analysisName = covariateName,
                            domainId = domainId,
                            startDay = covariateSettings$startDay,
                            endDay = covariateSettings$endDay,
                            isBinary = "N",
                            missingMeansZero = "Y")
  
  # Construct analysis reference:
  metaData <- list(sql = sql, call = match.call())
  result <- andromeda(covariates = covariates,
                      covariateRef = covariateRef,
                      analysisRef = analysisRef)
  
  attr(result, "metaData") <- metaData
  class(result) <- "CovariateData"
  return(result)
}




