createSurgeyConceptSet <- function(){
  #Some of the source codes are classification codes, which are excluded when joining with relationship_id = 'Maps to'.
  #To keep classification codes, first find the corresponding concept ids for each of the codes, then join with relationship_id = 'Maps to'
  #If the mapped concept is null, the source code concept will be considered if it is standard or classification
  #The codes which were not mapped to any concepts were non-procedure, such as condition, drug, observation, geography, regimen, measurement, with irrelevant class ids, such as Genetic Variation 
  query = "
  CREATE OR REPLACE TABLE @target_database_schema.surgery_code_concept_ids AS 
    SELECT
      sgc.SurgeryType type, sgc.Vocabulary vocab, sgc.Code code,
      CASE WHEN (c2.concept_id IS NULL AND (sgc.standard_concept = 'C' OR sgc.standard_concept = 'S')) THEN sgc.concept_id ELSE c2.concept_id END AS standard_concept_id,
      CASE WHEN (c2.concept_id IS NULL AND (sgc.standard_concept = 'C' OR sgc.standard_concept = 'S')) THEN sgc.vocabulary_id ELSE c2.vocabulary_id END AS standard_vocabulary_id,
      CASE WHEN (c2.concept_id IS NULL AND (sgc.standard_concept = 'C' OR sgc.standard_concept = 'S')) THEN sgc.domain_id ELSE c2.domain_id END AS standard_domain_id,
      CASE WHEN (c2.concept_id IS NULL AND (sgc.standard_concept = 'C' OR sgc.standard_concept = 'S')) THEN sgc.standard_concept ELSE 'mapped to standard' END AS concept_type
    FROM
      @vocabulary_database_schema.concept c1
    JOIN @vocabulary_database_schema.concept_relationship cr
      ON cr.concept_id_1 = c1.concept_id AND cr.relationship_id = 'Maps to'
    JOIN @vocabulary_database_schema.concept c2
      ON cr.concept_id_2 = c2.concept_id
    Right JOIN (
      SELECT sgc.*, c1.concept_id, c1.domain_id, c1.vocabulary_id, c1.standard_concept FROM @vocabulary_database_schema.concept c1
      RIGHT JOIN @target_database_schema.surgery_codes sgc
        ON
          c1.concept_code = sgc.Code AND (c1.vocabulary_id like 'ICD9%' OR c1.vocabulary_id like 'ICD10%' OR c1.vocabulary_id like 'CPT%' OR c1.vocabulary_id = 'HCPCS')
          AND c1.domain_id = 'Procedure'
    ) sgc
      ON
    c1.concept_id = sgc.concept_id 
    AND c2.domain_id = 'Procedure' AND c2.standard_concept = 'S'
  "
  
  renderedSql <- SqlRender::render(
    sql = query,
    target_database_schema = targetDatabaseSchema,
    vocabulary_database_schema = vocabularyDatabaseSchema
  )
  
  sql <- SqlRender::translate(renderedSql, targetDialect = dbms)
  connection <- DatabaseConnector::connect(connectionDetails)
  res <- DatabaseConnector::executeSql(connection, sql)
  DatabaseConnector::disconnect(connection = connection)
}


createCancerConceptSet <- function(){
  # Generating malignancy_icd9
  # malignancy_icd9 <- paste0(as.character(c(140:209, 230:239)), "%")
  # Only ICD10 gives all the concepts
  
  # Generating malignancy_icd10
  malignancy_icd10 <- c("C00", "C01", "C02", "C03", "C04", "C05", "C06", "C07", "C08", "C09")
  malignancy_icd10 <- c(malignancy_icd10, paste0("C", 10:97))
  malignancy_icd10 <- c(malignancy_icd10, "C7A", "C7B")
  malignancy_icd10 <- paste0(malignancy_icd10, "%")
  
  #Find all standard concept ids for ICD9 and ICD10 diagnosis codes, excluding procedures, observations, and measurements.  
  query = paste0("
  CREATE OR REPLACE TABLE @target_database_schema.cancer_icd10_concept_ids AS 
    SELECT CAST(c2.concept_id as string) AS standard_concept_id,
        c2.concept_name AS standard_concept_name,
        c2.vocabulary_id AS standard_vocabulary_id,
        c2.domain_id AS standard_domain_id,
        c2.concept_code standard_concept_code,
        c1.concept_id source_concept_id, c1.concept_name source_concept_name, c1.concept_code source_concept_code, cancer.code_temp
    FROM @vocabulary_database_schema.concept c1
    JOIN @vocabulary_database_schema.concept_relationship cr
      ON cr.concept_id_1 = c1.concept_id AND cr.relationship_id = 'Maps to'
    JOIN @vocabulary_database_schema.concept c2
      ON cr.concept_id_2 = c2.concept_id
    RIGHT JOIN (
        SELECT * FROM UNNEST(['", paste0(malignancy_icd10, collapse="', '"), "']) as code_temp
    ) cancer
    ON
      c1.concept_code like cancer.code_temp AND c1.vocabulary_id like 'ICD10%'
      AND c1.domain_id = 'Condition' AND c2.domain_id = 'Condition' AND c2.standard_concept = 'S'
  ")
  
  renderedSql <- SqlRender::render(
    sql = query,
    target_database_schema = targetDatabaseSchema,
    vocabulary_database_schema = vocabularyDatabaseSchema
  )
  
  sql <- SqlRender::translate(renderedSql, targetDialect = dbms)
  connection <- DatabaseConnector::connect(connectionDetails)
  res <- DatabaseConnector::executeSql(connection, sql)
  DatabaseConnector::disconnect(connection = connection)
}


createOpioidAdverseOutcomeConceptSet <- function(){
  oao <- read.csv('./codes/opioid-adverse-outcome-codes.csv')
  
  #Find all standard concept ids for opioid adverse outcome ICD10 diagnosis codes  
  query = paste0("
  CREATE OR REPLACE TABLE @target_database_schema.oao_code_concept_ids AS 
    SELECT CAST(c2.concept_id as string) AS standard_concept_id,
        c2.concept_name AS standard_concept_name,
        c2.vocabulary_id AS standard_vocabulary_id,
        c2.domain_id AS standard_domain_id,
        c2.concept_code standard_concept_code,
        c1.concept_id source_concept_id, c1.concept_name source_concept_name, c1.concept_code source_concept_code
    FROM @vocabulary_database_schema.concept c1
    JOIN @vocabulary_database_schema.concept_relationship cr
      ON cr.concept_id_1 = c1.concept_id AND cr.relationship_id = 'Maps to'
    JOIN @vocabulary_database_schema.concept c2
      ON cr.concept_id_2 = c2.concept_id
    RIGHT JOIN (
        SELECT * FROM UNNEST(['", paste0(oao$Code, collapse="', '"), "']) as code
    ) oao
    ON
      c1.concept_code = oao.code AND c1.vocabulary_id like 'ICD10%'
      WHERE c2.standard_concept = 'S'
  ")
  
  renderedSql <- SqlRender::render(
    sql = query,
    target_database_schema = targetDatabaseSchema,
    vocabulary_database_schema = vocabularyDatabaseSchema
  )
  
  sql <- SqlRender::translate(renderedSql, targetDialect = dbms)
  connection <- DatabaseConnector::connect(connectionDetails)
  res <- DatabaseConnector::executeSql(connection, sql)
  DatabaseConnector::disconnect(connection = connection)
}




