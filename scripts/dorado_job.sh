#!/bin/bash -l

# =============================================================================
#                                 dorado_job.sh
# =============================================================================
# Description:
#   This script automates the Dorado basecalling process for Nanopore sequencing data
#   within the Supercomputing Center (SCC) environment. It converts raw POD5 files
#   into unaligned BAM files, incorporating specified RNA modifications and quality
#   filtering parameters. The script ensures organized processing by handling multiple
#   partitions of data and enforces strict validation and error handling
#   to maintain pipeline integrity.
#
#   **Primary Functions:**
#     1. **Argument Parsing and Validation:**
#        - Ensures that all required input arguments are provided.
#        - Validates the existence and correctness of input directories and files.
#        - Confirms that the specified Dorado model type is supported.
#
#     2. **Environment Setup:**
#        - Loads necessary modules (e.g., CUDA) required for Dorado execution.
#
#     3. **Directory Management:**
#        - Checks and prepares output directories to prevent data conflicts and ensure proper file organization.
#
#     4. **Dorado Basecalling Execution:**
#        - Runs Dorado in a non-interactive mode to perform basecalling on raw POD5 files within each partition.
#        - Processes multiple POD5 files per partition, handling scenarios where input data is organized in partitions.
#
#     5. **Output Management:**
#        - Stores unaligned BAM files in the designated output directory with clear and consistent naming conventions based on the model type and partition.
#
#   **Workflow Overview:**
#
#     1. **Initialization Phase:**
#        - Parses and validates input arguments.
#        - Loads required modules.
#        - Validates the specified Dorado model type.
#
#     2. **Preparation Phase:**
#        - Reads the `partitions.json` file to identify partitions and associated POD5 files.
#        - Constructs output file paths and ensures that output directories are ready.
#
#     3. **Execution Phase:**
#        - Iterates through each partition, copies the associated POD5 files to a temporary directory, and executes Dorado basecalling.
#        - Directs the basecalling output to a single unaligned BAM file per partition.
#
#   **Job Dependencies:**
#     - **No Direct Dependencies:**
#       - This basecaller job is typically the first step in the pipeline and does not depend on any previous jobs.
#       - However, it may be part of a larger workflow managed by a main job submission script (e.g., `alignment_modkit_job.sh`) that handles dependencies between subsequent jobs.
#
#   **Input Path Format:**
#     - The input POD5 files are specified within a `partitions.json` file, which lists file paths organized by partitions. The expected structure of `partitions.json` is as follows:
#       ```json
#       {
#           "partition_1": {
#               "/path/to/file1.pod5": size1,
#               "/path/to/file2.pod5": size2,
#               ...
#           },
#           "partition_2": {
#               "/path/to/file3.pod5": size3,
#               "/path/to/file4.pod5": size4,
#               ...
#           },
#           ...
#       }
#       ```
#       - Each partition (e.g., `partition_1`) contains key-value pairs where keys are the full paths to POD5 files and values represent file sizes.
#
#   **Output:**
#     - **Unaligned BAM Files (`${UNALIGNED_BAM_DIR}`):**
#       - Generated BAM files are stored in the specified unaligned BAM directory, organized by partition.
#       - Naming convention:
#         - For each partition: `${UNALIGNED_BAM_DIR}/${PARTITION}/${MODEL_TYPE}_calls.bam`
#
#
#   **Arguments:**
#     1. `MODIFIED_BASES`    - Space-separated string of RNA modifications (e.g., `"m5C m6A_DRACH inosine_m6A pseU"`)
#     2. `ROOT_DIR`          - Root directory of the project (e.g., `/restricted/projectnb/leshlab/net/tjamali/project`)
#     3. `MODEL_NAME`        - Dorado model name (e.g., `hac@v5.1.0`)
#     4. `MIN_QSCORE`        - Minimum quality score for filtering low-quality reads (e.g., `9`)
#     5. `PARTITIONS_JSON`   - Path to the `partitions.json` file specifying POD5 file paths
#
#   **Notes:**
#     - **CUDA Module:**
#       - Ensure that the CUDA module version loaded is compatible with the installed version of Dorado.
#
#     - **Dorado Accessibility:**
#       - The script assumes that the `dorado` command is available in the environment. If Dorado is installed in a non-standard location, consider adding the installation path to the `PATH` variable or modifying the script to reference the full path to the `dorado` executable.
#
#     - **Input Data Structure:**
#       - The script is designed to handle multiple partitions as defined in the `partitions.json` file. Each partition can contain multiple POD5 files, and the script processes each partition independently.
#
#     - **Resource Allocation:**
#       - Adjust resource requests (`h_rt`, `mem_free`, `pe smp`) in the job submission command based on the size of your data and the computational requirements of Dorado.
#
#     - **Logging and Monitoring:**
#       - Implement additional logging if needed to capture more detailed information about the basecalling process, especially for large-scale pipelines.
#
#     - **Parallel Processing:**
#       - The script is designed to process partitions sequentially within a single job. If you need to parallelize basecalling across multiple partitions, consider modifying the script or integrating it within a larger workflow managed by a job scheduler that can handle multiple job submissions and dependencies.
#
# =============================================================================

# Enable strict error handling
set -euo pipefail

# ----------------------- Step 0: Parse Input Arguments -----------------------
if [ "$#" -ne 5 ]; then
    echo "Usage: $0 MODIFIED_BASES UNALIGNED_BAM_DIR MODEL_NAME MIN_QSCORE PARTITIONS_JSON"
    exit 1
