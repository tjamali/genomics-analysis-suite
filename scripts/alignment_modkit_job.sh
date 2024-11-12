#!/bin/bash -l

# =============================================================================
#                         alignment_modkit_job.sh
# =============================================================================
# Description:
#   This script orchestrates the alignment processing and modification extraction
#   as part of a bioinformatics pipeline. It automates the submission of a series
#   of jobs to the Slurm (or PBS) job scheduler, ensuring that each step is executed
#   in the correct order through job dependencies.
#
#   The pipeline consists of the following sequential steps:
#
#   1. **Preparation of Temporary Alignment Directory:**
#      - Creates a temporary directory (`TEMP_DIR`) to store BAM files ready for alignment.
#      - Copies and renames BAM files from the unaligned BAM directory (`UNALIGNED_BAM_DIR`)
#        to the temporary directory, ensuring consistent naming conventions.
#
#   2. **Submission of Alignment Array Job:**
#      - Submits an array job (`ALIGN_ARRAY_JOB`) where each task aligns a single BAM file.
#      - The number of array tasks corresponds to the number of BAM files prepared.
#      - Captures the **master job ID** of the array job to establish dependencies for subsequent jobs.
#
#   3. **Submission of Merge Job with Dependency:**
#      - Submits a Merge job (`MERGE_JOB`) that aggregates the results from all alignment tasks.
#      - This job is dependent on the successful completion of the entire Alignment Array Job.
#      - Utilizes the `-hold_jid` parameter to ensure it only starts after the array job finishes.
#
#   4. **Submission of Modkit Extractor Job with Dependency:**
#      - Submits a Modkit Extraction job (`MODKIT_JOB`) that performs downstream analysis on the merged data.
#      - This job is dependent on the successful completion of the Merge Job.
#      - Ensures proper sequencing by holding until the Merge Job completes.
#
#   **Job Dependencies:**
#     - **Merge Job** depends on the **Alignment Array Job**: The Merge Job will only start after all tasks in the Alignment Array Job have successfully completed.
#     - **Modkit Extraction Job** depends on the **Merge Job**: The Modkit Extraction Job will only start after the Merge Job has successfully completed.
#
# Usage:
#   This script is intended to be submitted via `qsub` from `main_job.sh`.
#   Example:
#     qsub alignment_modkit_job.sh GROUP SAMPLE UNALIGNED_BAM_DIR TEMP_DIR ALIGNED_BAM_DIR \
#         ANNOTATION_FILE REFERENCE_FILE ALIGN_THREADS MERGE_THREADS MODKIT_THREADS \
#         QSUB_PROJECT TOTAL_CPUS_ALIGN TOTAL_CPUS_MERGE TOTAL_CPUS_MODKIT ROOT_DIR \
#         MODIFIED_BASES ALL_MODS MODKIT_OUTPUT_DIR FILTER_THRESHOLD_ALL FILTER_THRESHOLD_A \
#         FILTER_THRESHOLD_C FILTER_THRESHOLD_T MOD_THRESHOLD_M6A MOD_THRESHOLD_PSEU \
#         MOD_THRESHOLD_INOSINE MOD_THRESHOLD_M5C VALID_COVERAGE_THRESHOLD PERCENT_MODIFIED_THRESHOLD
#
# =============================================================================

# ----------------------------- Configuration ----------------------------------

# Enable strict error handling
set -euo pipefail

# =============================================================================
# Define Variables from Environment
# =============================================================================

# All variables are assumed to be exported from main_job.sh
# No need to assign them here unless transformation is needed

# =============================================================================
# Pipeline Steps
# =============================================================================

echo "Starting Alignment Processing for Group: ${GROUP}, Sample: ${SAMPLE}"

# ----------------------- Step 1: Prepare Temporary Alignment Directory -----------------------
echo "Creating temporary alignment directory if it doesn't exist..."
mkdir -p "${TEMP_DIR}"

# Initialize a counter for naming BAM files
COUNTER=0

