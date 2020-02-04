#!/bin/bash
set -e
set -o pipefail
set -u

################################################################################
#### SET-UP ####
################################################################################
## Software and scripts:
VCFTOOLS=/dscrhome/rcw27/programs/vcftools/vcftools-master/bin/vcftools
module load Plink/1.90

## Command-line args:
FILE_ID=$1
VCF_DIR=$2
PLINK_DIR=$3
MAF=$4 # Minor allele frequency
LD_MAX=$5 # Give 1 if no LD pruning needed
SELECT_INDS=$6
INDFILE=$7 # Optional: File with inds to select from vcf
ID_OUT=$8 # Optional: ID for output file

## Process args:
[[ $ID_OUT == "NA" ]] && ID_OUT=$FILE_ID
ID_OUT=$FILE_ID
OUTFILE=$PLINK_DIR/$ID_OUT
VCF=$VCF_DIR/$FILE_ID.vcf.gz
[[ ! -d $PLINK_DIR ]] && echo "Creating dir $PLINK_DIR" && mkdir -p $PLINK_DIR

## Report:
printf "\n\n"
date
echo "##### vcf2plink.sh: Starting script."
echo "##### vcf2plink.sh: File ID: $FILE_ID"
echo "##### vcf2plink.sh: Minor allele frequency (MAF) cut-off: $MAF"
echo "##### vcf2plink.sh: LD_MAX: $LD_MAX"
echo "##### vcf2plink.sh: Plink dir: $PLINK_DIR"
echo "##### vcf2plink.sh: VCF file: $VCF"
echo "##### vcf2plink.sh: Output ID: $ID_OUT"
echo "##### vcf2plink.sh: Output file: $OUTFILE"
printf "\n"


################################################################################
#### PREP COMMAND TO LET VCFTOOLS SUBSET INDIVIDUALS (IF NEEDED) ####
################################################################################
## If $INDFILE exists (-e), then assign a "keep command"
## This command will be passed on to the vcftools program when it does the vcf->plink conversion
## If $KEEP_COMMAND is not assigned here, it can still be passed on to vcftools (see below),
## but since the variable is blank, nothing will be processed.  
echo "#######################################################################"
if [ $SELECT_INDS == TRUE -a $INDFILE != "NA" ]
then
	
	echo "#### vcf2plink.sh: Selecting individuals from file: $INDFILE"
	KEEP_COMMAND="--keep $INDFILE"
	
	echo -e "#### vcf2plink.sh: Keep command: $KEEP_COMMAND \n"
else
	echo "#### vcf2plink.sh: No ind-file specified - keeping all individuals."
	KEEP_COMMAND=""
fi
printf "\n\n"

################################################################################
#### CONVERT VCF TO PLINK ####
################################################################################
## Convert:
echo "##########################################################################"
echo "#### vcf2plink.sh: Converting vcf to plink..."
$VCFTOOLS --gzvcf $VCF $KEEP_COMMAND --plink --maf $MAF --out $OUTFILE
printf "\n\n"


################################################################################
#### EDIT PLINK FILES ####
################################################################################
## Replace chromosome notations:
echo "##########################################################################"
echo "#### vcf2plink.sh: Replacing chrom 0 by chrom 1 in PLINK map file..."
sed 's/^0/1/g' $OUTFILE.map > $OUTFILE.tmp.map
mv $OUTFILE.tmp.map $OUTFILE.map

## Create PLINK bed file:
echo -e "\n\n##### vcf2plink.sh: Creating binary PLINK files..."
plink --file $OUTFILE --make-bed --out $OUTFILE

echo -e "\n\n##### vcf2plink.sh: Creating PLINK files for adegenet..."
plink --file $OUTFILE --recodeA --out $OUTFILE.recodeA

## Perform LD pruning in PLINK, if $LD_MAX is not 1:
if [ $LD_MAX != 1 ]
then
	printf "\n\n"
	echo "##### vcf2plink.sh: LD pruning with PLINK..."
	mkdir $ID_OUT.$LD_MAX
	cd $ID_OUT.$LD_MAX
	plink --file ../$OUTFILE --indep-pairwise 50 5 $LD_MAX # calculate LD
	plink --file ../$OUTFILE --extract plink.prune.in --make-bed --out ../$PLINK_DIR/plink/$ID_OUT.LDpruned$LD_MAX # prune high LD sites
	plink --bfile ../$OUTFILE.LDpruned$LD_MAX --recode --out ../$OUTFILE.LDpruned$LD_MAX # convert binary "bed" files back to ped
	cd ..
	rm -r $ID_OUT.$LD_MAX
else
	echo "##### vcf2plink.sh: Skipping LD pruning..."
fi


################################################################################
#### REPORT ####
################################################################################
echo -e "\n\n###################################################################"
echo -e "#### vcf2plink.sh: Output files:"
ls -lh $OUTFILE*
printf "\n"

date
echo "#### vcf2plink.sh: Done with script."