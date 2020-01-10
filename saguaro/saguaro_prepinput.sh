#!/bin/bash
set -e
set -o pipefail
set -u


##### SOFTWARE #####
vcf2hmm=/dscrhome/rcw27/programs/saguaro/saguarogw-code-44/VCF2HMMFeature


##### COMMANDLINE ARGUMENTS #####
INFILE=$1
OUTFILE=$2

[[ ! -e $INFILE ]] && [[ -e $INFILE.gz ]] && echo "Unzipping $INFILE.gz ..." && gunzip -c $INFILE.gz > $INFILE

date
echo "Script: Prep Saguaro input"
echo "Input file (vcf): $INFILE"
echo "Output file (HMMFeature): $OUTFILE"

printf "\n\n"
echo "Prepping input file..."

$vcf2hmm -i $INFILE -o $OUTFILE

printf "\n\n"
echo "Done with script."
date
