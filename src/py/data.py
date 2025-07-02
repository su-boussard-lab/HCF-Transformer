import torch
import numpy as np
import pandas as pd
from torch.utils.data import Dataset
from sklearn.preprocessing import StandardScaler
from sklearn.model_selection import train_test_split

SEED = 13


class TabularDataset(Dataset):
    def __init__(self, dataset, label, scaler: StandardScaler = None):
        self.dataset = dataset
        self.pat_ids = dataset.index.to_numpy()
        self.feature_names = list(dataset.columns)
        self.label = label.to_numpy()
        if scaler is None:
            self.scaler = StandardScaler()
        else:
            self.scaler = scaler

    def __len__(self):
        return len(self.label)

    def __getitem__(self, idx):
        x = self.dataset[idx]
        y = self.label[idx]
        return torch.tensor(x, dtype=torch.float32), torch.tensor(y, dtype=torch.long)

    def scale_fit_transform(self):
        self.dataset = self.dataset.to_numpy()
        return
        if not hasattr(self.scaler, "n_features_in_"):
            self.dataset = self.scaler.fit_transform(self.dataset)
        else:
            print('Warning: The scaler has been already fitted!')

    def scale_transform(self):
        self.dataset = self.dataset.to_numpy()
        return
        if hasattr(self.scaler, "n_features_in_"):
            self.dataset = self.scaler.transform(self.dataset)
        else:
            raise AttributeError('The scaler is not already fitted!')

    def get_num_class(self):
        return self.label.shape[1]


def load_split_data(csv_file, is_expanded_test=False):
    print("Reading the dataset csv file ...")
    dataset = pd.read_csv(csv_file, index_col=0)

    # Set covariate names
    gender = list(dataset.columns[dataset.columns.str.startswith("Gender_")])
    race = list(dataset.columns[dataset.columns.str.startswith("Race_")])
    ethinicity = list(dataset.columns[dataset.columns.str.startswith("Ethnicity_")])

    # Numeric covarites
    age_cci = ["Age", "CCI"]
    utilization = ["HP_2", "ER_3"]
    priorityValue = ["PriorityGroupNorm_34"]
    ast_alt_ratio_a1c = ["LFT_Ratio_32", "A1C_4"]

    # Binary covariates 
    surgeryType = list(dataset.columns[dataset.columns.str.startswith("SurgeryType_")])
    dx_7_15 = ["NerveDisorder_7", "Cancer_15"]
    psycho_11_14 = ["Tobacco_11", "Alcohol_12", "Anxiety_13", "Depression_14"] #"Obesity_27"
    dx_17_18 = ["PriorChronicPain_17", "PriorOAO_18"]
    dx_19_26 = ["Hypertension_19", "Neuropathy_20", "Retinopathy_22", "COPD_23", "LipidDisorder_24", "ThyroidDisorder_25", "LiverDisorder_26"] # "Nephropathy_21" was deleted due to low incidence 
    
    dx = surgeryType + dx_7_15 + psycho_11_14 + dx_17_18 + dx_19_26

    gabapentin = ["Gabapentin_Prior_8", "Gabapentin_PreOp_9", "Gabapentin_Inpatient_10"]
    anyOpioid = ["AnyOpioid_Prior_30", "AnyOpioid_PreOp_10", "AnyOpioid_Inpatient_0", "AnyOpioid_Discharge_91"]
    priorOpioid = list(dataset.columns[dataset.columns.str.endswith("_Prior_30") & ~dataset.columns.str.startswith("AnyOpioid")])
    preOpOpioid = list(dataset.columns[dataset.columns.str.endswith("_PreOp_10") & ~dataset.columns.str.startswith("AnyOpioid")])
    inpatientOpioid = list(dataset.columns[dataset.columns.str.endswith("_Inpatient_0") & ~dataset.columns.str.startswith("AnyOpioid")])
    dischargeOpioid = list(dataset.columns[dataset.columns.str.endswith("_Discharge_91") & ~dataset.columns.str.startswith("AnyOpioid")])
    rx = gabapentin + anyOpioid + priorOpioid + preOpOpioid + inpatientOpioid + dischargeOpioid


    # Create a fixed time step feature with patient characterristics as a embedding diemnsion of 11 
    # all time steps include 11 features as embedding dimension
    demo = age_cci + utilization + priorityValue + ast_alt_ratio_a1c + psycho_11_14
    dx_prior = dx_7_15 + dx_19_26 + dx_17_18
    rx_prior = ["Gabapentin_Prior_8"] + list(dataset.columns[dataset.columns.str.endswith("_Prior_30")])
    rx_pre_op = ["Gabapentin_PreOp_9"] + list(dataset.columns[dataset.columns.str.endswith("_PreOp_10")])
    rx_inpatient = ["Gabapentin_Inpatient_10"] + list(dataset.columns[dataset.columns.str.endswith("_Inpatient_0")])
    opioid_discharge = ["Oxycodone_Discharge_91", "Hydrocodone_Discharge_91", "Morphine_Discharge_91", "Tramadol_Discharge_91", "Hydromorphone_Discharge_91", "Codeine_Discharge_91"]


    # create training instances X and output instances Y
    trainingOutputs = ["POU_Outcome", "Readmission_Outcome",  "ChronicPain_Outcome", "OAO_Outcome"]

    #X = dataset[age_cci + utilization + priorityValue + ast_alt_ratio_a1c + rx + dx]
    X = dataset[opioid_discharge + surgeryType + demo + dx_prior + rx_prior + rx_pre_op + rx_inpatient]
    Y = dataset[trainingOutputs]

    # Split the data
    print("Split dataset to train, val, and test sets ...")
    X_train, X_test, Y_train, Y_test = train_test_split(X, Y, test_size=0.2, random_state=SEED)
    X_train, X_val, Y_train, Y_val = train_test_split(X_train, Y_train, test_size=0.1, random_state=SEED)

    print(f'train dim: {X_train.shape}, val dim: {X_val.shape}, test dim: {X_test.shape}')

    # Generate datasets and normalize it
    train_dataset = TabularDataset(X_train, Y_train)
    train_dataset.scale_fit_transform()

    val_dataset = TabularDataset(X_val, Y_val, scaler=train_dataset.scaler)
    val_dataset.scale_transform()

    if is_expanded_test:
        X_test, Y_test = expand_testset(X_test, Y_test)
    
    test_dataset = TabularDataset(X_test, Y_test, scaler=train_dataset.scaler)
    test_dataset.scale_transform()

    return {'train': train_dataset,
            'val': val_dataset,
            'test': test_dataset}


