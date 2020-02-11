#!/bin/bash
set -e
set -o pipefail
set -u

################################################################################
#### SET-UP #####
################################################################################
## Software:
BCFTOOLS=/datacommons/yoderlab/programs/bcftools-1.10.2/bcftools
VCF2PLINK_SCRIPT=/datacommons/yoderlab/users/jelmer/scripts/genomics/conversion/vcf2plink.sh
SPLITVCF_SCRIPT=/datacommons/yoderlab/users/jelmer/scripts/genomics/conversion/splitVCF_byIndv.sh
MAKE_INDFILE_SCRIPT=/datacommons/yoderlab/users/jelmer/scripts/genomics/admixtools/admixtools_makeIndfile.R
module load R/3.4.4

## Command-line args:
FILE_ID=$1
shift
VCF_DIR=$1
shift
PLINK_DIR=$1
shift
VCF2PLINK=$1
shift
CREATE_INDFILE=$1
shift
SUBSET_INDFILE=$1
shift
INDFILE=$1
shift
POPFILE=$1
shift
PARFILE=$1
shift
ATOOLS_MODE=$1
shift
INDS_METADATA=$1
shift
ID_COLUMN=$1
shift
GROUPBY=$1
shift

## Process:
VCF=$VCF_DIR/$FILE_ID.vcf.gz # input file
PEDFILE=$PLINK_DIR/$FILE_ID.ped 
MAPFILE=$PLINK_DIR/$FILE_ID.map

## Report:
echo -e "\n#####################################################################"
date
echo "#### admixtools_prepinput.sh: Starting with script."
echo "#### admixtools_prepinput.sh: File ID: $FILE_ID"
echo "#### admixtools_prepinput.sh: VCF dir: $VCF_DIR"
echo "#### admixtools_prepinput.sh: PLINK dir: $PLINK_DIR"
echo "#### admixtools_prepinput.sh: Create indfile (TRUE/FALSE): $CREATE_INDFILE"
echo "#### admixtools_prepinput.sh: Subset indfile (TRUE/FALSE): $SUBSET_INDFILE"
printf "\n"
echo "#### admixtools_prepinput.sh: VCF file (input): $VCF"
echo "#### admixtools_prepinput.sh: Popfile (input): $POPFILE"
echo "#### admixtools_prepinput.sh: Indfile (output): $INDFILE"
echo "#### admixtools_prepinput.sh: Parfile (output): $PARFILE"
echo "#### admixtools_prepinput.sh: PED file (output): $PEDFILE"
echo "#### admixtools_prepinput.sh: MAP file (output): $MAPFILE"
printf "\n"
echo "#### admixtools_prepinput.sh: Admixtools mode: $ATOOLS_MODE"
printf "\n"
echo "#### admixtools_prepinput.sh: Inds metadata (optional): $INDS_METADATA"
echo "#### admixtools_prepinput.sh: ID column: $ID_COLUMN"
echo "#### admixtools_prepinput.sh: Group-by column: $GROUPBY"
printf "\n"


################################################################################
#### CONVERT VCF TO PLINK FORMAT ####
################################################################################
if [ $VCF2PLINK == TRUE ]
then
	echo "#### admixtools_prepinput.sh: Converting vcf to plink..."
	MAF=0
	LD_MAX=1
	SELECT_INDS=FALSE
	INDFILE_PLINK="NA"
	ID_OUT="NA"
	$VCF2PLINK_SCRIPT $FILE_ID $VCF_DIR $PLINK_DIR $MAF $LD_MAX $SELECT_INDS $INDFILE_PLINK $ID_OUT
	printf "\n\n"
else
	echo -e "\n#### admixtools_prepinput.sh: Not converting vcf to plink.\n"
fi


################################################################################
#### CREATE EIGENSTAT INDFILE ####
################################################################################
if [ $CREATE_INDFILE == TRUE ]
then
	echo "#### admixtools_prepinput.sh: Creating eigenstat indfile..."
	echo "#### admixtools_prepinput.sh: Inds metadata: $INDS_METADATA"
	echo "#### admixtools_prepinput.sh: Indfile: $INDFILE"
	
	INDLIST=indlist.$FILE_ID.tmp
	$BCFTOOLS query -l $VCF > $INDLIST
	
	Rscript $MAKE_INDFILE_SCRIPT $INDLIST $INDS_METADATA $INDFILE $ID_COLUMN $GROUPBY
	
	rm $INDLIST
