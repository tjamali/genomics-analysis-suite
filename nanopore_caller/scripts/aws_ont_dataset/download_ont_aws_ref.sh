#!/bin/bash -l

#---------------------------------------###------------------------------------------#
# This script is designed to submit a job to SCC usign qsub to download reference
# files (FASTA and its index) from an ONT S3 bucket. It sets up the necessary
# environment, specifies job requirements, and performs the download operations.
#---------------------------------------###------------------------------------------#

#$ -P leshlab       # Specify the SCC project name you want to use
#$ -N retrieve_refs # Give the job a name

# Specify a hard time limit for the job. 
# The job will be aborted if it runs longer than this time.
# The default time is 12 hours
#$ -l h_rt=12:00:00

# Send an email when the job finishes or if it is aborted (by default no email is sent).
#$ -m bea

# Combine output and error files into a single file
#$ -j y

# Keep track of information related to the current job
echo "=========================================================="
echo "Start date : $(date)"          # Print the start date and time of the job
echo "Job name : $JOB_NAME"          # Print the job name
echo "Job ID : $JOB_ID  $SGE_TASK_ID" # Print the job ID and task ID
echo "=========================================================="

# Load the awscli module to enable AWS S3 commands
module load awscli

# Download the reference FASTA file from the S3 bucket to the specified directory
aws s3 cp --no-sign-request s3://ont-open-data/giab_2023.05/analysis/benchmarking/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna /restricted/projectnb/leshlab/net/tjamali/project/code/data/refs/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna

# Download the corresponding FASTA index file from the S3 bucket to the specified directory
aws s3 cp --no-sign-request s3://ont-open-data/giab_2023.05/analysis/benchmarking/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.fai /restricted/projectnb/leshlab/net/tjamali/project/code/data/refs/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.fai

