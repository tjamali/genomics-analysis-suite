#!/bin/bash -l

# =============================================================================
#                                 dorado_job.sh
# =============================================================================
# Description:
#   This script automates the Dorado basecalling process for Nanopore sequencing data
#   within the Supercomputing Center (SCC) environment. It converts raw POD5 files
#   into unaligned BAM files, incorporating specified RNA modifications and quality
#   filtering parameters. The script ensures organized processing by handling multiple
#   samples and modification types, and it enforces strict validation and error handling
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
#        - Runs Dorado in a non-interactive mode to perform basecalling on raw POD5 files.
#        - Handles both scenarios where input data is organized in subdirectories and where it resides in a single directory.
#
#     5. **Output Management:**
#        - Stores unaligned BAM files in the designated output directory with clear and consistent naming conventions based on modification types and sample information.
#
#   **Workflow Overview:**
#
#     1. **Initialization Phase:**
#        - Parses and validates input arguments.
#        - Loads required modules.
#        - Validates the specified Dorado model type.
#
#     2. **Preparation Phase:**
#        - Iterates through input directories and subdirectories to identify POD5 files for basecalling.
#        - Constructs output file paths and ensures that output directories are ready.
#
#     3. **Execution Phase:**
#        - Executes Dorado basecalling for each identified POD5 file, directing the output to the appropriate unaligned BAM file.
#
#   **Job Dependencies:**
#     - **No Direct Dependencies:**
#       - This basecaller job is typically the first step in the pipeline and does not depend on any previous jobs.
#       - However, it may be part of a larger workflow managed by a main job submission script (e.g., `alignment_modkit_job.sh`) that handles dependencies between subsequent jobs.
#
#   **Input Path Format:**
#     - The input POD5 files must follow the directory structure:
#       ```
#       ${ROOT_DIR}/RNA/${GROUP}/${SAMPLE}/POD5_files/
#       ```
#       - `{ROOT_DIR}`: Root path of the project (e.g., `/restricted/projectnb/leshlab/net/tjamali/project`)
#       - `{GROUP}`: Experimental or biological group (e.g., `Control`, `AD`)
#       - `{SAMPLE}`: Specific sample identifier (e.g., `C0`, `A1`)
#
#   **Example Input Path:**
#   ```
#   ${ROOT_DIR}/RNA/Control/C0/POD5_files/
#   ```
#
#   **Output:**
#     - **Unaligned BAM Files (`${UNALIGNED_BAM_DIR}`):**
#       - Generated BAM files are stored in the specified unaligned BAM directory.
#       - Naming convention:
#         - For subdirectories: `${SUBFOLDER_NAME}/${MODEL_TYPE}_calls.bam`
#         - For single-directory inputs: `${MODEL_TYPE}_calls.bam`
#
#       - **Example Output Paths:**
#         ```
#         ${UNALIGNED_BAM_DIR}/C0/${MODEL_TYPE}_calls.bam
#         ${UNALIGNED_BAM_DIR}/${MODEL_TYPE}_calls.bam
#         ```
#
#   **Arguments:**
#     1. `GROUP`             - Experimental or biological group (e.g., `Control`, `AD`)
#     2. `SAMPLE`            - Sample identifier (e.g., `C0`, `A9`)
#     3. `MODIFIED_BASES`    - Space-separated string of RNA modifications (e.g., `"m5C m6A_DRACH inosine_m6A pseU"`)
#     4. `ALL_MODS`          - Combined modifications string separated by underscores (e.g., `"m5C_m6A_DRACH_inosine_m6A_pseU"`)
#     5. `ROOT_DIR`          - Root directory of the project (e.g., `/restricted/projectnb/leshlab/net/tjamali/project`)
#     6. `INPUT_DIR`         - Path to the POD5 input directory containing raw data
#     7. `UNALIGNED_BAM_DIR` - Directory where unaligned BAM files will be stored
#     8. `MODEL_NAME`        - Dorado model name (e.g., `hac@v5.1.0`)
#     9. `MIN_QSCORE`        - Minimum quality score for filtering low-quality reads (e.g., `9`)
#
#   **Notes:**
#     - **CUDA Module:**
#       - Ensure that the CUDA module version loaded is compatible with the installed version of Dorado.
#     
#     - **Dorado Accessibility:**
#       - The script assumes that the `dorado` command is available in the environment. If Dorado is installed in a non-standard location, consider adding the installation path to the `PATH` variable or modifying the script to reference the full path to the `dorado` executable.
#     
#     - **Input Data Structure:**
#       - The script is designed to handle both scenarios where POD5 files are organized within subdirectories and where they are placed directly within a single directory. It dynamically adjusts the output paths based on the presence of subdirectories.
#     
#     - **Resource Allocation:**
#       - Adjust resource requests (`h_rt`, `mem_free`, `pe smp`) in the job submission command based on the size of your data and the computational requirements of Dorado.
#     
#     - **Logging and Monitoring:**
#       - Implement additional logging if needed to capture more detailed information about the basecalling process, especially for large-scale pipelines.
#     
#     - **Parallel Processing:**
#       - The script is designed to be submitted as a single job. If you need to parallelize basecalling across multiple samples or groups, consider integrating this script within a larger workflow managed by a job scheduler that can handle multiple job submissions and dependencies.
#
# =============================================================================

