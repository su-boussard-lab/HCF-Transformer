import os.path
import time
import joblib
import torch
import torch.nn as nn
from torch.utils.data import DataLoader
import pandas as pd
import numpy as np

from data import *
from model import * #TabularTransformer, TabularRegression
from resnet import ResNet
from transformer import Transformer
from metric import compute_ci


from sklearn.metrics import average_precision_score, roc_auc_score
from sklearn.ensemble import RandomForestClassifier
from sklearn.linear_model import LogisticRegression
from xgboost import XGBClassifier


SEED = 13
BATCH = 32
NUM_EPOCH = 30 #20

MODER_DIR = '../outputs/models/'
SCALER_DIR = '../outputs/scaler/'
PLOT_DIR = 'outputs/plot/'

# Hyperparameters
d_embedding = 11 #32
hidden_size = 64
n_head = 1 #4
dim_feedforward = 512
num_layers = 1
dropout = 0.1
learningRate = 0.001
weightDecay = 1e-6

'''
# Hyperparameters
d_embedding = 32
n_head = 4
dim_feedforward = 128
num_layers = 3
dropout = 0.25
learningRate = 3e-4
weightDecay = 1e-6
'''


def calculate_auc_values(true_label: torch.tensor, pred: torch.tensor, num_class=4) -> float:
    true_label = true_label.detach().numpy()
    pred = pred.detach().numpy()
    roc_for_classes = list()
    for c in np.arange(num_class):
        roc = roc_auc_score(true_label[:, c], pred[:, c])
        pr = average_precision_score(true_label[:, c], pred[:, c])
        roc_for_classes.append([roc, pr])
    print(roc_for_classes)
    return roc_for_classes[0]  # np.mean(roc_for_classes, axis = 0)


def train_sklearn(dataset_dic: dict, model_type):
    train_dataset = dataset_dic['train']

    if model_type == 'RF':
        sklearn_model = RandomForestClassifier(n_estimators=600, max_depth=50, min_samples_split=3, min_samples_leaf=4,
                                               verbose=1)
    elif model_type == 'XG':
        sklearn_model = XGBClassifier(objective='binary:logistic', n_estimators=300, learning_rate=0.1,
                               min_child_weight=10, max_depth=3, colsample_bytree=0.8, seed=SEED)
    elif model_type == 'Lasso':
        sklearn_model = LogisticRegression(penalty='l1', solver='liblinear', C=0.01)

    print(f'The model {model_type} is fitting ...')
    start_time = time.time()
    sklearn_model.fit(train_dataset.dataset, train_dataset.label)
    end_time = time.time()
    running_time = (end_time - start_time) / 60
    print(f'The model fitting time: {running_time:.3f} minutes')
    # y_pred = cls_model.predict(test_dataset.dataset)

    print(f'The model {model_type} is saving in the output folder ...')
    os.makedirs(os.path.join(MODER_DIR, model_type), exist_ok=True)
    joblib.dump(sklearn_model, filename=os.path.join(MODER_DIR, model_type, model_type + "_model.pkl"))

    if model_type == 'RF':
        importance = sklearn_model.feature_importances_
        feature_importance = zip(train_dataset.feature_names, importance)
        sorted_feature_importance = sorted(feature_importance, key=lambda x:x[1], reverse=True)
        df_feature_importance = pd.DataFrame(sorted_feature_importance, columns=["Feature", "Importance"])
        df_feature_importance.to_csv(os.path.join(MODER_DIR, model_type, model_type + "_feature_importance.csv"), index=False)


