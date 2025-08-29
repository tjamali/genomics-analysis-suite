#!/bin/bash -l
#
# Script Name: run_basecaller.sh
#
# Description:
#   This script performs GPU-accelerated basecalling on .pod5 input files using the
#   Dorado basecaller. It loads the CUDA module, sets up necessary directories and
#   variables, checks for existing output to prevent overwrites, executes the
#   basecalling process with specified parameters such as reference file and minimum
#   quality score, sorts the resulting BAM files using samtools (replacing the
#   unsorted BAMs), and creates index files for the sorted BAMs. It prepares the
#   BAM files needed for training Remora.
#
# Usage:
#   ./run_basecaller.sh
#
# Requirements:
#   - CUDA module
#   - Dorado basecaller
#   - samtools
#
# Outputs:
#   - Sorted BAM files with high-quality basecalled reads in the specified output directory
#   - Index files for each sorted BAM file
#

# Enable strict error handling
set -euo pipefail

# Load the CUDA module to enable GPU support for the basecaller
module load cuda || { echo "Failed to load CUDA module"; exit 2; }

# Load samtools module if necessary (uncomment the following line if samtools is managed via modules)
module load samtools || { echo "Failed to load samtools module"; exit 2; }

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

# Ensure necessary environment variables are set
required_vars=(BASECALL_OUTPUT_DIR MOD_POD5 CAN_POD5 REFERENCE_FILE DORADO_MIN_QSCORE DORADO_MODEL_NAME)
for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        echo "Error: Environment variable $var is not set. Exiting."
        exit 1
    fi
done

# Ensure the output directory exists
if [ ! -d "$BASECALL_OUTPUT_DIR" ]; then
    echo "Output directory does not exist. Creating: $BASECALL_OUTPUT_DIR"
    mkdir -p "$BASECALL_OUTPUT_DIR"
else
    echo "Output directory exists: $BASECALL_OUTPUT_DIR"
fi

# Construct the output file paths
MOD_FILENAME=$(basename "$MOD_POD5" .pod5)
OUTPUT_MOD_BAM_FILE="${BASECALL_OUTPUT_DIR}/${MOD_FILENAME}.bam"

CAN_FILENAME=$(basename "$CAN_POD5" .pod5)
OUTPUT_CAN_BAM_FILE="${BASECALL_OUTPUT_DIR}/${CAN_FILENAME}.bam"

# Check if the output files already exist
check_output_file "$OUTPUT_MOD_BAM_FILE"
check_output_file "$OUTPUT_CAN_BAM_FILE"

# Execute the basecalling process
echo "Starting Dorado basecalling..."
dorado basecaller --reference "$REFERENCE_FILE" --emit-moves --min-qscore "$DORADO_MIN_QSCORE" "$DORADO_MODEL_NAME" "$MOD_POD5" > "$OUTPUT_MOD_BAM_FILE"
dorado basecaller --reference "$REFERENCE_FILE" --emit-moves --min-qscore "$DORADO_MIN_QSCORE" "$DORADO_MODEL_NAME" "$CAN_POD5" > "$OUTPUT_CAN_BAM_FILE"
echo "Dorado basecalling completed successfully."

# Sort and index the BAM files using samtools, replacing the original BAM files
echo "Starting sorting and indexing of BAM files with samtools..."

# Function to sort and index a BAM file
sort_and_index_bam() {
    local BAM_FILE="$1"

    echo "Sorting BAM file: $BAM_FILE"
    # Define a temporary sorted BAM file
    local TEMP_SORTED_BAM="${BAM_FILE}.sorted.bam"

    # Sort the BAM file
    samtools sort "$BAM_FILE" -o "$TEMP_SORTED_BAM"
    echo "Sorted BAM file created: $TEMP_SORTED_BAM"

    # Replace the original BAM file with the sorted BAM file
    mv "$TEMP_SORTED_BAM" "$BAM_FILE"
    echo "Replaced original BAM file with sorted BAM file: $BAM_FILE"

    # Index the sorted BAM file
    echo "Indexing sorted BAM file: $BAM_FILE"
    samtools index "$BAM_FILE"
    echo "Index file created: ${BAM_FILE}.bai"
}

# Sort and index MOD BAM file
sort_and_index_bam "$OUTPUT_MOD_BAM_FILE"

# Sort and index CAN BAM file
sort_and_index_bam "$OUTPUT_CAN_BAM_FILE"

echo "Sorting and indexing of BAM files completed successfully."

echo "All processes completed successfully."