else
	echo -e "\n#### admixtools_prepinput.sh: NOT CREATING EIGENSTAT INDFILE.\n"
fi


################################################################################
#### SUBSET INDFILE ####
################################################################################
## (INDFILE CAN ONLY LIST INDS THAT ARE ACTUALLY PRESENT IN THE VCF FILE)

if [ $SUBSET_INDFILE == TRUE ]
then
	echo -e "\n\n#### admixtools_prepinput.sh: Subsetting Eigenstat indfile..."
	NLINE_IN=$(cat $INDFILE | wc -l)
	
	INDS=( $($BCFTOOLS query -l $VCF) )
	> $INDFILE.tmp
	for IND in ${INDS[@]}; do grep $IND $INDFILE >> $INDFILE.tmp; done
	sort -u $INDFILE.tmp > $INDFILE
	rm $INDFILE.tmp
	
	NLINE_OUT=$(cat $INDFILE | wc -l)
	echo -e "#### admixtools_prepinput.sh: Nr of lines before subsetting: $NLINE_IN"
	echo -e "#### admixtools_prepinput.sh: Nr of lines after subsetting: $NLINE_OUT \n"
	[[ $NLINE_OUT == 0 ]] && echo -e "\n\n\n\n#### admixtools_prepinput.sh: ERROR: NO LINES LEFT IN INDFILE!\n\n\n\n"
fi


################################################################################
#### CREATE EIGENSTAT PARFILES #####
################################################################################
echo -e "\n#####################################################################"
echo "#### admixtools_prepinput.sh: Creating Eigenstat parfile..."

if [ $ATOOLS_MODE == "D" ]
then
	echo -e "\n#### admixtools_prepinput.sh: Creating parfile for D-mode...\n"
		
	printf "genotypename:\t$PEDFILE\n" > $PARFILE
	printf "snpname:\t$MAPFILE\n" >> $PARFILE
	printf "indivname:\t$INDFILE\n" >> $PARFILE
	printf "popfilename:\t$POPFILE\n" >> $PARFILE
	printf "printsd:\tYES\n" >> $PARFILE
	
	echo "#### admixtools_prepinput.sh: Parfile $PARFILE:"
	cat $PARFILE
	printf "\n"
	
elif [ $ATOOLS_MODE == F4 ]
then
	echo -e "\n#### Creating parfile for F4-mode...\n"
		
	#cp $PARFILE_DMODE $PARFILE_FMODE ### EDIT!
	printf "f4mode:\tYES\n" >> $PARFILE_FMODE
	
	echo -e "\n#### admixtools_prepinput.sh: Parfile $PARFILE:"
	cat $PARFILE
	printf "\n"
	
elif [ $ATOOLS_MODE == F3 ]
then
	echo "\n#### admixtools_prepinput.sh: Creating parfile for f3-mode...\n"
	
	printf "genotypename:\t$PEDFILE\n" > $PARFILE
	printf "snpname:\t$MAPFILE\n" >> $PARFILE
	printf "indivname:\t$INDFILE\n" >> $PARFILE
	printf "popfilename:\t$POPFILE\n" >> $PARFILE
	#printf "printsd:\tYES\n" >> $PARFILE
	
	echo "#### admixtools_prepinput.sh: Parfile $PARFILE:"
	cat $PARFILE
	printf "\n"
	
elif [ $ATOOLS_MODE == F4RATIO ]
then
	echo -e "\n#### admixtools_prepinput.sh: Creating parfile for f4-ratio-mode...\n"
	echo "#### admixtools_prepinput.sh: Creating parfile $PARFILE..."
	
	printf "genotypename:\t$PEDFILE\n" > $PARFILE
	printf "snpname:\t$MAPFILE\n" >> $PARFILE
	printf "indivname:\t$INDFILE\n" >> $PARFILE
	printf "popfilename:\t$POPFILE\n" >> $PARFILE
	printf "printsd:\tYES\n" >> $PARFILE
	
	echo "#### admixtools_prepinput.sh: Parfile $PARFILE:"
	cat $PARFILE
	printf "\n"
	
else
	echo -e "\n\n\n#### admixtools_prepinput.sh: ATOOLS_MODE variable $ATOOLS_MODE does not match any mode..."
	echo -e "#### admixtools_prepinput.sh: NOT CREATING PARFILE...\n\n\n"
fi


################################################################################
date
echo -e "\n#### admixtools_prepinput.sh: Done with script.\n"