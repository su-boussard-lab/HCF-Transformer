library(dplyr)
library(ggplot2)
source("./src/circularPlot.R")
source("./src/anovaTest.R")

generateSampleData <- function(){
  main_ids <- 1:200
  sub_ids <- 1:8
  row_indices <- unlist(lapply(main_ids, function(id) paste(id, sub_ids, sep = "_")))
  
  # Generate binary values for columns
  x_data <- data.frame(
    Oxycodone_Discharge_91 = sample(c(0, 1), 1600, replace = TRUE),
    Hydrocodone_Discharge_91 = sample(c(0, 1), 1600, replace = TRUE),
    Morphine_Discharge_91 = sample(c(0, 1), 1600, replace = TRUE),
    Tramadol_Discharge_91 = sample(c(0, 1), 1600, replace = TRUE),
    Hydromorphone_Discharge_91 = sample(c(0, 1), 1600, replace = TRUE),
    Codeine_Discharge_91 = sample(c(0, 1), 160, replace = TRUE),
    SurgeryType = c( rep('A', 500), rep('B', 100), rep('C', 400), rep('D', 600)),
    SurgeryType_1 = sample(c(0, 1), 1600, replace = TRUE),
    SurgeryType_2 = sample(c(0, 1), 1600, replace = TRUE),
    SurgeryType_3 = sample(c(0, 1), 1600, replace = TRUE),
    SurgeryType_4 = sample(c(0, 1), 1600, replace = TRUE),
    SurgeryType_5 = sample(c(0, 1), 1600, replace = TRUE),
    SurgeryType_6 = sample(c(0, 1), 1600, replace = TRUE)
  )
  
  # Generate binary values for prediction outputs
  pred_data <- data.frame(
    POU = runif(1600, min = 0, max = 1),
    Readmission = runif(1600, min = 0, max = 1),
    CP = runif(1600, min = 0, max = 1),
    OAO = runif(1600, min = 0, max = 1)
  )
  
  rownames(x_data) <- row_indices
  rownames(pred_data) <- row_indices
  
  return(list(x_data = x_data, pred_data = pred_data))
}

#sampleData <- generateSampleData()
#x_data_df <- sampleData$x_data
#ml_output_df <- sampleData$pred_data

