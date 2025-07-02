import joblib

from data import *
import os
import torch.nn as nn
import pandas as pd
from torch.utils.data import DataLoader
from sklearn.metrics import roc_auc_score, average_precision_score
from data import *
from metric import *
from resnet import ResNet
from transformer import Transformer
from model import *

SEED = 13
BATCH = 32
NUM_EPOCH = 20

# Hyperparameters
d_embedding = 11 # 32
hidden_size = 64
n_head = 1 # 4
dim_feedforward = 512
num_layers = 1
dropout = 0.1
learningRate = 0.001
weightDecay = 1e-6


def get_best_model_name(model_dir, model_type='Transformer'):
    best_auc = 0.0
    best_model_name = None
    for filename in os.listdir(os.path.join(model_dir, model_type)):
        name_seg = filename.split('_')
        if name_seg[-1] == '.tar':
            model_auc = name_seg[-2]
            model_auc = float(model_auc)
            if model_auc > best_auc:
                best_model_name = filename
                best_auc = model_auc

    return best_model_name


def calculate_performance(y_true, y_pred_proba, model_type, result_df):
    all_scores = []
    all_str_scores = []
    for i in range(y_true.shape[1]):
        roc_auc = compute_ci(y_true[:, i], y_pred_proba[:, i], sklearn_metric=roc_auc_score)
        pr_auc = compute_ci(y_true[:, i], y_pred_proba[:, i], sklearn_metric=average_precision_score)
        all_scores.append([roc_auc + pr_auc])
        all_str_scores.append([f"{roc_auc[0]:.3f} ({roc_auc[1]:.3f}-{roc_auc[2]:.3f})",
                               f"{pr_auc[0]:.3f} ({pr_auc[1]:.3f}-{pr_auc[2]:.3f})"])
        print(
            f"ROC AUC Score for class {i}: {roc_auc[0]:.3f} ({roc_auc[1]:.3f}-{roc_auc[2]:.3f}) --- PR AUC Score for class {i}: {pr_auc[0]:.3f} ({pr_auc[1]:.3f}-{pr_auc[2]:.3f})")

    all_scores = np.array(all_scores)

    # Average ROC AUC score across all classes
    average_auc = np.mean(all_scores, axis=0)
    print(f"Average Scores: {average_auc}")

    all_str_scores.append([f"{average_auc[0, 0]:.3f} ({average_auc[0, 1]:.3f}-{average_auc[0, 2]:.3f})",
                           f"{average_auc[0, 3]:.3f} ({average_auc[0, 4]:.3f}-{average_auc[0, 5]:.3f})"])

    all_str_scores = np.array(all_str_scores)
    result_df[f'AUROC_{model_type}'] = all_str_scores[:, 0]
    result_df[f'AUPRC_{model_type}'] = all_str_scores[:, 1]

    return result_df


def evaluate_sklean_model(dataset_dic, model_dir, model_type, result_df):
    print(f'\n    The model evaluation was started for model {model_type} ...')
    test_dataset = dataset_dic['test']
    sklearn_model = joblib.load(filename=os.path.join(model_dir, model_type, model_type + "_model.pkl"))

    if model_type == 'RF':
        importance = sklearn_model.feature_importances_
        feature_importance = zip(test_dataset.feature_names, importance)
        sorted_feature_importance = sorted(feature_importance, key=lambda x:x[1], reverse=True)
        df_feature_importance = pd.DataFrame(sorted_feature_importance, columns=["Feature", "Importance"])
        df_feature_importance.to_csv(os.path.join(model_dir, model_type, model_type + "_feature_importance.csv"), index=False)

    y_pred_proba = sklearn_model.predict_proba(test_dataset.dataset)
    if model_type == 'RF':
        y_pred_proba = np.transpose(y_pred_proba)[1]

    #result_df = calculate_performance(test_dataset.label, y_pred_proba, model_type, result_df)
    return result_df, y_pred_proba


