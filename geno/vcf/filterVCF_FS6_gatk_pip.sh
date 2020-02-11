#!/bin/bash
set -e
set -o pipefail
set -u

################################################################################
#### SET-UP ####
################################################################################

## Scripts:
SCRIPT_FILTER=/datacommons/yoderlab/users/jelmer/scripts/genomics/geno/vcf/filterVCF_FS6.sh

## Command-line arguments:
INPUT_NAME=$1
shift
OUTPUT_NAME=$1
shift
VCF_DIR_MAIN=$1
shift
VCF_DIR_FINAL=$1
shift
QC_DIR=$1
shift
REF=$1
shift
DP_MEAN=$1
shift
MAC=$1
shift
FILTER_INDS_BY_MISSING=$1
shift
SELECT_INDS_BY_FILE=$1
shift
INDFILE=$1
shift
MEM=$1
shift
JOBNAME=$1
shift
INDSEL_ID=$1
shift
SKIP_COMMON_STEPS=$1
shift
SKIP_FINAL_STEPS=$1
shift

COMMON_STEPS='TRUE'
MAC_LO='TRUE'
MAC_HI='TRUE'
SKIPMISS='TRUE'

while getopts 'CLHM' flag; do
  case "${flag}" in
    C) COMMON_STEPS='FALSE' ;;
    L) MAC_LO='FALSE' ;;
    H) MAC_HI='FALSE' ;;
    M) SKIPMISS='FALSE' ;;
    *) error "Unexpected option ${flag}" ;;
  esac
done

## Process:
[[ $SELECT_INDS_BY_FILE == TRUE ]] && OUTPUT_NAME=$OUTPUT_NAME.$INDSEL_ID
[[ ! -d $QC_DIR/logfiles ]] && mkdir -p $QC_DIR/logfiles

## Report:
echo -e "\n\n\n#################################################################"
date
echo "#### filterVCF_FS6_pip.sh: Starting script."
printf "\n"
echo "#### filterVCF_FS6_pip.sh: Input name: $INPUT_NAME"
echo "#### filterVCF_FS6_pip.sh: Output name: $OUTPUT_NAME"
printf "\n"
echo "#### filterVCF_FS6_pip.sh: Source dir (VCF_DIR_MAIN): $VCF_DIR_MAIN"
echo "#### filterVCF_FS6_pip.sh: Target dir (VCF_DIR_FINAL): $VCF_DIR_FINAL"
echo "#### filterVCF_FS6_pip.sh: QC dir: $QC_DIR"
echo "#### filterVCF_FS6_pip.sh: Reference genome: $REF"
echo "#### filterVCF_FS6_pip.sh: mean-min DP: $DP_MEAN"
echo "#### filterVCF_FS6_pip.sh: MAC: $MAC"
printf "\n"
echo "#### filterVCF_FS6_pip.sh: Filter inds by missing: $FILTER_INDS_BY_MISSING"
echo "#### filterVCF_FS6_pip.sh: Select inds by file: $SELECT_INDS_BY_FILE"
echo "#### filterVCF_FS6_pip.sh: Indiv selection ID: $INDSEL_ID"
echo "#### filterVCF_FS6_pip.sh: File with inds to keep: $INDFILE"
printf "\n"
echo "#### filterVCF_FS6_pip.sh: Steps-to-skip command for common filtering: $SKIP_COMMON_STEPS"
echo "#### filterVCF_FS6_pip.sh: Steps-to-skip command for final filtering: $SKIP_FINAL_STEPS"
printf "\n"
echo "#### filterVCF_FS6_pip.sh: Assigned memory: $MEM GB"
echo "#### filterVCF_FS6_pip.sh: Job name to give to slurm jobs: $JOBNAME"
printf "\n"
echo "#### filterVCF_FS6_pip.sh: Run common steps: $COMMON_STEPS"
echo "#### filterVCF_FS6_pip.sh: Run MAC_LO: $MAC_LO"
echo "#### filterVCF_FS6_pip.sh: Run MAC_HIGH: $MAC_HI"
echo "#### filterVCF_FS6_pip.sh: Run SKIPMISS: $SKIPMISS"
printf "\n"

