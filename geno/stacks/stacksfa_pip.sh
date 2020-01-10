#!/bin/bash
set -e
set -o pipefail
set -u

################################################################################
#### SET-UP ####
################################################################################
## Software & scripts:
SCR_STACKSFA_IND=/datacommons/yoderlab/users/jelmer/scripts/geno/stacks/stacksfa_ind.sh
SCR_STACKSFA_JOINT=/datacommons/yoderlab/users/jelmer/scripts/geno/stacks/stacksfa_joint.sh
module load R

## Args:
SET_ID_FASTA=$1
shift
INDFILE=$1
shift
FASTADIR_BASE=$1
shift
FASTA_RAW=$1
shift
VCF_RAW=$1
shift
VCF_FILT=$1
shift
VCF_HIDEPTH=$1
shift
BED_EXONS=$1
shift
REF=$1
shift
SCAF_FILE=$1
shift
BAMDIR=$1
shift
BAMSUFFIX=$1
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
SKIP_INDPART=$1
shift
SKIP_JOINTPART=$1
shift

DO_INDPART='TRUE'
DO_JOINTPART='TRUE'
while getopts 'IJZ' flag; do
  case "${flag}" in
  	I) DO_INDPART='FALSE' ;;  
  	J) DO_JOINTPART='FALSE' ;;
  esac
done

## Process args:
INDS=( $(cut -f 1 $INDFILE) ) #INDS=( mmyo006 mber013 mruf011 )

## Report:
echo -e "\n#####################################################################"
date
echo "#### stacksfa_pip.sh: Starting script."
echo "#### stacksfa_pip.sh: Full Set ID: $SET_ID_FASTA"
printf "\n"
echo "#### stacksfa_pip.sh: File with individuals: $INDFILE"
echo "#### stacksfa_pip.sh: Fasta dir - base: $FASTADIR_BASE"
echo "#### stacksfa_pip.sh: Raw Stacks fasta (input): $FASTA_RAW"
echo "#### stacksfa_pip.sh: VCF - raw: $VCF_RAW"
echo "#### stacksfa_pip.sh: VCF - filtered: $VCF_FILT"
echo "#### stacksfa_pip.sh: VCF - high-depth: $VCF_HIDEPTH"
echo "#### stacksfa_pip.sh: Bed - exons: $BED_EXONS"
echo "#### stacksfa_pip.sh: Ref genome: $REF"
echo "#### stacksfa_pip.sh: Scaffold file: $SCAF_FILE"
echo "#### stacksfa_pip.sh: Bam dir: $BAMDIR"
echo "#### stacksfa_pip.sh: Bam suffix: $BAMSUFFIX"
echo "#### stacksfa_pip.sh: Callable command: $CALLABLE_COMMAND"
echo "#### stacksfa_pip.sh: Max % missing per ind per locus: $MAXMISS_IND"
echo "#### stacksfa_pip.sh: Max % missing across inds per locus: $MAXMISS_MEAN"
echo "#### stacksfa_pip.sh: Min dist between loci: $MINDIST"
echo "#### stacksfa_pip.sh: Min locus length: $MINLENGTH"
echo "#### stacksfa_pip.sh: Length quantile: $LENGTH_QUANTILE"
echo "#### stacksfa_pip.sh: Max % missing inds per locus: $MAXINDMISS"
printf "\n"
echo "#### stacksfa_pip.sh: To skip in by-ind part: $SKIP_INDPART"
echo "#### stacksfa_pip.sh: To skip in joint part: $SKIP_JOINTPART"
printf "\n"
echo "#### stacksfa_pip.sh: Run by-ind part (TRUE/FALSE): $DO_INDPART"
echo "#### stacksfa_pip.sh: Run joint part (TRUE/FALSE): $DO_JOINTPART"
printf "\n"
echo "#### stacksfa_pip.sh: Individuals: ${INDS[@]}"

## Create dirs if needed:
[[ ! -d $FASTADIR_BASE/fasta/byInd/tmp ]] && mkdir -p $FASTADIR_BASE/fasta/byInd/tmp
[[ ! -d $FASTADIR_BASE/fasta/byLocus ]] && mkdir -p $FASTADIR_BASE/fasta/byLocus
[[ ! -d $FASTADIR_BASE/loci ]] && mkdir -p $FASTADIR_BASE/loci
[[ ! -d $FASTADIR_BASE/bed ]] && mkdir -p $FASTADIR_BASE/bed

## Unzip VCFs if needed:
[[ ! -e $VCF_RAW ]] && [[ -e $VCF_RAW.gz ]] && echo -e "\n#### Unzipping VCF_RAW...\n" && gunzip $VCF_RAW.gz
[[ ! -e $VCF_FILT ]] && [[ -e $VCF_FILT.gz ]] && echo -e "\n#### Unzipping VCF_FILT...\n" && gunzip $VCF_FILT.gz
[[ ! -e $VCF_HIDEPTH ]] && [[ -e $VCF_HIDEPTH.gz ]] && echo -e "\n#### Unzipping VCF_HIDEPTH...\n" && gunzip $VCF_HIDEPTH.gz

## Listing vcf files:
echo -e "#### Listing vcf files:"
ls -lh $VCF_RAW
printf "\n"
ls -lh $VCF_FILT
printf "\n"
ls -lh $VCF_HIDEPTH


################################################################################
#### RUN PER-IND PART ####
################################################################################
if [ $DO_INDPART == TRUE ]
then
	for IND in ${INDS[@]}
	do
		echo -e "\n#### stacksfa_pip.sh: Submitting stacksfa job for ind: $IND"
		
		BAM=$BAMDIR/${IND}$BAMSUFFIX
		
		sbatch -p yoderlab,common,scavenger --mem 8G -o slurm.stacksfa.ind.$SET_ID_FASTA.$IND \
			--job-name=stacksfa.$SET_ID_FASTA \
			$SCR_STACKSFA_IND $IND $FASTA_RAW $BAM $VCF_RAW $VCF_FILT $VCF_HIDEPTH $BED_EXONS \
			$REF $SCAF_FILE $FASTADIR_BASE "$CALLABLE_COMMAND" $SKIP_INDPART
	done
else
	echo -e "\n#### stacksfa_pip: SKIPPING by-ind part\n"
fi


################################################################################
#### RUN JOINT PART ####
################################################################################
if [ $DO_JOINTPART == TRUE ]
then
	echo -e "\n#### stacksfa_pip.sh: Submitting stacksfa job - joint part..."
	
	INDFILE_LIST=$FASTADIR_BASE/indlist.txt
	cut -f 1 $INDFILE > $INDFILE_LIST
	
	sbatch -p yoderlab,common,scavenger --mem 8G -o slurm.stacksfa.joint.$SET_ID_FASTA \
		--job-name=stacksfa.$SET_ID_FASTA --dependency=singleton \
		$SCR_STACKSFA_JOINT $SET_ID_FASTA $INDFILE_LIST $FASTADIR_BASE \
		$MAXMISS_IND $MAXMISS_MEAN $MINDIST $MINLENGTH $LENGTH_QUANTILE $MAXINDMISS $SKIP_JOINTPART
	
else
	echo -e "\n#### stacksfa_pip: SKIPPING joint part\n"
fi


echo -e "\n#### stacksfa_pip: Done with script.\n"