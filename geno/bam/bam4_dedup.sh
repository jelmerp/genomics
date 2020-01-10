#!/bin/bash
set -e
set -o pipefail
set -u

################################################################################
#### SET-UP #####
################################################################################
## Software:
SAMTOOLS=/datacommons/yoderlab/programs/samtools-1.6/samtools

## Command-line args:
ID=$1
INDIR=$2
OUTDIR=$3
PREFIX_IN=$4
PREFIX_OUT=$5
USE_R2=$6
BAMSTATS_DIR=$7

## Process args:
INPUT=$INDIR/$ID.$PREFIX_IN.bam
OUTPUT=$OUTDIR/$ID.$PREFIX_OUT.bam
STATSFILE=$BAMSTATS_DIR/$ID.bamFilterStats.txt
if [ $USE_R2 == "FALSE" ]
then
	echo "#### bam4_dedup.sh: Not using R2..."
	ADD_COMMAND="-s"
else
	ADD_COMMAND=""
fi


## Report:
echo -e "\n#### bam4_dedup.sh: Starting script."
date
echo "#### bam4_dedup.sh: ID: $ID"
echo "#### bam4_dedup.sh: Indir: $INDIR"
echo "#### bam4_dedup.sh: Outdir: $OUTDIR"
echo "#### bam4_dedup.sh: Prefix_in: $PREFIX_IN"
echo "#### bam4_dedup.sh: Prefix_out: $PREFIX_OUT"
echo "#### bam4_dedup.sh: Use R2: $USE_R2"
echo "#### bam4_dedup.sh: Bamstats dir: $BAMSTATS_DIR"
echo "#### bam4_dedup.sh: Bamstats file: $STATSFILE"


################################################################################
#### DEDUP #####
################################################################################
echo "#### bam4_dedup.sh: Deduplicating bamfile..."
$SAMTOOLS rmdup $ADD_COMMAND $INPUT $OUTPUT

echo "#### bam4_dedup.sh: Indexing bamfile..."
$SAMTOOLS index -b $OUTPUT


################################################################################
#### HOUSEKEEPING #####
################################################################################
NRSEQS_IN=$($SAMTOOLS view -c $INPUT)
NRSEQS_OUT=$($SAMTOOLS view -c $OUTPUT)

echo -e "\n#### bam4_dedup.sh: Nr of sequences before dedupping: $NRSEQS_IN"
echo -e "#### bam4_dedup.sh: Nr of sequences after dedupping: $NRSEQS_OUT \n"

echo "Nr of sequences before dedupping: $NRSEQS_IN" >> $STATSFILE 
echo "Nr of sequences after dedupping: $NRSEQS_OUT" >> $STATSFILE

date
echo -e "#### bam4_dedup.sh: Done with script. \n"
