#!/bin/bash -l

#---------------------------------------###------------------------------------------#
# This script is designed to run basecalling in non-interactive mode in SCC.
# This script is loading all the POD5 files in a directory.
#---------------------------------------###------------------------------------------#

#$ -P leshlab        # Specify the SCC project name you want to use
#$ -N basecaller     # Give the job a name
#$ -l h_rt=6:00:00  # Specify a hard time limit (12 hours)
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

# Load the CUDA module to enable GPU support for the basecaller
module load cuda || { echo "Failed to load CUDA module"; exit 2; }


# Variables
GROUP="Control"          # Experimental or biological group (e.g., Control, AD)
SAMPLE="C12"        # Sample identifier (e.g., C0, A9)
MODIFIED_BASES="m6A_DRACH"  # String of modifications (e.g., m5C, inosine_m6A, pseU, m6A_DRACH) separated by spaces
ALL_MODS=$(echo "${MODIFIED_BASES}" | tr ' ' '_')  # Combine modifications into a single string separated by underscores

ROOT_DIR="/restricted/projectnb/leshlab/net/tjamali/project"
REFERENCE_PATH="${ROOT_DIR}/refs/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna"
INPUT_PATH="${ROOT_DIR}/RNA/${GROUP}/${SAMPLE}/pod5"
OUTPUT_PATH="${ROOT_DIR}/RNA/${GROUP}/${SAMPLE}/unaligned_bam_${ALL_MODS}"
MODEL_NAME="hac@v5.1.0"
MIN_QSCORE=9  # This int value is used for filtering out low quality reads

# Extract the model type from the MODEL_NAME (word before '@')
MODEL_TYPE=$(echo "$MODEL_NAME" | awk -F'@' '{print $1}')

# Check if the MODEL_TYPE is one of fast, hac, or sup. If not, exit with an error code.
if [[ "$MODEL_TYPE" != "fast" && "$MODEL_TYPE" != "hac" && "$MODEL_TYPE" != "sup" ]]; then
    echo "Error: Model type not recognized from the model name. Please specify the model type."
    exit 3
fi

# Flag to check if there are subfolders
SUBFOLDER_FOUND=false

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
        OUTPUT_BAM_PATH="$OUTPUT_PATH/$SUBFOLDER_NAME/${MODEL_TYPE}_calls.bam"

        # Check if the directory exists and is empty
        check_directory "$(dirname "$OUTPUT_BAM_PATH")"

        # Run the basecaller function
        dorado basecaller --modified-bases $MODIFIED_BASES --min-qscore $MIN_QSCORE "$MODEL_NAME" "$SUBFOLDER" > "$OUTPUT_BAM_PATH"
    fi
done

# If no subfolders are found, use the parent directory for basecalling
if [ "$SUBFOLDER_FOUND" = false ]; then
    # Construct the output file path
    OUTPUT_BAM_PATH="$OUTPUT_PATH/${MODEL_TYPE}_calls.bam"

    # Check if the directory exists and is empty
    check_directory "$(dirname "$OUTPUT_BAM_PATH")"

    # Run the basecaller function
    #dorado basecaller --reference "$REFERENCE_PATH" --modified-bases $MODIFIED_BASES --min-qscore $MIN_QSCORE "$MODEL_NAME" "$INPUT_PATH" > "$OUTPUT_BAM_PATH"
    dorado basecaller --modified-bases $MODIFIED_BASES --min-qscore $MIN_QSCORE "$MODEL_NAME" "$INPUT_PATH" > "$OUTPUT_BAM_PATH"
fi
