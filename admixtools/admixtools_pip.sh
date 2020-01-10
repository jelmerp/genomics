#!/bin/bash
set -e
set -o pipefail
set -u

################################################################################
#### SET-UP ####
################################################################################
## Software and scripts:
SCRIPT_PREPINPUT=/datacommons/yoderlab/users/jelmer/scripts/admixtools/admixtools_prepInput.sh
SCRIPT_ATOOLS=/datacommons/yoderlab/users/jelmer/scripts/admixtools/admixtools_run.sh

## Positional args:
FILE_ID=$1
shift
RUN_ID=$1
shift
VCF_DIR=$1
shift
PLINK_DIR=$1
shift
ATOOLS_DIR=$1
shift
INDFILE=$1
shift
POPFILE=$1
shift
VCF2PLINK=$1
shift
CREATE_INDFILE=$1
shift
SUBSET_INDFILE=$1
shift
ATOOLS_MODE=$1
shift
INDS_METADATA=$1
shift
ID_COLUMN=$1
shift
GROUPBY=$1
shift
SELECT_INDS=$1
shift
INDLIST=$1
shift

## Process:
FILE_ID_FULL=${FILE_ID}$RUN_ID

INDIR=$ATOOLS_DIR/input/
OUTDIR=$ATOOLS_DIR/output/
OUTDIR_RAW=$ATOOLS_DIR/output/raw/

[[ $ATOOLS_MODE == "D" ]] && PARFILE=$INDIR/parfile_dmode_$FILE_ID_FULL.txt
[[ $ATOOLS_MODE == "F4" ]] && PARFILE=$INDIR/parfile_f4mode_$FILE_ID_FULL.txt
[[ $ATOOLS_MODE == "F3" ]] && PARFILE=$INDIR/parfile_f3_$FILE_ID_FULL.txt
[[ $ATOOLS_MODE == "F4RATIO" ]] && PARFILE=$INDIR/parfile_f4ratio_$FILE_ID_FULL.txt

[[ ! -d $ATOOLS_DIR/input ]] && mkdir -p $ATOOLS_DIR/input
[[ ! -d $ATOOLS_DIR/output/raw ]] && mkdir -p $ATOOLS_DIR/output/raw
[[ ! -d $PLINK_DIR ]] && mkdir -p $PLINK_DIR

## Report:
echo -e "\n\n###################################################################"
date
echo "#### admixtools_pip.sh: Starting script."
echo "#### admixtools_pip.sh: File ID: $FILE_ID"
echo "#### admixtools_pip.sh: Run ID: $RUN_ID"
echo "#### admixtools_pip.sh: VCF dir: $VCF_DIR"
echo "#### admixtools_pip.sh: PLINK dir: $PLINK_DIR"
echo "#### admixtools_pip.sh: Create indfile (TRUE/FALSE): $CREATE_INDFILE"
echo "#### admixtools_pip.sh: Subset indfile (TRUE/FALSE): $SUBSET_INDFILE"
printf "\n"
echo "#### admixtools_pip.sh: Admixtools mode: $ATOOLS_MODE"
printf "\n"
echo "#### admixtools_pip.sh: Metadata file: $INDS_METADATA"
echo "#### admixtools_pip.sh: ID column: $ID_COLUMN"
echo "#### admixtools_pip.sh: Group-by column: $GROUPBY"
printf "\n"
echo "#### admixtools_pip.sh: Select inds (TRUE/FALSE): $SELECT_INDS"
echo "#### admixtools_pip.sh: List with indivividuals to select: $INDLIST"
printf "\n"
echo "#### admixtools_pip.sh: Indfile (output): $INDFILE"
echo "#### admixtools_pip.sh: Popfile (input): $POPFILE"
echo "#### admixtools_pip.sh: Parfile: $PARFILE"
printf "\n"


################################################################################
#### PREP INPUT #####
################################################################################
echo "#### admixtools_pip.sh: Calling script to prep input files..."
$SCRIPT_PREPINPUT $FILE_ID $VCF_DIR $PLINK_DIR $VCF2PLINK $CREATE_INDFILE $SUBSET_INDFILE \
	$INDFILE $POPFILE $PARFILE $ATOOLS_MODE $INDS_METADATA $ID_COLUMN $GROUPBY $SELECT_INDS $INDLIST


################################################################################
#### RUN ADMIXTOOLS #####
################################################################################
## D-mode:
if [ $ATOOLS_MODE == "D" ]
then
	OUTPUT=$OUTDIR/$FILE_ID_FULL.dmode.out
	
	echo -e "\n#################################################################"
	echo "#### admixtools_pip.sh: Running admixtools in D mode:"
	echo "#### admixtools_pip.sh: Output: $OUTPUT"
	
	for POPFILE_LINE in $(seq 1 $(cat $POPFILE | wc -l))
	do
		echo -e "\n#### Line nr: $POPFILE_LINE"
		head -n $POPFILE_LINE $POPFILE | tail -n 1
		
		#sbatch -p yoderlab,common,scavenger --mem-per-cpu=12G -o slurm.admix.$FILE_ID.$POPFILE_LINE \
		$SCRIPT_ATOOLS $FILE_ID_FULL $POPFILE_LINE $PARFILE $OUTPUT $ATOOLS_MODE
	done
	
	## Combine output into single file:
	grep -h "result" $OUTPUT.line* > $OUTPUT
fi


## F4-mode: ## TO DO ##
if [ $ATOOLS_MODE == "F4" ]
then
	echo "#### admixtools_pip.sh: Running admixtools in F4 mode:"
	OUTPUT=$OUTDIR/$FILE_ID_FULL.f4mode.out
fi
	

## F3-mode:
if [ $ATOOLS_MODE == "F3" ]
then
	OUTPUT=$OUTDIR/$FILE_ID_FULL.f3.out
	POPFILE_LINE=ALL
	echo "#### admixtools_pip.sh: Running admixtools in f3 mode:"
	echo "#### admixtools_pip.sh: Output: $OUTPUT"
	
	$SCRIPT_ATOOLS $FILE_ID_FULL $POPFILE_LINE $PARFILE $OUTPUT $ATOOLS_MODE
fi


## F3-mode:
if [ $ATOOLS_MODE == "F4RATIO" ]
then
	OUTPUT=$OUTDIR/$FILE_ID_FULL.f4ratio.out
	POPFILE_LINE=ALL
	echo "#### admixtools_pip.sh: Running admixtools in f4ratio mode:"
	echo "#### admixtools_pip.sh: Output: $OUTPUT"
	
	$SCRIPT_ATOOLS $FILE_ID_FULL $POPFILE_LINE $PARFILE $OUTPUT $ATOOLS_MODE
fi


################################################################################
#### HOUSEKEEPING #####
################################################################################
## Report:
echo -e "\n\n#### admixtools_pip.sh: Admixtools output: $OUTPUT"
cat $OUTPUT
printf "\n"

echo "#### admixtools_pip.sh: Done with script."
date