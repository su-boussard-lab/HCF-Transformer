source("./src/a1cAnalysis.R")


render.cont <- function(x) {
  with(table1::stats.apply.rounding(table1::stats.default(x), digits=2), c("", "Mean (SD)"=sprintf("%s (&plusmn; %s)", MEAN, SD)))
}

render.iqr <- function(x){
  stats <- summary(x)
  avg <- mean(x)
  sdev <- sd(x)
  result <- c("", " Median (1st Qu, 3rd Qu) Mean(SD)" = sprintf("%.2f (%.2f, %.2f) %.2f (%.2f)", stats["Median"], stats["1st Qu."], stats["3rd Qu."], avg, sdev))
  return(result)
}


pvalue <- function(x, ...) {
  # Construct vectors of data y, and groups (strata) g
  y <- unlist(x)
  g <- factor(rep(1:length(x), times=sapply(x, length)))
  if (is.numeric(y)) {
    # Numerical variable: Wilcoxon rank-sum test
    p <- wilcox.test(y ~ g)$p.value
  } else {
    # For categorical variables, perform a chi-squared test of independence
    p <- chisq.test(table(y, g))$p.value
  }
  # Format the p-value, using an HTML entity for the less-than sign.
  # The initial empty string places the output on the line below the variable label.
  c("", sub("<", "&lt;", format.pval(p, digits=3, eps=0.001)))
}


pvalue_function <- function(variable, outcome) {
  if (is.factor(variable)) {
    # Categorical variable: Chi-squared test
    tbl <- table(variable, outcome)
    p <- chisq.test(tbl)$p.value
  } else if (is.numeric(variable)) {
    # Numerical variable: Wilcoxon rank-sum test
    p <- wilcox.test(variable ~ outcome)$p.value
  } else {
    p <- NA
  }
  return(p)
}

convert2numeric <- function(df){
  row_names <- rownames(df)
  df <- as.data.frame(lapply(df, function(x) as.numeric(ifelse(is.na(x) | x=="", NA, x))))
  rownames(df) <- row_names
  return(df)
}


covariateData <- Andromeda::loadAndromeda("./results/covariateData_V2")
dataset <- generateInputatMatrix(covariateData)

priorityGroup <- read.csv(file = "./results/priority_group_res/cohortLastPriorityGroup.csv", header = T, row.names = 1, stringsAsFactors = F)
dataset <- merge(dataset, priorityGroup, all.x = TRUE, by="row.names")
rownames(dataset) <- dataset$Row.names
dataset <- dataset[-1]


a1cPerc_4 <- c('4')
a1cDay_5 <- c('5')
diabetes_16 <- c('16')
alt_28 <- c('28')
altDay_29 <- c('29')
ast_30 <- c('30')
astDay_31 <- c('31')
age_1002 <- c('1002')


## Missing values are only related to alt and ast [28-31] = 90,425



##-------------------------------

filteredDataset <- dataset[dataset[diabetes_16] == 1, ]
filteredDataset <- filteredDataset[filteredDataset[a1cDay_5] <= 183 & filteredDataset[a1cPerc_4] >= 0 & filteredDataset[a1cPerc_4] <= 20, ]

filteredDataset <- filteredDataset[!is.na(filteredDataset[astDay_31]) & !is.na(filteredDataset[ast_30]) & 
                                     !is.na(filteredDataset[altDay_29]) & !is.na(filteredDataset[alt_28]) & 
                                     filteredDataset[astDay_31] <= 183 & filteredDataset[ast_30] >= 0 & 
                                     filteredDataset[altDay_29] <= 183 & filteredDataset[alt_28] >= 0,]


filteredDataset <- filteredDataset[(filteredDataset[age_1002] >= 18) & (filteredDataset[age_1002] <= 89), ]

opioidConceptIdName <- list("1103314"="Tramadol", "1124957"="Oxycodone", "1110410"="Morphine", "1103640"="Methadone", "1102527"="Meperidine", "1126658"="Hydromorphone", "1174888"="Hydrocodone", "1154029"="Fentanyl", "1201620"="Codeine")

