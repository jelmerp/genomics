#!/bin/bash
set -e
set -o pipefail
set -u

VCFTOOLS=/dscrhome/rcw27/programs/vcftools/vcftools-master/bin/vcftools

## Command-line arguments:
SCAFFOLD=$1
INFILE=$2
OUTFILE=$3

date
echo "Script: splitVCF_byScaffold.sh"
echo "Scaffold: $SCAFFOLD"
echo "Input file: $INFILE"
echo "OUtput file: $OUTFILE"


## Run vcftools:
$VCFTOOLS --gzvcf $INFILE --chr $SCAFFOLD --recode --recode-INFO-all --stdout | gzip -c > $OUTFILE

date
echo "Done with script."



################################################################################
## Alt. with bcftools:
#$BCFTOOLS view --regions-file $INTERVAL_FILE $GVCF_ALLSCAF -O v > $GVCF_SINGLESCAF