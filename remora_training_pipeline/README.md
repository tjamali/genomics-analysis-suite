# Remora Training Pipeline Usage Guide

## Overview

This repository provides a pipeline for training Remora models using Nanopore sequencing data. The main entry point to run the pipeline is through `run_pipeline.sh`, which initializes environment variables, submits the main job to the scheduler, and orchestrates subsequent steps such as basecalling, dataset preparation, and model training. This guide will help you understand how to use the pipeline, configure the necessary variables, and ensure all prerequisites are met for successful execution.

## Prerequisites

Before running the Remora Training Pipeline, ensure that the following prerequisites are satisfied:

- **Python Version:**
  - The pipeline was developed and tested using **Python 3.10.12**. 

- **Python Environment:**
  - **Conda:** Ensure Conda is installed. The pipeline uses a Conda environment named `nanopore`, which must include the following packages:  
    - `pod5`               **0.3.23**  
    - `polars-lts-cpu`     **1.19.0**  
    - `ont-remora`         **3.2.0**  
  
- **Job Scheduler:**
  - **Cluster Access:** Access to a cluster job scheduler (e.g., `qsub` for Shared Computing Cluster (SCC)) is required to manage and submit jobs.

- **Tools and Modules Installation:**
  - **CUDA:** GPU support is essential for basecalling and model training. Ensure the CUDA module is available and compatible with your system.
  - **Dorado Basecaller:** Required for GPU-accelerated basecalling (version 0.8.0).
  - **Samtools:** For sorting and indexing BAM files (version 1.12).
  - **Remora:** Installed within the `nanopore` Conda environment for dataset preparation and model training.
  
- **Environment Configuration:**
  - **Conda Environment:** The pipeline activates a Conda environment named `nanopore`. Ensure this environment exists and has all necessary packages installed.
  - **Module Management:** The pipeline uses `module load` commands to load necessary modules (e.g., `cuda`, `samtools`, `miniconda`). Ensure these modules are available on your cluster.

- **Directory Structure:**
  - Organize your project directories as outlined below to ensure smooth execution:
  
    ```
    ROOT_DIR
    ├── remora_dataset/
    │   ├── basecalls/
    │   │   └── (Output BAM files from basecalling)
    │   ├── subset/
    │   │   └── (Input .pod5 files)
    │   ├── training_dataset/
    │   │   ├── can_chunks/
    │   │   ├── mod_chunks/
    │   │   ├── train_dataset.jsn
    │   │   └── train_dataset.log
    │   ├── references/
    │   │   ├── all_5mers.fa
    │   │   └── all_5mers.fa.fai
    │   └── 5mer_levels.txt
    ├── remora_code/
    │   └── models/
    │       └── ConvLSTM_w_ref.py
    ├── remora_output/
    │   └── training_results/
    └── remora_training_pipeline/
        ├── run_pipeline.sh
        └── scripts/
            ├── main_job.sh
            ├── run_basecaller.sh
            ├── prepare_training_dataset.sh
            └── run_training.sh
    ```

- **JSON Processor:**
  - Ensure `jq` is installed for any JSON parsing needs during the pipeline execution.

## Running the Pipeline

### Script: `run_pipeline.sh`

This is the main script for initiating the Remora Training Pipeline. It sets up environment variables, ensures script permissions, and submits the `main_job.sh` script to the job scheduler.

#### Execution Command

```bash
./run_pipeline.sh
```

### Key Features

- **Environment Variable Initialization:**
  - Sets up all required variables for the pipeline, ensuring consistency across all jobs.
  
- **Script Permissions:**
  - Ensures that all necessary scripts are executable before submission.
  
- **Job Submission:**
  - Submits the `main_job.sh` script to the job scheduler with appropriate resource allocations and naming conventions.

### Script: `main_job.sh`

This script orchestrates the execution of the Remora Training Pipeline by submitting the `run_basecaller.sh`, `prepare_training_dataset.sh`, and `run_training.sh` scripts as separate jobs. It ensures that each job is submitted with dependencies, so that each subsequent job waits for the previous one to complete successfully before starting.

#### Key Features

- **Job Submission with Dependencies:**
  - Submits each job script with dependencies using the `-hold_jid` flag, ensuring sequential execution.
  
- **Error Handling:**
  - Exits the pipeline if any of the job submissions fail.
  
