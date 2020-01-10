#!/bin/bash
set -e
set -o pipefail
set -u

## Software:
SPLITSTREE=/datacommons/yoderlab/programs/splitstree4/SplitsTree

## Command-line args:
INFILE=$1
OUTFILE=$2

## Report:
printf "\n"
date
echo "#### splitstree_run.sh: Starting script."
echo "#### splitstree_run.sh: Slurm job name: $SLURM_JOB_NAME"
echo "#### splitstree_run.sh: Slurm job ID: $SLURM_JOB_ID"
echo "#### splitstree_run.sh: Nexus input: $INFILE"
echo "#### splitstree_run.sh: Nexus output: $OUTFILE"

## Run splitstree:
echo -e "\n#### splitstree_run.sh: Running Splitstree..."
$SPLITSTREE -g -i $INFILE -x "UPDATE; SAVE REPLACE=yes FILE=$OUTFILE.tmp; QUIT"

## Remove sequences from nexus output:
echo -e "\n#### splitstree_run.sh: Removing actual sequence from Nexus output..."
START=$(grep -n "BEGIN Characters;" $OUTFILE.tmp | cut -f1 -d:)
END=$(grep -n "END;.*Characters" $OUTFILE.tmp | cut -f1 -d:)
sed "$START,${END}d" $OUTFILE.tmp > $OUTFILE

rm -f $OUTFILE.tmp

echo -e "\n#### splitstree_run.sh: Done with script."
date