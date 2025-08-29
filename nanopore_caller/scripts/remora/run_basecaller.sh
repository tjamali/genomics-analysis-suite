#!/bin/bash -l
#
# Script Name: run_basecaller.sh
#
# Description:
#   This script performs GPU-accelerated basecalling on a .pod5 input file using the
#   Dorado basecaller. It loads the CUDA module, sets up necessary directories and
#   variables, checks for existing output to prevent overwrites, and executes the
#   basecalling process with specified parameters such as reference file and minimum
#   quality score. It prepares the bam file needed for training Remora.
#
# Usage:
#   ./run_basecaller.sh
#
# Requirements:
#   - CUDA module
#   - Dorado basecaller
#
# Outputs:
#   - BAM file with high-quality basecalled reads in the specified output directory
#

# Load the CUDA module to enable GPU support for the basecaller

module load cuda || { echo "Failed to load CUDA module"; exit 2; }

# Variables
ROOT_DIR="/restricted/projectnb/leshlab/net/tjamali/project/remora_dataset"
INPUT_FILE="${ROOT_DIR}/subset/5mC_rep2.pod5"
OUTPUT_DIR="${ROOT_DIR}/basecalls"
REFERENCE_FILE="${ROOT_DIR}/references/all_5mers.fa"
MODEL_NAME="sup@v5.0.0"
MIN_QSCORE=9  # This int value is used for filtering out low quality reads

# Function to check if output file exists
check_output_file() {
    local FILE="$1"
    if [ -f "$FILE" ]; then
        echo "Error: Output file already exists: $FILE. Exiting."
        exit 1
    else
        echo "Output file does not exist. Proceeding."
    fi
}

# Ensure the output directory exists
if [ ! -d "$OUTPUT_DIR" ]; then
    echo "Output directory does not exist. Creating: $OUTPUT_DIR"
    mkdir -p "$OUTPUT_DIR"
else
    echo "Output directory exists: $OUTPUT_DIR"
fi

# Construct the output file path
FILENAME=$(basename "$INPUT_FILE" .pod5)
OUTPUT_BAM_FILE="$OUTPUT_DIR/${FILENAME}.bam"

# Check if the output file exists
check_output_file "$OUTPUT_BAM_FILE"

dorado basecaller --reference "$REFERENCE_FILE" --emit-moves --min-qscore $MIN_QSCORE "$MODEL_NAME" "$INPUT_FILE" > "$OUTPUT_BAM_FILE"

