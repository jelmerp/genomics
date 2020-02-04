#!/bin/bash
set -e
set -o pipefail
set -u

################################################################################
#### SET-UP ####
################################################################################
## Scripts:
SCRIPT_VCF2PLINK=/datacommons/yoderlab/users/jelmer/scripts/genomics/conversion/vcf2plink.sh
SCRIPT_ADMIXTURE_RUN=/datacommons/yoderlab/users/jelmer/scripts/genomics/admixture/admixture_run.sh

## Positional args:
FILE_ID=$1
VCF_DIR=$2
PLINK_DIR=$3
OUTDIR=$4
MAF=$5
LD_MAX=$6
NCORES=$7
INDFILE=$8

## Report:
date
echo "#### admixture_pip.sh: Starting script."
echo "#### admixture_pip.sh: File ID: $FILE_ID"
echo "#### admixture_pip.sh: Vcf dir: $VCF_DIR"
echo "#### admixture_pip.sh: Plink dir: $PLINK_DIR"
echo "#### admixture_pip.sh: Output dir: $OUTDIR"
echo "#### admixture_pip.sh: MAF: $MAF"
echo "#### admixture_pip.sh: Max LD: $LD_MAX"
echo "#### admixture_pip.sh: Number of cores: $NCORES"
echo "#### admixture_pip.sh: File with individuals to subset (optional): $INDFILE"
printf "\n"

[[ ! -d $PLINK_DIR ]] && echo -e "#### admixture_pip.sh: Creating dir PLINK_DIR\n" && mkdir -p $PLINK_DIR # If absent, create dir for PLINK-files
[[ ! -d $OUTDIR ]] && echo -e "#### admixture_pip.sh: Creating dir OUTDIR\n" && mkdir -p $OUTDIR # If absent, create dir for ADMIXTURE output


################################################################################
#### CONVERT VCF TO PLINK ####
################################################################################
echo -e "\n#####################################################################"
echo "#### admixture_pip.sh: Submitting VCF2PLINK script..."
$SCRIPT_VCF2PLINK $FILE_ID $VCF_DIR $PLINK_DIR $MAF $LD_MAX $INDFILE


################################################################################
#### INDIVIDUALS ####
################################################################################
echo -e "\n\n###################################################################"
echo "#### admixture_pip.sh: Creating individuals-file:"
INDIV_FILE=$OUTDIR/$FILE_ID.indivs.txt

PEDFILE=$PLINK_DIR/$FILE_ID.ped
echo "#### admixture_pip.sh: Ped file: $PEDFILE"

cut -f1 $PEDFILE > $INDIV_FILE

echo "#### admixture_run.sh: Listing indiv file:"
ls -lh $INDIV_FILE

echo "#### admixture_run.sh: Showing indiv file:"
cat $INDIV_FILE



################################################################################
#### SUBMIT JOBS TO RUN ADMIXTURE FOR EACH K ####
################################################################################
echo -e "\n\n###################################################################"
echo "#### admixture_pip.sh: Running admixture..."
printf "\n"

for K in 1 2 3 4 5 6 7 8 9
do
	echo "#### admixture_pip.sh: Value of K: $K"
	sbatch -p common,yoderlab,scavenger --mem 8G --ntasks $NCORES -o slurm.admixture.run.$FILE_ID.K$K \
	$SCRIPT_ADMIXTURE_RUN $FILE_ID $PLINK_DIR $OUTDIR $K $NCORES
	printf "\n"
done

## Report:
echo -e "\n\n###################################################################"
echo "#### admixture_pip.sh: Done with script."
date