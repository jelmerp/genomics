#!/bin/bash
set -e
set -o pipefail
set -u

################################################################################
#### SET-UP #####
################################################################################
## Command-line args:
LIBRARY_ID=$1
INDIR=$2
OUTDIR=$3
STATSDIR=$4
BARCODE_FILE=$5
FLIP_SCRIPT=$6

## Prep:
NLINES_FILE=$STATSDIR/$LIBRARY_ID.flipStats.linenumbers.txt # Output stats file
[[ ! -d $OUTDIR ]] && echo "#### flipReads.sh: Creating dir $OUTDIR" && mkdir $OUTDIR
[[ ! -d $STATSDIR ]] && echo "#### flipReads.sh: Creating dir $STATSDIR" && mkdir -p $STATSDIR

## Report:
date
echo "#### flipReads.sh: Library ID: $LIBRARY_ID"
echo "#### flipReads.sh: Indir: $INDIR"
echo "#### flipReads.sh: Outdir: $OUTDIR"
echo "#### flipReads.sh: Statsdir: $STATSDIR"
echo "#### flipReads.sh: File with barcodes: $BARCODE_FILE"
echo "#### flipReads.sh: Flipping script: $FLIP_SCRIPT"
echo "#### flipReads.sh: File with line numbers: $NLINES_FILE"
printf "\n"


################################################################################
#### FLIP READS #####
################################################################################
## Get files:
FILES=$(ls $INDIR/*${LIBRARY_ID}*)
echo -e "#### flipReads.sh: Fastq files:\n $FILES"

## Define read-files and prefix:
READ1_IN=$(echo $FILES | cut -d" " -f1)
READ2_IN=$(echo $FILES | cut -d" " -f2)
PREFIX=$(basename -s "_R1_001.fastq.gz" $READ1_IN)
READ1_OUT=$OUTDIR/${PREFIX}_R1_flipped.fastq
READ2_OUT=$OUTDIR/${PREFIX}_R2_flipped.fastq

## Report:
echo -e "\n#### flipReads.sh: File with R1 reads:"
ls -lh $READ1_IN
echo -e "\n#### flipReads.sh: File with R2 reads:"
ls -lh $READ2_IN
echo -e "\n#### flipReads.sh: Prefix: $PREFIX"
echo "#### flipReads.sh: Read 1 outfile: $READ1_OUT"
echo "#### flipReads.sh: Read 2 outfile: $READ2_OUT"

## Unzip:
[[ $READ1_IN =~ \.gz$ ]] && echo "#### flipReads.sh: Unzipping READ1_IN..." && gunzip $READ1_IN
[[ $READ2_IN =~ \.gz$ ]] && echo "#### flipReads.sh: Unzipping READ2_IN..." && gunzip $READ2_IN

## Names to use for flipping script:
READ1_IN=$(echo $READ1_IN | sed 's/.gz//')
READ2_IN=$(echo $READ2_IN | sed 's/.gz//')


################################################################################
#### RUN FLIPPING SCRIPT ####
################################################################################
echo -e "\n#### flipReads.sh: Running Perl flipping script..."
$FLIP_SCRIPT $BARCODE_FILE $READ1_IN $READ2_IN $READ1_OUT $READ2_OUT > $STATSDIR/flipStats.$PREFIX


################################################################################
#### HOUSEKEEPING ####
################################################################################
## Report:
echo -e "\n#### flipReads.sh: Reporting line numbers:"
wc -l $READ1_IN
wc -l $READ2_IN
wc -l $READ1_OUT
wc -l $READ2_OUT

wc -l $READ1_IN >> $NLINES_FILE
wc -l $READ2_IN >> $NLINES_FILE
wc -l $READ2_OUT >> $NLINES_FILE
wc -l $READ2_OUT >> $NLINES_FILE

## Gzip:
echo -e "\#### flipReads.sh: Gzipping fastqs..."
gzip $READ1_OUT
gzip $READ2_OUT
#[[ $READ1_IN =~ \.gz$ ]] && gzip $READ1_IN
#[[ $READ2_IN =~ \.gz$ ]] && gzip $READ2_IN

## Report:
echo -e "\n#### flipReads.sh: Done with script flipReads.sh"
date


################################################################################
# RUNDIR=POELSTRA_5372_190116A1
# LIBRARY_ID="lemurRadseqHybridZone_r03"
# INDIR=/work/jwp37/radseq/seqdata/fastq/r03/$RUNDIR/raw
# OUTDIR=/work/jwp37/radseq/seqdata/fastq/r03/$RUNDIR/raw_flipped
# STATSDIR=analyses/qc/fastq
# BARCODE_FILE=metadata/r03/barcodes_r03.txt
# FLIP_SCRIPT=/datacommons/yoderlab/users/jelmer/radseq/scripts/fastq_process/flip_trim_sbfI_170601.pl