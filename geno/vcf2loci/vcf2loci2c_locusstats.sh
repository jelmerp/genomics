#!/bin/bash
set -e
set -o pipefail
set -u

################################################################################
#### SET-UP ####
################################################################################
## Software:
AMAS=/datacommons/yoderlab/programs/AMAS/amas/AMAS.py

## Command-line args:
DIR_FASTA=$1
FILE_STATS_ALL=$2

## Process:
DIR_STATS=$(dirname $FILE_STATS_ALL)

## Report:
echo -e "\n\n#### vcf2loci2c_locusstats.sh: Starting script."
echo -e "#### vcf2loci2c_locusstats.sh: Fasta dir: $DIR_FASTA"
echo -e "#### vcf2loci2c_locusstats.sh: Output file: $FILE_STATS_ALL \n"


################################################################################
#### GET LOCUS STATS ####
################################################################################
## Initiate output file:
> $FILE_STATS_ALL

## Get stats for each fasta file:
echo "#### vcf2loci2c_locusstats.sh: Cycling through fasta files..."
for FASTA in $DIR_FASTA/*
do
	echo "#### vcf2loci2c_locusstats.sh: Fasta file: $FASTA"
	
	FASTA_ID=$(basename $FASTA)
	FILE_STATS=$DIR_STATS/tmp.$FASTA_ID.stats.txt
	
	$AMAS summary -f fasta -d dna -i $FASTA -o $FILE_STATS
	
	cat $FILE_STATS | grep -v "Alignment_name" >> $FILE_STATS_ALL
done

## Include header with column names:
HEADER=$(head -n 1 $FILE_STATS)
(echo "$HEADER" && cat $FILE_STATS_ALL) > $DIR_STATS/tmp.txt && mv $DIR_STATS/tmp.txt $FILE_STATS_ALL


################################################################################
#### HOUSEKEEPING ####
################################################################################
echo "#### vcf2loci2c_locusstats.sh: Removing temporary files:"
find $DIR_STATS -name 'tmp*txt' | xargs rm -f

echo -e "\n#### vcf2loci2c_locusstats.sh: Done with script." 
date