def evaluate_best_nn_model(dataset_dic, model_type, model_dir, result_df):
    print(f'\n    The model evaluation was started for model {model_type} ...')
    test_dataset = dataset_dic['test']
    test_loader = DataLoader(test_dataset, batch_size=BATCH, shuffle=False)
    classifier = nn.Sigmoid()

    model_name = get_best_model_name(model_dir=model_dir, model_type=model_type)
    print(f'\n The best model is {model_name}.')
    print(f' This model is tested on a dataset with size of {len(test_dataset)}.')

    num_features = test_dataset.dataset.shape[1]
    num_classes = test_dataset.label.shape[1]

    if model_type == 'Transformer':
        eval_model = TabularTransformer(num_features=num_features, d_embedding=d_embedding, n_head=n_head,
                                   dim_feedforward=dim_feedforward, num_layers=num_layers, dropout=dropout,
                                   num_classes=num_classes)
    elif model_type == 'ResNet':
        eval_model = ResNet(num_features=num_features, size_embedding=d_embedding, num_layers=num_layers, hidden_factor=2,
                       hidden_dropout=dropout, residual_dropout=dropout, dim_out=num_classes)

    elif model_type == 'Transformer2':
        eval_model = Transformer(num_features=num_features, dim_token=d_embedding, num_heads=n_head,
                            dim_hidden=dim_feedforward, num_blocks=num_layers, att_dropout=dropout,
                            ffn_dropout=dropout, res_dropout=dropout, dim_out=num_classes)

    elif model_type == 'SeqTransformer':
        eval_model = SeqTransformer(d_embedding=d_embedding, n_head=n_head,
                               dim_feedforward=dim_feedforward, num_layers=num_layers, dropout=dropout,
                               num_classes=num_classes)

    elif model_type == 'BiLSTM':
        eval_model = BiLSTM(d_embedding=d_embedding, hidden_size=hidden_size, num_layers=num_layers, dropout=dropout,
                       num_classes=num_classes)

    eval_model.load_state_dict(torch.load(os.path.join(model_dir, model_type, model_name)))

    eval_model.eval()
    y_pred_score = torch.empty(size=(0, test_dataset.get_num_class()))
    y_true = torch.empty(size=(0, test_dataset.get_num_class()))
    with torch.no_grad():
        for batch_idx, batch_data in enumerate(test_loader):
            batch_test_X, batch_test_Y = batch_data
            test_output = eval_model(batch_test_X)

            if y_pred_score.size(0) == 0:
                y_pred_score = classifier(test_output)
                y_true = batch_test_Y
            else:
                y_pred_score = torch.cat((y_pred_score, classifier(test_output)), dim=0)
                y_true = torch.cat((y_true, batch_test_Y), dim=0)

    #result_df = calculate_performance(y_true, y_pred_score, model_type, result_df)
    return result_df, y_pred_score


model_dir = '../outputs/models/'
# data_dic = load_split_data('/Users/behzadn/BoussardLab/NLM-pain/RemainingDeliverables(DL)/opioid-treatment/results/covariateData.csv')
data_dic = load_split_data('P:\\ORD_Curtin_202003006D\\Behzad\\opioid-treatment\\opioid-treatment-3\\results\\covariateData_DM_V2.csv',
                           is_expanded_test=True)

all_res_df = pd.DataFrame({'Class': np.arange(data_dic['train'].label.shape[1] + 1)})

all_res_df, y_score_seqtransformer = evaluate_best_nn_model(data_dic, model_dir=model_dir, model_type='SeqTransformer', result_df=all_res_df)
all_res_df, y_score_bilstm = evaluate_best_nn_model(data_dic, model_dir=model_dir, model_type='BiLSTM', result_df=all_res_df)
all_res_df, y_score_rf = evaluate_sklean_model(data_dic, model_dir=model_dir, model_type='RF', result_df=all_res_df)
all_res_df, y_score_xg = evaluate_sklean_model(data_dic, model_dir=model_dir, model_type='XG', result_df=all_res_df)

# all_res_df, y_score_transformer = evaluate_best_nn_model(data_dic, model_dir=model_dir, model_type='Transformer', result_df=all_res_df)
# all_res_df, y_score_resnet = evaluate_best_nn_model(data_dic, model_dir=model_dir, model_type='ResNet', result_df=all_res_df)
# all_res_df, y_score_transformer = evaluate_best_nn_model(data_dic, model_dir=model_dir, model_type='Transformer2', result_df=all_res_df)

#os.makedirs("../outputs/csv", exist_ok=True)
#all_res_df.to_csv('../outputs/csv/all_res.csv', index=False)

for out in [(y_score_seqtransformer, 'seqtransformer'), (y_score_bilstm, 'bilstm'), (y_score_rf, 'rf'), (y_score_xg, 'xg')]:
    model_outputs = pd.DataFrame(data=out[0],
                                 index=data_dic["test"].pat_ids,
                                 columns=['POU', 'Readmission', 'CP', 'OAO'])
    model_outputs.to_csv(f'../outputs/csv/{out[1]}_output_test_set_scores.csv', index=True)

'''
print('Generating ROC plot ...')

model_score_dict = {
    'SeqTransformer': y_score_seqtransformer,
    'BiLSTM': y_score_bilstm,
    'Random Forest': y_score_rf,
    'XGBoost': y_score_xg
}


plot_dir = "../outputs/plot"
os.makedirs(plot_dir, exist_ok=True)
plot_roc(data_dic['test'].label, model_score_dict, output_dir=plot_dir)
plot_roc_ci(data_dic['test'].label, model_score_dict, output_dir=plot_dir)
'''
