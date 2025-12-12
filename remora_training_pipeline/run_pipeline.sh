#!/bin/bash

# =============================================================================
#                             run_pipeline.sh
# =============================================================================
# Description:
#   This script initializes all necessary variables for the Remora training
#   pipeline and submits the `main_job.sh` script to the job scheduler (qsub).
#   It serves as the entry point for executing the entire pipeline.
#
# Key Features:
# - **Environment Variable Initialization**: Sets up all required variables
#   for the pipeline, ensuring consistency across all jobs.
#
# - **Script Permissions**: Ensures that all necessary scripts are executable.
#
# - **Job Submission**: Submits the `main_job.sh` script to the job scheduler
#   with appropriate resource allocations and naming conventions.
#
# Usage:
#   ./run_pipeline.sh
#
# Notes:
# - Before running the script, verify that the paths to directories and files
#   (e.g., DATASET_DIR) are correct and accessible.
# - Adjust resource allocations and parameters as needed based on your data
#   and computational environment.
# - Ensure that all variables in the script are correctly set before running.
#
# Directory Structure and Permissions:
# Ensure that your directory structure is organized as follows, and that all 
# scripts have the appropriate executable permissions:
#
#    ROOT_DIR
#    ├── remora_dataset/
#    │   ├── basecalls/
#    │   │   └── (Output BAM files from basecalling)
#    │   ├── subset/
#    │   │   └── (Input .pod5 files)
#    │   ├── training_dataset/
#    │   │   ├── can_chunks/
#    │   │   ├── mod_chunks/
#    │   │   ├── train_dataset.jsn
#    │   │   └── train_dataset.log
#    │   ├── references/
#    │   │   ├── all_5mers.fa
#    │   │   └── all_5mers.fa.fai
#    │   └── 5mer_levels.txt
#    ├── remora_code/
#    │   └── models/
#    │       └── ConvLSTM_w_ref.py
#    ├── remora_output/
#    │   └── training_results/
#    └── remora_training_pipeline/
#        ├── run_pipeline.sh
#        └── scripts/
#            ├── main_job.sh
#            ├── run_basecaller.sh
#            ├── prepare_training_dataset.sh
#            └── run_training.sh
#
# Author: Tayeb Jamali
# Date: 2025-6-20
# =============================================================================

# Enable strict error handling
set -euo pipefail

# =============================================================================
# Main Pipeline Variables
# =============================================================================

# -------------------- General Pipeline Variables ------------------------

# Root directory of the project
ROOT_DIR="/restricted/projectnb/leshlab/net/tjamali/project"

# Directory containing pipeline scripts
SCRIPTS_DIR="${ROOT_DIR}/remora_training_pipeline/scripts"

# Dataset directory
DATASET_DIR="${ROOT_DIR}/remora_dataset"

# Directory containing training outputs. If the directory is not empty you need to use overwrite tage otherwise you get error.
TRAINING_RESULTS="${ROOT_DIR}/remora_output/training_results"

# Directory to store Dorado's basecalls
BASECALL_OUTPUT_DIR="${DATASET_DIR}/basecalls"

# -------------------- File Path Variables -------------------------------

# Reference file for basecalling
REFERENCE_FILE="${DATASET_DIR}/references/all_5mers.fa"

# Paths for training dataset preparation
CAN_POD5="${DATASET_DIR}/subset/control_rep1.pod5"             # Canonical input file
CAN_BAM="${DATASET_DIR}/basecalls/control_rep1.bam"
CAN_CHUNKS="${DATASET_DIR}/training_dataset/can_chunks"

MOD_POD5="${DATASET_DIR}/subset/5mC_rep1.pod5"                 # Modified input file
MOD_BAM="${DATASET_DIR}/basecalls/5mC_rep1.bam"
MOD_CHUNKS="${DATASET_DIR}/training_dataset/mod_chunks"

