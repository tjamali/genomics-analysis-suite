#!/bin/bash -l

#----------------------------------------###-------------------------------------------#
# This script runs basecalling in an interactive session on SCC using the qrsh command.
# This script loads all subfolders containing POD5 files and then runs the basecaller 
# for them one by one.
# Ensure to first run the following command to activate an interactive session:
# qrsh -P leshlab -l h_rt=12:00:00 -l mem_free=128G -pe omp 4 -l gpus=1 -l gpu_type=L40S
#----------------------------------------###-------------------------------------------#

# Function to display usage format
usage() {
    echo "Usage: $0 <INPUT_PATH> [REFERENCE_PATH] [MODEL_NAME] [MIN_QSCORE] [MIN_ACC]"
    echo
    echo "Arguments:"
    echo "  INPUT_PATH          The parent directory containing subfolders with POD5 files."
    echo "  REFERENCE_PATH      (Optional) The reference file path."
    echo "  MODEL_NAME          (Optional) The model name to use for basecalling. If not provided,"
    echo "                      you will be prompted to choose from a list of available models."
    echo "  MIN_QSCORE          (Optional) Minimum quality score."
    echo "  MIN_ACC             (Optional) Minimum accuracy."
    echo
    echo "Example:"
    echo "  $0 /path/to/input_dir /path/to/reference_file dna_r10.4.1_e8.2_400bps_sup@v5.0.0 0 0.999"
    exit 1
}

# Check if no arguments are provided
if [ $# -lt 1 ]; then
    usage
fi

# Get the parent directory from the first argument
INPUT_PATH=$1

# Get the reference file path from the second argument, if provided
REFERENCE_PATH=$2

# List of available models
AVAILABLE_MODELS=(
    "dna_r10.4.1_e8.2_400bps_sup@v5.0.0"
    "dna_r10.4.1_e8.2_400bps_hac@v5.0.0"
    "dna_r10.4.1_e8.2_400bps_fast@v5.0.0"
    # Add more models here if needed
)

# Get the model name from the third argument
MODEL_NAME=$3

# If the model name is not provided, show the list of available models and prompt the user to choose one
if [ -z "$MODEL_NAME" ]; then
    echo "Available models:"
    for i in "${!AVAILABLE_MODELS[@]}"; do
        echo "$i) ${AVAILABLE_MODELS[$i]}"
    done
    read -p "Choose a model by number: " MODEL_NUMBER
    MODEL_NAME=${AVAILABLE_MODELS[$MODEL_NUMBER]}
fi

# Get the minimum quality score from the fourth argument, if provided
MIN_QSCORE=$4

# Get the minimum accuracy from the fifth argument, if provided
MIN_ACC=$5

# Extract the model type from the MODEL_NAME (term before '@')
MODEL_TYPE=$(echo "$MODEL_NAME" | awk -F'@' '{print $1}' | awk -F'_' '{print $NF}')

# Check if the MODEL_TYPE is one of hac, sup, or fast. If not, prompt the user to input the MODEL_TYPE.
if [[ "$MODEL_TYPE" != "hac" && "$MODEL_TYPE" != "sup" && "$MODEL_TYPE" != "fast" ]]; then
    read -p "Model type not recognized. Please enter the model type (e.g., hac, sup, fast): " MODEL_TYPE
fi

# Extract the last directory name from the parent directory path
LAST_DIR_NAME=$(basename "$INPUT_PATH")

# Flag to check if there are subfolders
SUBFOLDER_FOUND=false

# Base directory for output
CTC_DATA_PATH="/restricted/projectnb/leshlab/net/tjamali/project/bonito_code/data/training/ctc-data"

# Function to run basecalling
run_basecaller() {
    local SUBFOLDER_PATH="$1"
    local OUTPUT_BAM_PATH="$2"
    if [ -z "$REFERENCE_PATH" ]; then
        bonito basecaller "$MODEL_NAME" "$SUBFOLDER_PATH" > "$OUTPUT_BAM_PATH"
    else
        bonito basecaller "$MODEL_NAME" --save-ctc --reference "$REFERENCE_PATH" --min-qscore ${MIN_QSCORE:-0} --min-accuracy-save-ctc ${MIN_ACC:-0.999} "$SUBFOLDER_PATH" > "$OUTPUT_BAM_PATH"
    fi
}

# Function to check if directory exists and is empty
check_directory() {
    local DIR_PATH="$1"
    if [ -d "$DIR_PATH" ]; then
        if [ "$(ls -A $DIR_PATH)" ]; then
            echo "Error: Directory already exists and is not empty. Exiting."
            exit 1
        else
            echo "Directory exists but is empty. Proceeding."
        fi
    else
        mkdir -p "$DIR_PATH"
        echo "Directory created: $DIR_PATH"
    fi
}

# Function to construct output path
construct_output_path() {
    local BASE_PATH="$1"
    local MODEL_TYPE="$2"
    local MIN_QSCORE="$3"
    local MIN_ACC="$4"

    if [ -z "$MIN_QSCORE" ] && [ -z "$MIN_ACC" ]; then
        echo "$BASE_PATH/$MODEL_TYPE/basecalls.bam"
    elif [ -z "$MIN_QSCORE" ]; then
        echo "$BASE_PATH/${MODEL_TYPE}_acc_${MIN_ACC}/basecalls.bam"
    elif [ -z "$MIN_ACC" ]; then
        echo "$BASE_PATH/${MODEL_TYPE}_qscore_${MIN_QSCORE}/basecalls.bam"
    else
        echo "$BASE_PATH/${MODEL_TYPE}_qscore_${MIN_QSCORE}_acc_${MIN_ACC}/basecalls.bam"
    fi
}

# Load modules and activate conda environment with error handling
module load miniconda || { echo "Failed to load miniconda module"; exit 2; }
conda activate nanopore || { echo "Failed to activate conda environment nanopore"; exit 3; }
module load cuda || { echo "Failed to load CUDA module"; exit 4; }


# Loop through each subfolder in the parent directory
for SUBFOLDER in "$INPUT_PATH"/*; do
    if [ -d "$SUBFOLDER" ]; then
        # If a subfolder is found, set the flag to true
        SUBFOLDER_FOUND=true

        # Extract the subfolder name
        SUBFOLDER_NAME=$(basename "$SUBFOLDER")

        # Construct the output file path
        OUTPUT_BAM_PATH=$(construct_output_path "$CTC_DATA_PATH/$LAST_DIR_NAME/$SUBFOLDER_NAME" "$MODEL_TYPE" "$MIN_QSCORE" "$MIN_ACC")

        # Check if the directory exists and is empty
        check_directory "$(dirname "$OUTPUT_BAM_PATH")"

        # Run the basecaller function
        run_basecaller "$SUBFOLDER" "$OUTPUT_BAM_PATH"
    fi
done

# If no subfolders are found, use the parent directory for basecalling
if [ "$SUBFOLDER_FOUND" = false ]; then
    # Get the last two directory names
    PARENT_DIR_NAME=$(basename "$(dirname "$INPUT_PATH")")

    # Construct the output file path
    OUTPUT_BAM_PATH=$(construct_output_path "$CTC_DATA_PATH/$PARENT_DIR_NAME/$LAST_DIR_NAME" "$MODEL_TYPE" "$MIN_QSCORE" "$MIN_ACC")

    # Check if the directory exists and is empty
    check_directory "$(dirname "$OUTPUT_BAM_PATH")"

    # Run the basecaller function
    run_basecaller "$INPUT_PATH" "$OUTPUT_BAM_PATH"
fi

