# Load the miniconda module to access conda
module load miniconda || { echo "Failed to load miniconda module"; exit 2; }

# Activate the conda environment named nanopore
conda activate nanopore || { echo "Failed to activate conda environment nanopore"; exit 3; }

# Load the CUDA module to enable GPU support
#module load cuda || { echo "Failed to load CUDA module"; exit 4; }

# Root directory of the project
ROOT_DIR="/restricted/projectnb/leshlab/net/tjamali/project"

# Define file paths
CAN_BAM="${ROOT_DIR}/remora_dataset/basecalls/control_rep1.bam"
CAN_POD5="${ROOT_DIR}/remora_dataset/subset/control_rep1.pod5"
CAN_CHUNKS="${ROOT_DIR}/remora_dataset/training_dataset/can_chunks"

MOD_BAM="${ROOT_DIR}/remora_dataset/basecalls/5mC_rep1.bam"
MOD_POD5="${ROOT_DIR}/remora_dataset/subset/5mC_rep1.pod5"
MOD_CHUNKS="${ROOT_DIR}/remora_dataset/training_dataset/mod_chunks"

KMER_LEVEL_TABLE="${ROOT_DIR}/remora_dataset/5mer_levels.txt"

TRAIN_DATASET="${ROOT_DIR}/remora_dataset/training_dataset/train_dataset.jsn"
TRAIN_LOG="${ROOT_DIR}/remora_dataset/training_dataset/train_dataset.log"

# Step 1: Data Preparation

# Run the remora commands
remora dataset prepare "$CAN_POD5" "$CAN_BAM" \
  --output-path "$CAN_CHUNKS" \
  --refine-kmer-level-table "$KMER_LEVEL_TABLE" \
  --refine-rough-rescale \
  --motif CG 0 \
  --mod-base-control \
#  --num-extract-chunks-workers 8

remora dataset prepare "$MOD_POD5" "$MOD_BAM" \
  --output-path "$MOD_CHUNKS" \
  --refine-kmer-level-table "$KMER_LEVEL_TABLE" \
  --refine-rough-rescale \
  --motif CG 0 \
  --mod-base m 5mC


# Step 2: Composing Training Datasets

# Run the remora command
remora dataset make_config "$TRAIN_DATASET" "$CAN_CHUNKS" "$MOD_CHUNKS" \
  --dataset-weights 1 1 \
  --log-filename "$TRAIN_LOG"

