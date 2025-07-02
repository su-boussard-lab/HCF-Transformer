import os.path

import numpy as np
from sklearn.metrics import roc_auc_score, roc_curve, auc
from sklearn.utils import resample
import matplotlib
import matplotlib.pyplot as plt
matplotlib.use('TkAgg')


def compute_ci(y_true, y_scores, sklearn_metric=roc_auc_score,  num_bootstrap=1000, ci=0.95, bootstrap_seed=13):
    """
    Compute sklearn metric scores with 95% confidence interval using bootstrapping.

    Parameters:
    y_true (array-like): True binary labels.
    y_scores (array-like): Target scores, can either be probability estimates of the positive class, confidence values, or binary decisions.
    sklearn_metric A sklearn performance metric function
    num_bootstrap (int): Number of bootstrap samples.
    ci (float): Confidence interval level.
    bootstrap_seed A random seed for reproducibility

    Returns:
    tuple: AUC score, lower bound of CI, upper bound of CI
    """
    metric = sklearn_metric(y_true, y_scores)
    bootstrapped_scores = []

    rng = np.random.RandomState(seed=bootstrap_seed)

    # indices_list = [resample(range(len(y_scores)), random_state=rng) for _ in range(num_bootstrap)]
    # bootstrapped_scores = [sklearn_metric(y_true[indices], y_scores[indices]) for indices in indices_list if len(np.unique(y_true[indices])) >= 2]

    for _ in range(num_bootstrap):
        indices = resample(range(len(y_scores)), random_state=rng)
        if len(np.unique(y_true[indices])) < 2:
            # We need at least one positive and one negative sample for ROC AUC
            continue

        score = sklearn_metric(y_true[indices], y_scores[indices])
        bootstrapped_scores.append(score)

    # Compute confidence interval
    sorted_scores = np.array(bootstrapped_scores)
    sorted_scores.sort()

    lower_bound = np.percentile(sorted_scores, (1 - ci) / 2 * 100)
    upper_bound = np.percentile(sorted_scores, (1 + ci) / 2 * 100)

    return metric, lower_bound, upper_bound


def plot_roc(y_true, y_score_dict, output_dir):
    print('\n    Generating ROC plots ...')
    for class_index in range(y_true.shape[1]):
        plt.figure()
        for model_name, y_scores in y_score_dict.items():
            base_fpr = np.linspace(0, 1, 101)
            fpr, tpr, _ = roc_curve(y_true[:, class_index], y_scores[:, class_index])
            tpr = np.interp(base_fpr, fpr, tpr)
            tpr[0] = 0.0
            tpr[-1] = 1.0
            roc_auc = auc(base_fpr, tpr)
            plt.plot(base_fpr, tpr, lw=2, label=f'{model_name} (AUC = {roc_auc:.3f})')

        plt.plot([0, 1], [0, 1], color='gray', linestyle='--')
        plt.xlim([0.0, 1.0])
        plt.ylim([0.0, 1.05])
        plt.yticks(fontsize=15)
        plt.xticks(fontsize=15)
        plt.xlabel('False Positive Rate', fontsize=20)
        plt.ylabel('True Positive Rate', fontsize=20)
        plt.legend(loc="lower right")
        plt.tight_layout()

        plt.savefig(os.path.join(output_dir, f'roc-class-{class_index}.pdf'))


def plot_roc_ci(y_true, y_score_dict, output_dir, num_bootstrap=1000, bootstrap_seed=13):
    print('\n    Generating ROC plots ...')
    for class_index in range(y_true.shape[1]):
        print(f'    Class {class_index} ...')
        plt.figure()
        for model_name, y_scores in y_score_dict.items():
            tprs = []
            aucs = []
            base_fpr = np.linspace(0, 1, 101)
            rng = np.random.RandomState(seed=bootstrap_seed)
            for _ in range(num_bootstrap):
                indices = resample(range(len(y_scores)), random_state=rng)
                if len(np.unique(y_true[indices, class_index])) < 2:
                    continue
                fpr, tpr, _ = roc_curve(y_true[indices, class_index], y_scores[indices, class_index])
                tpr = np.interp(base_fpr, fpr, tpr)
                tpr[0] = 0.0
                tpr[-1] = 1.0
                tprs.append(tpr)
                aucs.append(auc(base_fpr, tpr))

            tprs = np.array(tprs)
            mean_tprs = tprs.mean(axis=0)
            std_tprs = tprs.std(axis=0)
            roc_auc = auc(base_fpr, mean_tprs)

            sorted_aucs = np.array(aucs)
            sorted_aucs.sort()
            ci = 0.95
            lower_bound = np.percentile(sorted_aucs, (1 - ci) / 2 * 100)
            upper_bound = np.percentile(sorted_aucs, (1 + ci) / 2 * 100)

            # Calculate the 95% confidence interval
            tprs_upper = np.minimum(mean_tprs + 1.96 * std_tprs, 1)
            tprs_lower = np.maximum(mean_tprs - 1.96 * std_tprs, 0)

            plt.plot(base_fpr, tpr, lw=2, label=f'{model_name} AUC = {roc_auc:.2f}({lower_bound:.2f}-{upper_bound:.2f})')
            plt.fill_between(base_fpr, tprs_lower, tprs_upper, color='grey', alpha=0.3)

        plt.plot([0, 1], [0, 1], color='gray', linestyle='--')
        plt.xlim([0.0, 1.0])
        plt.ylim([0.0, 1.05])
        plt.yticks(fontsize=15)
        plt.xticks(fontsize=15)
        plt.xlabel('False Positive Rate', fontsize=20)
        plt.ylabel('True Positive Rate', fontsize=20)
        plt.legend(loc="lower right")
        plt.tight_layout()

        plt.savefig(os.path.join(output_dir, f'roc-ci-class-{class_index}.pdf'))


