#!/bin/bash -l

#---------------------------------------###------------------------------------------#
# This script is designed to submit a job to SCC using qsub for training a model
# using the bonito basecaller. It sets up the necessary environment, specifies job
# requirements, and runs the training command.
#---------------------------------------###------------------------------------------#

#$ -P leshlab        # Specify the SCC project name you want to use
#$ -N evaluation     # Give the job a name
#$ -l h_rt=12:00:00  # Specify a hard time limit (12 hours)
#$ -l gpus=1         # Request 1 GPU
#$ -l gpu_type=L40S  # Specify the GPU type
#$ -m ea             # Send email on job completion or abortion
#$ -j y              # Combine output and error files

# Keep track of information related to the current job
echo "=========================================================="
echo "Start date : $(date)"
echo "Job name : $JOB_NAME"
echo "Job ID : $JOB_ID  $SGE_TASK_ID"
echo "=========================================================="

# Load the miniconda module to access conda
module load miniconda || { echo "Failed to load miniconda module"; exit 2; }

# Activate the conda environment named nanopore
conda activate nanopore || { echo "Failed to activate conda environment nanopore"; exit 3; }

# Load the CUDA module to enable GPU support for the basecaller
module load cuda || { echo "Failed to load CUDA module"; exit 4; }

echo "Python executable: $(which python)"
echo "Python version: $(python --version)"

# Variables for paths
BONITO_MODEL_DIR="/restricted/projectnb/leshlab/net/tjamali/project/bonito_code/models/dna_r10.4.1_e8.2_400bps_hac@v5.0.0/"
MODEL_DIR="/restricted/projectnb/leshlab/net/tjamali/project/bonito_code/data/training/model/20230424_1302_3H_PAO89685_2264ba8c/hac/model_1_exp_7"
EVALUATION_DATA_DIR="/restricted/projectnb/leshlab/net/tjamali/project/bonito_code/data/evaluation/20230424_subfolder_50"

# Function to run bonito evaluate command
run_evaluation() {
    local MODEL_PATH="$1"
    local EVAL_DIR="$2"
    bonito evaluate "$MODEL_PATH" --directory "$EVAL_DIR" --chunks 50000 --weights 10
}

# Run the evaluation for the trained model
echo "Evaluation result for the trained model:"
run_evaluation "$MODEL_DIR" "$EVALUATION_DATA_DIR"

# Uncomment the following lines to evaluate the Bonito model
echo "Evaluation result for the Bonito model:"
run_evaluation "$BONITO_MODEL_DIR" "$EVALUATION_DATA_DIR"

