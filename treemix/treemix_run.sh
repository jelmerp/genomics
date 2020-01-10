#!/bin/bash
set -e
set -o pipefail
set -u

################################################################################
#### SET-UP ####
################################################################################
## Software and scripts:
TREEMIX=/datacommons/yoderlab/programs/treemix-1.13/src/treemix

# Command-line args:
FILE_ID=$1 # File ID for Treemix input file
NMIG=$2 # Nr of migration edges to be added
K=$3 # Blocksize
ROOT=$4 # Root taxon
TRMX_INDIR=$5 # Treemix input dir
TRMX_OUTDIR=$6 # Treemix output dir

## Define Treemix input and output files:
TRMX_INPUT=$TRMX_INDIR/$FILE_ID.tmix
TRMX_OUTPUT=$TRMX_OUTDIR/$FILE_ID.treemixOutput.k$K.mig$NMIG

## Report:
date
echo "#### treemix_run.sh: Starting with script."
echo "#### treemix_run.sh: file ID: $FILE_ID"
echo "#### treemix_run.sh: Number of migration events: $NMIG"
echo "#### treemix_run.sh: Value of K: $K"
echo "#### treemix_run.sh: Root: $ROOT"
echo "#### treemix_run.sh: Treemix input: $TRMX_INPUT"
echo "#### treemix_run.sh: Treemix output: $TRMX_OUTPUT"


################################################################################
#### RUN TREEMIX WITH ROOT TAXON ####
################################################################################
if [ $ROOT != 'none' ]
then
	echo -e "\n\n#### treemix_run.sh: Running treemix with root..."
	$TREEMIX -i $TRMX_INPUT.gz -root $ROOT -m $NMIG -k $K -o $TRMX_OUTPUT.root$ROOT
fi


################################################################################
#### RUN TREEMIX WITHOUT ROOT TAXON ####
################################################################################
if [ $ROOT == 'none' ]
then
	echo -e "\n\n#### treemix_run.sh: Running treemix without root..."
	$TREEMIX -i $TRMX_INPUT.gz -m $NMIG -k $K -o $TRMX_OUTPUT.rootNone
fi


echo -e "\n\n#### treemix_run.sh: Done with script."
date
