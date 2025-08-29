# Nanopore Pipeline Usage Guide

## Overview

This repository provides a pipeline for processing Nanopore RNA sequencing data. The main entry point to run the pipeline is through `run_pipeline.sh`, which manages various stages such as file partitioning, basecalling, alignment, and extracting modifications. This guide will help you understand how to use the pipeline and configure the necessary variables for your specific use case.

## Prerequisites

- **Python Environment:** Ensure you have Python 3 installed with necessary packages to run the Python script (`partition_pod5_files.py`).
- **Job Scheduler:** Access to a cluster job scheduler (e.g., `qsub` for Shared Computing Cluster (SCC)).
- **Tools Installation:**
  - **Dorado:** Version 0.8.0
  - **Minimap2:** Version 2.28
  - **Modkit:** Version 0.4.1
- **Environment Configuration:** Add the installed tools to your PATH by editing your `~/.bashrc` or `~/.bash_profile`. If you have access to the `leshlab` project, you can simply copy and paste the following at the end of the bash file. Otherwise, specify your own path to the installed tools.

  ```bash
  export PATH=$PATH:/restricted/projectnb/leshlab/net/tjamali/project/bin/dorado-0.8.0/bin
  export PATH=$PATH:/restricted/projectnb/leshlab/net/tjamali/project/bin/minimap2-2.28
  export PATH=$PATH:/restricted/projectnb/leshlab/net/tjamali/project/bin/modkit-0.4.1
  ```

- **JSON Processor:** Ensure `jq` is installed for JSON parsing.

## Running the Pipeline

### Script: `run_pipeline.sh`

This is the main script for running the pipeline. It initializes necessary variables, partitions `.pod5` files, and submits the main job to the scheduler.

#### Execution Command

```bash
./run_pipeline.sh
```

### Key Features

To help you understand the workflow of `run_pipeline.sh`, here are its key features:

- **Pod5 Files Listing and Partitioning:**  
  The script invokes the Python script (`partition_pod5_files.py`) to gather all `.pod5` files within `INPUT_DIR`, including all subdirectories. It then partitions these files into sublists where each sublist's total size does not exceed the specified size limit. This approach avoids manipulating the actual files and prepares the data for subsequent jobs.

- **File Size Validation:**  
  The Python script checks if any individual `.pod5` file exceeds the specified size limit. If such files are detected, the script raises an error and aborts execution to maintain pipeline integrity.

- **List Generation for Job Distribution:**  
  The Python script generates a comprehensive `partitions.json` file that contains information about all partitions. This facilitates organized processing for downstream jobs by providing a clear structure of how files are divided.

- **Environment Variable Exporting:**  
  The script exports all necessary variables to ensure that `main_job.sh` has access to the required configurations and paths. This includes paths to input/output directories, reference files, and job parameters.

- **Job Submission:**  
  Finally, `run_pipeline.sh` submits the `main_job.sh` script to the job scheduler with appropriate resource allocations and naming conventions. This ensures efficient and organized job management within the cluster environment.

### Key Variables to Configure

Before running the pipeline, ensure the following variables are correctly set in the `run_pipeline.sh` script. The **boldface** variables must be checked or specified, even if other variables are not. Some variables are derived from the **boldface** variables, e.g., `ALL_MODS` is generated from `MODIFIED_BASES`, or `UNALIGNED_BAM_DIR` is defined based on `OUTPUT_DIR` and `ALL_MODS`. Additionally, some variables have default values, so if you do not specify them, no error will likely occur. For example, the number of CPUs and threads for each job.

1. **Experimental Variables:**
   - **`GROUP`**: Defines the experimental or biological group (e.g., AD, Control).
   - **`SAMPLE`**: Defines the sample identifier (e.g., C0, A9).
   - **`MODIFIED_BASES`**: RNA modifications to consider (e.g., m5C inosine_m6A pseU). Ensure compatibility between selected modifications.
   - `ALL_MODS`: Combined modifications string separated by underscores (automatically derived from `MODIFIED_BASES`).

2. **Directory Paths:**
   - **`ROOT_DIR`**: The root directory for the project. Update this to match your filesystem.
   - **`SCRIPTS_DIR`**: Path to the pipeline's scripts directory.
   - **`INPUT_DIR`**: Directory containing `.pod5` files for Dorado basecalling. Default structure:
     `${ROOT_DIR}/RNA/${GROUP}/${SAMPLE}/pod5`.
   - **`OUTPUT_DIR`**: Directory containing all output folders and files. Default structure:
     `${ROOT_DIR}/RNA/${GROUP}/${SAMPLE}`.
   - `UNALIGNED_BAM_DIR`: Directory to store unaligned BAM files from Dorado. Default structure: `${OUTPUT_DIR}/unaligned_bam_${ALL_MODS}`.
   - `ALIGNED_BAM_DIR`: Directory to store aligned BAM files after alignment processing. Default structure:
     `${OUTPUT_DIR}/aligned_bam_${ALL_MODS}`.
   - `TEMP_DIR`: Temporary directory for alignment processing. Default structure:
     `${OUTPUT_DIR}/tmp_folder_for_alignment`.
   - `MODKIT_OUTPUT_DIR`: Output directory for Modkit extractor (default same as `ALIGNED_BAM_DIR`).