[[ ! -d $VCF_DIR_FINAL ]] && echo "#### filterVCF_FS6_pip.sh: Creating VCF_DIR_FINAL $VCF_DIR_FINAL" && mkdir -p $VCF_DIR_FINAL

echo "#### filterVCF_FS6_pip.sh: Removing empty vcf files:"
find $VCF_DIR_MAIN -maxdepth 1 -mmin +5 -type f -size -500c
find $VCF_DIR_MAIN -maxdepth 1 -mmin +5 -type f -size -500c -exec rm -f {} \;
printf "\n"


################################################################################
#### RUN FIRST STEPS - SAME FOR MACx AND MAC1 #####
################################################################################
if [ $COMMON_STEPS == TRUE ]
then
	echo -e "\n\n###############################################################"
	echo "#### filterVCF_FS6_pip.sh: Running common steps before mac: step 0 and/or step 1 and/or step 2 and/or step 3..."
	
	echo "#### filterVCF_FS6_pip.sh: Steps to skip: $SKIP_COMMON_STEPS"
	echo "#### filterVCF_FS6_pip.sh: Input name: $INPUT_NAME"
	echo "#### filterVCF_FS6_pip.sh: Output name: $OUTPUT_NAME_COMMON"
	
	JOB_COMMON_STEP=$(sbatch -p yoderlab,common,scavenger --mem ${MEM}G -o slurm.filterVCF.$OUTPUT_NAME.commonsteps \
	$SCRIPT_FILTER $INPUT_NAME $OUTPUT_NAME $VCF_DIR_MAIN $VCF_DIR_FINAL $QC_DIR $MEM $REF \
	$INDFILE $DP_MEAN $MAC $FILTER_INDS_BY_MISSING $SELECT_INDS_BY_FILE $INDSEL_ID $SKIP_COMMON_STEPS)
	
	## Change pars for next steps:
	INPUT_NAME=$OUTPUT_NAME
	SELECT_INDS_BY_FILE=FALSE
	
	JOB_COMMON_STEP=$(echo $JOB_COMMON_STEP | sed 's/Submitted batch job //')
	JOB_DEP="--dependency=afterok:$JOB_COMMON_STEP"
	
	VCF_IN=$VCF_DIR_MAIN/$INPUT_NAME.vcf.gz
else
	echo -e "#### filterVCF_FS6_pip.sh: Skipping common steps...\n"
	JOB_DEP=""
	VCF_IN=$VCF_DIR_MAIN/$INPUT_NAME.vcf
	[[ ! -e $VCF_IN ]] && [[ -e $VCF_IN.gz ]] && echo "#### filterVCF_FS6_pip.sh: unzipping input VCF for final steps" && gunzip -c $VCF_IN.gz > $VCF_IN
	echo "#### filterVCF_FS6_pip.sh: Input VCF for final steps:"
	ls -lh $VCF_IN
fi


################################################################################
#### RUN REST OF STEPS FOR MAC1 #####
################################################################################
if [ $MAC_LO == TRUE ]
then
	echo -e "\n\n###############################################################"
	echo "#### filterVCF_FS6_pip.sh: Submitting script with mac1..."
	
	MAC_LO=1
	OUTPUT_NAME_MAC_LO=$OUTPUT_NAME.mac1
	SKIP_MAC_LO=${SKIP_FINAL_STEPS}4
	
	echo "#### filterVCF_FS6_pip.sh: Input name: $INPUT_NAME"
	echo "#### filterVCF_FS6_pip.sh: Output name: $OUTPUT_NAME_MAC_LO"
	echo "#### filterVCF_FS6_pip.sh: Steps to skip: $SKIP_MAC_LO"
	echo "#### filterVCF_FS6_pip.sh: Job dependency: $JOB_DEP"
	
	sbatch --job-name=$JOBNAME $JOB_DEP \
		--mem ${MEM}G -p common,yoderlab,scavenger -o slurm.filterVCF.$OUTPUT_NAME_MAC_LO \
		$SCRIPT_FILTER $INPUT_NAME $OUTPUT_NAME_MAC_LO $VCF_DIR_MAIN $VCF_DIR_FINAL $QC_DIR $MEM $REF \
		$INDFILE $DP_MEAN $MAC_LO $FILTER_INDS_BY_MISSING $SELECT_INDS_BY_FILE $INDSEL_ID "$SKIP_MAC_LO"
