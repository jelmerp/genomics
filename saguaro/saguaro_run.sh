#!/bin/bash
set -e
set -o pipefail
set -u


##### SOFTWARE #####
SAGUARO=/dscrhome/rcw27/programs/saguaro/saguarogw-code-44/Saguaro


##### COMMANDLINE ARGUMENTS #####
INFILE=$1
OUTFILE=$2
N_ITER=$3

date
echo "Script: Run Saguaro"
echo "Input file: $INFILE"
echo "Output file: $OUTFILE"
echo "Nr of iterations: $N_ITER"

printf "\n\n"
echo "Running Saguaro..."
$SAGUARO -f $INFILE -o $OUTFILE -iter $N_ITER

printf "\n\n"
echo "Done with script."
date
