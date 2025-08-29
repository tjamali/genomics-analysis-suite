#!/bin/bash -l

#---------------------------------------###------------------------------------------#
# This script is designed to run basecalling in non-interactive mode in SCC.
# This script is loading all the POD5 files in a directory.
#---------------------------------------###------------------------------------------#

#$ -P leshlab        # Specify the SCC project name you want to use
#$ -N basecaller     # Give the job a name
#$ -l h_rt=12:00:00  # Specify a hard time limit (12 hours)
#$ -l mem_free=128G  # Request 128GB memory
#$ -pe omp 4         # Request 4 cores
#$ -l gpus=1         # Request 1 GPU
#$ -l gpu_type=L40S  # Specify the GPU type
#$ -m ea             # Send email on job completion or abortion
#$ -j y              # Combine output and error files

# Keep track of information related to the current job
echo "=========================================================="
echo "Start date : $(date)"
echo "Job name : $JOB_NAME"
echo "Job ID : $JOB_ID  $SGE_TASK_ID"
echo "=========================================================="

# Load the miniconda module to access conda
module load miniconda || { echo "Failed to load miniconda module"; exit 2; }

# Activate the conda environment named nanopore
conda activate nanopore || { echo "Failed to activate conda environment nanopore"; exit 3; }

# Load the CUDA module to enable GPU support for the basecaller
module load cuda || { echo "Failed to load CUDA module"; exit 4; }

echo "Python executable: $(which python)"
echo "Python version: $(python --version)"

# Variables
REFERENCE_PATH="/restricted/projectnb/leshlab/net/tjamali/project/bonito_code/data/refs/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna"
INPUT_PATH="/restricted/projectnb/leshlab/net/tjamali/project/bonito_code/data/giab_2023.05/flowcells/hg002/20230428_1310_3H_PAO89685_c9d0d53f"
MODEL_NAME="dna_r10.4.1_e8.2_400bps_sup@v5.0.0"
CTC_DATA_PATH="/restricted/projectnb/leshlab/net/tjamali/project/bonito_code/data/training/ctc-data"
MIN_QSCORE=0
MIN_ACC=0.99

# Extract the model type from the MODEL_NAME (word before '@')
MODEL_TYPE=$(echo "$MODEL_NAME" | awk -F'@' '{print $1}' | awk -F'_' '{print $NF}')

# Check if the MODEL_TYPE is one of fast, hac, or sup. If not, exit with an error code.
if [[ "$MODEL_TYPE" != "fast" && "$MODEL_TYPE" != "hac" && "$MODEL_TYPE" != "sup" ]]; then
    echo "Error: Model type not recognized from the model name. Please specify the model type."
    exit 5
fi

# Extract the last directory name from the parent directory path
LAST_DIR_NAME=$(basename "$INPUT_PATH")

# Flag to check if there are subfolders
SUBFOLDER_FOUND=false

# Function to run basecalling
run_basecaller() {
    local SUBFOLDER_PATH="$1"
    local OUTPUT_BAM_PATH="$2"
    if [ -z "$REFERENCE_PATH" ]; then
        bonito basecaller "$MODEL_NAME" "$SUBFOLDER_PATH" > "$OUTPUT_BAM_PATH"
    else
        bonito basecaller "$MODEL_NAME" --save-ctc --reference "$REFERENCE_PATH" --min-qscore $MIN_QSCORE --min-accuracy-save-ctc $MIN_ACC "$SUBFOLDER_PATH" > "$OUTPUT_BAM_PATH"
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

# Loop through each subfolder in the parent directory
for SUBFOLDER in "$INPUT_PATH"/*; do
    if [ -d "$SUBFOLDER" ]; then
        # If a subfolder is found, set the flag to true
        SUBFOLDER_FOUND=true

        # Extract the subfolder name
        SUBFOLDER_NAME=$(basename "$SUBFOLDER")

        # Construct the output file path based on the subfolder name, last directory name, model type, min_qscore, and min_acc
        OUTPUT_BAM_PATH="$CTC_DATA_PATH/$LAST_DIR_NAME/$SUBFOLDER_NAME/${MODEL_TYPE}_qscore_${MIN_QSCORE}_acc_${MIN_ACC}/basecalls.bam"

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

    # Construct the output file path using the last two directory names, model type, min_qscore, and min_acc
    OUTPUT_BAM_PATH="$CTC_DATA_PATH/$PARENT_DIR_NAME/$LAST_DIR_NAME/${MODEL_TYPE}_qscore_${MIN_QSCORE}_acc_${MIN_ACC}/basecalls.bam"

    # Check if the directory exists and is empty
    check_directory "$(dirname "$OUTPUT_BAM_PATH")"

    # Run the basecaller function
    run_basecaller "$INPUT_PATH" "$OUTPUT_BAM_PATH"
fi

