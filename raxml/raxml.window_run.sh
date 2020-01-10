#!/bin/bash
set -e
set -o pipefail
set -u

GENO=$1
OUTDIR=$2
RUN_NAME=$3
WINSIZE=$4
MINSITES=$5
NCORES=$6 
OUTGROUP=$7
INDS=$8

module load python/2.7.1
RAXML=xx


date
echo "Script: raxml.window_run.sh"
echo "Geno file: $GENO"
echo "Run name: $RUN_NAME"
echo "Window size: $WINSIZE"
echo "Minimum number of sites: $MINSITES"
echo "Number of cores: $NCORES"
echo "Outgroup individuals: $OUTGROUP"
echo "All individuals: $INDS"

python scripts/trees/smartin/raxml_sliding_windows.py -g $GENO -p $OUTDIR/$RUN_NAME --log $OUTDIR/$RUN_NAME.raxmllog --raxml $RAXML --genoFormat phased \
	--windType coordinate --windSize $WINSIZE --stepSize $WINSIZE --minSites $MINSITES \
	--model GTRCAT --outgroup $OUTGROUP --individuals $INDS -T $NCORES

gunzip -c $OUTDIR/$RUN_NAME.trees.gz > $OUTDIR/$RUN_NAME.trees.txt
rm $OUTDIR/$RUN_NAME.trees.gz

printf "\n\n"
echo "Done with script."
date