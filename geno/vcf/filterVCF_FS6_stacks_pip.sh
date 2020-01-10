#!/bin/bash
set -e
set -o pipefail
set -u

################################################################################
#### SET-UP ####
################################################################################
## Scripts:
SCRIPT_FILTER=/datacommons/yoderlab/users/jelmer/scripts/geno/filtervcf/filterVCF_FS6_stacks.sh
BGZIP=/datacommons/yoderlab/programs/htslib-1.6/bgzip
TABIX=/datacommons/yoderlab/programs/htslib-1.6/tabix

## Command-line arguments:
INPUT_NAME=$1
shift
OUTPUT_NAME=$1
shift
IN_DIR=$1
shift
OUT_DIR=$1
shift
QC_DIR=$1
shift
BAM_DIR=$1
shift
BAM_SUFFIX=$1
shift
REF=$1
shift
DP_MEAN=$1
shift
MAC=$1
shift
INDFILE=$1
shift
INDSEL_ID=$1
shift
SCAF_FILE=$1
shift
MEM=$1
shift
JOBNAME=$1
shift
SKIP_COMMON_STEPS=$1
shift
SKIP_FINAL_STEPS=$1
shift

COMMON_STEPS='TRUE'
MAC_LO='TRUE'
MAC_HI='TRUE'
SKIPMISS='TRUE'
KEEPALL='TRUE'

while getopts 'CLHMKZ' flag; do
  case "${flag}" in
    C) COMMON_STEPS='FALSE' ;;
    L) MAC_LO='FALSE' ;;
    H) MAC_HI='FALSE' ;;
    M) SKIPMISS='FALSE' ;;
    K) KEEPALL='FALSE' ;;
  esac
done

## Process:
[[ ! -d $QC_DIR/logfiles ]] && mkdir -p $QC_DIR/logfiles

## Report:
echo -e "\n\n###################################################################"
date
echo "#### filterVCF_FS6_stacks_pip.sh: Starting script."
echo "#### filterVCF_FS6_stacks_pip.sh: Input name: $INPUT_NAME"
echo "#### filterVCF_FS6_stacks_pip.sh: Output name: $OUTPUT_NAME"
printf "\n"
echo "#### filterVCF_FS6_stacks_pip.sh: Source dir: $IN_DIR"
echo "#### filterVCF_FS6_stacks_pip.sh: Target dir: $OUT_DIR"
echo "#### filterVCF_FS6_stacks_pip.sh: QC dir: $QC_DIR"
echo "#### filterVCF_FS6_stacks_pip.sh: Reference genome: $REF"
echo "#### filterVCF_FS6_stacks_pip.sh: mean-min DP: $DP_MEAN"
echo "#### filterVCF_FS6_stacks_pip.sh: MAC (for mac-hi filtering): $MAC"
printf "\n"
echo "#### filterVCF_FS6_stacks_pip.sh: Indiv selection ID: $INDSEL_ID"
echo "#### filterVCF_FS6_stacks_pip.sh: File with inds to keep: $INDFILE"
printf "\n"
echo "#### filterVCF_FS6_stacks_pip.sh: Steps-to-skip command for common filtering: $SKIP_COMMON_STEPS"
echo "#### filterVCF_FS6_stacks_pip.sh: Steps-to-skip command for final filtering: $SKIP_FINAL_STEPS"
printf "\n"
echo "#### filterVCF_FS6_stacks_pip.sh: Assigned memory: $MEM GB"
echo "#### filterVCF_FS6_stacks_pip.sh: Job name to give to slurm jobs: $JOBNAME"
printf "\n"
echo "#### filterVCF_FS6_stacks_pip.sh: Run common steps: $COMMON_STEPS"
echo "#### filterVCF_FS6_stacks_pip.sh: Run MAC_LO: $MAC_LO"
echo "#### filterVCF_FS6_stacks_pip.sh: Run MAC_HIGH: $MAC_HI"
echo "#### filterVCF_FS6_stacks_pip.sh: Run SKIPMISS: $SKIPMISS"
echo "#### filterVCF_FS6_stacks_pip.sh: Run KEEPALL: $KEEPALL"

[[ ! -d $OUT_DIR ]] && echo -e "\n#### filterVCF_FS6_stacks_pip.sh: Creating OUT_DIR $OUT_DIR" && mkdir -p $OUT_DIR

echo "#### filterVCF_FS6_stacks_pip.sh: Removing empty vcf files:"
find $IN_DIR -maxdepth 1 -mmin +5 -type f -size -100c
find $IN_DIR -maxdepth 1 -mmin +5 -type f -size -100c -exec rm -f {} \;

