#!/bin/bash
set -e
set -o pipefail
set -u

################################################################################
#### SET-UP ####
################################################################################
## Software and hard-coded dirs:
GATK4_EXC=/datacommons/yoderlab/programs/gatk-4.0.7.0/gatk
BCFTOOLS=/datacommons/yoderlab/programs/bcftools-1.6/bcftools
BGZIP=/datacommons/yoderlab/programs/htslib-1.6/bgzip
TABIX=/datacommons/yoderlab/programs/htslib-1.6/tabix

TMP_DIR=/work/jwp37/javaTmpDir

## Command-line args:
SETNAME="$1"
shift
MULTI_IND="$1"
shift
INTERVAL_FILE="$1"
shift
INTERVAL_ID="$1"
shift
GVCF_DIR="$1"
shift
VCF_DIR_SCAFFOLD="$1"
shift
REF="$1"
shift
ADD_COMMANDS="$1"
shift
MEM="$1"
shift
NCORES="$1"
shift
count=0
while [ "$*" != "" ]
  do INDS[$count]=$1
  shift
  count=`expr $count + 1`
done

## Process command-line args:
VCF_OUT=$VCF_DIR_SCAFFOLD/$SETNAME.$INTERVAL_ID.rawvariants.vcf
[[ $ADD_COMMANDS == "none" ]] && ADD_COMMANDS=""
INDS_COMMAND=$(for IND in ${INDS[@]}; do printf " --variant $GVCF_DIR/$IND.rawvariants.g.vcf"; done)
[[ ! -d $GVCF_DIR/byScaffold ]] && echo "#### gatk2_jointgeno.sh: Creating directory $GVCF_DIR/byScaffold" && mkdir -p $GVCF_DIR/byScaffold
[[ ! -d $TMP_DIR ]] && mkdir -p $TMP_DIR

## Report:
date
echo "#### gatk2_jointgeno.sh: Starting script."
echo "#### gatk2_jointgeno.sh: Job ID: $SLURM_JOB_ID"
echo "#### gatk2_jointgeno.sh: Number of nodes [from slurm variables]: $SLURM_JOB_NUM_NODES" # Specify with -N
printf "\n"
echo "#### gatk2_jointgeno.sh: Set name: $SETNAME"
echo "#### gatk2_jointgeno.sh: Multi-ind TRUE/FALSE: $MULTI_IND"
echo "#### gatk2_jointgeno.sh: Interval file: $INTERVAL_FILE"
echo "#### gatk2_jointgeno.sh: Interval ID: $INTERVAL_ID"
echo "#### gatk2_jointgeno.sh: Input dir: $GVCF_DIR"
echo "#### gatk2_jointgeno.sh: Output dir: $VCF_DIR_SCAFFOLD"
echo "#### gatk2_jointgeno.sh: Reference genome file: $REF"
echo "#### gatk2_jointgeno.sh: Additional GATK commands: $ADD_COMMANDS"
echo "#### gatk2_jointgeno.sh: Memory: $MEM"
echo "#### gatk2_jointgeno.sh: Number of cores: $NCORES"
printf "\n"
echo "#### gatk2_jointgeno.sh: Number of individuals: ${#INDS[@]}"
echo "#### gatk2_jointgeno.sh: Individuals: ${INDS[@]}"
printf "\n"
echo "#### gatk2_jointgeno.sh: Output VCF: $VCF_OUT"


################################################################################
#### MERGE GVCFS BY IND (FOR ONE SCAFFOLD) ####
###############################################################################
echo -e "\n\n###################################################################"

if [ $MULTI_IND == TRUE ] 
then
	echo -e "#### gatk2_jointgeno.sh: Step 1: running GenomicsDBImport...\n"
	
	DB_DIR=$VCF_DIR_SCAFFOLD/DBs/$SETNAME.$INTERVAL_ID
	[[ -d $DB_DIR ]] && echo "#### gatk2_jointgeno.sh: Removing directory $DB_DIR" && rm -r $DB_DIR # GATK throws error if dir already exists.
	[[ ! -d $VCF_DIR_SCAFFOLD/DBs ]] && echo "#### gatk2_jointgeno.sh: Creating directory $VCF_DIR_SCAFFOLD/DBs" && mkdir -p $VCF_DIR_SCAFFOLD/DBs
	
	echo -e "#### gatk2_jointgeno.sh: Database dir: $DB_DIR"
	echo -e "#### gatk2_jointgeno.sh: Output VCF file: $VCF_OUT \n"
	
	$GATK4_EXC --java-options "-Xmx${MEM}g" GenomicsDBImport \
		$INDS_COMMAND \
		--genomicsdb-workspace-path $DB_DIR \
		--batch-size 0 \
		--intervals $INTERVAL_FILE \
		--reader-threads $NCORES \
		--interval-padding 100
	
	GENO_INPUT="gendb://$DB_DIR"
else
	echo "#### gatk2_jointgeno.sh: Analyzing single sample, so skipping GenomicsDBImport..."
	GENO_INPUT=$GVCF_DIR/$SETNAME.rawvariants.g.vcf
fi


################################################################################
#### RUN GATK JOINT GENOTYPING ####
################################################################################
echo -e "\n\n#################################################################"
echo -e "#### gatk2_jointgeno.sh: Step 2: genotyping GVCF with all inds combined..."
echo -e "#### gatk2_jointgeno.sh: GVCF input: $GENO_INPUT"
echo -e "#### gatk2_jointgeno.sh: Output VCF file: $VCF_OUT \n"

## Run GATK:
$GATK4_EXC --java-options "-Xmx${MEM}g" GenotypeGVCFs \
	-R $REF -V $GENO_INPUT --use-new-qual-calculator \
	-O $VCF_OUT --TMP_DIR=$TMP_DIR

#-G StandardAnnotation


################################################################################
#### HOUSEKEEPING ####
################################################################################
echo -e "\n#### gatk2_jointgeno.sh: Output file:"
ls -lh $VCF_OUT

NVAR=$(grep -v "##" $VCF_OUT | wc -l)
echo -e "\n#### gatk2_jointgeno.sh: Number of variants in jointly-genotyped-vcf: $NVAR \n"

echo "#### gatk2_jointgeno.sh: Done with script gatk2_jointgeno.sh"
date