KMER_LEVEL_TABLE="${DATASET_DIR}/5mer_levels.txt"

TRAIN_DATASET="${DATASET_DIR}/training_dataset/train_dataset.jsn"
TRAIN_LOG="${DATASET_DIR}/training_dataset/train_dataset.log"

# Training parameters
MODEL="${ROOT_DIR}/remora_code/models/ConvLSTM_w_ref.py"

# Job Scheduler Parameters
QSUB_PROJECT="leshlab"                                          # SCC project name
QSUB_EMAIL="ea"                                                 # Email notifications on end/abort
QSUB_JOINT_STDERR="y"                                           # Combine stderr and stdout

# Resource allocations for each job

# Run Basecaller (Dorado)
DORADO_JOB_RUNTIME="12:00:00"                                   # Runtime limit
DORADO_JOB_MEMORY="128G"                                        # Memory requirement
TOTAL_CPUS_DORADO=4                                             # Number of CPU cores
TOTAL_GPUS_DORADO=1                                             # Number of GPUs
DORADO_GPU_TYPE="L40S"                                          # GPU type
DORADO_MODEL_NAME="sup@v5.0.0"                                  # Dorado model name
DORADO_MIN_QSCORE=9                                             # Minimum quality score

# Prepare Training Dataset
PREPARE_JOB_RUNTIME="1:00:00"
PREPARE_JOB_MEMORY="64G"
TOTAL_CPUS_PREPARE=8

# Run Training
TRAINING_JOB_RUNTIME="12:00:00"
TRAINING_JOB_MEMORY="128G"
TOTAL_CPUS_TRAINING=4
TOTAL_GPUS_TRAINING=1
TRAINING_GPU_TYPE="L40S"

# =============================================================================
# Environment Variable Exporting
# =============================================================================

# Export necessary variables to be available to main_job.sh
export ROOT_DIR SCRIPTS_DIR DATASET_DIR REFERENCE_FILE
export BASECALL_OUTPUT_DIR INPUT_POD5_FILE CAN_BAM CAN_POD5 CAN_CHUNKS
export MOD_BAM MOD_POD5 MOD_CHUNKS KMER_LEVEL_TABLE TRAIN_DATASET TRAIN_LOG MODEL
export TRAINING_RESULTS QSUB_PROJECT QSUB_EMAIL QSUB_JOINT_STDERR

# Export resource allocation variables
export DORADO_JOB_RUNTIME DORADO_JOB_MEMORY TOTAL_CPUS_DORADO TOTAL_GPUS_DORADO
export DORADO_GPU_TYPE DORADO_MODEL_NAME DORADO_MIN_QSCORE 

export PREPARE_JOB_RUNTIME PREPARE_JOB_MEMORY TOTAL_CPUS_PREPARE

export TRAINING_JOB_RUNTIME TRAINING_JOB_MEMORY TOTAL_CPUS_TRAINING
export TOTAL_GPUS_TRAINING TRAINING_GPU_TYPE

# =============================================================================
# Main Job Submission
# =============================================================================

echo "============================================="
echo "Starting Remora Training Pipeline Submission"
echo "============================================="

# Define job name based on the pipeline
MAIN_JOB_NAME="MAIN_JOB"

# Define the main_job.sh script path
MAIN_JOB_SCRIPT="${SCRIPTS_DIR}/main_job.sh"

# Submit main_job.sh using qsub, passing necessary environment variables
MAIN_JOB_ID=$(qsub -terse -V \
    -P "${QSUB_PROJECT}" \
    -N "${MAIN_JOB_NAME}" \
    -l h_rt="1:00:00" \
    -m "${QSUB_EMAIL}" \
    -j "${QSUB_JOINT_STDERR}" \
    "${MAIN_JOB_SCRIPT}"
)

echo "Main Job submitted with Job ID: ${MAIN_JOB_ID}"
echo "Pipeline submission initiated successfully."
echo "============================================="

