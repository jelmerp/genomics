#!/bin/bash
set -e
set -o pipefail
set -u

################################################################################
#### SET-UP ####
################################################################################
## Scripts:
SCRIPT_FILTERVCF=/datacommons/yoderlab/users/jelmer/scripts/genomics/radseq/filtering/filterVCF_FS6_pip.sh
SCRIPT_MASKBED=/datacommons/yoderlab/users/jelmer/scripts/genomics/radseq/vcf2loci/vcf2loci0_maskbed.sh
SCRIPT_VCF2FULLFA1=/datacommons/yoderlab/users/jelmer/scripts/genomics/radseq/vcf2loci/vcf2loci1.sh
SCRIPT_VCF2FULLFA2=/datacommons/yoderlab/users/jelmer/scripts/genomics/radseq/vcf2loci/vcf2loci2.sh
BCFTOOLS=/datacommons/yoderlab/programs/bcftools-1.6/bcftools
VCFTOOLS=/dscrhome/rcw27/programs/vcftools/vcftools-master/bin/vcftools

## Positional args:
ID_VCF_ORG=$1 # Original VCF ID
shift
ID_SUBSET=$1 # Individual subset ID
shift
ID_VCF2FASTA=$1
shift
SELECT_INDS_BY_FILE=$1
shift
FILTER_INDS_BY_MISSING=$1
shift
CALLABLE_COMMAND="$1"
shift
FILE_INDS=$1
shift
FILE_LD=$1
shift
REF=$1
shift
SUFFIX_RAWVCF=$1
shift
SUFFIX_BAM=$1
shift
MINMEANDP_VCF=$1
shift
DIR_VCF_MAIN=$1
shift
DIR_VCF_FINAL=$1
shift
DIR_VCFSTATS=$1
shift
DIR_BAM=$1
shift
DIR_FASTA=$1
shift
DIR_BED=$1
shift
MEM=$1
shift
TESTRUN=$1
shift
SKIP_COMMON_STEPS=$1
shift
SKIP_IN_1="$1"
shift
SKIP_IN_2="$1"
shift

## Additional args:
SKIP_FILTER_VCF='FALSE'
SKIP_BEDMASK='FALSE'
SKIP_VCF2FULLFASTA1='FALSE'
SKIP_VCF2FULLFASTA2='FALSE'

while getopts 'FB12' flag; do
  case "${flag}" in
  	F) SKIP_FILTER_VCF='TRUE' ;;  
  	B) SKIP_BEDMASK='TRUE' ;;
  	1) SKIP_VCF2FULLFASTA1='TRUE' ;;
    2) SKIP_VCF2FULLFASTA2='TRUE' ;;
    *) error "Unexpected option ${flag}" ;;
  esac
done

## Other variables:
VCF_MAC=1

## Process args:
[[ $SELECT_INDS_BY_FILE == "TRUE" ]] && INDS=( $(cat $FILE_INDS) )

ID_VCF=$ID_VCF_ORG.$ID_SUBSET
ID_FULL=$ID_VCF.$ID_VCF2FASTA

VCF_ALTREF=$DIR_VCF_MAIN/$ID_VCF.indselOnly.vcf # Nearly raw vcf used for producing AltRef fasta file # or VCF_ALTREF=$DIR_VCF_MAIN/$ID_VCF.rawSNPs.vcf, see below
VCF_FILTERED_MASK=$DIR_VCF_MAIN/$ID_VCF.skipMiss.mac1.vcf # Partially filtered vcf used for masking bad sites
VCF_FILTERED_INTERSECT=$DIR_VCF_FINAL/$ID_VCF.mac$VCF_MAC.FS7.vcf # Final vcf used to select loci with only high-qual SNPs
VCF_HIGHDEPTH=$DIR_VCF_MAIN/$ID_VCF.mac1.TooHighDepth.vcf # Vcf with sites with excessive depth

DIR_INDFASTA=$DIR_FASTA/$ID_FULL.byInd

BED_VCF_ALTREF=$DIR_BED/$ID_VCF.unfilteredVcf.bed
BED_VCF_FILTERED_MASK=$DIR_BED/$ID_VCF.filteredVcf.bed
BED_REMOVED_SITES=$DIR_BED/$ID_VCF.SitesInVcfRemovedByFilters.bed

SKIP_IN_VCFFILTER="-H"

JOBNAME=vcf2fasta.$ID_FULL

