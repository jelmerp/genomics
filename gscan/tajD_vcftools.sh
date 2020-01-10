#!/bin/bash
set -e
set -o pipefail
set -u

FILE_ID=$1
POPNAME=$2
INDS=$3
WINSIZE=$4
INDIR=$5
OUTDIR=$6

VCF_SOURCE=$INDIR/$FILE_ID.vcf.gz
VCF_TARGET=$INDIR/$FILE_ID.only$POPNAME.vcf.gz

OUTPUT=$OUTDIR/tajD.vcftools.${FILE_ID}.$POPNAME.win$WINSIZE.txt

date
echo "Script: tajD_vcftools.sh"
echo "VCF source: $FILE_ID"
echo "VCF source: $VCF_SOURCE"
echo "VCF target: $VCF_TARGET"
echo "Population: $POPNAME"
echo "Individuals: $INDS"
echo "Window size: $WINSIZE"
echo "Output: $OUTPUT"

echo "Splitting vcf with bcftools..."
bcftools view -O z -s $INDS $VCF_SOURCE > $VCF_TARGET

echo "Computing Tajima's D with vcftools..."
vcftools --gzvcf $VCF_TARGET --TajimaD $WINSIZE --out $OUTPUT 

echo "Done with script."
date