- **Logging:**
  - Outputs informative messages to track the pipeline's progress.

### Script: `run_basecaller.sh`

This script performs GPU-accelerated basecalling on `.pod5` input files using the Dorado basecaller. It loads the necessary modules, sets up directories and variables, checks for existing outputs to prevent overwrites, executes the basecalling process with specified parameters, sorts the resulting BAM files using `samtools`, and creates index files for the sorted BAMs.

#### Key Features

- **Module Loading:**
  - Loads the CUDA and Samtools modules required for basecalling and BAM file processing.
  
- **Output Validation:**
  - Checks if output BAM files already exist to prevent accidental overwrites.
  
- **Basecalling Execution:**
  - Runs Dorado basecaller with specified reference files and quality score thresholds.
  
- **BAM File Processing:**
  - Sorts and indexes BAM files using `samtools` to prepare them for downstream training.

### Script: `prepare_training_dataset.sh`

This script prepares the training dataset for Remora by processing the BAM and POD5 files. It activates the necessary Conda environment, loads required modules, and executes Remora dataset preparation commands.

#### Key Features

- **Conda Environment Activation:**
  - Activates the `nanopore` Conda environment where Remora is installed.
  
- **Module Loading:**
  - Loads the Miniconda and CUDA modules required for dataset preparation.
  
- **Dataset Preparation:**
  - Runs Remora commands to prepare datasets for both control and modified samples.
  
- **Configuration Generation:**
  - Composes training datasets by generating configuration files needed for model training.

### Script: `run_training.sh`

This script runs Remora model training in non-interactive mode. It activates the necessary Conda environment, loads required modules, and executes the Remora training command.

#### Key Features

- **Conda Environment Activation:**
  - Activates the `nanopore` Conda environment where Remora is installed.
  
- **Module Loading:**
  - Loads the Miniconda and CUDA modules required for model training.
  
- **Model Training Execution:**
  - Runs Remora's model training command with specified parameters, including chunk context and output paths.

## Key Variables to Configure

Before running the pipeline, ensure the following variables are correctly set in the `run_pipeline.sh` script. The **boldface** variables must be checked or specified, even if other variables are not. Some variables are derived from the **boldface** variables, and others have default values.

### 1. Experimental Variables

- **`GROUP`**: Defines the experimental or biological group (e.g., AD, Control).
- **`SAMPLE`**: Defines the sample identifier (e.g., C0, A9).
- **`MODIFIED_BASES`**: RNA modifications to consider (e.g., m5C, inosine, m6A, pseU). Ensure compatibility between selected modifications.
- `ALL_MODS`: Combined modifications string separated by underscores (automatically derived from `MODIFIED_BASES`).

### 2. Directory Paths

- **`ROOT_DIR`**: The root directory for the project. Update this to match your filesystem.
- **`SCRIPTS_DIR`**: Path to the pipeline's scripts directory.
- **`DATASET_DIR`**: Directory containing `.pod5` files and other dataset-related files.
- **`TRAINING_RESULTS`**: Directory containing all training output folders and files.
- **`BASECALL_OUTPUT_DIR`**: Directory to store Dorado's basecalls.
  
### 3. File Path Variables

- **`REFERENCE_FILE`**: Path to the reference FASTA file (e.g., `${DATASET_DIR}/references/all_5mers.fa`).
- **`CAN_POD5`**: Path to the canonical control `.pod5` input file (e.g., `${DATASET_DIR}/subset/control_rep1.pod5`).
- **`CAN_BAM`**: Path to the canonical control BAM file (e.g., `${DATASET_DIR}/basecalls/control_rep1.bam`).
- **`CAN_CHUNKS`**: Directory to store canonical control chunks (e.g., `${DATASET_DIR}/training_dataset/can_chunks`).
- **`MOD_POD5`**: Path to the modified `.pod5` input file (e.g., `${DATASET_DIR}/subset/5mC_rep1.pod5`).
- **`MOD_BAM`**: Path to the modified BAM file (e.g., `${DATASET_DIR}/basecalls/5mC_rep1.bam`).
- **`MOD_CHUNKS`**: Directory to store modified chunks (e.g., `${DATASET_DIR}/training_dataset/mod_chunks`).
- **`KMER_LEVEL_TABLE`**: Path to the k-mer levels table (e.g., `${DATASET_DIR}/5mer_levels.txt`).
- **`TRAIN_DATASET`**: Path to the training dataset JSON file (e.g., `${DATASET_DIR}/training_dataset/train_dataset.jsn`).
- **`TRAIN_LOG`**: Path to the training dataset log file (e.g., `${DATASET_DIR}/training_dataset/train_dataset.log`).
- **`MODEL`**: Path to the Remora model script (e.g., `${ROOT_DIR}/remora_code/models/ConvLSTM_w_ref.py`).