[[ ! -d $DIR_BED ]] && echo "#### vcf2loci_pip.sh: Creating dir $DIR_BED" && mkdir -p $DIR_BED
[[ ! -d $DIR_INDFASTA ]] && echo "#### vcf2loci_pip.sh: Creating dir $DIR_INDFASTA" && mkdir -p $DIR_INDFASTA
[[ ! -d $DIR_VCF_FINAL ]] && echo "#### vcf2loci_pip.sh: Creating dir $DIR_VCF_FINAL" && mkdir -p $DIR_VCF_FINAL

## Report:
echo -e "\n\n###################################################################"
date
echo "#### vcf2loci_pip.sh: Starting script."
echo "#### vcf2loci_pip.sh: Testrun (TRUE/FALSE): $TESTRUN"
printf "\n"
echo "#### vcf2loci_pip.sh: Original VCF ID: $ID_VCF_ORG"
echo "#### vcf2loci_pip.sh: Subset ID: $ID_SUBSET"
echo "#### vcf2loci_pip.sh: Vcf2fullfasta ID: $ID_VCF2FASTA"
echo "#### vcf2loci_pip.sh: Subset VCF ID: $ID_VCF"
echo "#### vcf2loci_pip.sh: Full ID: $ID_FULL"
printf "\n"
echo "#### vcf2loci_pip.sh: Select inds by file: $SELECT_INDS_BY_FILE"
echo "#### vcf2loci_pip.sh: Filter inds by missing: $FILTER_INDS_BY_MISSING"
printf "\n"
echo "#### vcf2loci_pip.sh: Rawfile suffix for VCF: $SUFFIX_RAWVCF"
echo "#### vcf2loci_pip.sh: Bamfile suffix: $SUFFIX_BAM"
echo "#### vcf2loci_pip.sh: Min-mean-DP for VCF filtering: $MINMEANDP_VCF"
echo "#### vcf2loci_pip.sh: CallableLoci command: $CALLABLE_COMMAND"
printf "\n"
echo "#### vcf2loci_pip.sh: Reference genome file: $REF"
echo "#### vcf2loci_pip.sh: File with individual IDs (indfile): $FILE_INDS"
echo "#### vcf2loci_pip.sh: Vcf dir - main: $DIR_VCF_MAIN"
echo "#### vcf2loci_pip.sh: Vcf dir - final: $DIR_VCF_FINAL"
echo "#### vcf2loci_pip.sh: Vcf QC dir: $DIR_VCFSTATS"
echo "#### vcf2loci_pip.sh: Bam dir: $DIR_BAM"
echo "#### vcf2loci_pip.sh: Fasta dir: $DIR_FASTA"
echo "#### vcf2loci_pip.sh: CreateLoci dir: $DIR_BED"
printf "\n"
echo "#### vcf2loci_pip.sh: Skip in filtering VCF - common steps: $SKIP_COMMON_STEPS"
echo "#### vcf2loci_pip.sh: Skip in filtering VCF - pip scripts: $SKIP_IN_VCFFILTER"
printf "\n"
echo "#### vcf2loci_pip.sh: Skip making mask bedfile: $SKIP_BEDMASK"
echo "#### vcf2loci_pip.sh: Skip vcf2fullFasta1: $SKIP_VCF2FULLFASTA1"
echo "#### vcf2loci_pip.sh: Skip vcf2fullFasta2: $SKIP_VCF2FULLFASTA2"
printf "\n"
echo "#### vcf2loci_pip.sh: Skip within vcf2fullFasta1.sh: $SKIP_IN_1"
echo "#### vcf2loci_pip.sh: Skip within vcf2fullFasta2.sh: $SKIP_IN_2"
printf "\n"
echo "#### vcf2loci_pip.sh: FILES TO CREATE:"
echo "#### vcf2loci_pip.sh: Bedfile for unfiltered vcf: $BED_VCF_ALTREF"
echo "#### vcf2loci_pip.sh: Bedfile for filtered vcf: $BED_VCF_FILTERED_MASK"
echo "#### vcf2loci_pip.sh: Bedfile with removed sites: $BED_REMOVED_SITES"
echo "#### vcf2loci_pip.sh: Vcf - for producing altref fasta: $VCF_ALTREF"
echo "#### vcf2loci_pip.sh: Vcf - filtered - for intersecting loci: $VCF_FILTERED_INTERSECT"
echo "#### vcf2loci_pip.sh: Vcf - filtered - for masking SNPs: $VCF_FILTERED_MASK"
echo "#### vcf2loci_pip.sh: Vcf - loci with excessive depth: $VCF_HIGHDEPTH"
printf "\n"
echo "#### vcf2loci_pip.sh: Job name to give to slurm jobs: $JOBNAME"
echo "#### vcf2loci_pip.sh: Memory: $MEM"