def train(dataset_dic: dict, save_scaler=False, model_type='transformer'):
    train_dataset = dataset_dic['train']
    val_dataset = dataset_dic['val']

    # save train set scaler
    if save_scaler:
        os.makedirs(SCALER_DIR, exist_ok=True)
        joblib.dump(train_dataset.scaler, filename=os.path.join(SCALER_DIR, 'train_scaler.gz'))

    num_features = train_dataset.dataset.shape[1]
    num_classes = train_dataset.label.shape[1]

    if model_type == 'Transformer':
        model = TabularTransformer(num_features=num_features, d_embedding=d_embedding, n_head=n_head,
                                   dim_feedforward=dim_feedforward, num_layers=num_layers, dropout=dropout,
                                   num_classes=num_classes)

    elif model_type == 'ResNet':
        model = ResNet(num_features=num_features, size_embedding=d_embedding, num_layers=num_layers, hidden_factor=2,
                       hidden_dropout=dropout, residual_dropout=dropout, dim_out=num_classes)

    elif model_type == 'Transformer2':
        model = Transformer(num_features=num_features, dim_token=d_embedding, num_heads=n_head,
                            dim_hidden=dim_feedforward, num_blocks=num_layers, att_dropout=dropout,
                            ffn_dropout=dropout, res_dropout=dropout, dim_out=num_classes)

    elif model_type == 'SeqTransformer':
        model = SeqTransformer(d_embedding=d_embedding, n_head=n_head,
                               dim_feedforward=dim_feedforward, num_layers=num_layers, dropout=dropout,
                               num_classes=num_classes)

    elif model_type == 'BiLSTM':
        model = BiLSTM(d_embedding=d_embedding, hidden_size=hidden_size, num_layers=num_layers, dropout=dropout,
                       num_classes=num_classes)

    #model = TabularRegression(num_features=num_features, num_hidden=256, num_classes=num_classes)

    #loss_fn = nn.BCEWithLogitsLoss(reduction='mean', pos_weight=torch.tensor((len(train_dataset.label) - np.sum(train_dataset.label, axis=0)) / np.sum(train_dataset.label, axis=0)))
    loss_fn = nn.BCEWithLogitsLoss(reduction='mean')

    optimizer = torch.optim.AdamW(model.parameters(), lr=learningRate, weight_decay=weightDecay)
    scheduler = torch.optim.lr_scheduler.ReduceLROnPlateau(optimizer, mode="max", factor=0.1, patience=5, threshold=0.001)

    train_loader = DataLoader(train_dataset, batch_size=BATCH, shuffle=True)
    val_loader = DataLoader(val_dataset, batch_size=BATCH, shuffle=False)

    # Training loop
    best_val_loss = float('inf')
    best_val_auc = 0
    classifier = nn.Sigmoid()
    os.makedirs(os.path.join(MODER_DIR, model_type), exist_ok=True)
    for epoch in range(NUM_EPOCH):
        model.train(True)
        train_loss = 0.0
        y_pred = torch.empty(size=(0, train_dataset.get_num_class()))
        y_true = torch.empty(size=(0, train_dataset.get_num_class()))
        for batch_idx, batch_data in enumerate(train_loader):
            batch_X, batch_Y = batch_data
            optimizer.zero_grad()
            outputs = model(batch_X)

            if y_pred.size(0) == 0:
                y_pred = classifier(outputs)
                y_true = batch_Y
            else:
                y_pred = torch.cat((y_pred, classifier(outputs)), dim=0)
                y_true = torch.cat((y_true, batch_Y), dim=0)

            loss = loss_fn(outputs, batch_Y.float())
            loss.backward()
            optimizer.step()
            train_loss += (loss.item() * batch_X.size(0))
            if batch_idx % 50 == 49:
                last_loss = train_loss / ((batch_idx + 1) * batch_X.size(0)) # loss per instance
                print('  batch {} loss: {}'.format(batch_idx + 1, last_loss))

        train_loss /= len(train_loader.dataset)
        train_auc = calculate_auc_values(y_true, y_pred, train_dataset.get_num_class())
        print('  epoch {} loss: {} macro_auc: {}'.format(epoch + 1, train_loss, train_auc))

        # Validation
        model.eval()
        val_loss = 0.0
        y_pred = torch.empty(size=(0, val_dataset.get_num_class()))
        y_true = torch.empty(size=(0, val_dataset.get_num_class()))
        with torch.no_grad():
            for batch_idx, batch_data in enumerate(val_loader):
                batch_val_X, batch_val_Y = batch_data
                val_output = model(batch_val_X)

                if y_pred.size(0) == 0:
                    y_pred = classifier(val_output)
                    y_true = batch_val_Y
                else:
                    y_pred = torch.cat((y_pred, classifier(val_output)), dim=0)
                    y_true = torch.cat((y_true, batch_val_Y), dim=0)

                loss = loss_fn(val_output, batch_val_Y.float())
                val_loss += (loss.item() * batch_val_X.size(0))

        val_loss /= len(val_loader.dataset)
        val_auc = calculate_auc_values(y_true, y_pred, train_dataset.get_num_class())

        print(f'*** Epoch {epoch + 1}, Train Loss: {train_loss:.4f}, Val Loss: {val_loss:.4f}')
        print(f'*** Epoch {epoch + 1}, Train Macro AUC: {train_auc[0]:.3f}, Val Macro AUC: {val_auc[0]:.3f}')
        print(f'*** Epoch {epoch + 1}, Train Macro PR: {train_auc[1]:.3f}, Val Macro PR: {val_auc[1]:.3f}')

        if val_auc[0] > best_val_auc:
            best_val_auc = val_auc[0]
            torch.save(model.state_dict(),
                       os.path.join(MODER_DIR, model_type, f'epoch_{epoch + 1}_val_pr_{val_auc[1]:.3f}_val_auc_{val_auc[0]:.3f}_.tar'))

        scheduler.step(val_auc[0])
        print(f'*** Epoch {epoch + 1}, Learning rate for the next epoch is: {optimizer.param_groups[0]["lr"]} \n')


# data_dic = load_split_data('/Users/behzadn/BoussardLab/NLM-pain/RemainingDeliverables(DL)/opioid-treatment/results/covariateData.csv',)
# data_dic = load_split_data('P:\\ORD_Curtin_202003006D\\Behzad\\opioid-treatment\\opioid-treatment-3\\results\\covariateData.csv',)
data_dic = load_split_data('P:\\ORD_Curtin_202003006D\\Behzad\\opioid-treatment\\opioid-treatment-3\\results\\covariateData_DM_V2.csv')

#train_sklearn(data_dic, 'RF')
#train_sklearn(data_dic, 'XG')
#train(data_dic, model_type='SeqTransformer')
#train(data_dic, model_type='BiLSTM')
#train(data_dic, model_type='Transformer')
train(data_dic, model_type='ResNet')