# This adds duplicated test patients with different combination of 6 discharge opioids
def expand_testset(df_x_test, df_y_test):
    first_six_dis_op = df_x_test.iloc[:, :6]
    rest_fe = df_x_test.iloc[:, 6:]

    # Generate 7 discharge opioid options: All zero or one used
    identity_matrix = np.eye(6, dtype=int)
    zero_row = np.zeros((1, 6), dtype=int)
    identity_matrix = np.vstack((zero_row, identity_matrix))

    expanded_x = []
    expanded_y = []
    expanded_patient_ids = []

    for (idx1, first_six_cols), (idx2, rest_cols) in zip(first_six_dis_op.iterrows(), rest_fe.iterrows()):
        first_six_cols = first_six_cols.values
        rest_cols = rest_cols.values
        repeated_rest_cols = np.tile(rest_cols, (7, 1))
        new_rows = np.hstack((identity_matrix, repeated_rest_cols))
        original_row = np.hstack((first_six_cols, rest_cols))

        repeated_x = np.vstack((original_row, new_rows))
        repeated_y = np.tile(df_y_test.loc[idx1], (8, 1))

        expanded_x.extend(repeated_x)
        expanded_y.extend(repeated_y)

        # expanded_patient_ids.extend([df_x_test.index[idx]] * 8)
        new_ids = [f"{idx1}_{i}" for i in range(1, 9)]
        expanded_patient_ids.extend(new_ids)

    expanded_x = np.vstack(expanded_x)
    expanded_y = np.vstack(expanded_y)
    expanded_x_df = pd.DataFrame(expanded_x, columns=df_x_test.columns, index=expanded_patient_ids)
    expanded_y_df = pd.DataFrame(expanded_y, columns=df_y_test.columns, index=expanded_patient_ids)
    
    return expanded_x_df, expanded_y_df