echo "#### vcf2loci_pip.sh: Removing empty vcf files:"
find $VCF_DIR_MAIN -maxdepth 1 -mmin +1 -type f -size -500c
find $VCF_DIR_MAIN -maxdepth 1 -mmin +1 -type f -size -500c -exec rm -f {} \;
printf "\n"


################################################################################
#### FILTER_VCF ####
################################################################################
if [ $SKIP_FILTER_VCF == FALSE ]
then
	echo -e "\n\n###############################################################"
	echo "#### vcf2loci_pip.sh: Running script for vcf filtering..."
	
	SKIP_FINAL_STEPS="-123w"
	INPUT_NAME=$ID_VCF_ORG.$SUFFIX_RAWVCF
	OUTPUT_NAME=$ID_VCF
	INDSEL_ID=$ID_SUBSET
	
	$SCRIPT_FILTERVCF $INPUT_NAME $OUTPUT_NAME $DIR_VCF_MAIN $DIR_VCF_FINAL $DIR_VCFSTATS $REF \
		$MINMEANDP_VCF $VCF_MAC $FILTER_INDS_BY_MISSING $SELECT_INDS_BY_FILE $FILE_INDS \
		$MEM $JOBNAME $INDSEL_ID $SKIP_COMMON_STEPS $SKIP_FINAL_STEPS $SKIP_IN_VCFFILTER
else
	echo -e "#### vcf2loci_pip.sh: Skipping vcf-filtering step.\n"
fi


################################################################################
#### CHECKING FOR PRESENCE OF VCF FILES ####
################################################################################
echo -e "\n\n###################################################################"
echo -e "\n#### vcf2loci_pip.sh: Checking for presence of VCF files:"

## Altref VCF:
[[ ! -e $VCF_ALTREF* ]] && echo -e "#### vcf2loci_pip.sh: Changing VCF_ALTREF..." && VCF_ALTREF=$DIR_VCF_MAIN/$ID_VCF_ORG*$ID_SUBSET*$SUFFIX_RAWVCF*vcf
[[ ! -e $VCF_ALTREF* ]] && echo -e "#### vcf2loci_pip.sh: Changing VCF_ALTREF..." && VCF_ALTREF=$DIR_VCF_MAIN/$ID_VCF_ORG*$SUFFIX_RAWVCF*$ID_SUBSET*vcf 
[[ ! -e $VCF_ALTREF ]] && [[ -e $VCF_ALTREF.gz ]] && echo -e "#### vcf2loci_pip.sh: Unzipping VCF_ALTREF...\n" && gunzip $VCF_ALTREF.gz

if [ ! -e $VCF_ALTREF ]
then
	VCF_IN=$DIR_VCF_MAIN/$ID_VCF_ORG.$SUFFIX_RAWVCF.vcf
	[[ -e $VCF_IN ]] && [[ ! -e $VCF_IN.gz ]] && "#### vcf2loci_pip.sh: gzipping VCF..." && gzip $VCF_IN 
	VCF_ALTREF=$DIR_VCF_MAIN/$ID_VCF_ORG.$SUFFIX_RAWVCF.$ID_SUBSET.indselOnly.vcf
	KEEP_COMMAND="--keep $FILE_INDS"
	$VCFTOOLS --gzvcf $VCF_IN.gz --recode --recode-INFO-all $KEEP_COMMAND --stdout > $VCF_ALTREF
fi
echo -e "\n#### vcf2loci_pip.sh: VCF_ALTREF:"; ls -lh $VCF_ALTREF

## Other VCFs:
[[ ! -e $VCF_FILTERED_MASK ]] && [[ -e $VCF_FILTERED_MASK.gz ]] && echo -e "\n#### vcf2loci_pip.sh: Unzipping VCF_FILTERED_MASK...\n" && gunzip $VCF_FILTERED_MASK.gz
[[ ! -e $VCF_FILTERED_INTERSECT ]] && [[ -e $VCF_FILTERED_INTERSECT.gz ]] && echo -e "\n#### vcf2loci_pip.sh: Unzipping VCF_FILTERED_INTERSECT...\n" && gunzip $VCF_FILTERED_INTERSECT.gz
[[ ! -e $VCF_HIGHDEPTH ]] && [[ -e $VCF_HIGHDEPTH.gz ]] && echo -e "\n#### vcf2loci_pip.sh: Unzipping VCF_HIGHDEPTH...\n" && gunzip $VCF_HIGHDEPTH.gz

