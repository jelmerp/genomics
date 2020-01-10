#!/bin/bash
set -e
set -o pipefail
set -u

################################################################################
#### SET-UP ####
################################################################################
## Software and scripts:
SCR_GSTACKS=/datacommons/yoderlab/users/jelmer/scripts/geno/stacks/runGstacks.sh
SCR_POPSTACKS=/datacommons/yoderlab/users/jelmer/scripts/geno/stacks/runPopstacks.sh
SCR_FILTERVCF=/datacommons/yoderlab/users/jelmer/scripts/geno/filtervcf/filterVCF_FS6_stacks_pip.sh
SCR_STACKSFAPIP=/datacommons/yoderlab/users/jelmer/scripts/geno/stacks/stacksfa_pip.sh
chmod -R +x /datacommons/yoderlab/users/jelmer/scripts/*

## Command-line args:
GSTACKS_ID=$1
shift
POPSTACKS_ID=$1
shift
FASTA_ID=$1
shift
STACKSDIR_BASE=$1
shift
BAMDIR=$1
shift
BAMSUFFIX=$1
shift
POPMAP_GSTACKS=$1
shift
POPMAP_POPSTACKS=$1
shift
ADD_OPS_GSTACKS=$1
shift
ADD_OPS_POPSTACKS=$1
shift
REF=$1
shift
SCAF_FILE=$1
shift
CALLABLE_COMMAND="$1"
shift
MAXMISS_IND=$1
shift
MAXMISS_MEAN=$1
shift
MINDIST=$1
shift
MINLENGTH=$1
shift
LENGTH_QUANTILE=$1
shift
MAXINDMISS=$1
shift
NCORES=$1
shift

RUN_GSTACKS='TRUE'
RUN_POPSTACKS='TRUE'
FILTER_VCF='TRUE'
FILTER_FASTA='TRUE'

SKIP_INDPART_FASTA="-Z" # C: CALLABLELOCI / V: VCF-MASK / W: WGFASTA / M: MASKFASTA / D: FILTER_HIGHDEPTH / E: EXTRACT_LOCUSFASTA / S: LOCUSSTATS
SKIP_JOINTPART_FASTA="-Z" # F: FILTER_LOCI / E: EXTRACT_LOCI / M: MERGE_FASTA / S: SPLIT_FASTA
SKIP_PIP_FASTA="-Z" # I: INDPART / J: JOINTPART 

while getopts 'GPVFCI' flag; do
  case "${flag}" in
    G) RUN_GSTACKS='FALSE' ;;
    P) RUN_POPSTACKS='FALSE' ;;
    V) FILTER_VCF='FALSE' ;;
    F) FILTER_FASTA='FALSE' ;;
    C) SKIP_INDPART_FASTA="${SKIP_INDPART_FASTA}C" ;;
    I) SKIP_PIP_FASTA="${SKIP_PIP_FASTA}I" ;;
  esac
done

## Process args:
OUTDIR_GSTACKS=$STACKSDIR_BASE/$GSTACKS_ID/
OUTDIR_POPSTACKS=$OUTDIR_GSTACKS/$POPSTACKS_ID/
SET_ID_FULL=$GSTACKS_ID.$POPSTACKS_ID

## Report:
echo -e "\n#### stacks_pip.sh: Starting with script."
date
echo "#### stacks_pip.sh: gstacks ID: $GSTACKS_ID"
echo "#### stacks_pip.sh: popstacks ID: $POPSTACKS_ID"
echo "#### stacks_pip.sh: fasta ID: $FASTA_ID"
printf "\n"
echo "#### stacks_pip.sh: Stacks base dir: $STACKSDIR_BASE"
echo "#### stacks_pip.sh: Bam dir: $BAMDIR"
echo "#### stacks_pip.sh: Bam suffix: $BAMSUFFIX"
echo "#### stacks_pip.sh: Popmap for gstacks: $POPMAP_GSTACKS"
echo "#### stacks_pip.sh: Popmap for popstacks: $POPMAP_POPSTACKS"
echo "#### stacks_pip.sh: Additional options for gstacks: $ADD_OPS_GSTACKS"
echo "#### stacks_pip.sh: Additional options for popstacks: $ADD_OPS_POPSTACKS"
echo "#### stacks_pip.sh: Number of cores: $NCORES"
printf "\n"
echo "#### stacks_pip.sh: Output dir for gstacks: $OUTDIR_GSTACKS"
echo "#### stacks_pip.sh: Output dir for popstacks: $OUTDIR_POPSTACKS"
printf "\n"
#echo "#### stacks_pip.sh: Bed - exons: $BED_EXONS"
echo "#### stacks_pip.sh: Ref genome (for vcf & fasta filtering): $REF"
echo "#### stacks_pip.sh: Scaffold file (for vcf & fasta filtering): $SCAF_FILE"
printf "\n"
echo "#### stacks_pip.sh: Callable command (for fasta filtering): $CALLABLE_COMMAND"
echo "#### stacks_pip.sh: Maxmiss - ind (for fasta filtering): $MAXMISS_IND"
echo "#### stacks_pip.sh: Maxmiss - mean (for fasta filtering): $MAXMISS_MEAN"
echo "#### stacks_pip.sh: Min dist between loci (for fasta filtering): $MINDIST"
echo "#### stacks_pip.sh: Min locus length: $MINLENGTH"
echo "#### stacks_pip.sh: Length quantile: $LENGTH_QUANTILE"
echo "#### stacks_pip.sh: Max % missing inds per locus: $MAXINDMISS"
printf "\n"
echo "#### stacks_pip.sh: Run popstacks: $RUN_GSTACKS"
echo "#### stacks_pip.sh: Run gstacks: $RUN_POPSTACKS"
echo "#### stacks_pip.sh: Filter vcf: $FILTER_VCF"
echo "#### stacks_pip.sh: Filter fasta: $FILTER_FASTA"


################################################################################
#### RUN GSTACKS ####
################################################################################
echo -e "\n\n###################################################################"
if [ $RUN_GSTACKS == TRUE ]
then
	echo -e "#### stacks_pip.sh: Submitting gstacks job... \n"
	sbatch -p yoderlab,common,scavenger -N 1-1 --ntasks $NCORES --mem-per-cpu 4G \
		--job-name=stacks.$SET_ID_FULL -o slurm.gstacks.$GSTACKS_ID \
		$SCR_GSTACKS $OUTDIR_GSTACKS $BAMDIR $BAMSUFFIX $POPMAP_GSTACKS "$ADD_OPS_GSTACKS" $NCORES
else
	echo -e "#### stacks_pip.sh: SKIPPING gstacks step..."
fi

	
################################################################################
#### RUN POPSTACKS ####
################################################################################
echo -e "\n\n###################################################################"
if [ $RUN_POPSTACKS == TRUE ]
then
	echo -e "#### stacks_pip.sh: Submitting popstacks job... \n"
	
	sbatch -p yoderlab,common,scavenger -N 1-1 --ntasks $NCORES --mem-per-cpu 4G \
		--dependency=singleton --job-name=stacks.$SET_ID_FULL -o slurm.popstacks.$SET_ID_FULL \
		$SCR_POPSTACKS $SET_ID_FULL $OUTDIR_GSTACKS $OUTDIR_POPSTACKS $POPMAP_POPSTACKS "$ADD_OPS_POPSTACKS" $NCORES
			
else
	echo -e "#### stacks_pip.sh: SKIPPING popstacks step..."
fi


################################################################################
#### FILTER VCF ####
################################################################################
echo -e "\n\n###################################################################"
if [ $FILTER_VCF == TRUE ]
then
	echo -e "#### stacks_pip.sh: Submitting filter-vcf job... \n"
	
	## Process args:
	INPUT_NAME=$SET_ID_FULL.snps
	OUTPUT_NAME=$SET_ID_FULL
	IN_DIR=$OUTDIR_POPSTACKS/vcf/
	OUT_DIR=$OUTDIR_POPSTACKS/vcf/
	QC_DIR=$OUTDIR_POPSTACKS/vcf/qc/
	
	[[ ! -d $OUTDIR_POPSTACKS/vcf/qc/ ]] && mkdir -p $OUTDIR_POPSTACKS/vcf/qc/
	
	SCAF_FILE_VCF=$OUTDIR_POPSTACKS/vcf/scaf_file_vcf.txt
	tail -n +2 $SCAF_FILE | cut -f 1 > $SCAF_FILE_VCF
	
	## Hard-coded options:
	DP_MEAN=5
	MAC=3 # Mac-high
	INDFILE=notany
	INDSEL_ID=notany
	MEM=4
	JOBNAME=stacks.$SET_ID_FULL
	SKIP_COMMON_STEPS="-5678"
	SKIP_FINAL_STEPS="-1234"
	SKIP_PIP_FILTERVCF="-Z" ## CHANGE
	
	sbatch -p yoderlab,common,scavenger -N 1-1 --ntasks $NCORES --mem-per-cpu 4G \
		--dependency=singleton --job-name=stacks.$SET_ID_FULL -o slurm.filterstacksvcf.$SET_ID_FULL.pip \
		$SCR_FILTERVCF $INPUT_NAME $OUTPUT_NAME $IN_DIR $OUT_DIR $QC_DIR $BAMDIR $BAMSUFFIX \
		$REF $DP_MEAN $MAC $INDFILE $INDSEL_ID $SCAF_FILE_VCF \
		$MEM $JOBNAME $SKIP_COMMON_STEPS $SKIP_FINAL_STEPS $SKIP_PIP_FILTERVCF
else
	echo -e "#### stacks_pip.sh: SKIPPING filter-vcf step..."
fi


################################################################################
#### FILTER FASTA ####
################################################################################
echo -e "\n\n###################################################################"
if [ $FILTER_FASTA == TRUE ]
then
	[[ $FILTER_VCF == TRUE ]] && sleep 60
	echo -e "#### stacks_pip.sh: Submitting filter-fasta job... \n"
	
	## Process args:
	INDFILE=$POPMAP_POPSTACKS
	FASTA_RAW=$OUTDIR_POPSTACKS/fasta/$SET_ID_FULL.samples.fa
	VCF_RAW=$OUTDIR_POPSTACKS/vcf/$SET_ID_FULL.snps.vcf
	VCF_FILT=$OUTDIR_POPSTACKS/vcf/$SET_ID_FULL.skipMiss.mac1.vcf
	VCF_HIDEPTH=$OUTDIR_POPSTACKS/vcf/$SET_ID_FULL.commonsteps.TooHighDepth.vcf
	
	SET_ID_FASTA=$SET_ID_FULL.$FASTA_ID
	FASTADIR_BASE=$OUTDIR_POPSTACKS/$FASTA_ID
	
	echo -e "#### stacks_pip.sh: Skip in ind-part: $SKIP_INDPART_FASTA"
	echo -e "#### stacks_pip.sh: Skip in joint-part: $SKIP_JOINTPART_FASTA"
	echo -e "#### stacks_pip.sh: Skip in pip: $SKIP_PIP_FASTA \n"

	sbatch -p yoderlab,common,scavenger -N 1-1 --ntasks $NCORES --mem-per-cpu 4G \
		--dependency=singleton --job-name=stacks.$SET_ID_FULL -o slurm.stacksfa.pip.$SET_ID_FULL \
		$SCR_STACKSFAPIP $SET_ID_FASTA $INDFILE $FASTADIR_BASE $FASTA_RAW $VCF_RAW $VCF_FILT $VCF_HIDEPTH \
		$REF $SCAF_FILE $BAMDIR $BAMSUFFIX "$CALLABLE_COMMAND" $MAXMISS_IND $MAXMISS_MEAN $MINDIST $MINLENGTH $LENGTH_QUANTILE $MAXINDMISS \
		$SKIP_INDPART_FASTA $SKIP_JOINTPART_FASTA $SKIP_PIP_FASTA
	
else
	echo -e "#### stacks_pip.sh: SKIPPING filter-fasta step..."
fi


echo -e "\n#### stacks_pip.sh: Done with script. \n"
date