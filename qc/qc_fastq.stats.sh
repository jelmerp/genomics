#!/bin/bash
set -e
set -o pipefail
set -u

################################################################################
##### SET-UP #####
################################################################################
## Command-line args:
FASTQ=$1
OUTDIR=$2

## Software:
EAUTILS_FASTQSTATS=/datacommons/yoderlab/programs/ExpressionAnalysis-ea-utils-bd148d4/clipper/fastq-stats

## Process:
FASTQ_ID=$(basename -s .fastq.gz $FASTQ)
OUTPUT=$OUTDIR/$FASTQ_ID.fastqstats.txt

## Report:
printf "\n"
date
echo "##### fastq.stats.sh: Starting script."
echo "##### fastq.stats.sh: Input fastq file: $FASTQ"
echo "##### fastq.stats.sh: Outdir: $OUTDIR"
echo "##### fastq.stats.sh: Output file: $OUTPUT"
printf "\n"


################################################################################
##### RUN #####
################################################################################
$EAUTILS_FASTQSTATS $FASTQ > $OUTPUT

echo "##### fastq.stats.sh: Output file:"
ls -lh $OUTPUT

################################################################################
date
echo -e "##### qc_bam.sh: Done with script fastq.stats.sh\n"