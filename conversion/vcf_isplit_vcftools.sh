#!/bin/bash
set -e
set -o pipefail
set -u

################################################################################
##### SET-UP #####

## Software:
VCFTOOLS=/dscrhome/rcw27/programs/vcftools/vcftools-master/bin/vcftools

## Command-line arguments:
SOURCE_ID="$1"
TARGET_ID="$2"
INDIR="$3"
OUTDIR="$4"
INDFILE="$5"
ADDITIONAL_COMMAND="$6"

## Process variables:
[[ -e $INDIR/$SOURCE_ID.vcf ]] && echo -e "\n##### splitVCFbyInd_vcftools.sh: Unzipped VCF detected...\n" && INFILE="$INDIR/$SOURCE_ID.vcf"
[[ -e $INDIR/$SOURCE_ID.vcf.gz ]] && echo "\n##### splitVCFbyInd_vcftools.sh: Unzipped VCF detected...\n" && INFILE="$INDIR/$SOURCE_ID.vcf.gz"
[[ -e $INDIR/$SOURCE_ID.vcf ]] && [[ -e $INDIR/$SOURCE_ID.vcf.gz ]] && echo "\n##### splitVCFbyInd_vcftools.sh: NO VCF FILE DETECTED...\n"

OUTFILE=$OUTDIR/${TARGET_ID}.vcf.gz
LOGFILE=$OUTDIR/$TARGET_ID.vcftools.log


## Report:
date
echo "##### splitVCFbyInd_vcftools.sh: Starting script."
echo "##### splitVCFbyInd_vcftools.sh: Source ID: $SOURCE_ID"
echo "##### splitVCFbyInd_vcftools.sh: Target ID: $TARGET_ID"
echo "##### splitVCFbyInd_vcftools.sh: Source dir: $INDIR"
echo "##### splitVCFbyInd_vcftools.sh: Target dir: $OUTDIR"
echo "##### splitVCFbyInd_vcftools.sh: Indfile: $INDFILE"
printf "\n"
echo "##### splitVCFbyInd_vcftools.sh: Input file name: $INFILE"
echo "##### splitVCFbyInd_vcftools.sh: Output file name: $OUTFILE"
echo "##### splitVCFbyInd_vcftools.sh: Vcftools log file name: $LOGFILE"
printf "\n"
echo "##### splitVCFbyInd_vcftools.sh: Additional command: $ADDITIONAL_COMMAND"
printf "\n"

[[ ! -d $OUTDIR ]] && echo "##### splitVCFbyInd_vcftools.sh: Creating output dir" && mkdir -p $OUTDIR 

## Individual selection command:
if [ ! -z $INDFILE ] && [ -e $INDFILE ]
then
	echo "##### splitVCFbyInd_vcftools.sh: Selecting individuals from file: $INDFILE"
	KEEP_COMMAND="--keep $INDFILE"
	echo "##### splitVCFbyInd_vcftools.sh: Keep command: $KEEP_COMMAND"
	printf "\n"
fi


################################################################################
##### RUN VCFTOOLS #####
################################################################################
echo -e "##### splitVCFbyInd_vcftools.sh: Running vcftools..."
$VCFTOOLS --gzvcf "$INFILE" $KEEP_COMMAND $ADDITIONAL_COMMAND --recode --recode-INFO-all --stdout 2>$LOGFILE | gzip > $OUTFILE

echo -e "\n\n##### splitVCFbyInd_vcftools.sh: Resulting vcf file after individual filtering:"
ls -lh $OUTFILE

echo -e "\n##### splitVCFbyInd_vcftools.sh: Showing contents of logfile:"
cat $LOGFILE

printf "\n"
echo "##### splitVCFbyInd_vcftools.sh: Done with script."
date
