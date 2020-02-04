#!/bin/bash
set -e
set -o pipefail
set -u

## Software:
module load R
SCRIPT_FILTERLOCI=/datacommons/yoderlab/users/jelmer/scripts/genomics/radseq/vcf2loci/vcf2loci2d_filterloci.R

## Command-line args:
FILE_LOCUSSTATS_INTERMED=$1
FILE_LD=$2
MAXMISS=$3
MIN_LOCUSDIST=$4
MAX_LD=$5
DIR_LOCUSFASTA_INTERMED=$6
DIR_LOCUSFASTA_FINAL=$7

## Report:
echo "##### vcf2loci2d_filterloci_sub.sh: Starting script."
echo "##### vcf2loci2d_filterloci_sub.sh: FILE_LOCUSSTATS_INTERMED: $FILE_LOCUSSTATS_INTERMED"
echo "##### vcf2loci2d_filterloci_sub.sh: FILE_LD: $FILE_LD"
echo "##### vcf2loci2d_filterloci_sub.sh: MAXMISS: $MAXMISS"
echo "##### vcf2loci2d_filterloci_sub.sh: MIN_LOCUSDIST: $MIN_LOCUSDIST"
echo "##### vcf2loci2d_filterloci_sub.sh: DIR_LOCUSFASTA_INTERMED: $DIR_LOCUSFASTA_INTERMED"
echo "##### vcf2loci2d_filterloci_sub.sh: DIR_LOCUSFASTA_FINAL: $DIR_LOCUSFASTA_FINAL"

## Submit script:
echo "##### vcf2loci2d_filterloci_sub.sh: Submitting R script..."
Rscript $SCRIPT_FILTERLOCI $FILE_LOCUSSTATS_INTERMED $FILE_LD $MAXMISS \
	$MIN_LOCUSDIST $MAX_LD $DIR_LOCUSFASTA_INTERMED $DIR_LOCUSFASTA_FINAL

## Report:
echo -e "\n\n##### vcf2loci2d_filterloci_sub.sh: Done with script."