fi


################################################################################
#### RUN REST OF STEPS FOR MAC x #####
################################################################################
if [ $MAC_HI == TRUE ]
then
	sleep 120
	
	echo -e "\n\n###############################################################"
	echo "#### filterVCF_FS6_pip.sh: filterVCF_FS6_pip.sh: Submitting script with mac-x..."

	OUTPUT_NAME_MAC_HI=$OUTPUT_NAME.mac$MAC
	SKIP_MAC_HI=$SKIP_FINAL_STEPS
	
	echo "#### filterVCF_FS6_pip.sh: Input name: $INPUT_NAME"
	echo "#### filterVCF_FS6_pip.sh: Output name: $OUTPUT_NAME_MAC_HI"
	echo "#### filterVCF_FS6_pip.sh: Steps to skip: $SKIP_MAC_HI"
	echo "#### filterVCF_FS6_pip.sh: Job dependency: $JOB_DEP"
	
	sbatch --job-name=$JOBNAME $JOB_DEP \
		--mem ${MEM}G -p common,yoderlab,scavenger -o slurm.filterVCF.$OUTPUT_NAME_MAC_HI \
		$SCRIPT_FILTER $INPUT_NAME $OUTPUT_NAME_MAC_HI $VCF_DIR_MAIN $VCF_DIR_FINAL $QC_DIR $MEM $REF \
		$INDFILE $DP_MEAN $MAC $FILTER_INDS_BY_MISSING $SELECT_INDS_BY_FILE $INDSEL_ID "$SKIP_MAC_HI"
fi


################################################################################
#### RUN WITHOUT FILTERING FOR MISSING DATA #####
################################################################################
if [ $SKIPMISS == TRUE ]
then
	echo -e "\n\n###############################################################"
	echo "#### filterVCF_FS6_pip.sh: Submitting script not filtering for missing data..."
	
	SELECT_INDS_BY_FILE=FALSE
	OUTPUT_NAME_SKIPMISS=$OUTPUT_NAME.skipMiss.mac1
	SKIP_SKIPMISS=${SKIP_FINAL_STEPS}45tw
	
	echo "#### filterVCF_FS6_pip.sh: Input name: $INPUT_NAME"
	echo "#### filterVCF_FS6_pip.sh: Output name: $OUTPUT_NAME_SKIPMISS"
	echo "#### filterVCF_FS6_pip.sh: Steps to skip: $SKIP_SKIPMISS"
	
	SKIPMISS_SLURMFILE=$QC_DIR/logfiles/slurm.filterVCF.$OUTPUT_NAME_SKIPMISS
	echo "#### filterVCF_FS6_pip.sh: Skipmiss slurm file: $SKIPMISS_SLURMFILE"
	
	sbatch --job-name=$JOBNAME $JOB_DEP --mem ${MEM}G -p common,yoderlab,scavenger -o $SKIPMISS_SLURMFILE \
		$SCRIPT_FILTER $INPUT_NAME $OUTPUT_NAME_SKIPMISS $VCF_DIR_MAIN $VCF_DIR_MAIN $QC_DIR $MEM $REF \
		$INDFILE $DP_MEAN $MAC $FILTER_INDS_BY_MISSING $SELECT_INDS_BY_FILE $INDSEL_ID "$SKIP_SKIPMISS"
fi


################################################################################
printf "\n"
echo "#### filterVCF_FS6_pip.sh: Done with script."
date