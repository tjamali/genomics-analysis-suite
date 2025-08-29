#!/bin/bash

# =============================================================================
#                             run_pipeline.sh
# =============================================================================
# Description:
# This script initializes all necessary variables for the Nanopore pipeline
# and submits the `main_job.sh` script to the job scheduler (qsub). It serves
# as the entry point for executing the entire pipeline.
#
# Key Features:
# - **Pod5 Files Listing and Partitioning**: Invokes the Python script
#   (`partition_pod5_files.py`) to gather all `.pod5` files within `INPUT_DIR`,
#   including all subdirectories, and partition them into sublists where each
#   sublist's total size does not exceed the specified size limit. This
#   approach avoids manipulating the actual files and prepares the data for
#   subsequent jobs.
#
# - **File Size Validation**: The Python script checks if any individual
#   `.pod5` file exceeds the specified size limit. If such files are
#   detected, the script raises an error and aborts execution to maintain
#   pipeline integrity.
#
# - **List Generation for Job Distribution**: The Python script generates
#   a comprehensive `partitions.json` file that contains information about all
#   partitions, facilitating organized processing for downstream jobs.
#
# - **Environment Variable Exporting**: Exports all necessary variables to
#   ensure that `main_job.sh` has access to the required configurations and
#   paths.
#
# - **Job Submission**: Submits the `main_job.sh` script to the job scheduler
#   with appropriate resource allocations and naming conventions, ensuring
#   efficient and organized job management.
#
# Usage:
#   ./run_pipeline.sh
#
# Notes:
# - Before running the script, verify that the paths to directories and files
#   (e.g., ROOT_DIR, INPUT_DIR) are correct and accessible.
# - Adjust resource allocations and parameters as needed based on your data
#   and computational environment.
# - Ensure that all variables in the script are correctly set before running.
#
# The following variables  must be checked or specified, even if other variables are not.
# - GROUP, SAMPLE, MODIFIED_BASES, ROOT_DIR, SCRIPTS_DIR, INPUT_DIR, OUTPUT_DIR,
#   REFERENCE_FILE, ANNOTATION_FILE, MODEL_NAME, QSUB_PROJECT
#
# Author: Tayeb Jamali
# Date: 2024-11-13
# =============================================================================

# Enable strict error handling
set -euo pipefail

# =============================================================================
# Main Pipeline Variables
# =============================================================================

# -------------------- General Pipeline Variables ------------------------

GROUP="AD"                                                      # Experimental or biological group (e.g., Control, AD)
SAMPLE="XYZ"                                                    # Sample identifier (e.g., C0, A9)
MODIFIED_BASES="m5C inosine_m6A pseU"                           # String of RNA modifications (e.g., m5C, m6A_DRACH, inosine_m6A, pseU) separated by spaces. Note that m6A_DRACH cannot be used together with inosine_m6A.
ALL_MODS=$(echo "${MODIFIED_BASES}" | tr ' ' '_')               # Combine modifications into a single string separated by underscores

ROOT_DIR="/restricted/projectnb/leshlab/net/tjamali/project"    # Root directory of the project
SCRIPTS_DIR="${ROOT_DIR}/RNA_pipeline_ver_1.1/scripts"          # Pipeline's scripts directory

# -------------------- File Path Variables -------------------------------

ANNOTATION_FILE="${ROOT_DIR}/refs/gencode.v46.primary_assembly.annotation.bed"  # Path to the annotation BED file
REFERENCE_FILE="${ROOT_DIR}/refs/reference.mmi"                                 # Path to the reference .mmi file

# -------------------- Directory Path Variables --------------------------

INPUT_DIR="${ROOT_DIR}/RNA/${GROUP}/${SAMPLE}/pod5"             # Directory containing POD5 files for Dorado basecalling
OUTPUT_DIR="${ROOT_DIR}/RNA/${GROUP}/${SAMPLE}"                 # The base directory for output folders and files
UNALIGNED_BAM_DIR="${OUTPUT_DIR}/unaligned_bam_${ALL_MODS}"     # Directory to store unaligned BAM files from Dorado
ALIGNED_BAM_DIR="${OUTPUT_DIR}/aligned_bam_${ALL_MODS}"         # Directory to store aligned BAM files after alignment processing
TEMP_DIR="${OUTPUT_DIR}/tmp_folder_for_alignment"               # Temporary directory for alignment processing
MODKIT_OUTPUT_DIR="${ALIGNED_BAM_DIR}"                          # Define the output directory for modkit extractor (same as ALIGNED_BAM_DIR)

# -------------------- Python Partitioning Parameters ----------------------

SIZE_LIMIT=25       # GB - Size limit per partition

# Path to the Python partitioning script
PARTITION_SCRIPT="${SCRIPTS_DIR}/partition_pod5_files.py"       # Updated script name

# -------------------- Dorado Job Parameters ----------------------

TOTAL_CPUS_DORADO=4                                             # Total CPUs requested for Dorado
MODEL_NAME="hac@v5.1.0"                                         # Dorado model name (e.g., hac@v5.1.0)
MIN_QSCORE=9                                                    # Minimum quality score for filtering low-quality reads

TOTAL_GPUS_DORADO=1                                             # Total GPUs requested for Dorado
DORADO_JOB_RUNTIME="12:00:00"                                   # Defines the runtime limit for dorado job
DORADO_JOB_MEMORY="128G"                                        # Defines the memory requirement for dorado job
DORADO_GPU_TYPE="L40S"                                          # Defines the GPU type for dorado job

