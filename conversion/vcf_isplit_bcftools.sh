#!/bin/bash
set -e
set -o pipefail
set -u

################################################################################
#### SET-UP ####
################################################################################
## Command-line args:
VCF_IN=$1
VCF_OUT=$2
INDS=$3

## Process:
[[ ! -e $VCF_IN ]] && [[ -e $VCF_IN.gz ]] && echo "#### vcf2fullFasta.sh: Only found zipped VCF..." && VCF_IN=$VCF_IN.gz

## Report:
date
echo "#### vcf_isplit_bcftools.sh: Starting script."
echo "#### vcf_isplit_bcftools.sh: VCF input file: $VCF_IN"
echo "#### vcf_isplit_bcftools.sh: VCF input file: $VCF_OUT"
echo "#### vcf_isplit_bcftools.sh: Individuals: $INDS"
echo -e "\n#### vcf_isplit_bcftools.sh: Listing input file:"
ls -lh $VCF_IN


################################################################################
#### SPLIT VCF ####
################################################################################
echo "#### vcf_isplit_bcftools.sh: Extracting individual(s)..."
bcftools view -O v -s $INDS $VCF_IN > $VCF_OUT

echo "#### vcf_isplit_bcftools.sh: Listing output file:"
ls -lh $VCF_OUT

echo "#### vcf_isplit_bcftools.sh: Done with script."
date



################################################################################
################################################################################
### Usage:
# FILE_ID=Cdec; scripts/conversion/vcf_isplit_bcftools.sh phylB.SNPs.GATKfilt.biallelic Cdec088,Cdec328 $FILE_ID.SNPs.GATKfilt.biallelic
# [INDS should be a comma-separated list of individuals IDs that should be included. To exclude an individual, place a ^ before the ID.]

#bcftools view -s $INDS $VCF_IN | bcftools filter -o -O z -i "MAF[0]>$MAF" > $VCF_OUT.gz