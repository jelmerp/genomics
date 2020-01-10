#!/bin/bash
set -e
set -o pipefail
set -u

## Command-line args:
ID=$1
INDIR=$2
OUTDIR=$3

echo -e "\n\n###################################################################"
echo -e "#### mergeFast.sh: Starting script."
date

## Process args:
R1_OUT=$OUTDIR/$ID.R1.fastq.gz
R2_OUT=$OUTDIR/$ID.R2.fastq.gz

## Only run if outpt file does not already exist:
if [ ! -s $R1_OUT ]
then
	## List input files:
	echo -e "\n#### mergeFast.sh: Listing R1 input files:"
	find $INDIR -name "$ID*R1*q.gz" -exec ls -lh {} \;
	echo -e "\n#### mergeFast.sh: Listing R2 input files:"
	find $INDIR -name "$ID*R2*q.gz" -exec ls -lh {} \;
	
	## Concatenate fastq's:
	find $INDIR -name "$ID*R1*q.gz" -exec cat {} + > $R1_OUT
	find $INDIR -name "$ID*R2*q.gz" -exec cat {} + > $R2_OUT
	
else
	echo -e "\n\n\n#### mergeFast.sh: FILE R1 ALREADY EXISTS...SKIPPING.\n\n\n"
fi

## List output files:
echo -e "\n#### mergeFast.sh: Listing R1 output file:"
ls -lh $R1_OUT
echo -e "\n#### mergeFast.sh: Listing R2 output file:"
ls -lh $R2_OUT

## Report:
echo -e "\n#### mergeFast.sh: Done with script."
date