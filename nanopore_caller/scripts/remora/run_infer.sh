#!/bin/bash -l

#---------------------------------------###------------------------------------------#
# This script is designed to run Remora inference in non-interactive mode on SCC.
#---------------------------------------###------------------------------------------#

#$ -P leshlab        # Specify the SCC project name you want to use
#$ -N remora_infer   # Give the job a name
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

# Load the CUDA module to enable GPU support
module load cuda || { echo "Failed to load CUDA module"; exit 4; }


# Variables
INPUT_POD5="/restricted/projectnb/leshlab/net/tjamali/project/RNA/AD/A1/temp"
INPUT_BAM="/restricted/projectnb/leshlab/net/tjamali/project/RNA/AD/A1/aligned_bam_pass_inosine/a1_primary.bam"
OUTPUT_BAM="/restricted/projectnb/leshlab/net/tjamali/project/RNA/AD/A1/aligned_bam_pass_inosine/a1_mod.bam"

# Run Remora inference
remora infer from_pod5_and_bam "$INPUT_POD5" "$INPUT_BAM" --out-bam "$OUTPUT_BAM" --pore rna004_130bps --modified-bases inos || { echo "Remora inference failed"; exit 5; }

echo "=========================================================="
echo "End date : $(date)"
echo "=========================================================="

