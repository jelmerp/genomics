#!/bin/bash
set -e
set -o pipefail
set -u

################################################################################
#### SET-UP ####
################################################################################
## Software:
ADMIXTURE=/datacommons/yoderlab/programs/admixture_linux-1.3.0/admixture # Admixture binary

## Commmand-line arguments:
FILE_ID=$1
INDIR=$2
OUTDIR=$3
K=$4
NCORES=$5

## Process variables:
INPUT=$INDIR/$FILE_ID.bed
OUTLOG=$OUTDIR/$FILE_ID.$K.admixtureOutLog.txt

## Report:
echo -e "\n#####################################################################"
date
echo "#### admixture_run.sh: Starting script."
echo "#### admixture_run.sh: File ID: $FILE_ID"
echo "#### admixture_run.sh: Value of K: $K"
echo "#### admixture_run.sh: Number of cores: $NCORES"
echo "#### admixture_run.sh: Plink input file dir: $INDIR"
echo "#### admixture_run.sh: Output file dir: $OUTDIR"
printf "\n"
echo "#### admixture_run.sh: Input bed file: $INPUT"
echo "#### admixture_run.sh: Listing input file:"
ls -lh $INPUT
printf "\n"
echo "#### admixture_run.sh: Output file: $OUTLOG"
printf "\n"

[[ ! -d $OUTDIR/pfiles ]] && mkdir -p $OUTDIR/pfiles # Make outdir if it doesn't exist


################################################################################
#### CREATE INDIV FILE ####
################################################################################
## Creates a list of individuals used in the analysis directly from one the 
## files with the sequenced data. The ADMIXTURE output doesn't contain this info.

echo -e "\n#################################################################"
INDIV_FILE=$OUTDIR/$FILE_ID.indivs.txt
echo "#### admixture_run.sh: Indiv file: $INDIV_FILE"

if [ ! -e $OUTDIR/$FILE_ID.indivs.txt ]
	then
	echo "#### admixture_run.sh: Creating indiv file from pedfile..."
	
	PEDFILE=$INDIR/$FILE_ID.ped
	echo "#### admixture_run.sh: Ped file: $PEDFILE"
	
	cut -f1 $PEDFILE > $INDIV_FILE
	echo "#### admixture_run.sh: Listing indiv file:"
	ls -lh $INDIV_FILE
fi

echo "#### admixture_run.sh: Showing indiv file:"
cat $INDIV_FILE


################################################################################
#### RUN ADMIXTURE ####
################################################################################
echo -e "\n#####################################################################"
echo -e "#### admixture_run.sh: Running admixture..."
$ADMIXTURE --cv -j$NCORES $INPUT $K > $OUTLOG


################################################################################
#### FINAL HOUSEKEEPING ####
################################################################################
## Show outlog:
echo -e "\n#####################################################################"
echo -e "#### admixture_run.sh: Contents of logfile..."
cat $OUTLOG
printf "\n"

## Move files:
echo -e "\n#### admixture_run.sh: Moving files to output dir..."
ls -lh $FILE_ID*Q
ls -lh $FILE_ID*P

mv $FILE_ID*Q $OUTDIR/
mv $FILE_ID*P $OUTDIR/pfiles/

echo -e "\n#### admixture_run.sh: Done with script."
date
