#!/bin/bash

# =============================================================================
#                             run_pipeline.sh
# =============================================================================
# Description:
# This script initializes all necessary variables for the Nanopore pipeline
# and submits the main_job.sh script to the job scheduler (qsub). It serves
# as the entry point for executing the entire pipeline.
#
# Enhancements:
# - **Pod5 Files Segregation**: If pod5 files are present directly within
#   INPUT_DIR alongside subfolders, the script invokes the Python script
#   (distribute_files_by_size.py) to move these pod5 files into a separate
#   directory named `pod5_segregated_folder`. This ensures a clean directory
#   structure by preventing mixed content within INPUT_DIR.
#
# - **Pod5 File Size Validation**: After segregation, the script checks if any
#   individual pod5 file exceeds the specified size limit (22 GB). If such files
#   are detected, the script raises an error and aborts execution to maintain
#   pipeline integrity.
#
# - **File Distribution into Subfolders**: If the total size of INPUT_DIR
#   exceeds the specified size limit (22 GB), the Python script distributes
#   the pod5 files into subfolders within INPUT_DIR, ensuring that each
#   subfolder does not exceed the size limit. This prevents memory issues
#   during downstream processing.
#
# - **Empty Subfolders Cleanup**: Regardless of whether file distribution
#   occurs, the script ensures that any empty subfolders within INPUT_DIR are
#   removed, maintaining an organized directory structure.
#
# Usage:
#   ./run_pipeline.sh
#
# Author: Tayeb Jamali
# Date: 2024-11-7
# =============================================================================

# ----------------------------- Configuration ----------------------------------

# Enable strict error handling
set -euo pipefail

# =============================================================================
# Main Pipeline Variables
# =============================================================================

# -------------------- General Pipeline Variables ------------------------

GROUP="AD"                                         # Experimental or biological group (e.g., Control, AD)
SAMPLE="XYZ"                                       # Sample identifier (e.g., C0, A9)
MODIFIED_BASES="m5C inosine_m6A pseU"              # String of RNA modifications (e.g., m5C, m6A_DRACH, inosine_m6A, pseU) separated by spaces. Note that m6A_DRACH cannot be used together with inosine_m6A.
ALL_MODS=$(echo "${MODIFIED_BASES}" | tr ' ' '_')  # Combine modifications into a single string separated by underscores

ROOT_DIR="/restricted/projectnb/leshlab/net/tjamali/project"  # Root directory of the project

# -------------------- File Path Variables -------------------------------

ANNOTATION_FILE="${ROOT_DIR}/refs/gencode.v46.primary_assembly.annotation.bed"  # Path to the annotation BED file
REFERENCE_FILE="${ROOT_DIR}/refs/reference.mmi"                                 # Path to the reference .mmi file

# -------------------- Directory Path Variables --------------------------

INPUT_DIR="${ROOT_DIR}/RNA/${GROUP}/${SAMPLE}/pod5"                               # Directory containing POD5 files for Dorado basecalling
UNALIGNED_BAM_DIR="${ROOT_DIR}/RNA/${GROUP}/${SAMPLE}/unaligned_bam_${ALL_MODS}"  # Directory to store unaligned BAM files from Dorado
ALIGNED_BAM_DIR="${ROOT_DIR}/RNA/${GROUP}/${SAMPLE}/aligned_bam_${ALL_MODS}"      # Directory to store aligned BAM files after alignment processing
TEMP_DIR="${ROOT_DIR}/RNA/${GROUP}/${SAMPLE}/tmp_folder_for_alignment"            # Temporary directory for alignment processing
MODKIT_OUTPUT_DIR="${ALIGNED_BAM_DIR}"                                            # Define the output directory for modkit extractor (same as ALIGNED_BAM_DIR)

# -------------------- Python Distribution Parameters ----------------------

SIZE_LIMIT=22       # GB - Size limit per subfolder

# Path to the Python distribution script
DISTRIBUTE_SCRIPT="${ROOT_DIR}/RNA_pipeline/scripts/distribute_files_by_size.py"  # Update the path as necessary