# Enable strict error handling
set -euo pipefail

# ----------------------- Step 0: Parse Input Arguments -----------------------
if [ "$#" -ne 9 ]; then
    echo "Usage: $0 GROUP SAMPLE MODIFIED_BASES ALL_MODS ROOT_DIR INPUT_DIR UNALIGNED_BAM_DIR MODEL_NAME MIN_QSCORE"
    exit 1
fi

GROUP="${1}"                  # Experimental or biological group (e.g., Control, AD)
SAMPLE="${2}"                 # Sample identifier (e.g., C0, A9)
MODIFIED_BASES="${3}"         # String of modifications (e.g., m5C, m6A_DRACH, inosine_m6A, pseU) separated by spaces
ALL_MODS="${4}"               # Combined modifications string separated by underscores
ROOT_DIR="${5}"               # Root directory of the project
INPUT_DIR="${6}"              # Path to the POD5 input directory
UNALIGNED_BAM_DIR="${7}"      # Directory where unaligned BAM files will be stored
MODEL_NAME="${8}"             # Dorado model name (e.g., hac@v5.1.0)
MIN_QSCORE="${9}"             # Minimum quality score for filtering reads

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

# ----------------------- Step 4: Directory Validation Function -----------------------
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

# ----------------------- Step 5: Run Dorado Basecaller -----------------------
# Flag to check if there are subfolders
SUBFOLDER_FOUND=false

# Loop through each subfolder in the parent directory
for SUBFOLDER in "${INPUT_DIR}"/*; do
    if [ -d "$SUBFOLDER" ]; then
        # If a subfolder is found, set the flag to true
        SUBFOLDER_FOUND=true

        # Extract the subfolder name
        SUBFOLDER_NAME=$(basename "$SUBFOLDER")

        # Construct the output file path based on the subfolder name and model type
        OUTPUT_BAM_FILE="${UNALIGNED_BAM_DIR}/${SUBFOLDER_NAME}/${MODEL_TYPE}_calls.bam"

        # Check if the directory exists and is empty
        check_directory "$(dirname "$OUTPUT_BAM_FILE")"

        # Run the basecaller function
        dorado basecaller --modified-bases $MODIFIED_BASES --min-qscore $MIN_QSCORE "$MODEL_NAME" "$SUBFOLDER" > "$OUTPUT_BAM_FILE"
    fi
done

# If no subfolders are found, use the parent directory for basecalling
if [ "$SUBFOLDER_FOUND" = false ]; then
    # Construct the output file path
    OUTPUT_BAM_FILE="${UNALIGNED_BAM_DIR}/${MODEL_TYPE}_calls.bam"

    # Check if the directory exists and is empty
    check_directory "$(dirname "$OUTPUT_BAM_FILE")"

    # Run the basecaller function
    dorado basecaller --modified-bases $MODIFIED_BASES --min-qscore $MIN_QSCORE "$MODEL_NAME" "$INPUT_DIR" > "$OUTPUT_BAM_FILE"
fi

echo "Dorado Basecalling completed successfully."
echo "=========================================================="
echo "End date : $(date)"
echo "=========================================================="