# Outpatient opioid use covariates
for(id in names(opioidConceptIdName)){
  covId <- as.character(as.numeric(id) * 10000 + 90)
  names(filteredDataset)[names(filteredDataset) == covId] <- paste0(opioidConceptIdName[[id]], "_Outpatient_90")
}
outcomeCovariate <-apply(filteredDataset[names(filteredDataset)[endsWith(names(filteredDataset), "_Outpatient_90")]], 1, sum)
outcomeCovariate[outcomeCovariate > 0] <- 1
filteredDataset['AnyOpioid_Outpatient_90'] <- outcomeCovariate


# Discharge opioid use covariates
for(id in names(opioidConceptIdName)){
  covId <- as.character(as.numeric(id) * 10000 + 91)
  names(filteredDataset)[names(filteredDataset) == covId] <- paste0(opioidConceptIdName[[id]], "_Discharge_91")
}
outcomeCovariate <-apply(filteredDataset[names(filteredDataset)[endsWith(names(filteredDataset), "_Discharge_91")]], 1, sum)
outcomeCovariate[outcomeCovariate > 0] <- 1
filteredDataset['AnyOpioid_Discharge_91'] <- outcomeCovariate


# Inpatient opioid use covariates
for(id in names(opioidConceptIdName)){
  covId <- as.character(as.numeric(id) * 10000 + 0)
  names(filteredDataset)[names(filteredDataset) == covId] <- paste0(opioidConceptIdName[[id]], "_Inpatient_0")
}
outcomeCovariate <-apply(filteredDataset[names(filteredDataset)[endsWith(names(filteredDataset), "_Inpatient_0")]], 1, sum)
outcomeCovariate[outcomeCovariate > 0] <- 1
filteredDataset['AnyOpioid_Inpatient_0'] <- outcomeCovariate


# Preoperative opioid use covariates
for(id in names(opioidConceptIdName)){
  covId <- as.character(as.numeric(id) * 10000 - 10)
  names(filteredDataset)[names(filteredDataset) == covId] <- paste0(opioidConceptIdName[[id]], "_PreOp_10")
}
outcomeCovariate <-apply(filteredDataset[names(filteredDataset)[endsWith(names(filteredDataset), "_PreOp_10")]], 1, sum)
outcomeCovariate[outcomeCovariate > 0] <- 1
filteredDataset['AnyOpioid_PreOp_10'] <- outcomeCovariate


# Prior opioid-exposed covariates
for(id in names(opioidConceptIdName)){
  covId <- as.character(as.numeric(id) * 10000 - 30)
  names(filteredDataset)[names(filteredDataset) == covId] <- paste0(opioidConceptIdName[[id]], "_Prior_30")
}
outcomeCovariate <-apply(filteredDataset[names(filteredDataset)[endsWith(names(filteredDataset), "_Prior_30")]], 1, sum)
outcomeCovariate[outcomeCovariate > 0] <- 1
filteredDataset['AnyOpioid_Prior_30'] <- outcomeCovariate


for(id in names(opioidConceptIdName)){
  covId <- as.character(as.numeric(id) * 10000 + 365)
  names(filteredDataset)[names(filteredDataset) == covId] <- paste0(opioidConceptIdName[[id]], "_POU_365")
}

# Demographic covariates
ageGroup1<- seq(from=15, to=85, by=5)
ageGroup2<- seq(from=19, to=89, by=5)
ageGroup <- paste0('AgeGroup_[',ageGroup1, '-', ageGroup2, ']')
ageGroupIds <- as.character(3:17 * 1000 + 3)
for(i in 1:15){
  names(filteredDataset)[names(filteredDataset) == ageGroupIds[i]] <- ageGroup[i]
}

# remove other age groups > 90
# These age groups should have any records with 1 value as they have already removed.
#sum(filteredDataset[names(filteredDataset)[endsWith(names(filteredDataset), "003")]])
filteredDataset <- filteredDataset[, -which(names(filteredDataset) %in% names(filteredDataset)[endsWith(names(filteredDataset), "003")])]



raceIdName <- list('8515004'='Asian', '8516004'='Black', '8657004'='AI_AN', '8527004'='White', '8557004'='Hawaiian')
for(id in names(raceIdName)){
  names(filteredDataset)[names(filteredDataset) == id] <- paste0("Race_", raceIdName[[id]])
}

