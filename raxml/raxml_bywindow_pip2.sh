#!/bin/bash
set -e
set -o pipefail
set -u

################################################################################
#### SETUP ####
################################################################################
## Scripts and hardcoded dirs:
SCRIPT_SPLIT_VCF=scripts/genomics/conversion/vcf_split_bycoords.sh
SCRIPT_VCF2FASTA=scripts/genomics/conversion/vcf2fasta.sh
SCRIPT_RAXML_RUN=scripts/genomics/raxml/raxml_run.sh

OUTDIR_VCF=seqdata/tmp/vcf_singlescaf
FASTA_DIR=seqdata/tmp/fasta/
RAXML_DIR=analyses/trees/raxml

[[ ! -d $OUTDIR_VCF ]] && mkdir -p $OUTDIR_VCF
[[ ! -d $FASTA_DIR ]] && mkdir -p $FASTA_DIR
[[ ! -d $RAXML_DIR ]] && mkdir -p $RAXML_DIR

## Command-line args:
FILE_ID=$1
INDIR=$2
OUTDIR=$3
WINDOW_FILE=$4
WINDOW_LINE=$5
MODEL=$6 # Raxml model
MINSITES=$7 # Min nr of sites in window
SKIPFASTA=$8 # TRUE: skip fasta step / FALSE: convert to fasta first
OUTGROUPS="$9" # Raxml outgroups

## Process command-line args:
VCF_IN=$INDIR/$FILE_ID
SCAFFOLD_M=$(cat $WINDOW_FILE | sed -ne "$WINDOW_LINE,${WINDOW_LINE}p;${WINDOW_LINE}q" | cut -f 1 | sed 's/^[ \t]*//;s/[ \t]*$//')
START_M=$(cat $WINDOW_FILE | sed -ne "$WINDOW_LINE,${WINDOW_LINE}p;${WINDOW_LINE}q" | cut -f 2 | sed 's/^[ \t]*//;s/[ \t]*$//')
END_M=$(cat $WINDOW_FILE | sed -ne "$WINDOW_LINE,${WINDOW_LINE}p;${WINDOW_LINE}q" | cut -f 3 | sed 's/^[ \t]*//;s/[ \t]*$//')

## Report:
date
echo "Script: raxml.scaffold.sub.sh"
echo "File ID: $FILE_ID"
echo "Input dir: $INDIR"
echo "Output dir: $OUTDIR"
echo "Window file: $WINDOW_FILE"
echo "Window line: $WINDOW_LINE"
echo "Model: $MODEL"
echo "Minimum number of sites: $MINSITES"
echo "Skip fasta step: $SKIPFASTA"
echo "Outgroups: $OUTGROUPS"
echo "VCF input file: $VCF_IN"


################################################################################
#### CREATE FASTA ####
################################################################################
if [ $SKIPFASTA == FALSE ]
then
	echo -e "Cutting up vcfs in windows... (Scaffold: $SCAFFOLD_M, Start: $START_M, End: $END_M) \n"
	$SCRIPT_SPLIT_VCF $FILE_ID $SCAFFOLD_M $START_M $END_M $INDIR $OUTDIR_VCF
	
	FILE_ID_FULL=$FILE_ID.$SCAFFOLD_M.$START_M.$END_M
	echo -e "\n## File ID - split VCF: $FILE_ID_FULL"
	
	echo "## Converting vcf to fasta..."
	$SCRIPT_VCF2FASTA $FILE_ID_FULL $OUTDIR_VCF $FASTA_DIR ALL
else
	echo "## Skipping fasta step..."
fi

## Check fasta - check nr of sites in window:
echo "## Checking number of sites..."
NRSITES=$(cat $FASTA_DIR/$FILE_ID_FULL.varpos | wc -l)
echo "## Number of sites: $NRSITES"
echo "$SCAFFOLD_M $START_M $END_M $NRSITES" >> $RAXML_DIR/nrSites.$FILE_ID.raxmlWindows.txt


################################################################################
#### RUN RAXML IF NUMBER OF SITES IS OK ####
################################################################################
if [ "$NRSITES" -ge "$MINSITES" ]
then
	echo "## Number of sites OK"
	echo -e "\n\n## Running Raxml..."
	INPUT=$FASTA_DIR/$FILE_ID_FULL.fasta
	ASC_COR=FALSE
	BOOTSTRAP=0
	$SCRIPT_RAXML_RUN $INPUT $FILE_ID_FULL $OUTDIR $MODEL $ASC_COR $BOOTSTRAP "$OUTGROUPS"
else
	echo -e "\n## WARNING: TOO FEW SITES, SKIPPING RAXML STEP\n"
fi


################################################################################
#### HOUSEKEEPING ####
################################################################################
echo -e "\n## Removing tmp fasta files..."
rm -f $FASTA_DIR/$FILE_ID_FULL*
rm -f $OUTDIR/RAxML_info.$FILE_ID_FULL*
rm -f $OUTDIR/RAxML_log.$FILE_ID_FULL*
rm -f $OUTDIR/RAxML_parsimonyTree.$FILE_ID_FULL*
rm -f $OUTDIR/RAxML_result.$FILE_ID_FULL*

date
echo -e "## Done with script.\n\n"