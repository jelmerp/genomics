#!/bin/bash
set -e
set -o pipefail
set -u

################################################################################
#### SET-UP ####
################################################################################
## Scripts and software:
SCRIPT_VCF2TREEMIX=/datacommons/yoderlab/users/jelmer/scripts/genomics/conversion/vcf2treemix.sh
SCRIPT_TREEMIX=/datacommons/yoderlab/users/jelmer/scripts/genomics/treemix/treemix_run.sh

## Command-line args:
FILE_ID=$1 # VCF file ID (File should be $VCF_DIR/$FILE_ID.vcf.gz
VCF_DIR=$2 # VCF dir 
PREP_INPUT=$3 # TRUE/FALSE, whether or not to create the input files from a VCF
MINMIG=$4 # Minimum nr of migration edges
MAXMIG=$5 # Maximum nr of migration edges
ROOT=$6 # Root taxon
TREEMIX_DIR=$7 # Treemix base dir
INDS_METADATA=$8 # Metadata file
GROUP_BY_COLUMN=$9 # Column in metadata file to group individuals by (e.g. the column with the species name)

## Define Treemix input and output dirs:
TREEMIX_INDIR=$TREEMIX_DIR/input
TREEMIX_OUTDIR=$TREEMIX_DIR/output

## Make dirs if needed:
[[ ! -d $TREEMIX_INDIR ]] && echo -e "#### treemix_pip.sh: Creating dir ${TREEMIX_INDIR}\n" && mkdir -p $TREEMIX_INDIR
[[ ! -d $TREEMIX_OUTDIR ]] && echo -e "#### treemix_pip.sh: Creating dir ${TREEMIX_OUTDIR}\n" && mkdir -p $TREEMIX_OUTDIR

## Report:
echo -e "\n#####################################################################"
date
echo "#### treemix_pip.sh: Starting with script."
echo "#### treemix_pip.sh: File ID: $FILE_ID"
echo "#### treemix_pip.sh: VCF dir: $VCF_DIR"
echo "#### treemix_pip.sh: Prep input: $PREP_INPUT"
echo "#### treemix_pip.sh: Min nr of mig events: $MINMIG"
echo "#### treemix_pip.sh: Max nr of mig events: $MAXMIG"
echo "#### treemix_pip.sh: Root: $ROOT"
echo "#### treemix_pip.sh: Treemix input dir: $TREEMIX_INDIR"
echo "#### treemix_pip.sh: Treemix output dir: $TREEMIX_OUTDIR"
printf "\n"
echo "#### treemix_pip.sh: Metadata file: $INDS_METADATA"
echo "#### treemix_pip.sh: Column in metadata file to group individuals by: $GROUP_BY_COLUMN"
printf "\n"


################################################################################
#### PREPARE TREEMIX INPUT ####
################################################################################
if [ $PREP_INPUT == "TRUE" ]
then
	echo -e "\n#### treemix_pip.sh: Preparing Treemix input - calling vcf2treemix.sh...\n"
	$SCRIPT_VCF2TREEMIX $FILE_ID $VCF_DIR $TREEMIX_DIR $INDS_METADATA $GROUP_BY_COLUMN
else
	echo -e "\n#### treemix_pip.sh: Skipping input preparation...\n"
fi


################################################################################
#### RUN TREEMIX ####
################################################################################
echo -e "\n#### treemix_pip.sh: Running Treemix...\n"

K=1000 # Set blocksize to 1000

for NMIG in $(seq $MINMIG $MAXMIG)
do
	sbatch -p yoderlab,common,scavenger --mem 50G -o slurm.treemix_run.$FILE_ID.$NMIG.txt \
	$SCRIPT_TREEMIX $FILE_ID $NMIG $K $ROOT $TREEMIX_INDIR $TREEMIX_OUTDIR
done


## Report:
echo -e "#### treemix_pip.sh: Done with script.\n"
date
echo "##########################################################################"