ethnicityIdName <- list('38003564005'='Non_Hispanic', '38003563005'='Hispanic')
for(id in names(ethnicityIdName)){
  names(filteredDataset)[names(filteredDataset) == id] <- paste0("Ethnicity_", ethnicityIdName[[id]])
}

genderIdName <- list('8507001'='Male', '8532001'='Female')
for(id in names(genderIdName)){
  names(filteredDataset)[names(filteredDataset) == id] <- paste0("Gender_", genderIdName[[id]])
}



surgeryIdName <- list('10010001'= 'PartialExcBone', '10020001'= 'SpinalFusion', '10030001'= 'TreatFracDisHipFemur', '10040001'= 'TreatFracDisLowExtremity',
                      '10050001'= 'CABG', '10060001'= 'ColorecResect', '10070001'= 'Appendectomy', '10080001'= 'Cholecystectomy',
                      '10090001'= 'InguinHerniaRepair', '10100001'= 'HysterecAbVag' ,'10110001'= 'OophorectomyUniBi', '10120001'= 'Laminectomy',
                      '10130001'= 'KneeReplacement', '10140001'= 'Thoracotomy', '10150001'= 'Mastectomy', '10160001'= 'OtherHand',
                      '10170001'= 'DistalRadFrac', '10180001'= 'ExciLysisPeriAdhesions','10190001'= 'Prostatectomy')
for(id in names(surgeryIdName)){
  names(filteredDataset)[names(filteredDataset) == id] <- paste0("SurgeryType_", surgeryIdName[[id]])
}



names(filteredDataset)[names(filteredDataset) == "1002"] <- "Age"
names(filteredDataset)[names(filteredDataset) == "1901"] <- "CCI"

names(filteredDataset)[names(filteredDataset) == "2"] <- "HP_2"
names(filteredDataset)[names(filteredDataset) == "3"] <- "ER_3"
names(filteredDataset)[names(filteredDataset) == "4"] <- "A1C_4"
names(filteredDataset)[names(filteredDataset) == "5"] <- "A1CDay_5"
names(filteredDataset)[names(filteredDataset) == "6"] <- "SurgeryYear_6"
names(filteredDataset)[names(filteredDataset) == "7"] <- "NerveDisorder_7"
names(filteredDataset)[names(filteredDataset) == "7973990008"] <- "Gabapentin_Prior_8"
names(filteredDataset)[names(filteredDataset) == "7973990009"] <- "Gabapentin_PreOp_9"
names(filteredDataset)[names(filteredDataset) == "7973990010"] <- "Gabapentin_Inpatient_10"
names(filteredDataset)[names(filteredDataset) == "11"] <- "Tobacco_11"
names(filteredDataset)[names(filteredDataset) == "12"] <- "Alcohol_12"
names(filteredDataset)[names(filteredDataset) == "13"] <- "Anxiety_13"
names(filteredDataset)[names(filteredDataset) == "14"] <- "Depression_14"
names(filteredDataset)[names(filteredDataset) == "15"] <- "Cancer_15"
names(filteredDataset)[names(filteredDataset) == "16"] <- "Diabetes_16"
names(filteredDataset)[names(filteredDataset) == "17"] <- "PriorChronicPain_17"
names(filteredDataset)[names(filteredDataset) == "18"] <- "PriorOAO_18"
names(filteredDataset)[names(filteredDataset) == "19"] <- "Hypertension_19"
names(filteredDataset)[names(filteredDataset) == "20"] <- "Neuropathy_20"
names(filteredDataset)[names(filteredDataset) == "21"] <- "Nephropathy_21"
names(filteredDataset)[names(filteredDataset) == "22"] <- "Retinopathy_22"
names(filteredDataset)[names(filteredDataset) == "23"] <- "COPD_23"
names(filteredDataset)[names(filteredDataset) == "24"] <- "LipidDisorder_24"
names(filteredDataset)[names(filteredDataset) == "25"] <- "ThyroidDisorder_25"
names(filteredDataset)[names(filteredDataset) == "26"] <- "LiverDisorder_26"
names(filteredDataset)[names(filteredDataset) == "27"] <- "Obesity_27"
names(filteredDataset)[names(filteredDataset) == "28"] <- "ALT_28"
names(filteredDataset)[names(filteredDataset) == "29"] <- "ALT_Day_29"
names(filteredDataset)[names(filteredDataset) == "30"] <- "AST_30"
names(filteredDataset)[names(filteredDataset) == "31"] <- "AST_Day_31"
filteredDataset["LFT_Ratio_32"] <- filteredDataset$AST_30 / filteredDataset$ALT_28
names(filteredDataset)[names(filteredDataset) == "priority"] <- "PriorityGroup_33"

