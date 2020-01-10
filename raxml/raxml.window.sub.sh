#!/bin/bash
set -e
set -o pipefail
set -u

##### SOFTWARE AND FIXED DIRS #####
OUTDIR_VCF=/work/jwp37/singlegenomes/seqdata/vcf_singleScaf
FASTA_DIR=/work/jwp37/singlegenomes/seqdata/fasta/
RAXML_DIR=analyses/trees/raxml

SCRIPT_SPLIT_VCF=scripts/conversion/splitVCF_byCoords.sh
SCRIPT_VCF2FASTA=scripts/conversion/vcf2fasta.sh
SCRIPT_RAXML_RUN=scripts/trees/raxml_run.sh


##### COMMAND-LINE ARGS #####
FILE_ID=$1
INDIR=$2
OUTDIR=$3
WINDOW_FILE=$4
WINDOW_LINE=$5
MODEL=$6 # Raxml model
MINSITES=$7 # Min nr of sites in window
SKIPFASTA=$8 # TRUE: skip fasta step / FALSE: convert to fasta first
OUTGROUPS="$9" # Raxml outgroups


##### PROCESS VARIABLES #####
VCF_IN=$INDIR/$FILE_ID
SCAFFOLD_M=$(cat $WINDOW_FILE | sed -ne "$WINDOW_LINE,${WINDOW_LINE}p;${WINDOW_LINE}q" | cut -f 1 | sed 's/^[ \t]*//;s/[ \t]*$//')
START_M=$(cat $WINDOW_FILE | sed -ne "$WINDOW_LINE,${WINDOW_LINE}p;${WINDOW_LINE}q" | cut -f 2 | sed 's/^[ \t]*//;s/[ \t]*$//')
END_M=$(cat $WINDOW_FILE | sed -ne "$WINDOW_LINE,${WINDOW_LINE}p;${WINDOW_LINE}q" | cut -f 3 | sed 's/^[ \t]*//;s/[ \t]*$//')


##### REPORT VARIABLES #####
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


##### CREATE FASTA #####
if [ $SKIPFASTA == FALSE ]
then
	echo "Cutting up vcfs in windows... (Scaffold: $SCAFFOLD_M, Start: $START_M, End: $END_M)"
	printf "\n"
	$SCRIPT_SPLIT_VCF $FILE_ID $SCAFFOLD_M $START_M $END_M $INDIR $OUTDIR_VCF
	
	FILE_ID_FULL=$FILE_ID.$SCAFFOLD_M.$START_M.$END_M
	printf "\n"
	echo "File ID - split VCF: $FILE_ID_FULL"
	
	echo "Converting vcf to fasta..."
	$SCRIPT_VCF2FASTA $FILE_ID_FULL $OUTDIR_VCF $FASTA_DIR ALL
else
	echo "Skipping fasta step..."
fi


##### CHECK NUMBER OF STES IN WINDOW #####
echo "Checking number of sites..."
NRSITES=$(cat $FASTA_DIR/$FILE_ID_FULL.varpos | wc -l)
echo "Number of sites: $NRSITES"
echo "$SCAFFOLD_M $START_M $END_M $NRSITES" >> $RAXML_DIR/nrSites.$FILE_ID.raxmlWindows.txt


##### RUN RAXML IF NUMBER OF SITES IS OK #####
if [ "$NRSITES" -ge "$MINSITES" ]
then
	echo "Number of sites OK"
	printf "\n\n"
	echo "Running Raxml..."
	INPUT=$FASTA_DIR/$FILE_ID_FULL.fasta
	ASC_COR=FALSE
	BOOTSTRAP=0
	$SCRIPT_RAXML_RUN $INPUT $FILE_ID_FULL $OUTDIR $MODEL $ASC_COR $BOOTSTRAP "$OUTGROUPS"
else
	printf "\n"; echo "TOO FEW SITES, SKIPPING RAXML STEP"; printf "\n"
fi


##### CLEAN UP #####
printf "\n"
echo "Removing fasta files..."
rm -f $FASTA_DIR/$FILE_ID_FULL*
rm -f $OUTDIR/RAxML_info.$FILE_ID_FULL*
rm -f $OUTDIR/RAxML_log.$FILE_ID_FULL*
rm -f $OUTDIR/RAxML_parsimonyTree.$FILE_ID_FULL*
rm -f $OUTDIR/RAxML_result.$FILE_ID_FULL*

echo "Done with script raxml.window.sub.sh"
date
printf "\n\n\n"
