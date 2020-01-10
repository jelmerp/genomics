#!/bin/bash
set -e
set -o pipefail
set -u

################################################################################
#### SET-UP ####
################################################################################
## Software:
FAIDX=/datacommons/yoderlab/programs/miniconda2/bin/faidx

## Command-line args:
LOCUSLIST=$1
DIR_LOCUSFASTA_INTERMED=$2
FASTA_MERGED=$3
FIRST=$4
LAST=$5

## Report:
echo -e "\n\n###################################################################"
date
echo -e "#### vcf2loci2b_locusfasta.sh: Starting script."
echo -e "#### vcf2loci2b_locusfasta.sh: Locus list: $LOCUSLIST"
echo -e "#### vcf2loci2b_locusfasta.sh: Fasta dir - by locus: $DIR_LOCUSFASTA_INTERMED"
echo -e "#### vcf2loci2b_locusfasta.sh: Fasta - merged: $FASTA_MERGED"
echo -e "#### vcf2loci2b_locusfasta.sh: First locus: $FIRST"
echo -e "#### vcf2loci2b_locusfasta.sh: Last locus: $LAST \n\n"


################################################################################
#### EXTRACT SINGLE-LOCUS FASTA FILES FROM MERGED FASTA ####
################################################################################
echo -e "#### vcf2loci2b_locusfasta.sh: Cycling through locus-list lines... \n"
for LINE in $(seq $FIRST $LAST)
do
	LOCUS_REALNAME=$(head -n $LINE $LOCUSLIST | tail -n 1)
	LOCUS_FAIDXNAME=$(echo "$LOCUS_REALNAME" | sed 's/:/,/g')
	FASTA=$DIR_LOCUSFASTA_INTERMED/$LOCUS_REALNAME.fa
	
	$FAIDX --regex "$LOCUS_FAIDXNAME" $FASTA_MERGED | sed 's/,/:/g' > $FASTA
	
	echo "#### vcf2loci2b_locusfasta.sh: Line: $LINE    Fasta: $FASTA"
done

## Report:
echo -e "\n#### vcf2loci2b_locusfasta.sh: Done with script."
date
