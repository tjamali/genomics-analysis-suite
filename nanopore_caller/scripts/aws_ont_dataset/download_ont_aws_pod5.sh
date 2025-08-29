#!/bin/bash -l

#---------------------------------------###------------------------------------------#
# This script is designed to submit a job to SCC using qsub to download POD5 files
# from an ONT S3 bucket. It sets up the necessary environment, specifies job
# requirements, and performs the download operations.
#---------------------------------------###------------------------------------------#

#$ -P leshlab       # Specify the SCC project name you want to use
#$ -N retrieve_pod5s # Give the job a name

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

# Download POD5 files from the S3 bucket to the specified directory
aws s3 cp --no-sign-request --recursive s3://ont-open-data/giab_2023.05/flowcells/hg002/20230428_1310_3H_PAO89685_c9d0d53f/pod5_pass/ /restricted/projectnb/leshlab/net/tjamali/project/code/data/giab_2023.05/flowcells/hg002/20230428_1310_3H_PAO89685_c9d0d53f/
#aws s3 sync --no-sign-request s3://ont-open-data/giab_2023.05/flowcells/hg002/20230424_1302_3H_PAO89685_2264ba8c/pod5_pass/ /restricted/projectnb/leshlab/net/tjamali/project/code/data/giab_2023.05/flowcells/hg002/20230424_1302_3H_PAO89685_2264ba8c/