VCF_IN=$IN_DIR/$INPUT_NAME.vcf
if [ ! -s $VCF_IN.gz.tbi ]
then
	echo -e "\n#### filterVCF_FS6_stacks_pip.sh: .tbi file not found, bgzipping, tabixing, and unzipping input VCF..."
	[[ ! -s $VCF_IN.gz ]] && [[ -s $VCF_IN ]] && $BGZIP $VCF_IN
	$TABIX $VCF_IN.gz
	gunzip $VCF_IN.gz
fi


################################################################################
#### RUN WITHOUT FILTERING FOR MISSING DATA ####
################################################################################
if [ $SKIPMISS == TRUE ]
then
	echo -e "\n\n###############################################################"
	echo "#### filterVCF_FS6_stacks_pip.sh: Submitting script - not filtering for missing data..."
	
	FILTER_INDS_BY_MISSING=FALSE
	OUTPUT_NAME_SKIPMISS=$OUTPUT_NAME.skipMiss.mac1
	SKIP_SKIPMISS="-2678"
	echo "#### filterVCF_FS6_stacks_pip.sh: Input name: $INPUT_NAME"
	echo "#### filterVCF_FS6_stacks_pip.sh: Output name: $OUTPUT_NAME_SKIPMISS"
	echo "#### filterVCF_FS6_stacks_pip.sh: Steps to skip: $SKIP_SKIPMISS"
	
	SKIPMISS_SLURMFILE=$QC_DIR/logfiles/slurm.filterstacksvcf.$OUTPUT_NAME_SKIPMISS
	echo "#### filterVCF_FS6_stacks_pip.sh: Skipmiss slurm file: $SKIPMISS_SLURMFILE"
	
	sbatch --job-name=$JOBNAME --mem ${MEM}G -p common,yoderlab,scavenger -o $SKIPMISS_SLURMFILE \
		$SCRIPT_FILTER $INPUT_NAME $OUTPUT_NAME_SKIPMISS $IN_DIR $OUT_DIR $QC_DIR $BAM_DIR $BAM_SUFFIX \
		$REF $DP_MEAN $MAC_LO $FILTER_INDS_BY_MISSING $INDFILE $INDSEL_ID $SCAF_FILE $MEM $SKIP_SKIPMISS
fi


################################################################################
#### RUN WITHOUT REMOVING INDIVIDUALS ####
################################################################################
if [ $KEEPALL == TRUE ]
then
	echo -e "\n\n###############################################################"
	echo "#### filterVCF_FS6_stacks_pip.sh: Submitting script - keep all inds..."
	
	FILTER_INDS_BY_MISSING=FALSE
	OUTPUT_NAME_KEEPALL=$OUTPUT_NAME.keepall.mac1
	SKIP_KEEPALL=""
	echo "#### filterVCF_FS6_stacks_pip.sh: Input name: $INPUT_NAME"
	echo "#### filterVCF_FS6_stacks_pip.sh: Output name: $OUTPUT_NAME_KEEPALL"
	
	KEEPALL_SLURMFILE=$QC_DIR/logfiles/slurm.filterstacksvcf.$OUTPUT_NAME_KEEPALL
	echo "#### filterVCF_FS6_stacks_pip.sh: Keepall slurm file: $KEEPALL_SLURMFILE"
	
	sbatch --job-name=$JOBNAME --mem ${MEM}G -p common,yoderlab,scavenger -o $KEEPALL_SLURMFILE \
		$SCRIPT_FILTER $INPUT_NAME $OUTPUT_NAME_KEEPALL $IN_DIR $OUT_DIR $QC_DIR $BAM_DIR $BAM_SUFFIX \
		$REF $DP_MEAN $MAC_LO $FILTER_INDS_BY_MISSING $INDFILE $INDSEL_ID $SCAF_FILE $MEM $SKIP_KEEPALL
fi

echo -e "\n\n###################################################################"
echo "\n#### filterVCF_FS6_stacks_pip.sh: Setting FILTER_INDS_BY_MISSING for next steps..."
	if [ -s $INDFILE ]
	then
		FILTER_INDS_BY_MISSING=FALSE
	else
		FILTER_INDS_BY_MISSING=TRUE
	fi
echo "#### filterVCF_FS6_stacks_pip.sh: Filter inds by missing: $FILTER_INDS_BY_MISSING"


