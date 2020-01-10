#!/bin/bash
set -e
set -o pipefail
set -u

################################################################################
#### SET-UP ####
################################################################################
## Software:
BCFTOOLS=/datacommons/yoderlab/programs/bcftools-1.6/bcftools
TABIX=/datacommons/yoderlab/programs/htslib-1.6/tabix
BGZIP=/datacommons/yoderlab/programs/htslib-1.6/bgzip
VCFTOOLS=/dscrhome/rcw27/programs/vcftools/vcftools-master/bin/vcftools

## Command-line args: 
FILE_ID=$1 # File ID (basename) for VCF
VCF_DIR=$2 # Dir with VCF
QC_DIR=$3 # Dir for QC outpur
RUN_BCF=$4 # FALSE/TRUE
RUN_BCF_BY_IND=$5 # FALSE/TRUE
RUN_VCF_SITESTATS=$6 # FALSE/TRUE

## Process:
VCF=$VCF_DIR/$FILE_ID.vcf.gz

## Report:
date
echo "#### qc_vcf.sh: Starting script."
echo "#### qc_vcf.sh: Indiv ID: $FILE_ID"
echo "#### qc_vcf.sh: VCF dir: $VCF_DIR"
echo "#### qc_vcf.sh: Input VCF file: $VCF"
echo "#### qc_vcf.sh: Base QC dir: $QC_DIR"
echo "#### qc_vcf.sh: Run bcftoolsStats: $RUN_BCF"
echo "#### qc_vcf.sh: Run bcftoolsStats by ind: $RUN_BCF_BY_IND"
echo -e "#### qc_vcf.sh: Run vcftools sitestats modules: $RUN_VCF_SITESTATS \n"

## Index VCF:
if [ ! -e $VCF.tbi ]
then
	echo "#### qc_vcf.sh: No .tbi file found..."
	
	if [ -e $VCF_DIR/$FILE_ID.vcf ]
	then
		echo "#### qc_vcf.sh: Rezipping vcf using bgzip..."
		$BGZIP -f $VCF_DIR/$FILE_ID.vcf
	elif [ -e $VCF ]
	then
		echo "#### qc_vcf.sh: Rezipping vcf using bgzip..."
		gunzip -f $VCF
		$BGZIP -f $VCF_DIR/$FILE_ID.vcf	
	else
		echo -e "\n\n#### qc_vcf.sh: VCF FILE NOT FOUND!!\n\n"
		exit 1
	fi
	
	echo "#### qc_vcf.sh: Indexing vcf with tabix..." 
	$TABIX -f -p vcf $VCF
	printf "\n"
else
	echo "#### qc_vcf.sh: .tbi file found."
fi

## List input VCF:
echo -e "#### qc_vcf.sh: Listing input VCF file:"
ls -lh $VCF

## Create directories:
[[ ! -d $QC_DIR ]] && echo "#### qc_vcf.sh: Creating QC_dir $QC_DIR..." && mkdir -p $QC_DIR
[[ ! -d $QC_DIR/bcftools ]] && echo "#### qc_vcf.sh: Creating QC_dir $QC_DIR/bcftools ..." && mkdir -p $QC_DIR/bcftools
[[ ! -d $QC_DIR/vcftools ]] && echo "#### qc_vcf.sh: Creating QC_dir $QC_DIR/vcftools ..." && mkdir -p $QC_DIR/vcftools

## Defaults if "RUN_BCF" and "RUN_BCF_BY_IND" are not assigned:
[[ -z $RUN_BCF ]] && RUN_BCF=TRUE
[[ -z $RUN_BCF_BY_IND ]] && RUN_BCF_BY_IND=FALSE
[[ -z $RUN_VCF_SITESTATS ]] && RUN_VCF_SITESTATS=TRUE


################################################################################
#### RUN BCFTOOLS-STATS ON ENTIRE VCF ####
################################################################################
if [ $RUN_BCF == TRUE ]
then
	echo -e "\n###############################################################"
	echo "#### qc_vcf.sh: Running bcftools-stats on entire vcf..."
	
	OUTFILE=$QC_DIR/bcftools/$FILE_ID.bcftools.txt
	
	$BCFTOOLS stats --samples - $VCF > $OUTFILE
	
	echo -e "\n#### qc_vcf.sh: bcftools-stats output file: $OUTFILE"
	ls -lh $OUTFILE
fi


################################################################################
#### RUN BCFTOOLS-STATS SAMPLE-BY-SAMPLE ####
################################################################################
IDs_SINGLE=( $($BCFTOOLS query -l $VCF) )

if [ $RUN_BCF_BY_IND == TRUE ] && [ ${#IDs_SINGLE[@]} -gt 1 ]
then
	echo -e "\n#################################################################"
	echo "#### qc_vcf.sh: Running bcftools-stats sample-by-sample..."
	echo "#### qc_vcf.sh: Number of samples in vcf: ${#IDs_SINGLE[@]}"
	printf "\n"
	
	for ID_SINGLE in ${IDs_SINGLE[@]}
	do
		echo "#### qc_vcf.sh: ID: $ID_SINGLE"
		OUTFILE_IND=$QC_DIR/bcftools/$FILE_ID.$ID_SINGLE.bcftools.txt
		$BCFTOOLS stats --samples $ID_SINGLE $VCF > $OUTFILE_IND
	done
fi


################################################################################
#### VCFTOOLS: DEPTH AND MISSINGNESS STATS #####
################################################################################
echo -e "\n#### qc_vcf.sh: Running vcftools to get missing-indv stats..."
$VCFTOOLS --gzvcf $VCF --missing-indv --stdout > $QC_DIR/vcftools/$FILE_ID.imiss

echo -e "\n#### qc_vcf.sh: Running vcftools to get depth stats..."
$VCFTOOLS --gzvcf $VCF --depth --stdout > $QC_DIR/vcftools/$FILE_ID.idepth

if [ $RUN_VCF_SITESTATS == TRUE ]
then
	echo -e "\n#### qc_vcf.sh: Running vcftools to get missing-site stats..."
	$VCFTOOLS --gzvcf $VCF --missing-site --stdout > $QC_DIR/vcftools/$FILE_ID.smiss
	
	echo -e "\n#### qc_vcf.sh: Running vcftools to get site-mean-depth stats..."
	$VCFTOOLS --gzvcf $VCF --site-mean-depth --stdout > $QC_DIR/vcftools/$FILE_ID.sdepth
fi


################################################################################
#### REPORT #####
################################################################################
echo "#### qc_vcf.sh: QC Output files:"
ls -lh $QC_DIR/vcftools/$FILE_ID*
[[ $RUN_BCF == TRUE ]] && ls -lh $QC_DIR/bcftools/$FILE_ID*

echo -e "\n#### idepth file:"
cat $QC_DIR/vcftools/$FILE_ID.idepth

echo -e "\n#### qc_vcf.sh: Done with script."
date
