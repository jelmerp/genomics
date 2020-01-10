#!/bin/bash
set -e
set -o pipefail
set -u

INDIR_BASE=$1
OUTDIR_BASE=$2
LIBRARY=$3

date
echo "Script: renameFastq.sh"
echo "INDIR_BASE: $INDIR_BASE"
echo "OUTDIR_BASE: $OUTDIR_BASE"
echo "LIBRARY: $LIBRARY"
echo "Starting R script..."

module load R
Rscript scripts/ipyrad/renameFastq.R $INDIR_BASE $OUTDIR_BASE $LIBRARY


echo "Done with script."
date