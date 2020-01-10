#!/bin/bash
set -e
set -o pipefail
set -u

################################################################################
#### SET-UP ####
################################################################################

## Software/scripts:
NEWHYBRIDS=/datacommons/yoderlab/programs/newhybrids/newhybrids-no-gui-linux.exe

## Positional args:
INFILE=$1
OUTDIR=$2
BURNIN=$3
NSWEEPS=$4

[[ -z $BURNIN ]] && BURNIN=10000 #10k=default
[[ -z $NSWEEPS ]] && NSWEEPS=50000 #50k=default

## Report:
echo -e "\n################################################################################"
date
echo "##### newhybrids_run.sh: Starting script."
echo "##### newhybrids_run.sh: Input file: $INFILE"
echo "##### newhybrids_run.sh: Output dir: $OUTDIR"
echo "##### newhybrids_run.sh: Number of burn-in sweeps: $BURNIN"
echo "##### newhybrids_run.sh: Number of sweeps after burn-in: $NSWEEPS"
printf "\n"

## Process args:
[[ ! -d $OUTDIR ]] && echo -e "##### newhybrids_run: Creating output dir $OUTDIR \n" && mkdir -p $OUTDIR
cd $OUTDIR


################################################################################
#### RUN NEWHYBRIDS ####
################################################################################
echo "##### newhybrids_run.sh: Starting newhybrids run..."
$NEWHYBRIDS -d $INFILE --burn-in $BURNIN --num-sweeps $NSWEEPS --no-gui 


################################################################################
#### REPORT ####
################################################################################
echo -e "\n################################################################################"
echo "##### newhybrids_run.sh: Listing output files in output dir $OUTDIR:"
ls -lh
printf "\n"

echo "##### newhybrids_run.sh: Done with script."
date
printf "\n"