################################################################################
#### RUN FIRST STEPS - SAME FOR MACx AND MAC1 ####
################################################################################
if [ $COMMON_STEPS == TRUE ]
then
	echo -e "\n\n###############################################################"
	echo "#### filterVCF_FS6_stacks_pip.sh: Running common steps before mac..."
	
	OUTPUT_NAME_COMMON=$OUTPUT_NAME.commonsteps

	echo "#### filterVCF_FS6_stacks_pip.sh: Steps to skip: $SKIP_COMMON_STEPS"
	echo "#### filterVCF_FS6_stacks_pip.sh: Input name: $INPUT_NAME"
	echo "#### filterVCF_FS6_stacks_pip.sh: Output name: $OUTPUT_NAME_COMMON"
	
	JOB_COMMON_STEP=$(sbatch -p yoderlab,common,scavenger --mem ${MEM}G -o slurm.filterstacksvcf.$OUTPUT_NAME.commonsteps --job-name=$JOBNAME \
	$SCRIPT_FILTER $INPUT_NAME $OUTPUT_NAME_COMMON $IN_DIR $OUT_DIR $QC_DIR $BAM_DIR $BAM_SUFFIX \
	$REF $DP_MEAN $MAC $FILTER_INDS_BY_MISSING $INDFILE $INDSEL_ID $SCAF_FILE $MEM $SKIP_COMMON_STEPS)
	
	## Change pars for next steps:
	INPUT_NAME=$OUTPUT_NAME_COMMON
	JOB_COMMON_STEP=$(echo $JOB_COMMON_STEP | sed 's/Submitted batch job //')
	JOB_DEP="--dependency=afterok:$JOB_COMMON_STEP"
	VCF_IN=$IN_DIR/$INPUT_NAME.vcf.gz
else
	echo -e "#### filterVCF_FS6_stacks_pip.sh: SKIPPING common steps...\n"
	JOB_DEP=""
	VCF_IN=$IN_DIR/$INPUT_NAME.vcf
	[[ ! -e $VCF_IN ]] && [[ -e $VCF_IN.gz ]] && echo "#### filterVCF_FS6_stacks_pip.sh: unzipping input VCF for final steps" && gunzip -c $VCF_IN.gz > $VCF_IN
	echo "#### filterVCF_FS6_stacks_pip.sh: Input VCF for final steps:"
	ls -lh $VCF_IN
fi


################################################################################
#### RUN REST OF STEPS FOR MAC-1 ####
################################################################################
if [ $MAC_LO == TRUE ]
then
	echo -e "\n\n###############################################################"
	echo "#### filterVCF_FS6_stacks_pip.sh: Submitting script with mac1..."
	
	MAC_LO=1
	OUTPUT_NAME_MAC_LO=$OUTPUT_NAME.mac1
	SCAF_FILE=notany # No scaffold selection needed
	echo "#### filterVCF_FS6_stacks_pip.sh: Input name: $INPUT_NAME"
	echo "#### filterVCF_FS6_stacks_pip.sh: Output name: $OUTPUT_NAME_MAC_LO"
	echo "#### filterVCF_FS6_stacks_pip.sh: Job dependency: $JOB_DEP"
	
	sbatch --job-name=$JOBNAME $JOB_DEP \
		--mem ${MEM}G -p common,yoderlab,scavenger -o slurm.filterstacksvcf.$OUTPUT_NAME_MAC_LO \
		$SCRIPT_FILTER $INPUT_NAME $OUTPUT_NAME_MAC_LO $IN_DIR $OUT_DIR $QC_DIR $BAM_DIR $BAM_SUFFIX \
		$REF $DP_MEAN $MAC_LO $FILTER_INDS_BY_MISSING $INDFILE $INDSEL_ID $SCAF_FILE $MEM $SKIP_FINAL_STEPS
fi


################################################################################
#### RUN REST OF STEPS FOR MAC-HI ####
################################################################################
if [ $MAC_HI == TRUE ]
then
	echo -e "\n\n###############################################################"
	echo "#### filterVCF_FS6_stacks_pip.sh: filterVCF_FS6_stacks_pip.sh: Submitting script with mac-hi..."

	MAC_HI=$MAC
	OUTPUT_NAME_MAC_HI=$OUTPUT_NAME.mac$MAC
	SCAF_FILE=notany # No scaffold selection needed
	echo "#### filterVCF_FS6_stacks_pip.sh: Input name: $INPUT_NAME"
	echo "#### filterVCF_FS6_stacks_pip.sh: Output name: $OUTPUT_NAME_MAC_HI"
	echo "#### filterVCF_FS6_stacks_pip.sh: Job dependency: $JOB_DEP"
	
	sbatch --job-name=$JOBNAME $JOB_DEP \
		--mem ${MEM}G -p common,yoderlab,scavenger -o slurm.filterstacksvcf.$OUTPUT_NAME_MAC_HI \
		$SCRIPT_FILTER $INPUT_NAME $OUTPUT_NAME_MAC_HI $IN_DIR $OUT_DIR $QC_DIR $BAM_DIR $BAM_SUFFIX \
		$REF $DP_MEAN $MAC_HI $FILTER_INDS_BY_MISSING $INDFILE $INDSEL_ID $SCAF_FILE $MEM $SKIP_FINAL_STEPS
fi


echo -e "\n#### filterVCF_FS6_stacks_pip.sh: Done with script."
date