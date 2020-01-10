#!/bin/bash
set -e
set -o pipefail
set -u

## Software:
RAXML=/dscrhome/rcw27/programs/raxml/standard-RAxML-master/raxmlHPC-SSE3

## Command-line arguments:
INPUT=$1
FILE_ID=$2
OUTDIR=$3
MODEL=$4
ASC_COR=$5
BOOTSTRAP=$6
OUTGROUPS="$7"

## Other variables:
OUTPUT=$FILE_ID.$MODEL.bootstrap$BOOTSTRAP

date
echo "Script: raxml_run.sh"
echo "Input: $INPUT"
echo "Output dir: $OUTDIR"
echo "File ID: $FILE_ID"
echo "Run ID: $OUTPUT"
echo "Model: $MODEL"
echo "Nr of bootstraps: $BOOTSTRAP"
echo "Outgroups: $OUTGROUPS"

rm -f RAxML*$OUTPUT*

## Run RAxML:
if [ $BOOTSTRAP == 0 ]
then
	if [ $ASC_COR == TRUE ]
	then
		echo "Running Raxml with ascertainment correction (only variable sites)..."
		$RAXML -N 1 -m $MODEL -s $INPUT -n $OUTPUT -p8749587 --asc-corr=lewis $OUTGROUPS
		elif [ $MODEL == GTRCAT ]
		then
			echo "Running Raxml with CAT model and no rate heterogeneity (-V flag)..."
			$RAXML -N 1 -m $MODEL -V -s $INPUT -n $OUTPUT -p8749587 $OUTGROUPS
		else
			echo "Running Raxml without ascertainment correction..."
			$RAXML -N 1 -m $MODEL -s $INPUT -n $OUTPUT -p8749587 $OUTGROUPS
		fi
	else
		if [ $ASC_COR == TRUE ]
		then
			echo "Running Raxml with ascertainment correction (only variable sites)..."
			$RAXML -N 1 -m $MODEL -s $INPUT -n $OUTPUT -p8749587 -x 12345 -f a -N $BOOTSTRAP $OUTGROUPS --asc-corr=lewis
			elif [ $MODEL == GTRCAT ]
			then
				echo "Running Raxml with CAT model and no rate heterogeneity (-V flag)..."
				$RAXML -N 1 -m $MODEL -V -s $INPUT -n $OUTPUT -p8749587 -x 12345 -f a -N $BOOTSTRAP $OUTGROUPS
			else
				echo "Running Raxml without ascertainment correction..."
				$RAXML -N 1 -m $MODEL -s $INPUT -n $OUTPUT -p8749587 -x 12345 -f a -N $BOOTSTRAP $OUTGROUPS
			fi
		fi

mv RAxML*$OUTPUT* $OUTDIR

echo "Done with script."
date