echo -e "\n#### vcf2loci_pip.sh: VCF_FILTERED_MASK:"
ls -lh $VCF_FILTERED_MASK
echo -e "\n#### vcf2loci_pip.sh: VCF_FILTERED_INTERSECT:"
ls -lh $VCF_FILTERED_INTERSECT
echo -e "\n#### vcf2loci_pip.sh: VCF_HIGHDEPTH:"
ls -lh $VCF_HIGHDEPTH

## Get individuals present in VCF:
INDS=( $($BCFTOOLS query -l $VCF_FILTERED_INTERSECT) )
echo -e "\n\n#### vcf2loci_pip.sh: Individuals: ${INDS[@]} \n"


################################################################################
#### GET BEDFILE WITH SITES REMOVED BY VCF FILTERING ####
################################################################################
echo -e "\n\n###################################################################"
if [ $SKIP_BEDMASK == FALSE ]
then
	echo "#### vcf2loci_pip.sh: Calling script to create bedfile with sites removed by vcf filtering..."
	
	MASKBED_JOB=$(sbatch --job-name=$JOBNAME --dependency=singleton \
	-p yoderlab,common,scavenger --mem ${MEM}G -o slurm.vcf2loci0.$ID_FULL \
	$SCRIPT_MASKBED $VCF_ALTREF $VCF_FILTERED_MASK $BED_VCF_ALTREF \
	$BED_VCF_FILTERED_MASK $BED_REMOVED_SITES $MEM)
		
	MASKBED_JOB=$(echo $MASKBED_JOB | sed 's/Submitted batch job //')
	MASKBED_DEPENDENCY="--dependency=afterok:$MASKBED_JOB"
else
	echo -e "#### vcf2loci_pip.sh: Skipping bed-filtering step.\n"
fi

	
################################################################################
#### SCRIPT 1 - FOR EACH IND, CREATE CALLLABLE-LOCI BED, AND MASKED ALT-REF FASTA ####
################################################################################
echo -e "\n\n###################################################################"
if [ $SKIP_VCF2FULLFASTA1 == FALSE ]
then
	echo "#### vcf2loci_pip.sh: For each ind, create callable-loci bedfile and masked alt-ref fasta:"
	echo "#### vcf2loci_pip.sh: Number of inds: ${#INDS[@]}"
	echo "#### vcf2loci_pip.sh: Calling script vcf2loci1.sh..."
	
	for IND in ${INDS[@]}
	do
		echo -e "\n#### vcf2loci_pip.sh: Individual: $IND"
		
		BAM=$DIR_BAM/$IND.$SUFFIX_BAM*bam
		echo "#### Bam file:"
		ls -lh $BAM
		
		sbatch --job-name=$JOBNAME $MASKBED_DEPENDENCY \
			-p yoderlab,common,scavenger --mem ${MEM}G -o slurm.vcf2loci1.$IND.$ID_FULL \
			$SCRIPT_VCF2FULLFA1 $IND $ID_VCF $BAM $VCF_ALTREF $BED_REMOVED_SITES \
			$DIR_INDFASTA $DIR_BED $REF "$CALLABLE_COMMAND" $MEM $SKIP_IN_1
	done
else
	echo -e "#### vcf2loci_pip.sh: Skipping vcf2loci1 script.\n"
fi


################################################################################
#### SCRIPT 2 - FOR ALL INDS AT ONCE, DELIMIT AND EXTRACT LOCI ####
################################################################################
if [ $SKIP_VCF2FULLFASTA2 == FALSE ]
then
	echo -e "\n\n###############################################################"
	echo "#### vcf2loci_pip.sh: For all inds at once, delimit and extract loci:"
	echo "#### vcf2loci_pip.sh: Calling script vcf2fullFasta2.sh..."
	
	if [ $SELECT_INDS_BY_FILE == "FALSE" ] && [ ! -e $FILE_INDS ]
	then
			echo "vcf2loci_pip.sh: Creating on-the-fly indfile"
			FILE_INDS=slurm.indfile.$ID_FULL.tmp && printf "%s\n" "${INDS[@]}" > $FILE_INDS
	fi
	
	sbatch --job-name=$JOBNAME --dependency=singleton \
		-p yoderlab,common,scavenger --mem ${MEM}G -o slurm.vcf2loci2.$ID_FULL \
		$SCRIPT_VCF2FULLFA2 $ID_VCF $ID_VCF2FASTA $FILE_INDS $FILE_LD $DIR_BED \
		$DIR_FASTA $VCF_FILTERED_INTERSECT $VCF_HIGHDEPTH $TESTRUN $SKIP_IN_2
else
	echo -e "#### vcf2loci_pip.sh: Skipping vcf2loci2 script.\n"
fi


echo -e "\n###################################################################"
echo "#### Done with script vcf2loci_pip.sh"
date