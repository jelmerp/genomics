#!/bin/bash
set -e
set -o pipefail
set -u

################################################################################
#### SET-UP ####
################################################################################
## Software:
JAVA=/datacommons/yoderlab/programs/java_1.8.0/jre1.8.0_144/bin/java
PICARD=/datacommons/yoderlab/programs/picard_2.13.2/picard.jar

## Command-line arguments:
SETNAME=$1
VCF_DIR_IN=$2
VCF_DIR_OUT=$3

## Process args:
VCF_LIST=$VCF_DIR_IN/$SETNAME.vcflist.txt
ls $VCF_DIR_IN/$SETNAME.*rawvariants.vcf > $VCF_LIST
VCF_OUT=$VCF_DIR_OUT/$SETNAME.rawvariants.vcf

[[ ! -d $VCF_DIR_OUT ]] && echo "Creating dir $VCF_DIR_OUT" && mkdir $VCF_DIR_OUT 

## Report:
date
echo "#### gatk3_mergevcfs: Starting script."
echo "#### gatk3_mergevcfs: Job ID: $SLURM_JOB_ID"
echo "#### gatk3_mergevcfs: Number of nodes (from slurm variables): $SLURM_JOB_NUM_NODES" # Specify with -N
echo "#### gatk3_mergevcfs: Set name: $SETNAME"
echo "#### gatk3_mergevcfs: VCF dir in: $VCF_DIR_IN"
echo "#### gatk3_mergevcfs: VCF dir out: $VCF_DIR_OUT"
printf "\n"
echo "#### gatk3_mergevcfs: VCF list: $VCF_LIST"
echo "#### gatk3_mergevcfs: Output VCF: $VCF_OUT"


################################################################################
#### RUN GATK MERGEVCFS ####
################################################################################
echo -e "\n#### gatk3_mergevcfs: Running mergevcfs...\n"
$JAVA -jar $PICARD MergeVcfs I=$VCF_LIST O=$VCF_OUT


################################################################################
#### HOUSEKEEPING ####
################################################################################
echo -e "\n#### gatk3_mergevcfs: Output VCF $VCF_OUT"
ls -lh $VCF_OUT

NVAR=$(grep -v "##" $VCF_OUT | wc -l)
echo -e "\n#### gatk3_mergevcfs: Number of variants: $NVAR"

echo -e "\n#### gatk3_mergevcfs: Done with script."
date