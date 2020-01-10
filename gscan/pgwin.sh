#!/bin/bash
set -e
set -o pipefail
set -u

GENO=$1 # GENO=seqdata/variants_otherFormats/geno/EjaC.Dstat.NC_022205.1.DP5.geno.gz
OUTPUT=$2 # OUTPUT=ABBABABAoutput_EjaC.Dstat.NC_022205.1.DP5.csv
NCORES=$3

WINSIZE=$4 # WINSIZE=50000
STEPSIZE=$5 # STEPSIZE=100000
MINSITES=$6 # MINSITES=500
MINDATA=$7 # MINDATA=0.5

POP1=$8
POP2=$9

date
echo "Script: abbababa_run.sh"
echo "Geno file: $GENO"
echo "Nr of threads: $NCORES"
echo "Window size: $WINSIZE"
echo "Step size: $STEPSIZE"
echo "Minimum nr of sites: $MINSITES"
echo "Minimum prop of good data: $MINDATA"
echo "Population 1: $POP1"
echo "Population 2: $POP2"

module load python/2.7.1 # Scripts only seem to work with this version of Python 
python software/smartin/popgenWindows.py -T $NCORES --windSize $WINSIZE --stepSize $STEPSIZE --minSites $MINSITES -g $GENO -o $OUTPUT -f phased -p popA $POP1 -p popB $POP2

echo "Done with script."
date