# -------------------- Dorado Basecalling Parameters ----------------------

TOTAL_CPUS_DORADO=4                        # Total CPUs requested for Dorado
MODEL_NAME="hac@v5.1.0"                    # Dorado model name (e.g., hac@v5.1.0)
MIN_QSCORE=9                               # Minimum quality score for filtering low-quality reads

# -------------------- Alignment Parameters ----------------------

TOTAL_CPUS_ALIGN=16                        # Total CPUs requested for Alignment
ALIGN_THREADS=$((TOTAL_CPUS_ALIGN - 2))    # Number of threads for Alignment

# -------------------- Merge Parameters ----------------------

TOTAL_CPUS_MERGE=16                        # Total CPUs requested for Merge
MERGE_THREADS=$((TOTAL_CPUS_MERGE - 2))    # Number of threads for Merge

# -------------------- Modkit Extractor Parameters ------------------------

TOTAL_CPUS_MODKIT=16                       # Total CPUs requested for Modkit
MODKIT_THREADS=$((TOTAL_CPUS_MODKIT - 2))  # Number of threads for Modkit

# Define filter thresholds for modkit extractor
FILTER_THRESHOLD_ALL=0.8
FILTER_THRESHOLD_A=0.8
FILTER_THRESHOLD_C=0.8
FILTER_THRESHOLD_T=0.8

MOD_THRESHOLD_M6A=0.8
MOD_THRESHOLD_PSEU=0.8
MOD_THRESHOLD_INOSINE=0.8
MOD_THRESHOLD_M5C=0.8

VALID_COVERAGE_THRESHOLD=10        # Threshold for valid coverage
PERCENT_MODIFIED_THRESHOLD=10      # Threshold for percent modified

# ----------------------------- QSUB Parameters ------------------------------

QSUB_PROJECT="leshlab"          # SCC project name
QSUB_EMAIL="ea"                 # Email notifications on end/abort
QSUB_JOINT_STDERR="y"           # Combine stderr and stdout

# ------------------------- Distribute Files by Size -------------------------
# Execute the Python distribution script
python3 "${DISTRIBUTE_SCRIPT}" "${INPUT_DIR}" "${INPUT_DIR}" "${SIZE_LIMIT}"

# ----------------------------- Submit Main Job -------------------------------

echo "============================================="
echo "Starting Nanopore Pipeline Submission"
echo "Group: ${GROUP}, Sample: ${SAMPLE}"
echo "============================================="

# Export variables to be available to main_job.sh
export GROUP SAMPLE MODIFIED_BASES ALL_MODS ROOT_DIR
export ANNOTATION_FILE REFERENCE_FILE
export INPUT_DIR UNALIGNED_BAM_DIR ALIGNED_BAM_DIR TEMP_DIR MODKIT_OUTPUT_DIR
export TOTAL_CPUS_DORADO MODEL_NAME MIN_QSCORE
export TOTAL_CPUS_ALIGN ALIGN_THREADS
export TOTAL_CPUS_MERGE MERGE_THREADS
export TOTAL_CPUS_MODKIT MODKIT_THREADS
export FILTER_THRESHOLD_ALL FILTER_THRESHOLD_A FILTER_THRESHOLD_C FILTER_THRESHOLD_T
export MOD_THRESHOLD_M6A MOD_THRESHOLD_PSEU MOD_THRESHOLD_INOSINE MOD_THRESHOLD_M5C
export VALID_COVERAGE_THRESHOLD PERCENT_MODIFIED_THRESHOLD
export QSUB_PROJECT QSUB_EMAIL QSUB_JOINT_STDERR

# Define job names based on the enhanced naming convention
MAIN_JOB_NAME="main_job_${GROUP}_${SAMPLE}"

# Define the main_job.sh script path
MAIN_JOB_SCRIPT="${ROOT_DIR}/RNA_pipeline/scripts/main_job.sh"

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
