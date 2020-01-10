#!/bin/bash
set -e
set -o pipefail
set -u

## Dfoil software:
FASTA2DFOIL=/datacommons/yoderlab/programs/dfoil/fasta2dfoil.py
DFOIL=/datacommons/yoderlab/programs/dfoil/dfoil.py

FILE_ID=$1
FASTA=$2
DFOIL_INFILE=$3
DFOIL_OUTFILE=$4
TAXA="$5"


##### STEP 2 - PREP DFOIL INPUT FROM FASTA #####
echo "Starting input file prep..."
module load python/2.7.11
$FASTA2DFOIL $FASTA --out $DFOIL_INFILE --names "$TAXA"
echo "Done with input file prep"

##### STEP 3 - RUN DFOIL #####
echo "Starting Dfoil run..."
module load Python/3.6.4
$DFOIL --infile $DFOIL_INFILE --out $DFOIL_OUTFILE #--mode dfoilalt

printf "\n\n"
echo "Done with script."
date
