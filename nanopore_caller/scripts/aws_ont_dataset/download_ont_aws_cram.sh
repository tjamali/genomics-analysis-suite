#!/bin/bash -l

#---------------------------------------###------------------------------------------#
# This script is designed to submit a job to SCC using qsub to download CRAM and
# CRAI files from an ONT S3 bucket and convert it into a BAM file using samtools.
# It sets up the necessary environment, specifies job requirements, and performs
# the download and conversion operations.
#---------------------------------------###------------------------------------------#

#$ -P leshlab       # Specify the SCC project name you want to use
#$ -N get_crams    # Give job a name

# Specify hard time limit for the job.
# The job will be aborted if it runs longer than this time.
# The default time is 12 hours
#$ -l h_rt=12:00:00

# Send an email when the job finishes or if it is aborted (by default no email is sent).
#$ -m bea

# Combine output and error files into a single file
#$ -j y

# Keep track of information related to the current job
echo "=========================================================="
echo "Start date : $(date)"
echo "Job name : $JOB_NAME"
echo "Job ID : $JOB_ID  $SGE_TASK_ID"
echo "=========================================================="

# Load the awscli module to enable AWS S3 commands
module load awscli

# Download the CRAM file from the S3 bucket to the specified directory
aws s3 cp --no-sign-request s3://ont-open-data/giab_2023.05/analysis/hg002/hac/PAO89685.pass.cram /restricted/projectnb/leshlab/net/tjamali/project/code/data/giab_2023.05/analysis/hg002/hac/PAO89685.pass.cram

# Download the corresponding CRAI file from the S3 bucket to the specified directory
aws s3 cp --no-sign-request s3://ont-open-data/giab_2023.05/analysis/hg002/hac/PAO89685.pass.cram.crai /restricted/projectnb/leshlab/net/tjamali/project/code/data/giab_2023.05/analysis/hg002/hac/PAO89685.pass.cram.crai

# Load the samtools module to enable CRAM to BAM conversion and indexing
module load samtools

# Convert the downloaded CRAM file to a BAM file using samtools
samtools view -T /restricted/projectnb/leshlab/net/tjamali/project/code/data/refs/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna -b \
-o /restricted/projectnb/leshlab/net/tjamali/project/code/data/giab_2023.05/analysis/hg002/hac/PAO89685.pass.bam \
/restricted/projectnb/leshlab/net/tjamali/project/code/data/giab_2023.05/analysis/hg002/hac/PAO89685.pass.cram

# Optional: Sort the BAM file (commented out by default)
# samtools sort -o sorted_PAO89685.pass.bam PAO89685.pass.bam

# Index the BAM file using samtools
samtools index /restricted/projectnb/leshlab/net/tjamali/project/code/data/giab_2023.05/analysis/hg002/hac/PAO89685.pass.bam