fi

MODIFIED_BASES="${1}"         # Space-separated string of RNA modifications (e.g., "m5C inosine_m6A pseU")
UNALIGNED_BAM_DIR="${2}"      # Directory where unaligned BAM files will be stored
MODEL_NAME="${3}"             # Dorado model name (e.g., hac@v5.1.0)
MIN_QSCORE="${4}"             # Minimum quality score for filtering reads
PARTITIONS_JSON="${5}"        # Path to the partitions.json file

# ----------------------- Step 1: Job Information -----------------------
echo "=========================================================="
echo "Start date : $(date)"
echo "Job name : $JOB_NAME"
echo "Job ID : $JOB_ID"
# Only echo SGE_TASK_ID if it's set
if [[ -n "${SGE_TASK_ID-}" ]]; then
    echo "Task ID : $SGE_TASK_ID"
fi
echo "=========================================================="

# ----------------------- Step 2: Load Necessary Modules -----------------------
module load cuda || { echo "Failed to load CUDA module"; exit 2; }

# ----------------------- Step 3: Validate Model Type -----------------------
# Extract the model type from the MODEL_NAME (word before '@')
MODEL_TYPE=$(echo "$MODEL_NAME" | awk -F'@' '{print $1}')

# Check if the MODEL_TYPE is one of fast, hac, or sup. If not, exit with an error code.
if [[ "$MODEL_TYPE" != "fast" && "$MODEL_TYPE" != "hac" && "$MODEL_TYPE" != "sup" ]]; then
    echo "Error: Model type not recognized from the model name. Please specify the model type."
    exit 3
fi

# ----------------------- Step 4: Validate Partitions JSON -----------------------
if [ ! -f "${PARTITIONS_JSON}" ]; then
    echo "[ERROR] partitions.json not found at '${PARTITIONS_JSON}'."
    exit 4
fi

# ----------------------- Step 5: Define Directory Validation Function -----------------------
# Function to check if directory exists and is empty
check_directory() {
    local DIR_PATH="$1"
    if [ -d "$DIR_PATH" ]; then
        if [ "$(ls -A "$DIR_PATH")" ]; then
            echo "Error: Directory '$DIR_PATH' already exists and is not empty. Exiting."
            exit 1
        else
            echo "Directory exists but is empty. Proceeding."
        fi
    else
        mkdir -p "$DIR_PATH"
        echo "Directory created: $DIR_PATH"
    fi
}

# ----------------------- Step 6: Define Cleanup Function -----------------------
# Function to clean up temporary directories upon exit
cleanup() {
    if [[ -d "$TEMP_DIR" ]]; then
        rm -rf "$TEMP_DIR"
        echo "Cleaned up temporary directory: $TEMP_DIR"
    fi
}
trap cleanup EXIT

# ----------------------- Step 7: Parse Partitions JSON and Run Dorado -----------------------
# Ensure jq is installed
if ! command -v jq &> /dev/null; then
    echo "[ERROR] jq is not installed. Please install jq to parse JSON files."
    exit 5
fi

# Read all partition names
PARTITIONS=$(jq -r 'keys[]' "$PARTITIONS_JSON")

# Iterate through each partition
for PARTITION in $PARTITIONS; do
    echo "Processing ${PARTITION}..."

    # Extract all POD5 file paths for the current partition
    POD5_FILES=$(jq -r --arg partition "$PARTITION" '.[$partition] | keys[]' "$PARTITIONS_JSON")

    # Define the output BAM directory and BAM file path for this partition
    OUTPUT_BAM_DIR="${UNALIGNED_BAM_DIR}/${PARTITION}"
    OUTPUT_BAM_FILE="${OUTPUT_BAM_DIR}/${MODEL_TYPE}_calls.bam"

    # Validate the output directory
    check_directory "${OUTPUT_BAM_DIR}"

    # Define the temporary directory within UNALIGNED_BAM_DIR with naming pattern "${PARTITION}_pod5"
    TEMP_DIR="${UNALIGNED_BAM_DIR}/${PARTITION}_pod5"
    mkdir -p "${TEMP_DIR}"
    echo "Temporary directory created: ${TEMP_DIR}"

    # Copy POD5 files into the temporary directory
    for POD5_FILE in $POD5_FILES; do
        if [ -f "${POD5_FILE}" ]; then
            cp "${POD5_FILE}" "${TEMP_DIR}/" || { echo "Failed to copy ${POD5_FILE}"; exit 6; }
        else
            echo "Warning: POD5 file '${POD5_FILE}' does not exist. Skipping."
        fi
    done

    # Run Dorado basecaller on the temporary directory
    echo "Running Dorado basecaller for ${PARTITION}..."
    dorado basecaller --modified-bases $MODIFIED_BASES --min-qscore $MIN_QSCORE "$MODEL_NAME" "$TEMP_DIR" > "$OUTPUT_BAM_FILE"

    echo "Dorado basecalling for ${PARTITION} completed successfully. Output: ${OUTPUT_BAM_FILE}"

    # Clean up the temporary directory
    rm -rf "${TEMP_DIR}"

    echo "Removed temporary directory: ${TEMP_DIR}"
    echo "----------------------------------------------------------"
done

echo "All partitions have been processed successfully."
echo "=========================================================="
echo "End date : $(date)"
echo "=========================================================="
