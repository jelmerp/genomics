#!/bin/bash
set -e
set -o pipefail
set -u

################################################################################
#### SET-UP ####
################################################################################
## Software:
BWA=/datacommons/yoderlab/programs/bwa-0.7.15/bwa
SAMTOOLS=/datacommons/yoderlab/programs/samtools-1.6/samtools

## Command-line args:
ID=$1
READGROUP_STRING="$2" #"@RG\tID:group1\tSM:$IND\tPL:illumina\tLB:lib1"
REF=$3
FASTQ_DIR=$4
BAM_DIR=$5
FASTQ1=$6
FASTQ2=$7

## Process args:
[[ ! -d $BAM_DIR ]] && mkdir -p $BAM_DIR
BAM_OUT=$BAM_DIR/$ID.bam

## Report:
printf "\n"
date
echo "#### geno2_align.sh: Script: geno2_align.sh"
echo "#### geno2_align.sh: Job ID: $SLURM_JOB_ID"
echo "#### geno2_align.sh: Number of nodes: $SLURM_JOB_NUM_NODES"
echo "#### geno2_align.sh: Nr of tasks: $SLURM_NTASKS"
printf "\n"
echo "#### geno2_align.sh: Aligning fastq files to reference genome for: $ID"
echo "#### geno2_align.sh: Readgroup string: $READGROUP_STRING"
echo "#### geno2_align.sh: Reference fasta: $REF"
echo "#### geno2_align.sh: Fastq 1: $FASTQ1"
echo "#### geno2_align.sh: Fastq 2: $FASTQ2"
echo "#### geno2_align.sh: Bam (output) dir: $BAM_DIR"
echo "#### geno2_align.sh: Bam (output) file: $BAM_OUT"
printf "\n"


################################################################################
#### MAP WITH BWA ####
################################################################################
echo "#### geno2_align.sh: Mapping with bwa mem..."
$BWA mem $REF -aM -R "$READGROUP_STRING" -t $SLURM_NTASKS $FASTQ1 $FASTQ2 | $SAMTOOLS view -b -h > $BAM_OUT

## Report:
echo -e "\n#### geno2_align.sh: Resulting bam file:"
ls -lh $BAM_OUT

date
echo -e "\n#### geno2_align.sh: Done with script.\n"


################################################################################
################################################################################
## bwa flags:
# -t nr of threads
# -a alignments for single-end / unpaired reads are also output, as secondary alignments
# -M shorter split reads are output as secondary alignments, for Picard compatibility
# -R "@RG\tID:group1\tSM:$IND\tPL:illumina\tLB:lib1"