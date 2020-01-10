#!/bin/bash
set -e
set -o pipefail
set -u

### Software:
MSMC=/datacommons/yoderlab/programs/msmc2/msmc_2.0.0_linux64bit


### Variables:
METHOD="$1"
shift
P_PAR="$1"
shift
RUN_NAME="$1"
shift
ID="$1"
shift
count=0; while [ "$*" != "" ]; do MSMC_INPUT[$count]=$1; shift; count=`expr $count + 1`; done


### Process variables:
#MSMC_INPUT=`for SCAFFOLD in ${SCAFFOLDS[@]}; do find analyses/msmc/input/$METHOD/ind/ -maxdepth 1 -name "*$ID.$SCAFFOLD*.txt"; done`

MSMC_OUTPUT=analyses/msmc/output/$METHOD/ind/msmc_output.$ID.$RUN_NAME

[[ -z $SLURM_NTASKS ]] && SLURM_NTASKS=1 # If not run through slurm


### Report settings/parameters:
date
echo "Script: $SLURM_JOB_NAME"
echo "Number of tasks/processors: $SLURM_NTASKS"
echo "Job ID: $SLURM_JOB_ID"

echo "Run name: $RUN_NAME"
echo "SNP calling method: $METHOD"
echo "Period setting: $P_PAR"
echo "Population or individuals ID: $ID"
#echo "Scaffolds: ${SCAFFOLDS[@]}"
echo "MSMC_OUTPUT: $MSMC_OUTPUT"
echo "MSMC_INPUT: ${MSMC_INPUT[@]}"


### Run MSMC:
echo "Starting MSMC run..."
$MSMC -t $SLURM_NTASKS -p $P_PAR -o $MSMC_OUTPUT ${MSMC_INPUT[@]}

### Move "loop" and "log" output files:
mv $MSMC_OUTPUT*loop.txt analyses/msmc/output/$METHOD/log_and_loop/
mv $MSMC_OUTPUT*log analyses/msmc/output/$METHOD/log_and_loop/


echo "Done with script."
date



# --fixedRecombination for >1 ind; -t is nr of segments/cores; -p time segment scheme
# PSMC default: -p 1*4+25*2+1*4+1*6 # MSMC default: -p 10*1+15*2

### Testing:
# module load bioinfo-tools; module load msmc
# msmc -t 16 -p 10*1+15*2 -o out.txt pup1.txt pup2.txt
# msmc -t 16 -p 10*1+15*2 -o out.txt cro1.txt cro2.txt
# msmc -t 16 -p 10*1+15*2 -o out.txt pup1ed.txt pup2ed.txt
# 
# cat pup1.txt | sed s/\\.1//g > pup1ed.txt
# cat pup2.txt | sed s/\\.1//g > pup2ed.txt