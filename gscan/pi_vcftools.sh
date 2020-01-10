#!/bin/bash
set -e
set -o pipefail
set -u

## Command-line arguments:
VCF_ID=$1
WINDOW_SIZE=$2
VCF_DIR=$3
PI_DIR=$4

## Process:
VCF=$VCF_DIR/$VCF_ID.vcf.gz

## Report:
date
echo "SCRIPT: pi_vcftools.sh"
echo "VCF: $VCF"
echo "Window size: $WINDOW_SIZE"

## Calculate pi:
#echo -e "\n\n####: Calculating pi per site..."
#vcftools --gzvcf $VCF --site-pi --out $PI_DIR/$VCF_ID

echo -e "\n\n####: Calculating pi per window..."
vcftools --gzvcf $VCF --window-pi $WINDOW_SIZE --out $PI_DIR/$VCF_ID

## Report:
printf "\n \n"
echo -e "\n\n####: pi_vcftools.sh: Done with script."
date
