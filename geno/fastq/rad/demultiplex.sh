#!/bin/bash
set -e
set -o pipefail
set -u

################################################################################
#### SET-UP ####
################################################################################
## Scripts:
export LD_LIBRARY_PATH=/datacommons/yoderlab/users/gtiley/compilers/gccBin/lib64/:$LD_LIBRARY_PATH
STACKS_PROCESS_RADTAGS=/datacommons/yoderlab/programs/stacks-2.0b/process_radtags

## Command-line args:
R1=$1
R2=$2
OUTDIR=$3
DIR_STATS=$4
BARCODE_FILE=$5

## Prep:
[[ $R1 =~ \.gz$ ]] && INPUT_COMMAND="-i gzfastq" && ID=$(basename $R1 .fastq.gz)
[[ $R1 =~ \.fastq$ ]] && INPUT_COMMAND="-i fastq" && ID=$(basename $R1 .fastq)
STATSFILE=$DIR_STATS/$ID.demultiplexStats.txt

## Report:
date
echo "#### demultiplex.sh: Starting script."
echo "#### demultiplex.sh: Input fastq R1: $R1"
echo "#### demultiplex.sh: Input fastq R2: $R2"
echo "#### demultiplex.sh: Output fastq dir: $OUTDIR"
echo "#### demultiplex.sh: Output stats dir: $DIR_STATS"
echo "#### demultiplex.sh: Output stats file: $STATSFILE"
echo "#### demultiplex.sh: File with barcodes: $BARCODE_FILE"
echo -e "\n#### demultiplex.sh: ID: $ID"
echo -e "#### demultiplex.sh: Stacks input format command: $INPUT_COMMAND \n"

## Create output dir if not there yet:
[[ ! -d $OUTDIR ]] && echo -e "#### Creating dir $OUTDIR \n" && mkdir -p $OUTDIR


################################################################################
#### RUN STACKS PROCESS_RADTAGES ####
################################################################################
## Run:
$STACKS_PROCESS_RADTAGS --paired -r --inline_null $INPUT_COMMAND -e sbfI \
	-1 $R1 -2 $R2 -o $OUTDIR -b $BARCODE_FILE -y gzfastq > $STATSFILE

# -r option: rescue barcodes and radtags
# -e option: specify enzyme (=sbfI)
# --inline_null option: barcode is inline with sequence, occurs only on single-end read (default).


## Remove "rem" files:
echo -e "\n#### demultiplex.sh: Removing rem files:"
rm -f $OUTDIR/*rem.1.fq*
rm -f $OUTDIR/*rem.2.fq*


################################################################################
#### HOUSEKEEPING ####
################################################################################
## Report:
echo -e "\n#### demultiplex.sh: Showing stats file contents:"
cat $STATSFILE

echo -e "\n#### demultiplex.sh: Done with script."
date