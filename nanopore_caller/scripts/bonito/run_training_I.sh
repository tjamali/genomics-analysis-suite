#!/bin/bash -l

#----------------------------------------###-------------------------------------------#
# This script submits a job to SCC using qsub for training a basecaller model.
# It sets up the environment, specifies job requirements, and runs the training command.
#----------------------------------------###-------------------------------------------#

#$ -P leshlab          # Specify the SCC project name
#$ -N training         # Job name
#$ -l h_rt=18:00:00    # Specify a hard time limit (12 hours)
#$ -l mem_free=128G    # Request 128GB of memory
#$ -pe omp 4           # Request 4 OpenMP threads
#$ -l gpus=1           # Request 1 GPU
#$ -l gpu_type=L40S    # Specify the GPU type
#$ -m ea               # Send an email when the job finishes or is aborted
#$ -j y                # Combine output and error files into a single file

# Job information
echo "=========================================================="
echo "Start date : $(date)"
echo "Job name   : $JOB_NAME"
echo "Job ID     : $JOB_ID  $SGE_TASK_ID"
echo "=========================================================="

# Define variables
MODEL_NUM=2
EXP_NUM=14
BONITO_PATH="/restricted/projectnb/leshlab/net/tjamali/project/bonito_code"
DATASET_PATH="$BONITO_PATH/data/training/ctc-data/20230428_1310_3H_PAO89685_c9d0d53f/subfolder_0/sup_qscore_0_acc_0.995"
CONFIG_PATH="$BONITO_PATH/models/configs/dna_r10.4.1_hac@v5.1.0.toml"

# Extract the run folder from DATASET_PATH
RUN_FOLDER=$(echo "$DATASET_PATH" | awk -F'/' '{print $(NF-2)}')

# Extract the model type from CONFIG_PATH (word before '@')
MODEL_TYPE=$(basename "$CONFIG_PATH" | awk -F'@' '{print $1}' | awk -F'_' '{print $NF}')

# Check if the MODEL_TYPE is one of hac, sup, or fast. If not, exit with error.
if [[ "$MODEL_TYPE" != "hac" && "$MODEL_TYPE" != "sup" && "$MODEL_TYPE" != "fast" ]]; then
    echo "Error: MODEL_TYPE cannot be found from the config filename. It must contains 'hac', 'sup', or 'fast'. Exiting."
    exit 1
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

echo "Python executable: $(which python)"
echo "Python version   : $(python --version)"

# Run Bonito training
bonito train -f "$MODEL_OUTPUT_PATH" --directory "$DATASET_PATH" --config "$CONFIG_PATH" --lr 2e-3 --epochs 15