# check priority group null values and set them (2570 patients) to the majority group (Group 1)
sum(is.na(filteredDataset$PriorityGroup_33))
filteredDataset$PriorityGroup_33[is.na(filteredDataset$PriorityGroup_33)] <- "GROUP 1"
filteredDataset['PriorityGroupNorm_34'] <- 1 / as.numeric(substr(filteredDataset$PriorityGroup_33, 7, nchar(filteredDataset$PriorityGroup_33)))

names(filteredDataset)[names(filteredDataset) == "100"] <- "Readmission_Outcome"
names(filteredDataset)[names(filteredDataset) == "101"] <- "OAO_Outcome"
names(filteredDataset)[names(filteredDataset) == "102"] <- "ChronicPain_Outcome"

outcomeCovariate <-apply(filteredDataset[names(filteredDataset)[endsWith(names(filteredDataset), "_POU_365")]], 1, sum)
outcomeCovariate[outcomeCovariate > 0] <- 1
filteredDataset['POU_Outcome'] <- outcomeCovariate




covNames <- names(filteredDataset)[startsWith(names(filteredDataset), "AgeGroup_")]
filteredDataset$AgeGroup <- covNames[max.col(filteredDataset[covNames], ties.method = "first")]

covNames <- names(filteredDataset)[startsWith(names(filteredDataset), "Race_")]
filteredDataset$Race <- covNames[max.col(filteredDataset[covNames], ties.method = "first")]

covNames <- names(filteredDataset)[startsWith(names(filteredDataset), "Gender_")]
filteredDataset$Gender <- covNames[max.col(filteredDataset[covNames], ties.method = "first")]

covNames <- names(filteredDataset)[startsWith(names(filteredDataset), "Ethnicity_")]
filteredDataset$Ethnicity <- covNames[max.col(filteredDataset[covNames], ties.method = "first")]

covNames <- names(filteredDataset)[startsWith(names(filteredDataset), "SurgeryType_")]
filteredDataset$SurgeryType <- covNames[max.col(filteredDataset[covNames], ties.method = "first")]


# Dataset is ready for ML models
write.csv(filteredDataset, file = "./results/covariateData_DM_V2.csv", row.names = T)


# data set analysis (Table 1)
#getSummaryStats(filteredDataset, 'ALT_28')
#getSummaryStats(filteredDataset, 'AST_30')
#getSummaryStats(filteredDataset, 'LFT_Ratio_32')




filteredDataset$AnyOpioid_Prior_30 <- 
  factor(filteredDataset$AnyOpioid_Prior_30, 
         levels=c(0, 1),
         labels=c("Opioid-Naive", "Opioid-Exposed"))

filteredDataset$AnyOpioid_Inpatient_0 <- 
  factor(filteredDataset$AnyOpioid_Inpatient_0, 
         levels=c(0, 1),
         labels=c("No", "Yes"))

filteredDataset$AnyOpioid_PreOp_10 <- 
  factor(filteredDataset$AnyOpioid_PreOp_10, 
         levels=c(0, 1),
         labels=c("No", "Yes"))

filteredDataset$AnyOpioid_Discharge_91 <- 
  factor(filteredDataset$AnyOpioid_Discharge_91, 
         levels=c(0, 1),
         labels=c("No", "Yes"))

filteredDataset$Gabapentin_Prior_8 <- 
  factor(filteredDataset$Gabapentin_Prior_8, 
         levels=c(0, 1),
         labels=c("No", "Yes"))

filteredDataset$Gabapentin_PreOp_9 <- 
  factor(filteredDataset$Gabapentin_PreOp_9, 
         levels=c(0, 1),
         labels=c("No", "Yes"))

filteredDataset$Gabapentin_Inpatient_10 <- 
  factor(filteredDataset$Gabapentin_Inpatient_10, 
         levels=c(0, 1),
         labels=c("No", "Yes"))

filteredDataset$POU_Outcome <- 
  factor(filteredDataset$POU_Outcome, 
         levels=c(0, 1),
         labels=c("Non-POU", "POU"))