analyseOptimalOpioid <- function(mlOutputFilePath, modelName, modelThreshold) {
  
  #The CSV files exist in the VA Windows development workspace
  x_data_df <- read.csv(file = "./results/covariateData_DM_V2.csv", header = T, row.names = 1)
  ml_output_df <- read.csv(mlOutputFilePath, row.names = 1)
  
  
  opioid_discharge_col_names <- c("Oxycodone_Discharge_91", "Hydrocodone_Discharge_91", "Morphine_Discharge_91", "Tramadol_Discharge_91", "Hydromorphone_Discharge_91", "Codeine_Discharge_91")
  outcome_col_names <- c("POU_Outcome", "Readmission_Outcome",  "ChronicPain_Outcome", "OAO_Outcome")
  surgery_col_names <- names(x_data_df)[startsWith(names(x_data_df), "SurgeryType_")]
  physio_con_names <- c("Age", "CCI", "LFT_Ratio_32", "A1C_4", "HP_2", "ER_3", "Race", "Ethnicity")
  
  x_data_df <- x_data_df[c(opioid_discharge_col_names, surgery_col_names, c("SurgeryType"),physio_con_names, outcome_col_names)]
  
  x_data_df$dischOpCount <- apply(x_data_df[opioid_discharge_col_names], 1, sum)
  
  #x_data_df$actual_opu <- opioid_discharge_col_names[max.col(x_data_df[opioid_discharge_col_names], ties.method = "first")]
  x_data_df$actual_opu <- apply(x_data_df[opioid_discharge_col_names], 1, function(x){
    if (sum(x) == 0){
      return("Non-opioid")
    } else {
      return(opioid_discharge_col_names[max.col(matrix(x, nrow = 1), ties.method = "first")])
    }
  })
  
  x_data_df$actual_opu <- sub("_.*", "", x_data_df$actual_opu)
  
  x_data_df$SurgeryType <- sub("SurgeryType_", "", x_data_df$SurgeryType)
  
  x_data_df$SurgeryTypeCat <- x_data_df$SurgeryType
  x_data_df$SurgeryTypeCat <- sub('Appendectomy|ColorecResect|ExciLysisPeriAdhesions|InguinHerniaRepair|Cholecystectomy|HysterecAbVag|OophorectomyUniBi|Prostatectomy', 'Abd/Gyn/Uro', x_data_df$SurgeryTypeCat)
  x_data_df$SurgeryTypeCat <- sub('CABG|Thoracotomy', 'Cardiothoracic', x_data_df$SurgeryTypeCat)
  x_data_df$SurgeryTypeCat <- sub('DistalRadFrac|KneeReplacement|OtherHand|PartialExcBone|TreatFracDisHipFemur|TreatFracDisLowExtremity', 'Ortho/Plastics', x_data_df$SurgeryTypeCat)
  x_data_df$SurgeryTypeCat <- sub('SpinalFusion|Laminectomy', 'Neurosurgical', x_data_df$SurgeryTypeCat)
  x_data_df$SurgeryTypeCat <- sub('Mastectomy', 'Breast', x_data_df$SurgeryTypeCat)
  
  
  ml_output_df$pat_id = sub("_.*", "", rownames(ml_output_df))
  ml_output_df$row_id = rownames(ml_output_df)
  
  x_y_test <- merge(x_data_df, ml_output_df, all = FALSE, by.x="row.names", by.y = "pat_id")
  rownames(x_y_test) <- x_y_test$row_id
  x_y_test <- x_y_test[-1]
  
  
  # Extract the patient_id part of the rownames (before "_") and sub_id that indicates repeated x rows with different discharge opioid
  x_y_test <- x_y_test %>%
    mutate(
      pat_id = as.numeric(sub("_.*", "", rownames(x_y_test))),
      sub_id = as.numeric(sub(".*_", "", rownames(x_y_test))),
      #Optimal_Value = (4 - (POU + Readmission + CP + OAO)) / 4,
      #Optimal_Value = (POU/0.45) + (Readmission/0.1) + (CP/0.1) + (OAO/0.02),
      #Optimal_Value = (POU/0.304) + (Readmission/0.142) + (CP/0.21) + (OAO/0.135), # for HCF
      #Optimal_Value = (POU/0.358) + (Readmission/0.117) + (CP/0.178) + (OAO/0.129), # for RF
      Optimal_Value = (POU/modelThreshold$POU_T) + (Readmission/modelThreshold$Read_T) + (CP/modelThreshold$CP_T) + (OAO/modelThreshold$OAO_T),
      #Optimal_Value = (POU/modelThreshold$POU_T),
      sub_cat = case_when(
        sub_id == 1 ~ "Actual",
        sub_id == 2 ~ "Non-opioid",
        sub_id == 3 ~ "Oxycodone",
        sub_id == 4 ~ "Hydrocodone",
        sub_id == 5 ~ "Morphine",
        sub_id == 6 ~ "Tramadol",
        sub_id == 7 ~ "Hydromorphone",
        sub_id == 8 ~ "Codeine",
        TRUE ~ "unknown"),
      
      SurgeryTypeCode = case_when(
        SurgeryType == 'Appendectomy' ~ "S1",
        SurgeryType == 'ColorecResect' ~ "S2",
        SurgeryType == 'ExciLysisPeriAdhesions' ~ "S3",
        SurgeryType == 'InguinHerniaRepair' ~ "S4",
        SurgeryType == 'Cholecystectomy' ~ "S5",
        SurgeryType == 'HysterecAbVag' ~ "S6",
        SurgeryType == 'OophorectomyUniBi' ~ "S7",
        SurgeryType == 'Prostatectomy' ~ "S8",
        SurgeryType == 'CABG' ~ "S9",
        SurgeryType == 'Thoracotomy' ~ "S10",
        SurgeryType == 'DistalRadFrac' ~ "S11",
        SurgeryType == 'KneeReplacement' ~ "S12",
        SurgeryType == 'OtherHand' ~ "S13",
        SurgeryType == 'PartialExcBone' ~ "S14",
        SurgeryType == 'TreatFracDisHipFemur' ~ "S15",
        SurgeryType == 'TreatFracDisLowExtremity' ~ "S16",
        SurgeryType == 'SpinalFusion' ~ "S17",
        SurgeryType == 'Laminectomy' ~ "S18",
        SurgeryType == 'Mastectomy' ~ "S19",
        TRUE ~ "unknown"),
    ) %>%
    relocate(pat_id, sub_id, sub_cat, actual_opu, SurgeryType, SurgeryTypeCode, SurgeryTypeCat, Optimal_Value, .before = 1) %>%
    arrange(pat_id, sub_id)
  
  
  
  # Plot prediction distribution for each outcome
  # pred_df <- x_y_test[x_y_test$sub_id == 1,]
  # plotPredictionDistribution(pred_df, model_name = modelName, actual_outcome_col = "POU_Outcome", pred_col = "POU")
  # plotPredictionDistribution(pred_df, model_name = modelName, actual_outcome_col = "Readmission_Outcome", pred_col = "Readmission")
  # plotPredictionDistribution(pred_df, model_name = modelName, actual_outcome_col = "ChronicPain_Outcome", pred_col = "CP")
  # plotPredictionDistribution(pred_df, model_name = modelName, actual_outcome_col = "OAO_Outcome", pred_col = "OAO")
  # 
  
  # Calculate the average optimal value per groups and their ANOVA test p values
  
  x_y_test <- x_y_test[x_y_test$sub_id > 1, ]
  
  
  # x_y_test <- x_y_test %>%
  #   group_by(pat_id) %>% 
  #   mutate(
  #     actual_op_value = Optimal_Value[sub_cat == actual_opu]
  #   ) %>%
  #   mutate(
  #     relative_risk = Optimal_Value/actual_op_value,
  #     risk_value = Optimal_Value
  #   ) %>%
  #   relocate(relative_risk, actual_op_value, risk_value, .before = 8)
  # 
  # x_y_test$Optimal_Value = x_y_test$relative_risk
  
  
  opioid_grouped_df <- x_y_test %>% 
    group_by(actual_opu, sub_cat, sub_id) %>%
    summarise(
      avg_optimal_value = mean(Optimal_Value)
    ) %>% 
    arrange(actual_opu, sub_id)
  
  
  plotCircularChart(opioid_grouped_df, model_name = modelName)
  runAnova(x_y_test = x_y_test, main_groups_col = "actual_opu", model_name = modelName)

  
  
  
  # Calculate the difference between the actual and optimal values
  x_y_test <- x_y_test %>%
    group_by(pat_id) %>% 
    mutate(
      diff_min_actual = round(first(Optimal_Value[sub_cat == actual_opu], default = NA) - min(Optimal_Value), digits = 4),
      min_optimal_op = sub_cat[which.min(Optimal_Value)]
    ) %>%
    relocate(min_optimal_op, diff_min_actual, .before = 9)
  
  
  diff_optimal_df <- x_y_test %>%
    distinct(pat_id, SurgeryType, SurgeryTypeCode,SurgeryTypeCat, actual_opu, min_optimal_op, diff_min_actual)
  
  
  group_diff_optimal_df <- diff_optimal_df %>% 
    group_by(min_optimal_op, actual_opu) %>%
    summarise(
      cnt = n(),
      avg_diff = round(mean(diff_min_actual), digits = 5),
      std = round(sd(diff_min_actual), digits = 5),
      se = round(sd(diff_min_actual) / sqrt(n()), digits = 5),
      ci = round(sd(diff_min_actual) / sqrt(n()) * 1.96, digits = 5),
    ) %>% arrange(desc(cnt))
  
  
  write.csv(group_diff_optimal_df, paste("./results/V2/csv/optimalDifference", "overall", modelName, ".csv", sep = "_"), row.names = F)
  
  
  
  # Calculate the distribution of TRR in actual and optimal discharge opioids
  actual_trr_df <- x_y_test[x_y_test$sub_cat == x_y_test$actual_opu, ] %>%
    select(pat_id, actual_opu, min_optimal_op, Optimal_Value, Race, Ethnicity) %>%
    mutate(Opioid = "Actual")
  
  optimal_trr_df <- x_y_test[x_y_test$sub_cat == x_y_test$min_optimal_op, ] %>%
    select(pat_id, actual_opu, min_optimal_op, Optimal_Value, Race, Ethnicity) %>%
    mutate(Opioid = "Optimal")
  
  NonOpioid_trr_df <- x_y_test[x_y_test$sub_cat == 'Non-opioid', ] %>%
    select(pat_id, actual_opu, min_optimal_op, Optimal_Value, Race, Ethnicity) %>%
    mutate(Opioid = "Non-opioid")
  
  trr_df <- rbind(actual_trr_df, optimal_trr_df, NonOpioid_trr_df)
  
  plotTrrDistribution(trr_df, model_name = modelName, actual_outcome_col = "Opioid", pred_col = "Optimal_Value")
  
  #plotTrrDistribution(x_y_test, model_name = modelName, actual_outcome_col = "sub_cat", pred_col = "Optimal_Value")
  #plotTrrDistribution(actual_trr_df, model_name = modelName, actual_outcome_col = "Race", pred_col = "Optimal_Value")
  #plotTrrDistribution(optimal_trr_df, model_name = modelName, actual_outcome_col = "Race", pred_col = "Optimal_Value")
  #plotTrrDistribution(actual_trr_df, model_name = modelName, actual_outcome_col = "Ethnicity", pred_col = "Optimal_Value")
  #plotTrrDistribution(optimal_trr_df, model_name = modelName, actual_outcome_col = "Ethnicity", pred_col = "Optimal_Value")
  
  # calculate the population differences across optimal opioid treatments
  population_charac_df <- x_y_test %>%
    distinct(pat_id, actual_opu, min_optimal_op, Age, CCI, LFT_Ratio_32, A1C_4)
  
  colnames(population_charac_df) <- c("pat_id", "Actual_Opioid", "Optimal_Opioid", "Age", "CCI", "AST_ALT_Ratio", "A1C")
  
  op_population_charac_df <- population_charac_df %>%
    group_by(Optimal_Opioid) %>%
    summarise(
      cnt = n(),
      Age_Mean = round(mean(Age), digits = 2),
      Age_CI = round(sd(Age) / sqrt(n()) * 1.96, digits = 4),
      CCI_Mean = round(mean(CCI), digits = 4),
      CCI_CI = round(sd(CCI) / sqrt(n()) * 1.96, digits = 4),
      `AST/ALT Ratio_Mean` = round(mean(AST_ALT_Ratio), digits = 4),
      AST_ALT_Ratio_CI = round(sd(AST_ALT_Ratio) / sqrt(n()) * 1.96, digits = 4),
      A1C_Mean = round(mean(A1C), digits = 4),
      A1C_CI = round(sd(A1C) / sqrt(n()) * 1.96, digits = 4)
    )
  
  write.csv(op_population_charac_df, paste("./results/V2/csv/optimalOpioidCharacteristic", modelName, ".csv", sep = "_"), row.names = F)
  
  op_population_charac_df <- op_population_charac_df[op_population_charac_df$Optimal_Opioid != "Oxycodone", ]
  plotOptimalOpioidCharacteristic(op_population_charac_df, model_name = modelName)
  
  
  
  actual_op_population_charac_df <- population_charac_df %>%
    group_by(Actual_Opioid) %>%
    summarise(
      cnt = n(),
      Age_Mean = round(mean(Age), digits = 2),
      Age_CI = round(sd(Age) / sqrt(n()) * 1.96, digits = 4),
      CCI_Mean = round(mean(CCI), digits = 4),
      CCI_CI = round(sd(CCI) / sqrt(n()) * 1.96, digits = 4),
      `AST/ALT Ratio_Mean` = round(mean(AST_ALT_Ratio), digits = 4),
      AST_ALT_Ratio_CI = round(sd(AST_ALT_Ratio) / sqrt(n()) * 1.96, digits = 4),
      A1C_Mean = round(mean(A1C), digits = 4),
      A1C_CI = round(sd(A1C) / sqrt(n()) * 1.96, digits = 4)
    )
  
  write.csv(actual_op_population_charac_df, paste("./results/V2/csv/actualOpioidCharacteristic", modelName, ".csv", sep = "_"), row.names = F)
  
  
  
  # calculate the total risk (Optimal_value) vs numerical varibales
  risk_to_numeric_var_df <- x_y_test[x_y_test$sub_cat == x_y_test$actual_opu, ] %>%
    select(pat_id, actual_opu, min_optimal_op, Optimal_Value, CCI, LFT_Ratio_32, A1C_4)
  
  colnames(risk_to_numeric_var_df) <- c("pat_id", "actual_op", "optimal_op", "Total_Risk", "CCI", "AST_ALT_Ratio", "A1C")
  
  plotRiskLftScatter(risk_to_numeric_var_df, model_name = modelName)
}

