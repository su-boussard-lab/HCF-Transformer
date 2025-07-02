import os
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib
from sklearn.metrics import precision_recall_curve, auc
from sklearn.metrics import accuracy_score, precision_score, recall_score, f1_score
matplotlib.use('TkAgg')


def compute_metrics(y_true, y_pred):
    metrics = {
        'Accuracy': accuracy_score(y_true, y_pred),
        'Precision': precision_score(y_true, y_pred),
        'Recall': recall_score(y_true, y_pred),
        'F1-score': f1_score(y_true, y_pred)
    }
    return metrics


def calc_best_threshold(y_test, y_scores, output_dir='./', outcome='POU'):
    # Compute precision, recall, and thresholds
    precision, recall, thresholds = precision_recall_curve(y_test, y_scores)

    # Compute F1-score for each threshold
    f1_scores = 2 * (precision * recall) / (precision + recall + 1e-9)  # Avoid division by zero

    # Find the threshold that gives the highest F1-score
    best_idx = np.argmax(f1_scores)
    best_threshold = thresholds[best_idx]
    best_f1 = f1_scores[best_idx]
    best_precision = precision[best_idx]
    best_recall = recall[best_idx]

    # Compute the area under the PR curve
    pr_auc = auc(recall, precision)


def plot_pr_roc(y_true_score_df, output_dir='./'):
    # Plot the precision-recall curve
    plt.figure(figsize=(8, 6))
    for outcome, (y_true, y_scores) in y_true_score_df.items():
        precision, recall, thresholds = precision_recall_curve(y_true, y_scores)
        pr_auc = auc(recall, precision)

        # Compute F1-score for each threshold
        f1_scores = 2 * (precision * recall) / (precision + recall + 1e-9)  # Avoid division by zero
        
        # Find the threshold that gives the highest F1-score
        best_idx = np.argmax(f1_scores)
        best_threshold = thresholds[best_idx]
        best_f1 = f1_scores[best_idx]
        best_precision = precision[best_idx]
        best_recall = recall[best_idx]
        print(f"{outcome}: Best threshold:{best_threshold:.3f}, Best F1:{best_f1:.4f}, Best Pr:{best_precision:.4f}, Best Re:{best_recall:.4f}")
        plt.plot(recall, precision, label=f'{outcome} (AUC = {pr_auc:.3f})')

    # Annotate the best threshold point
    #plt.scatter(best_recall, best_precision, color='red', s=100, edgecolors='black', label=f'Best Threshold = {best_threshold:.2f}\n(F1 = {best_f1:.2f})')

    # Labels and legend
    plt.xlabel('Recall')
    plt.ylabel('Precision')
    #plt.title('Precision-Recall Curve with Best F1-Score Threshold')
    plt.yticks(fontsize=15)
    plt.xticks(fontsize=15)
    plt.xlabel('False Positive Rate', fontsize=20)
    plt.ylabel('True Positive Rate', fontsize=20)
    plt.legend(loc="lower left")
    plt.tight_layout()

    plt.savefig(os.path.join(output_dir, f'PR_ROC.pdf'))


predictions = pd.DataFrame({
    'POU': [0.8, 0.4, 0.6, 0.3, 0.9],
    'Read': [0.7, 0.2, 0.8, 0.5, 0.6],
    'CP': [0.5, 0.1, 0.4, 0.9, 0.3],
    'OAO': [0.6, 0.3, 0.7, 0.2, 0.8]
}, index=[101, 102, 103, 104, 105])

outcomes = pd.DataFrame({
    'POU_Outcome': [1, 0, 1, 0, 1],
    'Read_Outcome': [1, 0, 1, 0, 1],
    'CP_Outcome': [0, 0, 0, 1, 0],
    'OAO_Outcome': [1, 0, 1, 0, 1]
}, index=[101, 102, 103, 104, 105])


output_dir = './'
model_name = 'seqtransformer'
os.makedirs(os.path.join(output_dir, model_name), exist_ok=True)

real_outcome_file = 'P:/ORD_Curtin_202003006D/Behzad/opioid-treatment/opioid-treatment-3/results/covariateData_DM_V2.csv'
pred_file = 'P:/ORD_Curtin_202003006D/Behzad/opioid-treatment/opioid-treatment-3/results/covariateData_DM_V2.csv'
#predictions = pd.read_csv('predictions.csv', index_col=0)
#outcomes = pd.read_csv('outcomes.csv', index_col=0, usecols=['POU_Outcome', 'Read_Outcome', 'CP_Outcome', 'OAO_Outcome'])

merged_df = predictions.merge(outcomes, left_index=True, right_index=True, how='inner')

outcomes = ['POU', 'Read', 'CP', 'OAO']
thresholds = [0.45, 0.1, 0.1, 0.02]

performance_results = {}
for out, t in zip(outcomes, thresholds):
    y_true = merged_df[f'{out}_Outcome']
    y_pred = (merged_df[out] >= t).astype(int)
    performance_results[f"{out} ({t})"] = compute_metrics(y_true, y_pred)

performance_df = pd.DataFrame(performance_results)
performance_df.to_csv(os.path.join(output_dir, model_name, 'performance_metrics.csv'), index=False)
print(performance_df)

y_true_score_df = {}
for out in outcomes:
    y_true = merged_df[f'{out}_Outcome']
    y_score = merged_df[out]
    y_true_score_df[out] = (y_true, y_score)

plot_pr_roc(y_true_score_df, output_dir=os.path.join(output_dir, model_name))