filteredDataset$Readmission_Outcome <- 
  factor(filteredDataset$Readmission_Outcome, 
         levels=c(0, 1),
         labels=c("Non-30-Day-Readmission", "30-Day-Readmission"))

filteredDataset$OAO_Outcome<- 
  factor(filteredDataset$OAO_Outcome, 
         levels=c(0, 1),
         labels=c("Non-OAO", "OAO"))

filteredDataset$ChronicPain_Outcome <- 
  factor(filteredDataset$ChronicPain_Outcome, 
         levels=c(0, 1),
         labels=c("Non-Chronic-Pain", "Chronic-Pain"))


filteredDataset$Gender <- 
  factor(filteredDataset$Gender, 
         levels=c("Gender_Female", "Gender_Male"),
         labels=c("Female", "Male"))

filteredDataset$Race <- 
  factor(filteredDataset$Race, 
         levels=c('Race_White', 'Race_Asian', 'Race_Black', 'Race_AI_AN', 'Race_Hawaiian'),
         labels=c("White", "Asian", "Black", "AI/AN", "Hawaiian"))


filteredDataset$Ethnicity <- 
  factor(filteredDataset$Ethnicity, 
         levels=c('Ethnicity_Non_Hispanic', 'Ethnicity_Hispanic'),
         labels=c("Non-Hispanic", "Hispanic"))


surgColNames <- names(filteredDataset)[startsWith(names(filteredDataset), "SurgeryType_")]
filteredDataset$SurgeryType <- 
  factor(filteredDataset$SurgeryType, 
         levels=surgColNames,
         labels=substr(surgColNames, 13, nchar(surgColNames)))

for(surg in surgColNames){
  filteredDataset[surg] <- 
    factor(filteredDataset[surg], 
           levels=c(0, 1),
           labels=c("No", "Yes"))
}

filteredDataset$SurgeryYear_6 <- factor(filteredDataset$SurgeryYear_6)

filteredDataset$NerveDisorder_7 <- 
  factor(filteredDataset$NerveDisorder_7, 
         levels=c(0, 1),
         labels=c("No", "Yes"))

filteredDataset$Tobacco_11 <- 
  factor(filteredDataset$Tobacco_11, 
         
         levels=c(0, 1),
         labels=c("No", "Yes"))

filteredDataset$Alcohol_12 <- 
  factor(filteredDataset$Alcohol_12, 
         levels=c(0, 1),
         labels=c("No", "Yes"))


filteredDataset$Anxiety_13 <- 
  factor(filteredDataset$Anxiety_13, 
         levels=c(0, 1),
         labels=c("No", "Yes"))

filteredDataset$Depression_14 <- 
  factor(filteredDataset$Depression_14, 
         levels=c(0, 1),
         labels=c("No", "Yes"))

filteredDataset$Cancer_15 <- 
  factor(filteredDataset$Cancer_15, 
         levels=c(0, 1),
         labels=c("No", "Yes"))

filteredDataset$PriorChronicPain_17 <- 
  factor(filteredDataset$PriorChronicPain_17, 
         levels=c(0, 1),
         labels=c("No", "Yes"))

filteredDataset$PriorOAO_18 <- 
  factor(filteredDataset$PriorOAO_18, 
         levels=c(0, 1),
         labels=c("No", "Yes"))

filteredDataset$Hypertension_19 <- 
  factor(filteredDataset$Hypertension_19, 
         levels=c(0, 1),
         labels=c("No", "Yes"))


filteredDataset$Neuropathy_20 <- 
  factor(filteredDataset$Neuropathy_20, 
         levels=c(0, 1),
         labels=c("No", "Yes"))


filteredDataset$Nephropathy_21 <- 
  factor(filteredDataset$Nephropathy_21, 
         levels=c(0, 1),
         labels=c("No", "Yes"))


filteredDataset$Retinopathy_22 <- 
  factor(filteredDataset$Retinopathy_22, 
         levels=c(0, 1),
         labels=c("No", "Yes"))


filteredDataset$COPD_23 <- 
  factor(filteredDataset$COPD_23, 
         levels=c(0, 1),
         labels=c("No", "Yes"))