# -------------------- Alignment Job Parameters ----------------------

TOTAL_CPUS_ALIGN=16                                             # Total CPUs requested for Alignment
ALIGN_THREADS=$((TOTAL_CPUS_ALIGN - 2))                         # Number of threads for Alignment

ALIGN_JOB_RUNTIME="2:00:00"                                     # Defines the runtime limit for alignment job
ALIGN_JOB_MEMORY="64G"                                          # Defines the memory requirement for alignment job

# -------------------- Merge Job Parameters ----------------------

TOTAL_CPUS_MERGE=16                                             # Total CPUs requested for Merge
MERGE_THREADS=$((TOTAL_CPUS_MERGE - 2))                         # Number of threads for Merge

MERGE_JOB_RUNTIME="2:00:00"                                     # Defines the runtime limit for merge job
MERGE_JOB_MEMORY="64G"                                          # Defines the memory requirement for merge job

# -------------------- Modkit Job Parameters ------------------------

TOTAL_CPUS_MODKIT=16                                            # Total CPUs requested for Modkit
MODKIT_THREADS=$((TOTAL_CPUS_MODKIT - 2))                       # Number of threads for Modkit

MODKIT_JOB_RUNTIME="3:00:00"                                    # Defines the runtime limit for modkit job
MODKIT_JOB_MEMORY="64G"                                         # Defines the memory requirement for modkit job

# Define filter thresholds for modkit extractor
FILTER_THRESHOLD_ALL=0.8
FILTER_THRESHOLD_A=0.8
FILTER_THRESHOLD_C=0.8
FILTER_THRESHOLD_T=0.8

MOD_THRESHOLD_M6A=0.8
MOD_THRESHOLD_PSEU=0.8
MOD_THRESHOLD_INOSINE=0.8
MOD_THRESHOLD_M5C=0.8

VALID_COVERAGE_THRESHOLD=10                                     # Threshold for valid coverage
PERCENT_MODIFIED_THRESHOLD=10                                   # Threshold for percent modified

# --------------------------- QSUB General Parameters ----------------------------

QSUB_PROJECT="leshlab"                                          # SCC project name
QSUB_EMAIL="ea"                                                 # Email notifications on end/abort
QSUB_JOINT_STDERR="y"                                           # Combine stderr and stdout

# =============================================================================
# File Partitioning
# =============================================================================

# Determine the directory where run_pipeline.sh resides
# This ensures that partitions.json is saved in the same directory as run_pipeline.sh
BASH_SOURCE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Execute the Python partitioning script to generate partitioned file lists
python3 "${PARTITION_SCRIPT}" "${INPUT_DIR}" "${SIZE_LIMIT}" --output_dir "${BASH_SOURCE_DIR}"

# =============================================================================
# Main Job Submission
# =============================================================================

echo "============================================="
echo "Starting Nanopore Pipeline Submission"
echo "Group: ${GROUP}, Sample: ${SAMPLE}"
echo "============================================="

# Export variables to be available to main_job.sh
export GROUP SAMPLE MODIFIED_BASES ALL_MODS ROOT_DIR SCRIPTS_DIR BASH_SOURCE_DIR
export ANNOTATION_FILE REFERENCE_FILE
export INPUT_DIR UNALIGNED_BAM_DIR ALIGNED_BAM_DIR TEMP_DIR MODKIT_OUTPUT_DIR
export TOTAL_CPUS_DORADO MODEL_NAME MIN_QSCORE TOTAL_GPUS_DORADO DORADO_JOB_RUNTIME DORADO_JOB_MEMORY DORADO_GPU_TYPE
export TOTAL_CPUS_ALIGN ALIGN_THREADS ALIGN_JOB_RUNTIME ALIGN_JOB_MEMORY
export TOTAL_CPUS_MERGE MERGE_THREADS MERGE_JOB_RUNTIME MERGE_JOB_MEMORY
export TOTAL_CPUS_MODKIT MODKIT_THREADS MODKIT_JOB_RUNTIME MODKIT_JOB_MEMORY
export FILTER_THRESHOLD_ALL FILTER_THRESHOLD_A FILTER_THRESHOLD_C FILTER_THRESHOLD_T
export MOD_THRESHOLD_M6A MOD_THRESHOLD_PSEU MOD_THRESHOLD_INOSINE MOD_THRESHOLD_M5C
export VALID_COVERAGE_THRESHOLD PERCENT_MODIFIED_THRESHOLD
export QSUB_PROJECT QSUB_EMAIL QSUB_JOINT_STDERR

# Define job names based on the enhanced naming convention
MAIN_JOB_NAME="main_job_${GROUP}_${SAMPLE}"

# Define the main_job.sh script path
MAIN_JOB_SCRIPT="${SCRIPTS_DIR}/main_job.sh"

echo "Submitting Main Job..."

# Submit main_job.sh using qsub, passing necessary environment variables
MAIN_JOB_ID=$(qsub -terse -V \
    -P "${QSUB_PROJECT}" \
    -N "${MAIN_JOB_NAME}" \
    -l h_rt=1:00:00 \
    -m "${QSUB_EMAIL}" \
    -j "${QSUB_JOINT_STDERR}" \
    "${MAIN_JOB_SCRIPT}"
)

echo "Main Job submitted with Job ID: ${MAIN_JOB_ID}"
echo "Pipeline submission initiated successfully."
echo "============================================="

