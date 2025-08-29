#!/bin/bash -l

# =============================================================================
#                             main_job.sh
# =============================================================================
# Description:
#   This script orchestrates the execution of the Remora training pipeline by
#   submitting the `run_basecaller.sh`, `prepare_training_dataset.sh`, and
#   `run_training.sh` scripts as separate jobs. It ensures that each job is
#   submitted with dependencies, so that each subsequent job waits for the
#   previous one to complete successfully before starting.
#
# Key Features:
# - **Job Submission with Dependencies**: Submits each job script with
#   dependencies using the `-hold_jid` flag, ensuring sequential execution.
#
# - **Error Handling**: Exits the pipeline if any of the job submissions fail.
#
# - **Logging**: Outputs informative messages to track the pipeline's progress.
#
# Usage:
#   This script is submitted via `run_pipeline.sh` and should not be run directly.
#
# Notes:
# - Ensure that all job scripts are present and executable.
# - Modify resource allocations within individual scripts if necessary.
#
# Author: Tayeb Jamali
# Date: 2024-12-19
# =============================================================================

# Enable strict error handling
set -euo pipefail

# =============================================================================
# Environment Setup
# =============================================================================

# All necessary variables are expected to be exported by run_pipeline.sh

# =============================================================================
# Function Definitions
# =============================================================================

# Function to check the exit status of a command
check_exit_status() {
    local STATUS=$1
    local STEP=$2
    if [ "${STATUS}" -ne 0 ]; then
        echo "Error: ${STEP} failed with exit status ${STATUS}. Aborting pipeline."
        exit ${STATUS}
    else
        echo "Success: ${STEP} submitted successfully."
    fi
}

# =============================================================================
# Pipeline Execution
# =============================================================================

echo "=========================================================="
echo "Remora Training Pipeline - Main Job Started"
echo "Start Date : $(date)"
echo "=========================================================="

# -------------------- Step 1: Submit Basecaller Job ------------------------

echo "Step 1: Submitting Basecaller Job"

# Define Dorado job name
DORADO_JOB_NAME="DORADO_JOB"

# Submit the run_basecaller.sh script
DORADO_JOB_ID=$(qsub -terse \
    -V \
    -P "${QSUB_PROJECT}" \
    -N "${DORADO_JOB_NAME}" \
    -l h_rt="${DORADO_JOB_RUNTIME}" \
    -l mem_free="${DORADO_JOB_MEMORY}" \
    -pe omp "${TOTAL_CPUS_DORADO}" \
    -l gpus="${TOTAL_GPUS_DORADO}" \
    -l gpu_type="${DORADO_GPU_TYPE}" \
    -m "${QSUB_EMAIL}" \
    -j "${QSUB_JOINT_STDERR}" \
    "${SCRIPTS_DIR}/run_basecaller.sh"
)

check_exit_status $? "Run Basecaller"

echo "Basecaller Job ID: ${DORADO_JOB_ID}"

# -------------------- Step 2: Submit Prepare Training Dataset Job ------------------------

echo "Step 2: Submitting Prepare Training Dataset Job"

# Define Prepare Training Dataset job name
PREPARE_JOB_NAME="PREPARE_JOB"

# Submit the prepare_training_dataset.sh script with dependency on DORADO_JOB_ID
PREPARE_JOB_ID=$(qsub -terse \
    -V \
    -P "${QSUB_PROJECT}" \
    -N "${PREPARE_JOB_NAME}" \
    -hold_jid "${DORADO_JOB_ID}" \
    -l h_rt="${PREPARE_JOB_RUNTIME}" \
    -l mem_free="${PREPARE_JOB_MEMORY}" \
    -pe omp "${TOTAL_CPUS_PREPARE}" \
    -m "${QSUB_EMAIL}" \
    -j "${QSUB_JOINT_STDERR}" \
    "${SCRIPTS_DIR}/prepare_training_dataset.sh"
)

check_exit_status $? "Prepare Training Dataset"

echo "Prepare Training Dataset Job ID: ${PREPARE_JOB_ID}"

# -------------------- Step 3: Submit Training Job ------------------------

echo "Step 3: Submitting Training Job"

# Define Training job name
TRAINING_JOB_NAME="TRAINING_JOB"

# Submit the run_training.sh script with dependency on PREPARE_JOB_ID
TRAINING_JOB_ID=$(qsub -terse \
    -V \
    -P "${QSUB_PROJECT}" \
    -N "${TRAINING_JOB_NAME}" \
    -hold_jid "${PREPARE_JOB_ID}" \
    -l h_rt="${TRAINING_JOB_RUNTIME}" \
    -l mem_free="${TRAINING_JOB_MEMORY}" \
    -pe omp "${TOTAL_CPUS_TRAINING}" \
    -l gpus="${TOTAL_GPUS_TRAINING}" \
    -l gpu_type="${TRAINING_GPU_TYPE}" \
    -m "${QSUB_EMAIL}" \
    -j "${QSUB_JOINT_STDERR}" \
    "${SCRIPTS_DIR}/run_training.sh"
)

check_exit_status $? "Run Training"

echo "Training Job ID: ${TRAINING_JOB_ID}"

# =============================================================================
# Pipeline Completion
# =============================================================================

echo "=========================================================="
echo "Remora Training Pipeline - Main Job Completed"
echo "Submitted Jobs:"
echo "1. run_basecaller.sh (Job ID: ${DORADO_JOB_ID})"
echo "2. prepare_training_dataset.sh (Job ID: ${PREPARE_JOB_ID})"
echo "3. run_training.sh (Job ID: ${TRAINING_JOB_ID})"
echo "End Date : $(date)"
echo "=========================================================="

