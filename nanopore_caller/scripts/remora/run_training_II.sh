# Load the miniconda module to access conda
module load miniconda || { echo "Failed to load miniconda module"; exit 2; }

# Activate the conda environment named nanopore
conda activate nanopore || { echo "Failed to activate conda environment nanopore"; exit 3; }

# Load the CUDA module to enable GPU support
#module load cuda || { echo "Failed to load CUDA module"; exit 4; }

# Root directory of the project
ROOT_DIR="/restricted/projectnb/leshlab/net/tjamali/project"

# Get the current date and time in YYYYMMDD_HHMMSS format
RUN_DATETIME=$(date +"%Y%m%d_%H%M%S")

# Define file paths
MODEL="${ROOT_DIR}/remora_code/models/Conv_TransLocal_w_ref.py"
TRAINING_RESULTS="${ROOT_DIR}/remora_output/training_results_${RUN_DATETIME}"
TRAIN_DATASET="${ROOT_DIR}/remora_dataset/training_dataset/train_dataset.jsn"

# Run the remora command
remora model train "$TRAIN_DATASET" \
  --model "$MODEL" \
  --device 0 \
  --lr 1e-4 \
  --num-test-chunks 20000 \
  --chunk-context 50 50 \
  --output-path "$TRAINING_RESULTS" \
  --size 32
