<img src="boussardlab.png" width="50%" style="margin-right: 20px; margin-top: 10px;" />

----------------------------

# HCF-Transformer: A Hierarchical Clinical Fusion Transformer for Optimizing Post-Surgical Opioid Prescriptions

-----------------------------

In this study, we propose a novel predictive model that determines the most optimal discharge opioid regimen for each patient based on their personalized risk profile. Our model, built on a transformer-based architecture, first predicts four key postoperative risks for diabetes patients and then evaluates different opioid prescription scenarios to identify the option that minimizes overall risk. By comparing the model-identified optimal opioid to the actual prescribed opioid, we assess the degree of alignment between current clinical practice and optimal risk-based prescribing.

##### Project resourcese: 

- [Source of Data](): VHA OMOP (Surgical Cohort)
- [Surgery types and codes](): codes/surgery_codes_for_pull_fin.csv
- [Opioid-related adverse ouctome ICD codes](): codes/opioid-adverse-outcome-codes.csv

## Project workflow:
1. **Cohort selection:** Create the surgical cohort
2. **Feature extraction:** Define and extract all clinical features for the cohort patients and create the project data set
3. **Dataset analysis:** Analyze and create a data set for diabetes population 
4. **Model training:** Train HCF-Transformer algorithm along with other baseline models
5. **Model evaluation:** Evaluate the prediction performance of the models on the the test set
6. **Optimal opioid evaluation:** Evaluate all the discharge opioid choices to find the optimal one
7. **Optimal opioid analysis:** Analyze the results and generate plots.

## Getting started

All the source codes are available in `src` folder. It includes R files and two sub-folders for SQL and Python codes.

- The workflow stages 1, 2, 3, and 7 have been developed by R (located `src`)
- The workflow stages 4, 5, and 6 have been developed by Python (located in `src > py`)

### Requirements
To clone and run this project, you will need:

R packages:

- R version >= 4.1.3
- SqlRender
- DatabaseConnector
- FeatureExtraction
- Andromeda


Python packages:

- Python version 3.11
- PyTorch 2.3.0
- scikit-learn 1.5.0


### 1. Cohort selection 
To create the cohort on the VHA SQL Server database, first run the `getSqlServerConnectionDetails` function to generate **connectionDetails** object and then run the `generateTargetCohort` function in the `runVA.R`. The both functions use OHDSI packages to create the cohort based on the SQL script located in `src > sql > target-cohort-optimized.sql`. 

The database connection details are available in the `runVA.R` file. It creates a surgical cohort without applying the last three criteria related to the diabetes population. Check out the MedWiki page for inclusion and exclusion criteria. By running the script, a cohort table named `cohort_opioid_treatment` will be generated in the database and all patients are stored by cohort_definition_id = 1.

### 2. Feature extraction
To create all the features and represent the cohort patients, first run the `getSqlServerConnectionDetails` function to create the *connectionDetails* object and then run the `runFeatureExtraction` function in the `runVA.R`.

It will creates the project's overall data set in the format of an Andromeda object in the `./results` directory. Andromeda is an OHDSI package that manages storing and loading big data sets.

**Please note that all the extracted features are based on OMOP concept ids and their feature names are not directly available. In the next stage, we will create a data set  with feature names.** 

### 3. Dataset analysis
Run all scripts in the `analyzeDataset2.R` file to create a data set for the diabetes population, applying the last three cohort criteria and replacing the feature names with feature ids. It will create a data set named `covariateData_DM_V2.csv` as well as Table 1 for all outcomes.

### 4. Model training
To train the HCF-Transformer model and other baseline models, run the `src > py > train.py`. It will train all models using `covariateData_DM_V2.csv` data set and save them under a directory named `outputs > models` 

### 5. Model evaluation:
After generating the trained models, run `src > py > evaluate.py` using the following load_split_data method: 
```
data_dic = load_split_data('covariateData_DM_V2.csv', is_expanded_test=False)
```

It will load the trained models and evaluate them on the test set and generate ROC plots (under directory `outputs/plot/`) as well as prediction outputs (under directory `outputs/csv/`).

### 6. Optimal opioid evaluation:
To evaluate optimal discharge, run `src > py > evaluate.py` using the following load_split_data method

```
data_dic = load_split_data('covariateData_DM_V2.csv', is_expanded_test=True)
```
By setting `is_expanded_test=True`, synthetic discharge opioid choices are generated for each patient data in the test set. Given 6 discharge opioid choices, a 7 x 6 matrix is created. While the first row is all zero, indicating the non-opioid treatment choice, the others generate a 6 x 6 identity matrix, each row indicating one opioid choice. Among all 7 choices, one is related to the actual opioid choice which was taken at the time of discharge, and others are synthetic data for evaluation.

Before running this stage,  you may want to move the previous prediction output files, which you created in the previous stage. Otherwise they will be overwritten by the expanded test set outputs.

### 7. Optimal opioid analysis:
After running Stage 6, the model prediction outputs are generated in for expanded test in the `outputs/csv/` directory. To analyze and plot the optimal discharge opioids, run all the script in `analyzeOptimalOpioid.R` 

## License
HCF-Transformer is licensed under Apache License 2.0.

## Support
Please contact Dr. Naderalvojoud at behzad@stanford.edu














