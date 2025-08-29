#!/bin/bash -l

# =============================================================================
# Script Name: run_training.sh
# =============================================================================
# Description:
#   This script runs Remora model training in non-interactive mode. It loads
#   necessary modules, activates the conda environment, and executes the
#   Remora training command.
#
# Usage:
#   ./run_training.sh
#
# Requirements:
#   - Miniconda module
#   - Conda environment named 'nanopore'
#   - CUDA module
#   - Remora installed in the conda environment
#
# Outputs:
#   - Trained Remora model files in the specified output directory
#

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

# Load the CUDA module to enable GPU support
module load cuda || { echo "Failed to load CUDA module"; exit 4; }

# Run the Remora training command
echo "Starting Remora model training..."
remora model train "$TRAIN_DATASET" \
  --model "$MODEL" \
  --device 0 \
  --chunk-context 50 50 \
  --output-path "$TRAINING_RESULTS"

echo "Remora model training completed successfully."

