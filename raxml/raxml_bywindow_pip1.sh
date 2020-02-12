#!/bin/bash
set -e
set -o pipefail
set -u

FILE_ID=$1
INDIR=$2
OUTDIR=$3
WINDOW_FILE=$4
WINDOW_LINE=$5
MODEL=$6
MINSITES=$7
SKIPFASTA=$8
OUTGROUPS="$9"

date
echo "## Script: raxml_bywindow_pip1.sh"
echo "## File ID: $FILE_ID"
echo "## Input dir: $INDIR"
echo "## Output dir: $OUTDIR"
echo "## Window file: $WINDOW_FILE"
echo "## Window line: $WINDOW_LINE"
echo "## Model: $MODEL"
echo "## Minimum number of sites: $MINSITES"
echo "## Skip fasta step: $SKIPFASTA"
echo "## Outgroups: $OUTGROUPS"

for WINDOW_LINE in $(seq $WINDOW_LINE $(($WINDOW_LINE+49)))
do
	echo "## Window line: $WINDOW_LINE"
	scripts/genomics/raxml/raxml_bywindow_pip2.sh $FILE_ID $INDIR $OUTDIR $WINDOW_FILE $WINDOW_LINE $MODEL $MINSITES $SKIPFASTA "$OUTGROUPS"
done

echo "## Done with script."
date