# Check if there are any subdirectories within the UNALIGNED_BAM_DIR
SUBFOLDERS=("${UNALIGNED_BAM_DIR}"/*/)
if [ -d "${SUBFOLDERS[0]}" ]; then
    # Loop through each subdirectory in the unaligned BAM directory
    for SUBFOLDER in "${UNALIGNED_BAM_DIR}"/*/; do
        # Find the BAM file within the subdirectory
        BAM_FILE=$(find "${SUBFOLDER}" -maxdepth 1 -name "*.bam")

        # If a BAM file is found, copy it to the TEMP_DIR with a numbered name
        if [ -n "${BAM_FILE}" ]; then
            cp "${BAM_FILE}" "${TEMP_DIR}/calls_${COUNTER}.bam"
            COUNTER=$((COUNTER + 1))  # Increment the counter
        else
            echo "No BAM file found in ${SUBFOLDER}."
        fi
    done
else
    # If no subdirectories, check for BAM files directly in the UNALIGNED_BAM_DIR
    BAM_FILE=$(find "${UNALIGNED_BAM_DIR}" -maxdepth 1 -name "*.bam")

    if [ -n "${BAM_FILE}" ]; then
        cp "${BAM_FILE}" "${TEMP_DIR}/calls.bam"
        COUNTER=1
    else
        echo "No BAM file found in ${UNALIGNED_BAM_DIR}."
        exit 1  # Exit if no BAM files are found
    fi
fi

echo "Prepared ${COUNTER} BAM file(s) for alignment processing."

# ----------------------- Step 2: Submit Alignment Array Job -----------------------
echo "Submitting Alignment Job as an array job..."

# Ensure the ALIGNED_BAM_DIR exists
mkdir -p "${ALIGNED_BAM_DIR}"

# Determine the number of BAM files in TEMP_DIR for alignment job submission
BAM_COUNT=$(ls "${TEMP_DIR}"/*.bam 2>/dev/null | wc -l)
if [ "${BAM_COUNT}" -eq 0 ]; then
    echo "No BAM files found in ${TEMP_DIR}. Exiting."
    exit 1
fi

# Define job name
ALIGN_ARRAY_JOB_NAME="align_array_job_${GROUP}_${SAMPLE}"

# Submit the alignment job as an array job and capture the array job ID
ALIGN_ARRAY_JOB_FULL_ID=$(qsub -terse \
    -t 1-"${BAM_COUNT}" \
    -P "${QSUB_PROJECT}" \
    -N "${ALIGN_ARRAY_JOB_NAME}" \
    -l h_rt=2:00:00 \
    -l mem_free=64G \
    -pe omp "${TOTAL_CPUS_ALIGN}" \
    -m ea \
    -j y \
    "${ROOT_DIR}/RNA_pipeline/scripts/align_array_job.sh" \
    "${TEMP_DIR}" "${ALIGNED_BAM_DIR}" "${ANNOTATION_FILE}" "${REFERENCE_FILE}" "${ALIGN_THREADS}"
)

# Print the full job ID for debugging
echo "Full Array Job Output: ${ALIGN_ARRAY_JOB_FULL_ID}"

# Extract the master job ID (adjust the parsing as needed based on the actual format)
ALIGN_ARRAY_JOB_ID=$(echo "${ALIGN_ARRAY_JOB_FULL_ID}" | cut -d '.' -f1)

# Optional: Verify the extracted job ID
echo "Extracted Master Job ID: ${ALIGN_ARRAY_JOB_ID}"

echo "Alignment Array Job submitted with Master Job ID: ${ALIGN_ARRAY_JOB_ID}"
echo

# ----------------------- Step 3: Submit Merge Job with Dependency -----------------------
echo "Submitting Merge Job with dependency on Alignment Array Job..."

# Define Merge Job Name
MERGE_JOB_NAME="merge_job_${GROUP}_${SAMPLE}"

MERGE_JOB_ID=$(qsub -terse \
    -hold_jid "${ALIGN_ARRAY_JOB_ID}" \
    -P "${QSUB_PROJECT}" \
    -N "${MERGE_JOB_NAME}" \
    -l h_rt=2:00:00 \
    -l mem_free=64G \
    -pe omp "${TOTAL_CPUS_MERGE}" \
    -m ea \
    -j y \
    "${ROOT_DIR}/RNA_pipeline/scripts/merge_job.sh" \
    "${ALIGNED_BAM_DIR}" "${SAMPLE}" "${GROUP}" "${MERGE_THREADS}"
)

echo "Merge Job submitted with Job ID: ${MERGE_JOB_ID}"
echo

# ----------------------- Step 4: Submit Modkit Extractor Job with Dependency -----------------------
echo "Submitting Modkit Extractor Job with dependency on Merge Job..."

# Define Modkit Job Name
MODKIT_JOB_NAME="modkit_job_${GROUP}_${SAMPLE}"

MODKIT_JOB_ID=$(qsub -terse \
    -hold_jid "${MERGE_JOB_ID}" \
    -P "${QSUB_PROJECT}" \
    -N "${MODKIT_JOB_NAME}" \
    -l h_rt=3:00:00 \
    -l mem_free=64G \
    -pe omp "${TOTAL_CPUS_MODKIT}" \
    -m ea \
    -j y \
    "${ROOT_DIR}/RNA_pipeline/scripts/modkit_job.sh" \
    "${GROUP}" "${SAMPLE}" "${MODIFIED_BASES}" "${ALL_MODS}" "${ROOT_DIR}" "${ALIGNED_BAM_DIR}" "${MODKIT_OUTPUT_DIR}" \
    "${FILTER_THRESHOLD_ALL}" "${FILTER_THRESHOLD_A}" "${FILTER_THRESHOLD_C}" "${FILTER_THRESHOLD_T}" \
    "${MOD_THRESHOLD_M6A}" "${MOD_THRESHOLD_PSEU}" "${MOD_THRESHOLD_INOSINE}" "${MOD_THRESHOLD_M5C}" \
    "${VALID_COVERAGE_THRESHOLD}" "${PERCENT_MODIFIED_THRESHOLD}" "${MODKIT_THREADS}"
)

echo "Modkit Extractor Job submitted with Job ID: ${MODKIT_JOB_ID}"
echo

# ----------------------------- Completion Message ----------------------------
echo "Alignment processing and subsequent jobs have been submitted successfully."
echo "============================================="
echo "Alignment Array Job ID: ${ALIGN_ARRAY_JOB_ID}"
echo "Merge Job ID: ${MERGE_JOB_ID}"
echo "Modkit Extractor Job ID: ${MODKIT_JOB_ID}"
echo "============================================="