3. **Reference Files:**
   - **`ANNOTATION_FILE`**: Path to the annotation BED file (e.g., `${ROOT_DIR}/refs/gencode.v46.primary_assembly.annotation.bed`).
   - **`REFERENCE_FILE`**: Path to the reference `.mmi` file (e.g., `${ROOT_DIR}/refs/reference.mmi`).

4. **Python Partitioning Parameters:**
   - `SIZE_LIMIT`: Size limit per partition in GB (e.g., 25 GB).
   - `PARTITION_SCRIPT`: Path to the Python partitioning script (`partition_pod5_files.py`).

5. **Dorado Job Parameters:**
   - `TOTAL_CPUS_DORADO`: Number of CPUs requested for Dorado (e.g., 4).
   - **`MODEL_NAME`**: Dorado model name (e.g., hac&#65312;v5.1.0).
   - `MIN_QSCORE`: Minimum quality score for filtering low-quality reads (e.g., 9).
   - `DORADO_JOB_RUNTIME`: Defines the runtime limit for the Dorado job (e.g., `12:00:00`).
   - `DORADO_JOB_MEMORY`: Defines the memory requirement for the Dorado job (e.g., `128G`).
   - `DORADO_GPU_TYPE`: Defines the GPU type for the Dorado job (e.g., `L40S`).

6. **Alignment Job Parameters:**
   - `TOTAL_CPUS_ALIGN`: Number of CPUs requested for Alignment (e.g., 16).
   - `ALIGN_THREADS`: Number of threads for Alignment (calculated as `TOTAL_CPUS_ALIGN - 2`).
   - `ALIGN_JOB_RUNTIME`: Defines the runtime limit for the alignment job (e.g., `2:00:00`).
   - `ALIGN_JOB_MEMORY`: Defines the memory requirement for the alignment job (e.g., `64G`).

7. **Merge Job Parameters:**
   - `TOTAL_CPUS_MERGE`: Number of CPUs requested for Merge (e.g., 16).
   - `MERGE_THREADS`: Number of threads for Merge (calculated as `TOTAL_CPUS_MERGE - 2`).
   - `MERGE_JOB_RUNTIME`: Defines the runtime limit for the merge job (e.g., `2:00:00`).
   - `MERGE_JOB_MEMORY`: Defines the memory requirement for the merge job (e.g., `64G`).

8. **Modkit Job Parameters:**
   - `TOTAL_CPUS_MODKIT`: Number of CPUs requested for Modkit (e.g., 16).
   - `MODKIT_THREADS`: Number of threads for Modkit (calculated as `TOTAL_CPUS_MODKIT - 2`).
   - `MODKIT_JOB_RUNTIME`: Defines the runtime limit for the Modkit job (e.g., `3:00:00`).
   - `MODKIT_JOB_MEMORY`: Defines the memory requirement for the Modkit job (e.g., `64G`).
   - `FILTER_THRESHOLD_ALL`, `FILTER_THRESHOLD_A`, `FILTER_THRESHOLD_C`, `FILTER_THRESHOLD_T`: Filter thresholds for Modkit extractor (e.g., 0.8).
   - `MOD_THRESHOLD_M6A`, `MOD_THRESHOLD_PSEU`, `MOD_THRESHOLD_INOSINE`, `MOD_THRESHOLD_M5C`: Modification thresholds (e.g., 0.8).
   - `VALID_COVERAGE_THRESHOLD`: Threshold for valid coverage (e.g., 10).
   - `PERCENT_MODIFIED_THRESHOLD`: Threshold for percent modified (e.g., 10).

9. **QSUB General Parameters:**
   - **`QSUB_PROJECT`**: SCC project name (e.g., leshlab).
   - `QSUB_EMAIL`: Email notification preference (`ea` for end and abort).
   - `QSUB_JOINT_STDERR`: Combine stderr and stdout (e.g., `y`).

## Notes

- **Environment Variables:**
  - If you need to add any additional modifications or variables, ensure they are exported so that they are accessible to subsequent scripts (`main_job.sh`).

- **Directory Paths and CPU Requirements:**
  - Always verify that the directory paths and CPU allocations are correctly configured to match your cluster environment and available resources.

- **Error Handling:**
  - The pipeline employs strict error handling (`set -euo pipefail`). Ensure that all dependencies are correctly installed and paths are accurately specified to avoid unexpected termination.

- **Logging and Monitoring:**
  - Implement additional logging within scripts if detailed tracking of the pipeline's progress is required, especially for large-scale data processing.

- **Reference Files:**
  - Ensure that reference files (`ANNOTATION_FILE`, `REFERENCE_FILE`) are up-to-date and correctly formatted to avoid processing errors.

- **Tool Versions:**
  - Maintain consistency in tool versions (Dorado, Minimap2, Modkit) as specified in the prerequisites to ensure compatibility and reproducibility of results.

For more detailed information, refer to the comments and documentation within each script.


