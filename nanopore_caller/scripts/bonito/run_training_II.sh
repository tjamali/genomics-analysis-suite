#!/bin/bash -l

#----------------------------------------###-------------------------------------------#
# This script is designed to submit a job to SCC using an interactive session for
# training a model. It sets up the necessary environment, specifies job requirements,
# and runs the training command.
# Ensure to first run the following command to activate an interactive session:
# qrsh -P leshlab -l h_rt=12:00:00 -l mem_free=128G -pe omp 4 -l gpus=1 -l gpu_type=L40S
#----------------------------------------###-------------------------------------------#

# Function to display usage format
usage() {
    echo "Usage: $0 <DATASET_PATH> <CONFIG_PATH> <MODEL_NUM> <EXP_NUM>"
    echo
    echo "Arguments:"
    echo "  DATASET_PATH    The full path to the training dataset."
    echo "                  Example: .../bonito_code/data/training/ctc-data/20230428_1310_3H_PAO89685_c9d0d53f/subfolder_0/sup_qscore_0_acc_0.995"
    echo
    echo "  CONFIG_PATH     The path to the configuration file used for training."
    echo "                  Example: .../bonito_code/models/configs/dna_r10.4.1_hac@v5.0.toml"
    echo
    echo "  MODEL_NUM       The model number to use in naming the output directory."
    echo "                  Example: 1"
    echo
    echo "  EXP_NUM         The experiment number to use in naming the output directory."
    echo "                  Example: 12"
    echo
    echo "Example:"
    echo "  $0 .../sup_qscore_0_acc_0.995 .../dna_r10.4.1_hac@v5.0.toml 1 12"
    exit 1
}

# Check if all required arguments are provided
if [ "$#" -ne 4 ]; then
    usage
fi

# Get inputs from command-line arguments
DATASET_PATH=$1
CONFIG_PATH=$2
MODEL_NUM=$3
EXP_NUM=$4

# Define the base BONITO path
BONITO_PATH="/restricted/projectnb/leshlab/net/tjamali/project/bonito_code"

# Extract the third folder from DATASET_PATH as RUN_FOLDER
RUN_FOLDER=$(echo "$DATASET_PATH" | awk -F'/' '{print $(NF-2)}')

# Extract the model type from the CONFIG_PATH (word before '@')
MODEL_TYPE=$(basename "$CONFIG_PATH" | awk -F'@' '{print $1}' | awk -F'_' '{print $NF}')

# Check if the MODEL_TYPE is one of hac, sup, or fast. If not, prompt the user to input the MODEL_TYPE.
if [[ "$MODEL_TYPE" != "hac" && "$MODEL_TYPE" != "sup" && "$MODEL_TYPE" != "fast" ]]; then
    read -p "Model type not recognized. Please enter the model type (e.g., hac, sup, fast): " MODEL_TYPE
fi

# Define output path for saving the trained model
MODEL_OUTPUT_PATH="$BONITO_PATH/data/training/model/$RUN_FOLDER/$MODEL_TYPE/model_${MODEL_NUM}_exp_${EXP_NUM}"

# Function to check if directory exists and is empty
check_directory() {
    local DIR_PATH="$1"
    if [ -d "$DIR_PATH" ]; then
        if [ "$(ls -A "$DIR_PATH")" ]; then
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

# Check if MODEL_OUTPUT_PATH exists and is not empty
check_directory "$MODEL_OUTPUT_PATH"

# Load modules and activate conda environment with error handling
module load miniconda || { echo "Failed to load miniconda module"; exit 2; }
conda activate nanopore || { echo "Failed to activate conda environment nanopore"; exit 3; }
module load cuda || { echo "Failed to load CUDA module"; exit 4; }

# Run bonito train command
bonito train -f "$MODEL_OUTPUT_PATH" --directory "$DATASET_PATH" --config "$CONFIG_PATH" --lr 2e-3 --epochs 15