filteredDataset$LipidDisorder_24 <- 
  factor(filteredDataset$LipidDisorder_24, 
         levels=c(0, 1),
         labels=c("No", "Yes"))


filteredDataset$ThyroidDisorder_25 <- 
  factor(filteredDataset$ThyroidDisorder_25, 
         levels=c(0, 1),
         labels=c("No", "Yes"))


filteredDataset$LiverDisorder_26 <- 
  factor(filteredDataset$LiverDisorder_26, 
         levels=c(0, 1),
         labels=c("No", "Yes"))


filteredDataset$Obesity_27 <- 
  factor(filteredDataset$Obesity_27, 
         levels=c(0, 1),
         labels=c("No", "Yes"))


dir.create(file.path(getwd(), 'results/table1_V2'))
for (out in c('POU_Outcome', 'OAO_Outcome', 'ChronicPain_Outcome', 'Readmission_Outcome')) {
  print(paste0('The ', out, ' outcome is running ...'))
  table1_output <- table1::table1(~ Age + Gender + Race + Ethnicity + SurgeryType + SurgeryYear_6 + PriorityGroup_33 +  
                                    AnyOpioid_Prior_30 +  AnyOpioid_PreOp_10 + AnyOpioid_Inpatient_0 + AnyOpioid_Discharge_91 +
                                    Gabapentin_Prior_8 + Gabapentin_PreOp_9 + Gabapentin_Inpatient_10 + 
                                    PriorChronicPain_17 + PriorOAO_18 +
                                    Hypertension_19 + Neuropathy_20 + Nephropathy_21 + Retinopathy_22 + COPD_23 + LipidDisorder_24 + ThyroidDisorder_25 + LiverDisorder_26 +
                                    Cancer_15 + NerveDisorder_7 + 
                                    Obesity_27 + Tobacco_11 + Alcohol_12 + Anxiety_13 + Depression_14 + 
                                    HP_2 + ER_3 + PriorityGroupNorm_34 +
                                    CCI + A1C_4 + A1CDay_5 + ALT_28 + ALT_Day_29 + AST_30 + AST_Day_31 + LFT_Ratio_32 | eval(parse(text = out)),
                      data=filteredDataset, 
                      overall=F,
                      render.continuous=render.iqr, #render.cont
                      extra.col=list(`P-value`=pvalue)
                      )
  
  write(table1_output, paste0(getwd(), '/results/table1_V2/DM_cohort_', out, '.html'))
}




table1_output <- table1::table1(~ PriorityGroup_33 + ALT_28 + ALT_Day_29 + AST_30 + AST_Day_31 + LFT_Ratio_32 | POU_Outcome,
                                data=filteredDataset, 
                                overall=F,
                                render.continuous=render.iqr, #render.cont
                                extra.col=list(`P-value`=pvalue))

write(table1_output, paste0(getwd(), '/results/table1/Priority_LTF_DM_cohort_POU', '.html'))




# table 1 for age and individual surgeries
surgColNames <- names(filteredDataset)[startsWith(names(filteredDataset), "SurgeryType_")]
surg_formula <- paste(surgColNames, collapse = " + ")
surg_formula <- paste0('~ Age + ', surg_formula, '| POU_Outcome')

table1_output <- table1::table1(eval(parse(text = surg_formula)),
                                data=filteredDataset, 
                                overall=F,
                                render.continuous=render.iqr, #render.cont
                                extra.col=list(`P-value`=pvalue))

write(table1_output, paste0(getwd(), '/results/table1/ind_surg_pou', '.html'))




plotDensity(filteredDataset, covariate = 'lft_ratio', outcome = 'Oxycodone', bins = 30)
plotHistogram(filteredDataset, covariate = 'lft_ratio', outcome = 'POU', bins = 30, output='./results/lft-res/plots/LFTvsPOU.pdf')
plotHistogram(filteredDataset, covariate = 'lft_ratio', outcome = 'Oxycodone', bins = 30, output='./results/lft-res/plots/LFTvsOxy.pdf')
plotHistogram(filteredDataset, covariate = 'lft_ratio', outcome = 'Hydrocodone', bins = 30, output='./results/lft-res/plots/LFTvsHydro.pdf')

colSums(is.na(filteredDataset[c('alt_value', 'alt_day_from', 'ast_value', 'ast_day_from', 'POU')]))

