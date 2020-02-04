#!/bin/bash
set -e
set -o pipefail
set -u

################################################################################
##### SETUP #####
################################################################################
## Software & scripts:
SCRIPT_CONVERT=/datacommons/yoderlab/users/jelmer/scripts/genomics/conversion/vcf2newhybrids.sh
SCRIPT_NEWHYBRIDS=/datacommons/yoderlab/users/jelmer/scripts/genomics/newhybrids/newhybrids_run.sh

## Positional args:
RUN_ID=$1
VCF=$2
NEWHYBRIDS_INPUT=$3
MEM=$4
BURNIN=$5
NSWEEPS=$6

## Report:
date
echo "##### newhybrids_pip.sh: Starting script."
echo "##### newhybrids_pip.sh: Slurm Job ID: $SLURM_JOB_ID"
echo "##### newhybrids_pip.sh: Vcf file : $VCF"
echo "##### newhybrids_pip.sh: Newhybrids input file (to create): $NEWHYBRIDS_INPUT"
echo "##### newhybrids_pip.sh: Memory: $MEM"
echo "##### newhybrids_run.sh: Number of burn-in sweeps: $BURNIN"
echo "##### newhybrids_run.sh: Number of sweeps after burn-in: $NSWEEPS"
printf "\n"


################################################################################
##### CONVERT VCF TO NEWHYBRIDS #####
################################################################################
SPIDFILE=/datacommons/yoderlab/users/jelmer/scripts/genomics/conversion/vcf2newhybrids.spid
echo "##### newhybrids_pip.sh: Input format: $INFORMAT"
echo "##### newhybrids_pip.sh: SPID-file: $SPIDFILE"
printf "\n"

echo "##### newhybrids_pip.sh: Calling conversion script..."
$SCRIPT_CONVERT $VCF $NEWHYBRIDS_INPUT $SPIDFILE $MEM
printf "\n\n"


################################################################################
##### RUN NEWHYBRIDS #####
################################################################################
echo "##### newhybrids_pip.sh: Calling newhybrids script..."
OUTDIR=analyses/newhybrids/output/$RUN_ID/
$SCRIPT_NEWHYBRIDS $NEWHYBRIDS_INPUT $OUTDIR $BURNIN $NSWEEPS
printf "\n\n"

## Report:
echo "##### newhybrids_pip.sh: Done with script."
date