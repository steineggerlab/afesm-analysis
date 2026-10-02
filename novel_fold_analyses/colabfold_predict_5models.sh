#!/bin/bash
# AF2-ColabFold prediction of the novel fold domains, 5 models (rank_001-005)
# usage: sbatch colabfold_predict_5models.sh <msa_dir> <pred_dir>
#SBATCH --job-name=colab_prediction
#SBATCH --nodelist=devbox001
#SBATCH --partition=gpu
#SBATCH --time=0
#SBATCH --gres=gpu:4
#SBATCH --output=/share/afesm6/50_novel_struct_dl/log_pred_novel_colabfold_%j.out

MSA_DIR=$1
PRED_DIR=$2

# ColabFold 1.5.5 (fdf3b235)
colabfold_batch --num-models 5 "$MSA_DIR" "$PRED_DIR"
