#!/bin/bash -l
#
# Script Name: prepare_training_dataset.sh
#
# Description:
#   This script prepares the training dataset for Remora by processing the
#   BAM and POD5 files. It loads necessary modules, activates the conda environment,
#   and executes Remora dataset preparation commands.
#
# Usage:
#   ./prepare_training_dataset.sh
#
# Requirements:
#   - Miniconda module
#   - Conda environment named 'nanopore'
#   - CUDA module
#   - Remora installed in the conda environment
#
# Outputs:
#   - Prepared training dataset files in the specified output directories
#

# Load the miniconda module to access conda
module load miniconda || { echo "Failed to load miniconda module"; exit 2; }

# Activate the conda environment named nanopore
conda activate nanopore || { echo "Failed to activate conda environment nanopore"; exit 3; }

# Load the CUDA module to enable GPU support
module load cuda || { echo "Failed to load CUDA module"; exit 4; }

# Step 1: Data Preparation

echo "Running Remora dataset prepare for Control Samples"
remora dataset prepare "$CAN_POD5" "$CAN_BAM" \
  --output-path "$CAN_CHUNKS" \
  --refine-kmer-level-table "$KMER_LEVEL_TABLE" \
  --refine-rough-rescale \
  --motif CG 0 \
  --mod-base-control

echo "Running Remora dataset prepare for Modified Samples"
remora dataset prepare "$MOD_POD5" "$MOD_BAM" \
  --output-path "$MOD_CHUNKS" \
  --refine-kmer-level-table "$KMER_LEVEL_TABLE" \
  --refine-rough-rescale \
  --motif CG 0 \
  --mod-base m 5mC

# Step 2: Composing Training Datasets

echo "Running Remora dataset make_config"
remora dataset make_config "$TRAIN_DATASET" "$CAN_CHUNKS" "$MOD_CHUNKS" \
  --dataset-weights 1 1 \
  --log-filename "$TRAIN_LOG"

echo "Training dataset preparation completed successfully."

