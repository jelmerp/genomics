#!/bin/bash
set -e
set -o pipefail
set -u

################################################################################
#### SET-UP ####
################################################################################
## Software and scripts:
SCRIPT_POPFILE=/datacommons/yoderlab/users/jelmer/scripts/genomics/treemix/treemix_makePopfile.R
SCRIPT_VCF2TREEMIX=/datacommons/yoderlab/users/jelmer/scripts/genomics/conversion/vcf2treemix.py
PYTHON3=/datacommons/yoderlab/programs/Python-3.6.3/python
BCFTOOLS=/datacommons/yoderlab/programs/bcftools-1.6/bcftools
module load R/3.4.4

## Command-line arguments:
FILE_ID=$1
VCF_DIR=$2
TREEMIX_DIR=$3
INDS_METADATA=$4
GROUP_BY_COLUMN=$5

## Process:
VCF=$VCF_DIR/$FILE_ID.vcf
TREEMIX_INFILE=$TREEMIX_DIR/input/$FILE_ID.tmix
INDFILE=$TREEMIX_DIR/popfiles/$FILE_ID.inds.txt
POPFILE=$TREEMIX_DIR/popfiles/$FILE_ID.popfile.txt

## Report:
printf "\n"
echo "##########################################################################"
date
echo "#### vcf2treemix.sh: Starting with script."
echo "#### vcf2treemix.sh: File ID: $FILE_ID"
echo "#### vcf2treemix.sh: VCF dir: $VCF"
echo "#### vcf2treemix.sh: Treemix base dir: $TREEMIX_DIR"
echo "#### vcf2treemix.sh: Metadata file: $INDS_METADATA"
echo "#### vcf2treemix.sh: Column in metadata file to group individuals by: $GROUP_BY_COLUMN"
printf "\n"
echo "#### vcf2treemix.sh: VCF file: $VCF"
echo "#### vcf2treemix.sh: Indfile (to create): $INDFILE"
echo "#### vcf2treemix.sh: Popfile (to create): $POPFILE"
echo "#### vcf2treemix.sh: Treemix input file (to create): $TREEMIX_INFILE"
printf "\n"

## Check for files:
[[ -e "$VCF" ]] && echo -e "#### vcf2treemix.sh: Unzipped VCF found.\n"
[[ ! -e "$VCF" ]] && echo -e "#### vcf2treemix.sh: Unzipped VCF not found, unzipping...\n" && gunzip -c $VCF.gz > $VCF

echo "#### vcf2treemix.sh: Listing VCF file:"
ls -lh $VCF
printf "\n"

## Create dirs if needed:
[[ ! -d $TREEMIX_DIR/input ]] && echo -e "vcf2treemix.sh: Creating dir $TREEMIX_DIR/input\n" && mkdir -p $TREEMIX_DIR/input
[[ ! -d $TREEMIX_DIR/popfiles ]] && echo -e "vcf2treemix.sh: Creating dir $TREEMIX_DIR/popfiles\n" && mkdir -p $TREEMIX_DIR/popfiles


################################################################################
#### CREATE TREEMIX POPFILE ####
################################################################################
echo "#### vcf2treemix.sh: Creating Treemix popfile..."
bcftools query -l $VCF > $INDFILE
$SCRIPT_POPFILE $INDFILE $INDS_METADATA $POPFILE $GROUP_BY_COLUMN
printf "\n\n"

echo "#### vcf2treemix.sh: Showing contents of Treemix popfile:"
cat $POPFILE
printf "\n"


################################################################################
#### CONVERT VCF TO TREEMIX FORMAT ####
################################################################################
echo -e "\n#### vcf2treemix.sh: Converting vcf to Treemix format..."
$PYTHON3 $SCRIPT_VCF2TREEMIX -vcf $VCF -pop $POPFILE && \
	
## Move and zip treemix input:
echo -e "\n#### vcf2treemix.sh: Moving and zipping treemix input..."
mv $VCF_DIR/$FILE_ID*tmix $TREEMIX_INFILE
gzip -f $TREEMIX_INFILE # -f: force, even if file already exists


################################################################################
#### REPORT ####
################################################################################
printf "\n"
echo "#### vcf2treemix.sh: Listing treemix input file:"
ls -lh $TREEMIX_INFILE.gz

printf "\n"
date
echo "#### vcf2treemix.sh: Done with script."
echo "##########################################################################"