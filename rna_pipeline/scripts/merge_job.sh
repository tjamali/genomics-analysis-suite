#!/bin/bash -l

# =============================================================================
#                             merge_job.sh
# =============================================================================
# Description:
#   This script is an integral component of the Nanopore sequencing pipeline,
#   responsible for consolidating and refining the alignment results generated
#   by parallel array jobs. It automates the following sequential steps:
#
#     1. **Merge Individual Aligned BAM Files:**
#        - Combines all aligned BAM files produced by the array jobs into a single
#          merged BAM file using `samtools merge`.
#
#     2. **Sort the Merged BAM File:**
#        - Sorts the merged BAM file to organize reads in a coordinate-sorted manner,
#          facilitating efficient access and processing in downstream analyses.
#
#     3. **Index the Sorted BAM File:**
#        - Creates an index for the sorted BAM file using `samtools index`, enabling
#          rapid retrieval of specific regions during data exploration and analysis.
#
#     4. **Filter for Primary Alignments:**
#        - Filters the sorted BAM file to retain only primary alignments, excluding
#          secondary, supplementary, and duplicate alignments using `samtools view`.
#
#     5. **Sort the Filtered BAM File:**
#        - Sorts the filtered BAM file to ensure consistency and optimal structure
#          for downstream applications.
#
#     6. **Index the Filtered and Sorted BAM File:**
#        - Indexes the final filtered and sorted BAM file to support efficient querying
#          and visualization.
#
#     7. **Clean Up Intermediate Files:**
#        - Removes temporary and intermediate files to conserve storage space and
#          maintain a clean working directory.
#
#   **Final Output:**
#     - A single, sorted, indexed, and filtered BAM file containing only primary
#       alignments, ready for subsequent analyses such as variant calling or visualization.
#
#   **Job Dependencies:**
#     - **Merge Job** (`merge_job.sh`) is dependent on the successful completion of all
#       **Alignment Array Jobs** (`array_job.sh`). These dependencies are managed externally
#       by the main job submission script (e.g., `alignment_modkit_job.sh`) using job
#       scheduling parameters to ensure that merging only occurs after all alignment tasks
#       are completed.
#
# Arguments:
#   1. OUTPUT_DIR      - Directory where the final merged and processed BAM files will be stored.
#   2. SAMPLE_NAME     - Identifier for the sample being processed (e.g., C0, A9).
#   3. GROUP_NAME      - Identifier for the experimental or biological group (e.g., Control, AD).
#   4. MERGE_THREADS   - Number of threads to allocate for merging and sorting operations.
#
# Usage:
#   This script is intended to be submitted as a dependent job via `qsub` or an equivalent
#   job scheduler after the completion of all Alignment Array Jobs.
#
# Notes:
#   - Ensure that all input directories and files exist and have the appropriate
#     read/write permissions before executing the script.
#   - Adjust resource requests (`h_rt`, `mem_free`, `pe omp`) based on the size
#     and number of BAM files to be merged to optimize performance and resource utilization.
#   - Monitor job submissions and statuses using scheduler-specific commands (e.g., `qstat`, `squeue`).
#   - Maintain consistent naming conventions for BAM files to facilitate accurate merging.
#
# =============================================================================

# Enable strict error handling
set -euo pipefail

# ----------------------- Step 0: Load Necessary Modules -----------------------
module load samtools || { echo "Failed to load samtools module"; exit 1; }

# ----------------------- Step 1: Parse Input Arguments -----------------------
OUTPUT_DIR="${1}"
SAMPLE_NAME="${2}"
GROUP_NAME="${3}"
MERGE_THREADS="${4}"

# ----------------------- Step 2: Job Information -----------------------
echo "=========================================================="
echo "Start date : $(date)"
echo "Job name : $JOB_NAME"
echo "Job ID : $JOB_ID"
# Only echo SGE_TASK_ID if it's set
if [[ -n "${SGE_TASK_ID-}" ]]; then
    echo "Task ID : $SGE_TASK_ID"
fi
echo "=========================================================="

# ----------------------- Step 3: Merge All BAM Files -----------------------
FINAL_BAM="${OUTPUT_DIR}/final_merged.bam"

echo "Merging BAM files into '${FINAL_BAM}' using ${MERGE_THREADS} threads..."
samtools merge -@ "${MERGE_THREADS}" "${FINAL_BAM}" "${OUTPUT_DIR}"/*_aligned.bam

# Remove individual aligned BAM files after successful merge
echo "Removing individual aligned BAM files..."
rm "${OUTPUT_DIR}"/*_aligned.bam

# ----------------------- Step 4: Sort the Final BAM File -----------------------
SORTED_BAM="${OUTPUT_DIR}/${GROUP_NAME}_${SAMPLE_NAME}.bam"

echo "Sorting the merged BAM file into '${SORTED_BAM}'..."
samtools sort -@ "${MERGE_THREADS}" -o "${SORTED_BAM}" "${FINAL_BAM}"

# ----------------------- Step 5: Index the Sorted BAM File -----------------------
echo "Indexing the sorted BAM file '${SORTED_BAM}'..."
samtools index "${SORTED_BAM}"

# ----------------------- Step 6: Filter for Primary Alignments -----------------------
PRIMARY_BAM="${SORTED_BAM%.bam}_primary.bam"

echo "Filtering primary alignments into '${PRIMARY_BAM}'..."
samtools view -@ "${MERGE_THREADS}" -b -F 0x100 -F 0x800 "${SORTED_BAM}" > "${PRIMARY_BAM}"

# ----------------------- Step 7: Sort Filtered BAM File -----------------------
SORTED_BAM="${PRIMARY_BAM%.bam}_sorted.bam"

echo "Sorting the primary BAM file into '${SORTED_BAM}'..."
samtools sort -@ "${MERGE_THREADS}" -o $SORTED_BAM $PRIMARY_BAM

mv $SORTED_BAM $PRIMARY_BAM

# ----------------------- Step 8: Index the Filtered BAM File -----------------------
echo "Indexing the filtered BAM file '${PRIMARY_BAM}'..."
samtools index "${PRIMARY_BAM}"

# ----------------------- Step 9: Clean Up Intermediate Files -----------------------
echo "Cleaning up intermediate file '${FINAL_BAM}'..."
rm "${FINAL_BAM}"

# Inform the user of completion
echo "Merging, sorting, indexing, and extracting primary reads completed successfully."
echo "Final BAM file: ${PRIMARY_BAM}"
echo "=========================================================="
echo "End date : $(date)"
echo "=========================================================="

