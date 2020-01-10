#!/bin/bash
set -e
set -o pipefail
set -u

################################################################################
#### SET-UP ####
################################################################################
## Create a mask bedfile from VCF files

## Software:
# Uses vcf2bed from bedops at /datacommons/yoderlab/programs/bedops/bin/
# Use bedtools

## Command-line args:
VCF_ALTREF=$1
shift
VCF_FILTERED_MASK=$1
shift
BED_VCF_ALTREF=$1
shift
BED_VCF_FILTERED_MASK=$1
shift
BED_REMOVED_SITES=$1
shift
MEM=$1
shift

## Report:
echo -e "\n###################################################################"
date
echo "#### vcf2loci0_maskbed.sh: Starting script."
echo "#### vcf2loci0_maskbed.sh: Input: altref VCF: $VCF_ALTREF"
echo "#### vcf2loci0_maskbed.sh: Input: filtered VCF (for mask): $VCF_FILTERED_MASK"
echo "#### vcf2loci0_maskbed.sh: Output: bedfile for altref VCF: $BED_VCF_ALTREF"
echo "#### vcf2loci0_maskbed.sh: Output: bedfile for filtered VCF: $BED_VCF_FILTERED_MASK"
echo "#### vcf2loci0_maskbed.sh: Output: bedfile with removed sites: $BED_REMOVED_SITES"
echo "#### vcf2loci0_maskbed.sh: Memory: $MEM"
printf "\n"

echo "#### vcf2loci0_maskbed.sh: Checking for presence of VCF files:"
[[ ! -e $VCF_ALTREF ]] && [[ -e $VCF_ALTREF.gz ]] && echo "Unzipping $VCF_ALTREF.gz..." && gunzip $VCF_ALTREF.gz 
[[ ! -e $VCF_FILTERED_MASK ]] && [[ -e $VCF_FILTERED_MASK.gz ]] && echo "Unzipping $VCF_FILTERED_MASK.gz..." && gunzip $VCF_FILTERED_MASK.gz
ls -lh $VCF_ALTREF
ls -lh $VCF_FILTERED_MASK


################################################################################
#### RUN VCF2BED AND BEDTOOLS-INTERSECT ####
################################################################################
echo -e "\n#### vcf2loci0_maskbed.sh: Converting vcfs to bedfiles..."
vcf2bed --sort-tmpdir=tmpdir --max-mem=${MEM}G < $VCF_FILTERED_MASK | cut -f 1,2,3 > $BED_VCF_FILTERED_MASK
vcf2bed --sort-tmpdir=tmpdir --max-mem=${MEM}G < $VCF_ALTREF | cut -f 1,2,3 > $BED_VCF_ALTREF

echo "#### vcf2loci0_maskbed.sh: Running bedtools intersect.."
bedtools intersect -v -a $BED_VCF_ALTREF -b $BED_VCF_FILTERED_MASK > $BED_REMOVED_SITES


################################################################################
#### REPORT ####
################################################################################
LINECOUNT_UNFILTERED=$( cat $BED_VCF_ALTREF | wc -l)
LINECOUNT_FILTERED=$( cat $BED_VCF_FILTERED_MASK | wc -l)
LINECOUNT_REMOVED=$( cat $BED_REMOVED_SITES | wc -l)
echo -e "\n#### vcf2loci0_maskbed.sh: Linecount unfiltered: $LINECOUNT_UNFILTERED"
echo "#### vcf2loci0_maskbed.sh: Linecount filtered: $LINECOUNT_FILTERED"
echo "#### vcf2loci0_maskbed.sh: Linecount removed-sites: $LINECOUNT_REMOVED"

echo -e "\n#### vcf2loci0_maskbed.sh: Done with script."
date