threshold_HCF_Prev <- list(POU_T = 0.45, Read_T = 0.1, CP_T = 0.1, OAO_T = 0.02)
threshold_HCF <- list(POU_T = 0.304, Read_T = 0.142, CP_T = 0.21, OAO_T = 0.135)
threshold_RF <- list(POU_T = 0.358, Read_T = 0.117, CP_T = 0.178, OAO_T = 0.129)

csvDir <- 'P:/ORD_Curtin_202003006D/Behzad/opioid-treatment/opioid-treatment-nn/outputs/csv/V2-expanded-test-set/'
predFileName <- paste0(csvDir, 'rf_output_expanded_test_set_scores.csv')
analyseOptimalOpioid(predFileName, 'RF', threshold_RF)

predFileName <- paste0(csvDir, 'seqtransformer_output_expanded_test_set_scores.csv')
analyseOptimalOpioid(predFileName, 'HCFT', threshold_HCF)

predFileName <- paste0(csvDir, 'seqtransformer_output_expanded_test_set_scores.csv')
analyseOptimalOpioid(predFileName, 'HCFT_Prev_Threshold', threshold_HCF_Prev)


# modelNames <- c("seqtransformer", "bilstm", "rf", "xg")
# fileNames <- paste0(csvDir, modelNames, '_output_expanded_test_set_scores.csv')
# for (i in 1:4){
#   print(paste("The analysis was started for", modelNames[i], "outputs ..."))
#   analyseOptimalOpioid(fileNames[i], modelNames[i])
# }