### 4. Job Scheduler Parameters

- **`QSUB_PROJECT`**: SCC project name (e.g., `leshlab`).
- **`QSUB_EMAIL`**: Email notification preference (`ea` for end and abort).
- **`QSUB_JOINT_STDERR`**: Combine stderr and stdout (e.g., `y`).

### 5. Resource Allocation Variables

#### Run Basecaller (Dorado)

- **`DORADO_JOB_RUNTIME`**: Runtime limit (e.g., `12:00:00`).
- **`DORADO_JOB_MEMORY`**: Memory requirement (e.g., `128G`).
- **`TOTAL_CPUS_DORADO`**: Number of CPU cores (e.g., `4`).
- **`TOTAL_GPUS_DORADO`**: Number of GPUs (e.g., `1`).
- **`DORADO_GPU_TYPE`**: GPU type (e.g., `L40S`).
- **`DORADO_MODEL_NAME`**: Dorado model name (e.g., `sup@v5.0.0`).
- **`DORADO_MIN_QSCORE`**: Minimum quality score (e.g., `9`).

#### Prepare Training Dataset

- **`PREPARE_JOB_RUNTIME`**: Runtime limit (e.g., `1:00:00`).
- **`PREPARE_JOB_MEMORY`**: Memory requirement (e.g., `64G`).
- **`TOTAL_CPUS_PREPARE`**: Number of CPU cores (e.g., `8`).

#### Run Training

- **`TRAINING_JOB_RUNTIME`**: Runtime limit (e.g., `12:00:00`).
- **`TRAINING_JOB_MEMORY`**: Memory requirement (e.g., `128G`).
- **`TOTAL_CPUS_TRAINING`**: Number of CPU cores (e.g., `4`).
- **`TOTAL_GPUS_TRAINING`**: Number of GPUs (e.g., `1`).
- **`TRAINING_GPU_TYPE`**: GPU type (e.g., `L40S`).

## Notes

- **Environment Variables:**
  - Ensure that all additional modifications or variables are exported so that they are accessible to subsequent scripts (`main_job.sh`).

- **Directory Paths and CPU Requirements:**
  - Always verify that the directory paths and CPU/GPU allocations are correctly configured to match your cluster environment and available resources.

- **Error Handling:**
  - The pipeline employs strict error handling (`set -euo pipefail`). Ensure that all dependencies are correctly installed and paths are accurately specified to avoid unexpected termination.

- **Logging and Monitoring:**
  - The pipeline scripts include echo statements for tracking progress. For more detailed logging, consider implementing additional logging mechanisms within the scripts.

- **Conda Environment Management:**
  - The pipeline activates a Conda environment named `nanopore`. Ensure this environment is properly set up with all required packages, including Remora.

- **Module Management:**
  - The scripts use `module load` commands to manage dependencies like CUDA and Samtools. Ensure that these modules are available and correctly configured on your cluster.

- **Reference Files:**
  - Ensure that reference files (`REFERENCE_FILE`, `all_5mers.fa`, `5mer_levels.txt`) are up-to-date and correctly formatted to avoid processing errors.

- **Tool Versions:**
  - Maintain consistency in tool versions (Dorado, Samtools, Remora) as specified in the prerequisites to ensure compatibility and reproducibility of results.

- **Job Scheduler Limits:**
  - Be aware of your cluster's job submission limits and adjust resource allocations accordingly to prevent job submission failures.

- **Pipeline Customization:**
  - Depending on your specific use case, you may need to adjust parameters such as quality scores, chunk contexts, or dataset weights. Ensure that any changes are compatible with downstream analysis.

For more detailed information, refer to the comments and documentation within each script.

## Contact

For any issues or questions regarding the Remora Training Pipeline, please contact:

**Author:** Tayeb Jamali  
**Email:** tjamali.official\@gmail.edu

**Date:** 2025-1-7


