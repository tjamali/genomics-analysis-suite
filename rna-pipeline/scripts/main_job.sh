#!/bin/bash -l

# =============================================================================
#                              main_job.sh
# =============================================================================
# Description:
#   This script orchestrates the execution of a bioinformatics pipeline by
#   submitting sub-jobs for Dorado Basecalling and Alignment using a job
#   scheduler (e.g., PBS, SGE, SLURM). It ensures that each step is executed
#   in the correct sequence through job dependencies, facilitating efficient
#   and automated processing of Nanopore sequencing data.
#
#   **Primary Functions:**
#
#     1. **Dorado Basecalling Submission:**
#        - Submits a Dorado basecalling job (`dorado_job.sh`) that converts raw POD5 files
#          into unaligned BAM files.
#        - Utilizes GPU acceleration for efficient processing by requesting appropriate
#          GPU resources.
#
#     2. **Alignment & Modkit Extraction Submission:**
#        - Submits an Alignment & Modkit Extraction job (`alignment_modkit_job.sh`) that
#          aligns the basecalled reads to a reference genome and extracts RNA modifications.
#        - This job is dependent on the successful completion of the Dorado Basecalling job,
#          ensuring proper sequencing within the pipeline.
#        - Internally, `alignment_modkit_job.sh` handles further job submissions for merging
#          and modification extraction.
#
#   **Job Dependencies:**
#     - **Dorado Basecalling Job (`dorado_job.sh`):**
#       - **Dependency:** None (it is the initial step in the pipeline).
#       - **Function:** Converts raw POD5 files into unaligned BAM files using Dorado.
#
#     - **Alignment & Modkit Extraction Job (`alignment_modkit_job.sh`):**
#       - **Dependency:** Must complete successfully after the Dorado Basecalling Job.
#       - **Function:** Aligns the basecalled reads to a reference genome and extracts RNA modifications.
#       - **Internal Dependencies:** Manages the submission of Merge and Modkit Extraction sub-jobs.
#
#   **Execution Context:**
#     - This script is intended to be submitted via `qsub` (or an equivalent job scheduler command)
#       from a higher-level script (e.g., `run_pipeline.sh`).
#     - It assumes that the necessary environment modules and tools (`qsub`, `dorado`, etc.)
#       are available and properly configured in the execution environment.
#
#   **Arguments:**
#     This script does not directly accept command-line arguments. Instead, it relies on
#     environment variables or variables defined within the script to specify parameters
#     such as group name, sample identifier, directories, and resource allocations.
#
#   **Usage:**
#     This script should **not** be run directly. Instead, use the higher-level script
#     `run_pipeline.sh` to submit it, ensuring that all necessary environment variables
#     and configurations are properly set.
#
#     **Example Submission Command via `run_pipeline.sh`:**
#     ```bash
#     qsub main_job.sh
#     ```
#
#   **Notes:**
#     - Ensure that all required variables are exported in the environment or defined
#       within `run_pipeline.sh` before submitting `main_job.sh`.
#     - Adjust resource requests (`h_rt`, `mem_free`, `pe omp`, `gpus`, `gpu_type`)
#       based on the specific requirements of your computational environment and the
#       size of the data being processed.
#     - Monitor job submissions and statuses using scheduler-specific commands
#       (e.g., `qstat` for PBS, `squeue` for SLURM).
#     - Maintain consistent naming conventions for jobs to facilitate easier tracking
#       and management within the job scheduler.
#
# =============================================================================

# Enable strict error handling
set -euo pipefail

# ----------------------- Step 0: Validate Partitions JSON -----------------------
PARTITIONS_JSON="${BASH_SOURCE_DIR}/partitions.json"  # Default path to partitions.json

if [ ! -f "${PARTITIONS_JSON}" ]; then
    echo "[ERROR] partitions.json not found at '${PARTITIONS_JSON}'. Aborting."
    exit 1
fi

# ----------------------- Step 1: Submit Dorado Basecalling Job -----------------------
echo "Submitting Dorado Basecalling Job to process all partitions..."

# Define Dorado job name
DORADO_JOB_NAME="dorado_job_${GROUP}_${SAMPLE}"

# Submit the Dorado basecalling script with necessary arguments and qsub options
DORADO_JOB_ID=$(qsub -terse -V \
    -P "${QSUB_PROJECT}" \
    -N "${DORADO_JOB_NAME}" \
    -l h_rt="${DORADO_JOB_RUNTIME}" \
    -l mem_free="${DORADO_JOB_MEMORY}" \
    -pe omp "${TOTAL_CPUS_DORADO}" \
    -l gpus="${TOTAL_GPUS_DORADO}" \
    -l gpu_type="${DORADO_GPU_TYPE}" \
    -m "${QSUB_EMAIL}" \
    -j "${QSUB_JOINT_STDERR}" \
    "${SCRIPTS_DIR}/dorado_job.sh" \
    "${MODIFIED_BASES}" "${UNALIGNED_BAM_DIR}" "${MODEL_NAME}" "${MIN_QSCORE}" "${PARTITIONS_JSON}"
)

echo "Dorado Basecalling Job submitted with Job ID: ${DORADO_JOB_ID}"
echo

# ----------------------- Step 2: Submit Alignment & Modkit Extraction Job -----------------------
echo "Submitting Alignment & Modkit Job for Alignment Processing and Extracting Modifications..."

# Define Alignment & Modkit Extraction job name
ALIGN_MODKIT_JOB_NAME="align_modkit_job_${GROUP}_${SAMPLE}"

# Submit alignment_modkit_job.sh with dependency on Dorado job
ALIGN_MODKIT_JOB_ID=$(qsub -terse -V \
    -hold_jid "${DORADO_JOB_ID}" \
    -P "${QSUB_PROJECT}" \
    -N "${ALIGN_MODKIT_JOB_NAME}" \
    -l h_rt=1:00:00 \
    -m "${QSUB_EMAIL}" \
    -j "${QSUB_JOINT_STDERR}" \
    "${SCRIPTS_DIR}/alignment_modkit_job.sh"
)

echo "Alignment Job submitted with Job ID: ${ALIGN_MODKIT_JOB_ID}"
echo

# ----------------------------- Completion Message ----------------------------
echo "Pipeline submission complete."
echo "============================================="
echo "Dorado Job ID: ${DORADO_JOB_ID}"
echo "Alignment & Modkit Extraction Job ID: ${ALIGN_MODKIT_JOB_ID}"
echo "============================================="

