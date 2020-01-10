#!/bin/bash
set -e
set -o pipefail
set -u

################################################################################
#### SET-UP ####
################################################################################
date
echo "##### qc_fastq.sh: Starting script."

## Software:
FASTQC=/datacommons/yoderlab/programs/fastqc_v0.11.5/FastQC/fastqc

## Command-line args:
INPUT="$1"
OUTDIR="$2"

## Report:
echo "##### qc_fastq.sh: Input: $INPUT"
echo "##### qc_fastq.sh: Output directory: $OUTDIR"
printf "\n"


################################################################################
#### RUN FASTQC ####
################################################################################
echo "##### qc_fastq.sh: Running fastqc..."
$FASTQC --outdir=$OUTDIR $INPUT


echo "##### qc_fastq.sh: Done with script."
date