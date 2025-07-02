
createCohortTableQuery <- function() {
  sql <- "
          CREATE TABLE IF NOT EXISTS @target_database_schema.@target_cohort_table (
            cohort_definition_id INT,
            subject_id INT,
            cohort_start_date DATE,
            cohort_end_date DATE
          );
  "
  renderedSql = render(
    sql = sql,
    target_database_schema = targetDatabaseSchema,
    target_cohort_table = cohortTable
  )
  query <- translate(renderedSql, targetDialect = dbms)
  connection <- connect(connectionDetails)
  executeSql(connection, query)
  disconnect(connection = connection)
}


generateTargetCohort <- function(targetSql = "./src/sql/target-cohort.sql") {
  # The edited cohort maintains two additional tables (includedEvents and inclusionEvents)
  #sql <-readSql("./src/sql/edited-target-cohort.sql")
  sql <-readSql(targetSql)
  renderedSql <- render(
                      sql = sql,
                      vocabulary_database_schema = vocabularyDatabaseSchema,
                      cdm_database_schema = cdmDatabaseSchema,
                      target_database_schema = targetDatabaseSchema,
                      target_cohort_table = cohortTable,
                      target_cohort_id = cohortId
                    )
  query <- translate(renderedSql, targetDialect = dbms)
  connection <- connect(connectionDetails)
  executeSql(connection, query)
  disconnect(connection = connection)
}


generateOutcomeCohort <- function(outcomeSql = "./src/sql/pou-outcome-cohort.sql", outcomeId = 2){
  sql <-readSql(outcomeSql)
  renderedSql <- render(
    sql = sql,
    vocabulary_database_schema = vocabularyDatabaseSchema,
    cdm_database_schema = cdmDatabaseSchema,
    target_database_schema = targetDatabaseSchema,
    target_cohort_table = cohortTable,
    target_cohort_id = cohortId,
    outcome_cohort_id = outcomeId
  )
  query <- translate(renderedSql, targetDialect = dbms)
  connection <- connect(connectionDetails)
  executeSql(connection, query)
  disconnect(connection = connection)
}




