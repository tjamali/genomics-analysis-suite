# Nanopore Pipeline Usage Guide

## Overview

This repository provides a pipeline for Nanopore RNA sequencing data processing. The main entry point to run the pipeline is through `run_pipeline.sh`, which manages various stages, such as file segregation, basecalling, alignment, and extracting modifications. This guide will help you understand the usage and provide details about what variables you may need to modify for your specific use case.

## Prerequisites

- Make sure you have all necessary dependencies installed, including a Python environment capable of running the Python script (`distribute_files_by_size.py`).
- Access to a cluster job scheduler (e.g., `qsub` for Sun Grid Engine).
- Modify paths and configuration details to match your environment.
- Install the following tools:
  - **Dorado**: Version 0.8.0
  - **Minimap2**: Version 2.28
  - **Modkit**: Version 0.4.1
- Add these tools to the `bashrc` file using the export command. You can open `bashrc` using `nano ~/.bashrc` and add the following lines at the end of the file.
  ```bash
  export PATH=$PATH:/restricted/projectnb/leshlab/net/tjamali/project/bin/dorado-0.8.0/bin
  export PATH=$PATH:/restricted/projectnb/leshlab/net/tjamali/project/bin/minimap2-2.28
  export PATH=$PATH:/restricted/projectnb/leshlab/net/tjamali/project/bin/modkit-0.4.1
  ```
  Then, run `source ~/.bashrc`.
 

## Running the Pipeline

### Script: `run_pipeline.sh`

This is the main script for running the pipeline. You can execute it with the following command:

```bash
./run_pipeline.sh
```

### Key Variables to Configure

1. **Experimental Variables**
   - `GROUP`: Defines the experimental group (e.g., `AD`, `Control`).
   - `SAMPLE`: Defines the sample identifier (e.g., `C0`, `A9`).
   - `MODIFIED_BASES`: RNA modifications to consider (e.g., `m5C`, `inosine_m6A`). Ensure compatibility between selected modifications.

2. **Directory Paths**
   - `ROOT_DIR`: The root directory for the project. Update this to match your filesystem.
   - `INPUT_DIR`, `UNALIGNED_BAM_DIR`, `ALIGNED_BAM_DIR`, etc.: Paths to input and output directories for different stages of the pipeline. These directories should be updated based on the desired locations of input files and the output of the pipeline. `INPUT_DIR` is where the script looks for your initial RNA data files. The default path structure is: `ROOT_DIR/RNA/GROUP/SAMPLE/pod5` (modify this to match your data path). The pod5 directory is expected to contain files for processing. It may also contain subfolders for distributing large numbers of files. `UNALIGNED_BAM_DIR`, `ALIGNED_BAM_DIR`, and `MODKIT_OUTPUT_DIR`  are output directories where unaligned BAM files, aligned BAM files, and modification extractor outputs will be saved, respectively. These paths are also defined using `GROUP` , `SAMPLE` , and `ROOT_DIR` . You may need to adjust these accordingly if your output directories differ.

3. **Reference Files**
   - The paths to reference files are defined using the following variables. If you are using different reference files, you must update these paths to point to your reference files. Alternatively, if you can use the same reference files, ensure your directory matches the provided paths.
      - `ANNOTATION_FILE`: The path to the annotation BED file
      - `REFERENCE_FILE`: The path to the reference .mmi file

4. **Python Distribution Script**
   - `DISTRIBUTE_SCRIPT`: Path to the Python file (`distribute_files_by_size.py`). Update this to match the correct location.

5. **Resource Parameters**
   - `TOTAL_CPUS_DORADO`, `TOTAL_CPUS_ALIGN`, `TOTAL_CPUS_MODKIT`, etc.: Update the number of CPUs used for each stage based on the available resources on your system.

### File Distribution 

The pipeline manages large POD5 files by distributing them into subfolders if they exceed a specified size limit. The following configurations are relevant:

- `SIZE_LIMIT`: Size limit for each subfolder in GB. Set this based on your system's memory capabilities to prevent resource overload.

The Python script `distribute_files_by_size.py` helps to:
- Segregate POD5 files if mixed content is present in `INPUT_DIR`.
- Ensure no single file exceeds the defined size limit.
- Flatten and distribute files into subfolders if required.

### Submitting the Main Job

The script uses `qsub` to submit the main job (`main_job.sh`). Ensure the following `qsub` parameters are correctly set for your environment:

- `QSUB_PROJECT`: The project name for job submission.
- `QSUB_EMAIL`: Set email notification preference (`e` for end, `a` for abort).

## Notes

- If you need to add any additional modifications or variables, make sure to export them so that they are available to the subsequent scripts (`main_job.sh`).
- Always check the directory paths and CPU requirements to ensure they are correctly configured for your cluster environment.

For further details, refer to the description and comments within each script, which explain the individual commands and logic in more depth.

