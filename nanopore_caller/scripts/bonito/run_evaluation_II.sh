#!/bin/bash -l

#----------------------------------------###-------------------------------------------#
# This script is designed to run model evaluation in an interactive session on SCC 
# This script sets up the necessary environment, specifies paths, and runs the evaluation command.
# Ensure to first run the following command to activate an interactive session:
# qrsh -P leshlab -l h_rt=12:00:00 -l mem_free=128G -pe omp 4 -l gpus=1 -l gpu_type=L40S
#----------------------------------------###-------------------------------------------#

# Function to display usage format
usage() {
    echo "Usage: $0 <MODEL_DIR> <MODEL_WEIGHTS> <EVALUATION_DATA_DIR> [BONITO_MODEL_DIR]"
    echo
    echo "Arguments:"
    echo "  MODEL_DIR            The directory of the trained model to evaluate."
    echo "  MODEL_WEIGHTS        The weights to use for evaluating the trained model."
    echo "  EVALUATION_DATA_DIR  The directory containing evaluation data."
    echo "  BONITO_MODEL_DIR     (Optional) The directory of the Bonito model for comparison."
    echo
    echo "Example:"
    echo "  $0 /path/to/model_dir 15 /path/to/evaluation_data_dir /path/to/bonito_model_dir"
    exit 1
}

# Check if the minimum number of arguments is provided
if [ $# -lt 3 ]; then
    usage
fi

# Get the model directory from the first argument
MODEL_DIR=$1

# Get the model weights from the second argument
MODEL_WEIGHTS=$2

# Get the evaluation data directory from the third argument
EVALUATION_DATA_DIR=$3

# Get the Bonito model directory from the fourth argument if provided
BONITO_MODEL_DIR=$4

# Load modules and activate conda environment with error handling
module load miniconda || { echo "Failed to load miniconda module"; exit 2; }
conda activate nanopore || { echo "Failed to activate conda environment nanopore"; exit 3; }
module load cuda || { echo "Failed to load CUDA module"; exit 4; }

# Run bonito evaluate command for the trained model
echo "Evaluation result for the trained model:"
bonito evaluate "$MODEL_DIR" --directory "$EVALUATION_DATA_DIR" --chunks 50000 --weights "$MODEL_WEIGHTS"

# Run bonito evaluate command for the Bonito model if provided
if [ -n "$BONITO_MODEL_DIR" ]; then
    echo "Evaluation result for the Bonito model:"
    bonito evaluate "$BONITO_MODEL_DIR" --directory "$EVALUATION_DATA_DIR" --chunks 50000 --weights 1
fi

