#!/bin/bash
set -e
set -o pipefail
set -u

## Software:
VCFTOOLS=/dscrhome/rcw27/programs/vcftools/vcftools-master/bin/vcftools

## Command-line arguments:
INDIR=$1
FILE_ID=$2
POP1=$3
POP2=$4
WINSIZE=$5
WINSTEP=$6
OUTDIR=$7
POPFILEDIR=$8

## Process arguments:
VCF=$INDIR/$FILE_ID.vcf.gz
OUTPUT=$OUTDIR/fst_${FILE_ID}_$POP1.${POP2}_win$WINSIZE.step$WINSTEP.txt

POPFILE1=$POPFILEDIR/$POP1.txt
POPFILE2=$POPFILEDIR/$POP2.txt

## Report:
date
echo "Script: vcftools.fst.sh"
echo "VCF source: $VCF"
echo "Population 1: $POP1"
echo "Population 1: $POP2"
echo "Window size: $WINSIZE"
echo "Window stepsize: $WINSTEP"
echo "Output dir: $OUTDIR"
echo "Popfile dir: $POPFILEDIR"
echo "Output: $OUTPUT"

## Run vcftools:
$VCFTOOLS --gzvcf $VCF --fst-window-size $WINSIZE --fst-window-step $WINSTEP --weir-fst-pop $POPFILE1 --weir-fst-pop $POPFILE2 --out $OUTPUT 

## Report:
echo "Done with script."
date