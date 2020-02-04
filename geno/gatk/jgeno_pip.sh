#!/bin/bash
set -e
set -o pipefail
set -u

################################################################################
#### SET-UP ####
################################################################################
## Scripts:
SCR_GENO=/datacommons/yoderlab/users/jelmer/scripts/genomics/geno/gatk/gatk2_jointgeno.sh
SCR_MERGEVCFS=/datacommons/yoderlab/users/jelmer/scripts/genomics/geno/gatk/gatk3_mergevcfs.sh
SCR_FILTER=/datacommons/yoderlab/users/jelmer/scripts/genomics/geno/vcf/filterVCF_FS6_pip.sh

## Command-line args:
FILE_ID=$1
shift
SCAFFOLD_FILE=$1
shift
GVCF_DIR=$1
shift
VCF_DIR=$1
shift
QC_DIR=$1
shift
REF=$1
shift
ADD_COMMANDS=$1
shift
MEM_JOB=$1
shift
MEM_GATK=$1
shift
NCORES=$1
shift
SKIP_GENO=$1
shift
DP_MEAN=$1
shift

count=0
while [ "$*" != "" ]
  do INDS[$count]=$1
  shift
  count=`expr $count + 1`
done

## Process args:
VCF_DIR_MAIN=$VCF_DIR/intermed/
VCF_DIR_FINAL=$VCF_DIR/final/
VCF_DIR_SCAFFOLD=$VCF_DIR/intermed_byscaffold
SCAFFOLDLIST_DIR=$VCF_DIR/scaffoldlists

## Report:
date
echo "#### jgeno_pip.sh: Starting script."
echo "#### jgeno_pip.sh: Slurm node name: $SLURMD_NODENAME"
echo "#### jgeno_pip.sh: File ID: $FILE_ID"
echo "#### jgeno_pip.sh: Scaffold file: $SCAFFOLD_FILE"
echo "#### jgeno_pip.sh: Gvcf dir: $GVCF_DIR"
echo "#### jgeno_pip.sh: Vcf dir - by scaffold: $VCF_DIR_SCAFFOLD"
echo "#### jgeno_pip.sh: Vcf dir - main: $VCF_DIR_MAIN"
echo "#### jgeno_pip.sh: Vcf dir - final: $VCF_DIR_FINAL"
echo "#### jgeno_pip.sh: QC dir: $QC_DIR"
echo "#### jgeno_pip.sh: Ref: $REF"
echo "#### jgeno_pip.sh: Additonal GATK commands: $ADD_COMMANDS"
echo "#### jgeno_pip.sh: Min Mean DP: $DP_MEAN"
printf "\n"
echo "#### jgeno_pip.sh: Memory allotted to jobs: $MEM_JOB"
echo "#### jgeno_pip.sh: Memory for GATK: $MEM_GATK"
echo "#### jgeno_pip.sh: Nr of cores: $NCORES"
echo "#### jgeno_pip.sh: Skip genotyping: $SKIP_GENO"
printf "\n"
echo "#### jgeno_pip.sh: Individuals: ${INDS[@]}"

## Make dirs if needed:
[[ ! -d $VCF_DIR_SCAFFOLD ]] && mkdir -p $VCF_DIR_SCAFFOLD
[[ ! -d $VCF_DIR_FINAL ]] && mkdir -p $VCF_DIR_FINAL
[[ ! -d $SCAFFOLDLIST_DIR ]] && mkdir -p $SCAFFOLDLIST_DIR


################################################################################
#### JOINT GENOTYPING OF GVCF FILES - BY SCAFFOLD ####
################################################################################
echo -e "\n\n###################################################################"
if [ $SKIP_GENO == TRUE ]
then
	echo -e "#### jgeno_pip.sh: Skipping genotyping...\n"
else
	echo -e "#### jgeno_pip.sh: Calling joint genotyping script per (set of) scaffold(s)...\n"
	
	echo "#### jgeno_pip.sh: Checking for presence of VCFs ..."
	for IND in ${INDS[@]}
	do
		echo -e "\n#### jgeno_pip.sh: Ind: $IND"
		ls -lh $GVCF_DIR/*$IND*vcf
	done

	MULTI_IND=TRUE
	LASTLINE=$(cat $SCAFFOLD_FILE | wc -l)
	echo -e "\n#### jgeno_pip.sh: Nr of scaffolds: $LASTLINE \n"
	
	for SCAFFOLD_NR in $(seq 1 1 $LASTLINE)
	do
		INTERVAL_ID=$(cat $SCAFFOLD_FILE | head -n $SCAFFOLD_NR | tail -n 1)
		INTERVAL_FILE=$SCAFFOLDLIST_DIR/$INTERVAL_ID.list
		cat $SCAFFOLD_FILE | head -n $SCAFFOLD_NR | tail -n 1 > $INTERVAL_FILE
		
		echo "#### jgeno_pip.sh: Interval ID (scaffold nr): $INTERVAL_ID"
		echo "#### jgeno_pip.sh: Scaffold list:"
		cat $INTERVAL_FILE
				
		sbatch --mem ${MEM_JOB}G -N 1-1 --ntasks $NCORES --job-name=jgeno.pip.$FILE_ID \
		-p yoderlab,common,scavenger -o slurm.jgeno5a.$FILE_ID.$INTERVAL_ID \
		$SCR_GENO $FILE_ID $MULTI_IND $INTERVAL_FILE $INTERVAL_ID \
		$GVCF_DIR $VCF_DIR_SCAFFOLD $REF "$ADD_COMMANDS" $MEM_GATK $NCORES ${INDS[@]}
		
		printf "\n"
	done
	
fi


################################################################################
#### MERGE BY-SCAFFOLD VCFS ####
################################################################################
echo -e "\n\n###################################################################"
echo -e "#### jgeno_pip.sh: Calling script to merge scaffolds...\n"

sbatch --mem ${MEM_JOB}G --job-name=jgeno.pip.$FILE_ID --dependency=singleton \
	-p yoderlab,common -o slurm.jgeno5b_mergevcf.$FILE_ID \
	$SCR_MERGEVCFS $FILE_ID $VCF_DIR_SCAFFOLD $VCF_DIR_MAIN


################################################################################
#### FILTER VCF FILES ####
################################################################################
echo -e "\n\n###################################################################"
echo -e "#### jgeno_pip.sh: Calling vcf filtering script...\n"

INPUT_NAME=$FILE_ID.rawvariants
OUTPUT_NAME=$FILE_ID
MAC=3
FILTER_INDS_BY_MISSING=TRUE
SELECT_INDS_BY_FILE=FALSE
SAMPLE_ID_FILE=notany
INDSEL_ID=notany
MEM=4
JOBNAME=$FILE_ID
SKIP_COMMON_STEPS="-456789tew"
SKIP_FINAL_STEPS="-123"
SKIP_IN_PIP=""

sbatch --mem ${MEM_JOB}G --job-name=jgeno.pip.$FILE_ID --dependency=singleton \
	-p yoderlab,common -o slurm.filtervcf.pip.$OUTPUT_NAME \
	$SCR_FILTER $INPUT_NAME $OUTPUT_NAME $VCF_DIR_MAIN $VCF_DIR_FINAL $QC_DIR $REF \
	$DP_MEAN $MAC $FILTER_INDS_BY_MISSING $SELECT_INDS_BY_FILE $SAMPLE_ID_FILE \
	$MEM_GATK $JOBNAME $INDSEL_ID $SKIP_COMMON_STEPS $SKIP_FINAL_STEPS $SKIP_IN_PIP


################################################################################
#### HOUSEKEEPING ####
################################################################################
echo -e "\n#####################################################################"
echo "#### jgeno_pip.sh: Done with script."
date
