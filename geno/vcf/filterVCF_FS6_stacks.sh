#!/bin/bash

#set -e
#set -o pipefail
#set -u
#set -xv

################################################################################
#### SET-UP #####
################################################################################
## Software & scripts:
SCR_QCVCF=/datacommons/yoderlab/users/jelmer/scripts/qc/qc_vcf.sh

JAVA=/datacommons/yoderlab/programs/java_1.8.0/jre1.8.0_144/bin/java
GATK3=/datacommons/yoderlab/programs/gatk-3.8-0/GenomeAnalysisTK.jar
GATK4_EXC=/datacommons/yoderlab/programs/gatk-4.0.7.0/gatk
BCFTOOLS=/datacommons/yoderlab/programs/bcftools-1.6/bcftools
VCFTOOLS=/dscrhome/rcw27/programs/vcftools/vcftools-master/bin/vcftools
MAWK=/datacommons/yoderlab/programs/mawk-1.3.4-20171017/mawk
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
FILTER_INDS_BY_MISSING=$1
shift
INDFILE=$1
shift
INDSEL_ID=$1
shift
SCAF_FILE=$1
shift
MEM=$1
shift

SKIP_1='FALSE'
SKIP_2='FALSE'
SKIP_3='FALSE'
SKIP_4='FALSE'
SKIP_5='FALSE'
SKIP_6='FALSE'
SKIP_7='FALSE'
SKIP_8='FALSE'
SKIP_ANNOT='FALSE'

while getopts '123456789Z' flag; do
  case "${flag}" in
    1) SKIP_1='TRUE' ;;
    2) SKIP_2='TRUE' ;;
    3) SKIP_3='TRUE' ;;
    4) SKIP_4='TRUE' ;;
    5) SKIP_5='TRUE' ;;
    6) SKIP_6='TRUE' ;;
    7) SKIP_7='TRUE' ;;
    8) SKIP_8='TRUE' ;;
    9) SKIP_ANNOT='TRUE' ;;
    *) error "Unexpected option ${flag}" ;;
  esac
done

## Process variables:
VCF_IN=$IN_DIR/$INPUT_NAME.vcf

SELECT_INDS_BY_FILE=FALSE; [[ -e $INDFILE ]] && SELECT_INDS_BY_FILE=TRUE
SELECT_SCAFS=FALSE; [[ -e $SCAF_FILE ]] && SELECT_SCAFS=TRUE
[[ $SELECT_INDS_BY_FILE == TRUE ]] && VCF_INDSEL=$IN_DIR/$INPUT_NAME.$INDSEL_ID.indselOnly.vcf.gz

ID=$IN_DIR/$OUTPUT_NAME

VCF_HIGHDEPTH=$IN_DIR/$OUTPUT_NAME.TooHighDepth.vcf
VCF_FS6=$OUT_DIR/$OUTPUT_NAME.FS6.vcf
VCF_FS7=$OUT_DIR/$OUTPUT_NAME.FS7.vcf
VCF_FS8=$IN_DIR/$OUTPUT_NAME.FS8.vcf
[[ $SKIP_7 == TRUE ]] && VCF_OUT_ALT=$IN_DIR/$OUTPUT_NAME.vcf

FILTSTATS=$QC_DIR/filtering/$OUTPUT_NAME.filterstats
FILTFILE=$QC_DIR/filtering/$OUTPUT_NAME

[[ ! -d $QC_DIR/filtering ]] && echo "#### filterVCF_FS6.sh: Creating dir $QC_DIR/filtering" && mkdir -p $QC_DIR/filtering  
[[ ! -e $VCF_IN ]] && [[ -e $VCF_IN.gz ]] && echo "#### filterVCF_FS6.sh: unzipping input VCF" && gunzip -f $VCF_IN.gz  
[[ ! -e $VCF_IN ]] && [[ ! -e $VCF_IN.gz ]] && echo -e "\n\n\n#### filterVCF_FS6.sh: ERROR: CANT FIND INPUT FILE #####\n\n\n"

## Filter settings:
DP_MIN=5
GQ_MIN=30

MAXMISS_GENO_1=0.5
MAXMISS_GENO_2=0.6
MAXMISS_GENO_3=0.7
MAXMISS_GENO_4=0.95

MAXMISS_IND_1=0.9
MAXMISS_IND_2=0.7
MAXMISS_IND_3=0.5
MAXMISS_IND_4=0.25

## Report:
echo -e "\n#####################################################################"
echo "#### filterVCF_FS6.sh: Script: filterVCF_FS6.sh"
date
printf "\n"
echo "#### filterVCF_FS6.sh: Input name: $INPUT_NAME"
echo "#### filterVCF_FS6.sh: Output name: $OUTPUT_NAME"
printf "\n"
echo "#### filterVCF_FS6.sh: Source dir: $IN_DIR"
echo "#### filterVCF_FS6.sh: Target dir: $OUT_DIR"
echo "#### filterVCF_FS6.sh: Filter stats dir: $QC_DIR"
echo "#### filterVCF_FS6.sh: Filter stats file: $FILTSTATS"
echo "#### filterVCF_FS6.sh: Assigned memory: $MEM GB"
echo "#### filterVCF_FS6.sh: Reference genome: $REF"
echo "#### filterVCF_FS6.sh: File with inds to keep: $INDFILE"
echo "#### filterVCF_FS6.sh: Filter inds by missing data: $FILTER_INDS_BY_MISSING"
echo "#### filterVCF_FS6.sh: Filter inds using file TRUE/FALSE: $SELECT_INDS_BY_FILE"
echo "#### filterVCF_FS6.sh: Indiv selection ID: $INDSEL_ID"
echo "#### filterVCF_FS6.sh: Dir with bamfiles: $BAM_DIR"
echo "#### filterVCF_FS6.sh: Suffix for bamfiles: $BAM_SUFFIX"
echo "#### filterVCF_FS6.sh: Scaffold file: $SCAF_FILE"
printf "\n"
echo "#### filterVCF_FS6.sh: Do prep step A (Select scaffolds).........: $SELECT_SCAFS"
echo "#### filterVCF_FS6.sh: Do prep step B (Select inds)..............: $SELECT_INDS_BY_FILE"
echo "#### filterVCF_FS6.sh: Skip step 1 (Filter by low DP)............: $SKIP_1"
echo "#### filterVCF_FS6.sh: Skip step 2 (Filter by missing data - 1-3): $SKIP_2"
echo "#### filterVCF_FS6.sh: Skip step 3 (Filter with GATK.............: $SKIP_3"
echo "#### filterVCF_FS6.sh: Skip step 4 (Filter by high depth):.......: $SKIP_4"
echo "#### filterVCF_FS6.sh: Skip step 5 (Filter by MAC)...............: $SKIP_5"
echo "#### filterVCF_FS6.sh: Skip step 6 (Filter by missing data - 4)..: $SKIP_6"
echo "#### filterVCF_FS6.sh: Skip step 7 (File organization)...........: $SKIP_7"
echo "#### filterVCF_FS6.sh: Skip step 8 (QC)..........................: $SKIP_8"
echo "#### filterVCF_FS6.sh: Skip VCF annotation by GATK (step 3a).....: $SKIP_ANNOT"

echo -e "\n#### filterVCF_FS6.sh: File ID: $ID"
echo "#### filterVCF_FS6.sh: VCF - in:"
ls -lh $VCF_IN

echo -e "\n#### filterVCF_FS6.sh: VCF-TooHighDepth: $VCF_HIGHDEPTH"
[[ $SKIP_7 == FALSE ]] && echo "#### filterVCF_FS6.sh: VCF - FS6: $VCF_FS6"
[[ $SKIP_7 == FALSE ]] && echo "#### filterVCF_FS6.sh: VCF - FS7: $VCF_FS7"
[[ $SKIP_7 == FALSE ]] && echo "#### filterVCF_FS6.sh: VCF - FS8: $VCF_FS8"
[[ $SKIP_7 == TRUE ]] && echo "#### filterVCF_FS6.sh: VCF - out: $VCF_OUT_ALT"
[[ $SELECT_INDS_BY_FILE == TRUE ]] && echo "#### filterVCF_FS6.sh: VCF - indsel: $VCF_INDSEL"

echo -e "\n#### filterVCF_FS6.sh: min DP: $DP_MIN"
echo "#### filterVCF_FS6.sh: min-mean DP: $DP_MEAN"
echo "#### filterVCF_FS6.sh: Minor Allele Count (MAC): $MAC"
echo "#### filterVCF_FS6.sh: Max miss - geno 1: $MAXMISS_GENO_1"
echo "#### filterVCF_FS6.sh: Max miss - geno 2: $MAXMISS_GENO_2"
echo "#### filterVCF_FS6.sh: Max miss - geno 3: $MAXMISS_GENO_3"
echo "#### filterVCF_FS6.sh: Max miss - geno 4: $MAXMISS_GENO_4"
echo "#### filterVCF_FS6.sh: Max miss - ind 1: $MAXMISS_IND_1"
echo "#### filterVCF_FS6.sh: Max miss - ind 2: $MAXMISS_IND_2"
echo "#### filterVCF_FS6.sh: Max miss - ind 3: $MAXMISS_IND_3"
echo "#### filterVCF_FS6.sh: Max miss - ind 4: $MAXMISS_IND_4"
echo -e "\n\n###################################################################"

## Bgzip, tabix, and unzip:
if [ ! -s $VCF_IN.gz.tbi ]
then
	echo "#### filterVCF_FS6.sh: Bgzipping, tabixing, and unzipping input VCF..."	
	$BGZIP $VCF_IN
	$TABIX $VCF_IN.gz
	gunzip $VCF_IN.gz
fi


################################################################################
#### PREP STEP A: SELECT SCAFFOLDS ####
################################################################################
if [ $SELECT_SCAFS == FALSE ]
then
	echo -e "\n#### filterVCF_FS6.sh: Skipping prep step a: Select scaffolds..."
	VCF_STEP0a=$VCF_IN
else
	[[ ! -e $SCAF_FILE ]] && echo -e "\n\n\n#### filterVCF_FS6.sh: ERROR: SCAF_FILE $SCAF_FILE CANNOT BE FOUND\n\n\n"
	echo -e "\n\n###############################################################"
	echo "#### filterVCF_FS6.sh: Prep step a: Selecting scaffolds from file: $SCAF_FILE"
	
	VCF_STEP0a=$ID.S0a.vcf
	
	SCAFS=( $(cat $SCAF_FILE) )
	SCAF_COMMAND=""
	for SCAF in ${SCAFS[@]}
	do
		SCAF_COMMAND=$(echo "$SCAF_COMMAND --chr $SCAF")
	done
	echo -e "#### filterVCF_FS6.sh: Scaffold command for vcftools: $SCAF_COMMAND \n"
	
	$VCFTOOLS --vcf $VCF_IN --recode --recode-INFO-all $SCAF_COMMAND --stdout > $VCF_STEP0a
	#$BCFTOOLS view --regions-file $SCAF_FILE $VCF_IN -O v > $VCF_STEP0a
fi
	
	
################################################################################
#### PREP STEP B: SELECT SAMPLES ####
################################################################################
if [ $SELECT_INDS_BY_FILE == FALSE ]
then
	echo -e "\n#### filterVCF_FS6.sh: Skipping prep step b (select inds)..."
	VCF_STEP0b=$VCF_STEP0a
else
	[[ ! -e $INDFILE ]] && echo -e "\n\n\n#### filterVCF_FS6.sh: ERROR: INDFILE $INDFILE CANNOT BE FOUND\n\n\n"
	echo -e "\n\n###############################################################"
	echo "#### filterVCF_FS6.sh: Step 0: Selecting individuals from file: $INDFILE"
	
	VCF_STEP0b=$ID.S0b.vcf
	
	KEEP_COMMAND="--keep $INDFILE"
	echo -e "\n#### filterVCF_FS6.sh: Keep command: $KEEP_COMMAND"
	echo -e "\n#### filterVCF_FS6.sh: Indfile contents:"
	cat $INDFILE
	
	echo -e "\n#### filterVCF_FS6.sh: Outputting to file $VCF_STEP0"
	
	$VCFTOOLS --vcf $VCF_STEP0a --recode --recode-INFO-all $KEEP_COMMAND --stdout > $VCF_STEP0b
	
	NR_INDS_REQUESTED=$(cat $INDFILE | wc -l)
	NR_INDS_PRESENT=$($BCFTOOLS query -l $VCF_STEP0b | wc -l)
	echo -e "\n#### filterVCF_FS6.sh: Number of individuals requested by indfile: $NR_INDS_REQUESTED"
	echo -e "#### filterVCF_FS6.sh: Number of individuals present in VCF: $NR_INDS_PRESENT \n"
	
	[[ $NR_INDS_REQUESTED != $NR_INDS_PRESENT ]] && \
	echo -e "\n\n\n\n#### filterVCF_FS6.sh: WARNING: NR OF INDS REQUESTED ($NR_INDS_REQUESTED) DOES NOT MATCH NR PRESENT ($NR_INDS_PRESENT) IN VCF\n\n\n\n" 
	
	echo "#### filterVCF_FS6.sh: Saving a copy of individual-selected file..."
	gzip -c $VCF_STEP0b > $VCF_INDSEL
	ls -lh $VCF_INDSEL
fi


################################################################################
#### STEP 1: FILTER BY MIN AND MIN-MEAN DEPTH ####
################################################################################
if [ $SKIP_1 == TRUE ]
then
	echo -e "\n#### filterVCF_FS6.sh: Skipping Step 1 (filtering by DP)..."
	VCF_STEP1=$VCF_STEP0b
else
	echo -e "\n#################################################################"
	echo -e "#### filterVCF_FS6.sh: Step 1: filtering genotypes by DP...\n"
	
	VCF_STEP1=$ID.S1.vcf
	
	$VCFTOOLS --vcf $VCF_STEP0b --recode --recode-INFO-all --minDP $DP_MIN --min-meanDP $DP_MEAN --stdout > $VCF_STEP1
	
	## Report:
	NVAR_ALLSNPS=$(grep -v "##" $VCF_STEP0b | wc -l)
	NVAR_S1=$(grep -v "##" $VCF_STEP1 | wc -l)
	NFILT_S1=$(($NVAR_ALLSNPS - $NVAR_S1))
	echo "#### filterVCF_FS6.sh: Number of SNPs prior to filtering: $NVAR_ALLSNPS"
	echo -e "#### filterVCF_FS6.sh: Number of SNPs filtered by min mean-DP $DP_MEAN: $NFILT_S1"
	echo -e "#### filterVCF_FS6.sh: Number of SNPs left after step 1: $NVAR_S1"
fi
echo -e "\n#### filterVCF_FS6.sh: VCF_STEP1 (after step 1): $VCF_STEP1  \n"


################################################################################
#### STEP 2: FILTER BY MISSING DATA - FIRST THREE ROUNDS ####
################################################################################
if [ $SKIP_2 == TRUE ]
then
	echo -e "\n#### filterVCF_FS6.sh: Skipping Step 2 (Filter by missing data - first three rounds)..."
	VCF_STEP2=$VCF_STEP1
else
	echo -e "\n#################################################################"
	echo -e "#### filterVCF_FS6.sh: Step 2: filtering genotypes & inds by missing data in 3 rounds..."
	date
	
	VCF_STEP2=$ID.S2.vcf
	
	## Round 1:
	if [ $FILTER_INDS_BY_MISSING == TRUE ]
	then
		echo -e "\n#### filterVCF_FS6.sh: Filtering genotypes by missing data - round 1...."
		$VCFTOOLS --vcf $VCF_STEP1 --recode --recode-INFO-all \
			--max-non-ref-af 0.99 --min-alleles 2 --max-missing $MAXMISS_GENO_1 --stdout > $ID.S2R1a.vcf
		
		echo -e "#### filterVCF_FS6.sh: Filtering individuals by missing data - round 1...."
		$VCFTOOLS --vcf $ID.S2R1a.vcf --missing-indv --stdout > $FILTFILE.round1.imiss ## Get amount of missing data per indv
		tail -n +2 $FILTFILE.round1.imiss | awk -v var="$MAXMISS_IND_1" '$5 > var' | cut -f1 > $FILTFILE.HiMissInds1 ## Get list of inds with too much missing data
		$VCFTOOLS --vcf $ID.S2R1a.vcf --recode --recode-INFO-all --remove $FILTFILE.HiMissInds1 --stdout > $ID.S2R1b.vcf ## Remove inds with too much missing data
		
		## Round 2:
		echo -e "#### filterVCF_FS6.sh: Filtering genotypes by missing data - round 2...."
		$VCFTOOLS --vcf $ID.S2R1b.vcf --recode --recode-INFO-all \
			--max-non-ref-af 0.99 --min-alleles 2 --max-missing $MAXMISS_GENO_2 --stdout > $ID.S2R2a.vcf
		
		echo -e "#### filterVCF_FS6.sh: Filtering individuals by missing data - round 2...."
		$VCFTOOLS --vcf $ID.S2R2a.vcf --missing-indv --stdout > $FILTFILE.round2.imiss ## Get amount of missing data per indv
		tail -n +2 $FILTFILE.round2.imiss | awk -v var="$MAXMISS_IND_2" '$5 > var' | cut -f1 > $FILTFILE.HiMissInds2 ## Get list of inds with too much missing data
		$VCFTOOLS --vcf $ID.S2R2a.vcf --recode --recode-INFO-all --remove $FILTFILE.HiMissInds2 --stdout > $ID.S2R2b.vcf ## Remove inds with too much missing data
		
		## Round 3:
		echo -e "#### filterVCF_FS6.sh: Filtering genotypes by missing data - round 3...."
		$VCFTOOLS --vcf $ID.S2R2b.vcf --recode --recode-INFO-all \
			--max-non-ref-af 0.99 --min-alleles 2 --max-missing $MAXMISS_GENO_3 --stdout > $ID.S2R3a.vcf 
		
		echo -e "#### filterVCF_FS6.sh: Filtering individuals by missing data - round 3...."
		$VCFTOOLS --vcf $ID.S2R3a.vcf --missing-indv --stdout > $FILTFILE.round3.imiss ## Get amount of missing data per indv
		tail -n +2 $FILTFILE.round3.imiss | awk -v var="$MAXMISS_IND_3" '$5 > var' | cut -f1 > $FILTFILE.HiMissInds3 ## Get list of inds with too much missing data
		$VCFTOOLS --vcf $ID.S2R3a.vcf --recode --recode-INFO-all --remove $FILTFILE.HiMissInds3 --stdout > $VCF_STEP2 ## Remove inds with too much missing data
		
		## Report:
		NVAR_S1=$(grep -v "##" $VCF_STEP1 | wc -l)
		NVAR_S2=$(grep -v "##" $VCF_STEP2 | wc -l)
		NVAR_S2R1=$(grep -v "##" $ID.S2R1a.vcf | wc -l)
		NVAR_S2R2=$(grep -v "##" $ID.S2R2a.vcf | wc -l)
		NVAR_S2R3=$(grep -v "##" $ID.S2R3a.vcf | wc -l)
		
		NFILT_S2R1=$(($NVAR_S1 - $NVAR_S2R1))
		NFILT_S2R2=$(($NVAR_S2R1 - $NVAR_S2R2))
		NFILT_S2R3=$(($NVAR_S2R2 - $NVAR_S2R3))
		
		NIND_EXCL_S2R1=$(cat $FILTFILE.HiMissInds1 | wc -l)
		NIND_EXCL_S2R2=$(cat $FILTFILE.HiMissInds2 | wc -l)
		NIND_EXCL_S2R3=$(cat $FILTFILE.HiMissInds3 | wc -l)
		
		NIND_ALL=$(cat $VCF_STEP1 | awk '{if ($1 == "#CHROM"){print NF-9; exit}}')
		NIND_S2=$(cat $VCF_STEP2 | awk '{if ($1 == "#CHROM"){print NF-9; exit}}')
		
		printf "\n\n"
		echo -e "#### filterVCF_FS6.sh: Number of inds prior to filtering by missing data: $NIND_ALL"
		echo -e "#### filterVCF_FS6.sh: Number of inds filtered in round 1: $NIND_EXCL_S2R1"
		echo -e "#### filterVCF_FS6.sh: Number of inds filtered in round 2: $NIND_EXCL_S2R2"
		echo -e "#### filterVCF_FS6.sh: Number of inds filtered in round 3: $NIND_EXCL_S2R3"
		echo -e "#### filterVCF_FS6.sh: Number of inds left after ind-filtering: $NIND_S2"
		printf "\n"
		echo -e "#### filterVCF_FS6.sh: Number of SNPs prior to filtering by missing data: $NVAR_S1"
		echo -e "#### filterVCF_FS6.sh: Number of SNPs filtered in round 1: $NFILT_S2R1"
		echo -e "#### filterVCF_FS6.sh: Number of SNPs filtered in round 2: $NFILT_S2R2"
		echo -e "#### filterVCF_FS6.sh: Number of SNPs filtered in round 3: $NFILT_S2R3"
		echo -e "#### filterVCF_FS6.sh: Number of SNPs left after step 2: $NVAR_S2"
	fi
	
	if [ $FILTER_INDS_BY_MISSING == FALSE ]
	then
		echo -e "\n\n#### filterVCF_FS6.sh: ONLY FILTERING BY MISSING DATA AT GENOTYPE LEVEL - NO INDS WILL BE REMOVED...."
		echo -e "\n\n#### filterVCF_FS6.sh: Filtering genotypes by missing data - all in a single round...."
		$VCFTOOLS --vcf $VCF_STEP4 --recode --recode-INFO-all \
			--max-non-ref-af 0.99 --min-alleles 2 --max-missing $MAXMISS_GENO_3 --stdout > $VCF_STEP2
			
		NVAR_S1=$(grep -v "##" $VCF_STEP1 | wc -l)
		NVAR_S2=$(grep -v "##" $VCF_STEP2 | wc -l)
		NFILT_S2=$(($NVAR_S1 - $NVAR_S2))
		echo -e "\n#### filterVCF_FS6.sh: Number of SNPs prior to filtering by missing data: $NVAR_S1"
		echo -e "#### filterVCF_FS6.sh: Number of SNPs filtered due to missing data: $NFILT_S2"
		echo -e "#### filterVCF_FS6.sh: Number of SNPs left: $NVAR_S2"
	fi
fi
echo -e "\n#### filterVCF_FS6.sh: VCF_STEP2 (after step 2): $VCF_STEP2 \n"


################################################################################
#### STEP 3: FILTER WITH GATK ####
################################################################################
if [ $SKIP_3 == TRUE ]
then
	echo -e "\n#### filterVCF_FS6.sh: Skipping Step 3 (Filter SNPs using GATK)..."
	VCF_STEP3=$VCF_STEP2
else
	echo -e "\n#################################################################"
	echo -e "#### filterVCF_FS6.sh: Step 3: Filter SNPS using GATK...\n"
	
	VCF_STEP3=$ID.S3.vcf
	
	## A: Annotate:
	if [ $SKIP_ANNOT == "FALSE" ]
	then
		echo -e "#### filterVCF_FS6.sh: Step 3a: Annotating SNPS using GATK...\n"
		
		INDS=( $($BCFTOOLS query -l $VCF_STEP2) )
		BAM_ARG=""
		for IND in ${INDS[@]}
		do
			BAMFILE=$BAM_DIR/${IND}$BAM_SUFFIX
			BAM_ARG=$(echo "$BAM_ARG -I $BAMFILE")
		done
		echo $BAM_ARG
		
		$JAVA -Xmx${MEM}G -jar $GATK3 -T VariantAnnotator -R $REF \
			-V $VCF_STEP2 -o $ID.S3annot.vcf $BAM_ARG \
			-A FisherStrand -A RMSMappingQuality -A MappingQualityRankSumTest -A ReadPosRankSumTest -A AlleleBalance
	fi
	
	## B: Soft-filter:
	echo -e "#### filterVCF_FS6.sh: Step 3a: Soft-filtering SNPS using GATK...\n"
	$GATK4_EXC --java-options "-Xmx${MEM}g" VariantFiltration -R $REF \
		-V $ID.S3annot.vcf -O $ID.S3b.vcf \
		--filter-expression "FS > 60.0" --filter-name "FS_gt60" \
		--filter-expression "MQ < 40.0" --filter-name "MQ_lt40" \
		--filter-expression "MQRankSum < -12.5" --filter-name "MQRankSum_ltm12.5" \
		--filter-expression "ReadPosRankSum < -8.0" --filter-name "ReadPosRankSum_ltm8" \
		--filter-expression "ABHet > 0.01 && ABHet < 0.2 || ABHet > 0.8 && ABHet < 0.99" --filter-name "ABHet_filt"
	
	#NFILT_QD=$(grep "QD_lt2" $ID.S3b.vcf | wc -l)  # QualByDepth (QD) # Not possible as Stacks gives no Qual score 
	NFILT_FS=$(grep "FS_gt60" $ID.S3b.vcf | wc -l) # FisherStrand (FS)
	NFILT_MQ=$(grep "MQ_lt40" $ID.S3b.vcf | wc -l) # RMSMappingQuality (MQ)
	NFILT_MQR=$(grep "MQRankSum_ltm12" $ID.S3b.vcf | wc -l) # MappingQualityRankSumTest (MQRankSum) 
	NFILT_READPOS=$(grep "ReadPosRankSum_ltm8" $ID.S3b.vcf | wc -l) # ReadPosRankSumTest (ReadPosRankSum)
	NFILT_ABHET=$(grep "ABHet_filt" $ID.S3b.vcf | wc -l)
	
	## C: Hard-filter:
	echo -e "\n#### filterVCF_FS6.sh: Step 3c: Hard-filtering SNPS using vcftools..."
	$VCFTOOLS --vcf $ID.S3b.vcf --remove-filtered-all --max-non-ref-af 0.99 --min-alleles 2 \
		--recode --recode-INFO-all --stdout > $VCF_STEP3
	
	## Report:
	NVAR_S2=$(grep -v "##" $VCF_STEP2 | wc -l)
	NVAR_S3=$(grep -v "##" $VCF_STEP3 | wc -l)
	NFILT_S3=$(($NVAR_S2 - $NVAR_S3))
	echo -e "\n#### filterVCF_FS6.sh: Total number of SNPs filtered by GATK filtering: $NFILT_S3"
	echo -e "#### filterVCF_FS6.sh: Number of SNPs after GATK filtering: $NVAR_S3"
	printf "\n"
	echo "#### filterVCF_FS6.sh: Nr of SNPs filtered by FS_gt60: $NFILT_FS"
	echo "#### filterVCF_FS6.sh: Nr of SNPs filtered by MQ_lt40: $NFILT_MQ"
	echo "#### filterVCF_FS6.sh: Nr of SNPs filtered by MQRankSum_ltm12: $NFILT_MQR"
	echo "#### filterVCF_FS6.sh: Nr of SNPs filtered by ReadPosRankSum_ltm8: $NFILT_READPOS"
	echo "#### filterVCF_FS6.sh: Nr of SNPs filtered by ABHet_filt: $NFILT_ABHET"
	
	gzip $ID.S3annot.vcf
fi
echo -e "\n#### filterVCF_FS6.sh: VCF_STEP3 (after step 3): $VCF_STEP3 \n"


################################################################################
#### STEP 4: FILTER FOR MAX DEPTH ####
################################################################################
if [ $SKIP_4 == TRUE ]
then
	echo -e "\n#### filterVCF_FS6.sh: Skipping Step 4..."
	VCF_STEP4=$VCF_STEP3
else
	echo -e "\n#################################################################"
	echo -e "#### filterVCF_FS6.sh: Step 4: Filter for high depth...\n"
	
	VCF_STEP4=$ID.S4.vcf
	
	## Create a file with the original site depth locus:
	$VCFTOOLS --vcf $VCF_STEP3 --site-depth --stdout | tail -n +2 | cut -f 3 > $FILTFILE.depth
	#cut -f8 $VCF | grep -oe "DP=[0-9]*" | sed -s 's/DP=//g' > $FILTFILE.depth
	
	## Calculate the average depth and standard deviation:
	
	DEPTH_MEAN=$(awk '{ total += $1; count++ } END { print total/count }' $FILTFILE.depth)
	DEPTH_SD=$(awk '{sum+=$1; sumsq+=$1*$1} END {print sqrt(sumsq/NR - (sum/NR)^2)}' $FILTFILE.depth)
	DEPTH_HI=$(perl -e "print int("$DEPTH_MEAN") + int("$DEPTH_SD") + int("$DEPTH_SD")" )
	
	## Calculate number of individuals in VCF file:
	NR_INDS=$($MAWK '/#/' $VCF_STEP3 | tail -1 | wc -w)
	NR_INDS=$(($NR_INDS - 9))
	
	## Calculate a max mean depth cutoff to use for filtering:
	MAXDEPTH=$(perl -e "print int($DEPTH_HI / $NR_INDS)")
	MEANDEPTH=$(perl -e "print int($DEPTH_MEAN / $NR_INDS)")
	
	## Combine all filters to create a final filtered VCF file:
	$VCFTOOLS --vcf $VCF_STEP3 --max-meanDP $MAXDEPTH --recode --recode-INFO-all --stdout > $VCF_STEP4
	
	## Save a separate file with loci with too high depth:
	$VCFTOOLS --vcf $VCF_STEP3 --min-meanDP $MAXDEPTH --recode --recode-INFO-all --stdout > $VCF_HIGHDEPTH
	
	## Report:
	NVAR_S3=$($MAWK '!/#/' $VCF_STEP3 | wc -l)
	NVAR_S4=$(grep -v "##" $VCF_STEP4 | wc -l)
	NFILT_S4=$(($NVAR_S3 - $NVAR_S4))
	echo -e "\n#### filterVCF_FS6.sh: Number of SNPs filtered based on max mean depth: $NFILT_S4"
	echo -e "#### filterVCF_FS6.sh: Mean depth: $MEANDEPTH"
	echo -e "#### filterVCF_FS6.sh: Max mean depth prior to dividing by nr of inds: $DEPTH_HI"
	echo -e "#### filterVCF_FS6.sh: Nr of inds in VCF: $NR_INDS"
	echo -e "#### filterVCF_FS6.sh: Max mean depth cutoff is: $MAXDEPTH"
fi
echo -e "\n#### filterVCF_FS6.sh: VCF_STEP4 (after step 4): $VCF_STEP4 \n"


################################################################################
#### STEP 5: FILTER BY MAC ####
################################################################################
if [ $SKIP_5 == TRUE ]
then
	echo -e "\n#### filterVCF_FS6.sh: Skipping Step 5 (Filter by MAC)..."
	VCF_STEP5=$VCF_STEP4
else
	echo -e "\n###############################################################"
	echo -e "#### filterVCF_FS6.sh: Step 5: Filtering by MAC...."
	
	VCF_STEP5=$ID.S5.vcf
	$VCFTOOLS --vcf $VCF_STEP4 --recode --recode-INFO-all --mac $MAC --stdout > $VCF_STEP5
	
	NVAR_S4=$(grep -v "##" $VCF_STEP4 | wc -l)
	NVAR_S5=$(grep -v "##" $VCF_STEP5 | wc -l)
	NFILT_S5=$(($NVAR_S4 - $NVAR_S5))
	echo -e "\n#### filterVCF_FS6.sh: Number of SNPs filtered by MAC $MAC: $NFILT_S5"
	echo -e "#### filterVCF_FS6.sh: Number of SNPs left after step 4: $NVAR_S5"
fi
echo -e "\n#### filterVCF_FS6.sh: VCF_STEP5 (after step 5): $VCF_STEP5 \n"


################################################################################
#### STEP 6: FILTER BY MISSING DATA - FINAL ROUND #####
################################################################################
if [ $SKIP_6 == TRUE ]
then
	echo -e "#### filterVCF_FS6.sh: Skipping Step 6 (filter by missing data - final round)..."
	VCF_STEP6=$VCF_STEP5
else
	echo -e "\n\n###############################################################"
	echo -e "#### filterVCF_FS6.sh: Step 6: Round 4 of missing data filtering..."
	
	VCF_STEP6=$VCF_FS6
	
	if [ $FILTER_INDS_BY_MISSING == TRUE ]
	then
		## Filter individuals:
		echo -e "\n#### filterVCF_FS6.sh: Filtering individuals by missing data...."
		$VCFTOOLS --vcf $VCF_STEP5 --missing-indv --stdout > $FILTFILE.round4.imiss ## Get amount of missing data per indv
		tail -n +2 $FILTFILE.round4.imiss | awk -v var="$MAXMISS_IND_4" '$5 > var' | cut -f1 > $FILTFILE.HiMissInds4 ## Get list of inds with too much missing data
		$VCFTOOLS --vcf $VCF_STEP5 --remove $FILTFILE.HiMissInds4 --recode --recode-INFO-all --stdout > $ID.S6a.vcf ## Remove inds with too much missing data
		
		## Report:
		NIND_EXCL_S6=$(cat $FILTFILE.HiMissInds4 | wc -l)
		NIND_S6=$(cat $ID.S6a.vcf | awk '{if ($1 == "#CHROM"){print NF-9; exit}}')
		echo -e "\n#### filterVCF_FS6.sh: Number of individuals filtered in round 4: $NIND_EXCL_S6"
		echo -e "#### filterVCF_FS6.sh: Number of individuals left after round 4 ind-filtering: $NIND_S6"
	else
		echo "\n#### filterVCF_FS6.sh SKIPPING filtering by inds...\n" && cp $VCF_STEP5 $ID.S6a.vcf
	fi
	
	## Filter genotypes:
	echo -e "\n#### filterVCF_FS6.sh: Filtering genotypes by missing data..."
	$VCFTOOLS --vcf $ID.S6a.vcf --recode --recode-INFO-all \
		--max-non-ref-af 0.99 --min-alleles 2 --max-missing $MAXMISS_GENO_4 --stdout > $VCF_STEP6
	
	## Report:
	NVAR_S6=$(zgrep -v "##" $VCF_STEP6 | wc -l)
	NFILT_S6=$(($NVAR_S5 - $NVAR_S6))
	echo -e "\n#### filterVCF_FS6.sh: Number of SNPs filtered in round 4: $NFILT_S6"
	echo -e "#### filterVCF_FS6.sh: Number of SNPs left after round 4 geno-filtering: $NVAR_S6"
	
	## Filter genotypes, allowing for NO missing data:
	echo -e "\n#### filterVCF_FS6.sh: Filtering genotypes by missing data - allowing for no missing data..."
	$VCFTOOLS --vcf $VCF_STEP5 --recode --recode-INFO-all \
		--max-non-ref-af 0.99 --min-alleles 2 --max-missing 1 --stdout | gzip > $ID.noMiss.vcf.gz
	
	NVAR_NOMISS=$(zgrep -v "##" $ID.noMiss.vcf.gz | wc -l)
	NFILT_NOMISS=$(($NVAR_S6 - $NVAR_NOMISS))
	echo -e "\n#### filterVCF_FS6.sh: Number of SNPs filtered when not allowing missing data: $NFILT_NOMISS"
	echo -e "#### filterVCF_FS6.sh: Number of SNPs left without missing data: $NVAR_NOMISS"
fi
echo -e "\n#### filterVCF_FS6.sh: VCF_STEP6 (after step 6): $VCF_STEP6 \n"


################################################################################
#### STEP 7: ORGANIZE FILES ####
################################################################################
echo -e "\n###################################################################"
echo -e "#### filterVCF_FS6.sh: Step 7: Organize files..."
	
if [ $SKIP_7 == FALSE ]
then
	## FS6 file (final file):
	gzip -f $VCF_STEP6
	
	## FS7 file (minus last missing data filtering step):
	mv $VCF_STEP5 $VCF_FS7
	gzip -c $VCF_FS7 > $VCF_FS7.gz
	rm $VCF_FS7
	
	## FS8 file (no missing data):
	mv $ID.noMiss.vcf.gz $VCF_FS8.gz
else
	## Final VCF file:
	mv $VCF_STEP6 $VCF_OUT_ALT
	#gzip $VCF_OUT_ALT
fi

## Remove intermediate files:
echo -e "\n#### filterVCF_FS6.sh: Gzipping and removing intermediate VCFs & tmp files..."
[[ -e $ID.commonsteps.vcf ]] && echo "#### filterVCF_FS6.sh: Gzipping $ID.commonsteps.vcf..." && gzip -f $ID.commonsteps.vcf
[[ -e $ID.S3.vcf ]] && echo "#### filterVCF_FS6.sh: Gzipping $ID.S3.vcf..." && gzip -f $ID.S3.vcf
[[ -e $VCF_HIGHDEPTH ]] && echo "#### filterVCF_FS6.sh: Gzipping $VCF_HIGHDEPTH..." && gzip -f $VCF_HIGHDEPTH
rm -f $ID.S2R*vcf $ID.S[0-9]a.vcf $ID.S[0-9]b.vcf $ID.S1.vcf $ID.S2.vcf $ID.S3.vcf $ID.S4.vcf $ID.S5.vcf $ID.S6.vcf $ID*idx $ID*tmp* out.log $ID*recode*
rm -f $QC_DIR/filtering/*$OUTPUT_NAME*depth


################################################################################
#### STEP 8: QC ####
################################################################################
if [ $SKIP_8 == TRUE ]
then
	echo -e "\n#### filterVCF_FS6.sh: Skipping Step 8 (QC)..."
else
	echo -e "\n#################################################################"
	echo -e "#### filterVCF_FS6.sh: Step 8: Calling QC scripts..."
	
	RUN_BCF=FALSE
	RUN_BCF_BY_IND=FALSE
	RUN_VCF_SITESTATS=FALSE
	
	## Run for FS6:
	$SCR_QCVCF $OUTPUT_NAME.FS6 $OUT_DIR $QC_DIR $RUN_BCF $RUN_BCF_BY_IND $RUN_VCF_SITESTATS
	
	## Run for FS7:
	$SCR_QCVCF $OUTPUT_NAME.FS7 $OUT_DIR $QC_DIR $RUN_BCF $RUN_BCF_BY_IND $RUN_VCF_SITESTATS
fi


################################################################################
#### REPORT ####
################################################################################
echo -e "\n#####################################################################"
echo -e "#### filterVCF_FS6.sh: Giving final stats:"

[[ $SKIP_7 == FALSE && $SKIP_3 == FALSE ]] && NFILT_TOTAL=$(($NVAR_ALLSNPS - $NFILT_S6))
[[ $SKIP_7 == FALSE && $SKIP_3 == FALSE ]] && echo -e "#### filterVCF_FS6.sh: Total number of sites filtered: $NFILT_TOTAL"
[[ $SKIP_7 == FALSE ]] && echo -e "#### filterVCF_FS6.sh: Remaining SNPs before last round of missing data removal: $NVAR_S5"
[[ $SKIP_7 == FALSE ]] && [[ $SKIP_10 == FALSE ]] && echo -e "#### filterVCF_FS6.sh: Remaining SNPs after all filtering: $NVAR_S6"

## Write to filterstats file:
echo "$OUTPUT_NAME" > $FILTSTATS
[[ $SKIP_1 == FALSE ]] && echo "Nr of SNPs - prior to filtering: $NVAR_ALLSNPS" >> $FILTSTATS
[[ $SKIP_1 == FALSE ]] && echo "Nr of SNPs - after depth filtering: $NVAR_S1" >> $FILTSTATS
[[ $SKIP_2 == FALSE ]] && echo "Nr of SNPs - after missing data 1-3: $NVAR_S2" >> $FILTSTATS
[[ $SKIP_3 == FALSE ]] && echo "Nr of SNPs - after GATK filtering: $NVAR_S3" >> $FILTSTATS
[[ $SKIP_4 == FALSE ]] && echo "Nr of SNPs - after MAC filtering: $NVAR_S3" >> $FILTSTATS
[[ $SKIP_4 == FALSE ]] && echo "Nr of SNPs - after max DP filtering: $NVAR_S4" >> $FILTSTATS
[[ $SKIP_6 == FALSE ]] && echo "Nr of SNPs - before last round of missing data removal (FS7): $NVAR_S5" >> $FILTSTATS
[[ $SKIP_6 == FALSE ]] && echo "Nr of SNPs - after all filtering (FS6): $NVAR_S6" >> $FILTSTATS
[[ $SKIP_6 == FALSE ]] && echo "Nr of SNPs - no missing data (FS8): $NVAR_NOMISS" >> $FILTSTATS
[[ $SKIP_6 == FALSE ]] && printf "\n"
[[ $SKIP_6 == FALSE ]] && echo "Maximum mean depth cutoff is: $MAXDEPTH" >> $FILTSTATS
[[ $SKIP_6 == FALSE ]] && printf "\n"
[[ $SKIP_1 == FALSE ]] && echo "Nr of SNPs filtered - min mean-DP $DP_MEAN: $NFILT_S1" >> $FILTSTATS
[[ $SKIP_5 == FALSE ]] && echo "Nr of SNPs filtered - MAC $MAC: $NFILT_S5" >> $FILTSTATS
[[ $SKIP_2 == FALSE ]] && [[ $FILTER_INDS_BY_MISSING == TRUE ]] && echo "Nr of SNPs filtered - missing data round 1: $NFILT_S2R1" >> $FILTSTATS
[[ $SKIP_2 == FALSE ]] && [[ $FILTER_INDS_BY_MISSING == TRUE ]] && echo "Nr of SNPs filtered - missing data round 2: $NFILT_S2R2" >> $FILTSTATS
[[ $SKIP_2 == FALSE ]] && [[ $FILTER_INDS_BY_MISSING == TRUE ]] && echo "Nr of SNPs filtered - missing data round 3: $NFILT_S2R3" >> $FILTSTATS
[[ $SKIP_6 == FALSE ]] && [[ $FILTER_INDS_BY_MISSING == TRUE ]] && echo "Nr of SNPs filtered - missing data round 4: $NFILT_S6" >> $FILTSTATS
[[ $SKIP_2 == FALSE ]] && [[ $FILTER_INDS_BY_MISSING == FALSE ]] && echo "Nr of SNPs filtered - missing data: $NFILT_S2" >> $FILTSTATS
[[ $SKIP_3 == FALSE ]] && echo "Nr of SNPs filtered - FS_gt60: $NFILT_FS" >> $FILTSTATS
[[ $SKIP_3 == FALSE ]] && echo "Nr of SNPs filtered - MQ_lt40: $NFILT_MQ" >> $FILTSTATS
[[ $SKIP_3 == FALSE ]] && echo "Nr of SNPs filtered - MQRankSum_ltm12: $NFILT_MQR" >> $FILTSTATS
[[ $SKIP_3 == FALSE ]] && echo "Nr of SNPs filtered - ReadPosRankSum_ltm8: $NFILT_READPOS" >> $FILTSTATS
[[ $SKIP_3 == FALSE ]] && echo "Nr of SNPs filtered - ABHet_filt: $NFILT_ABHET" >> $FILTSTATS
[[ $SKIP_4 == FALSE ]] && echo "Nr of SNPs filtered - maximum mean depth: $NFILT_S4" >> $FILTSTATS
[[ $SKIP_9 == FALSE && $SKIP_2 == FALSE ]] && echo "Total number of sites filtered: $NFILT_TOTAL" >> $FILTSTATS
[[ $SKIP_9 == FALSE ]] && echo "(Nr of SNPs filtered - not allowing missing data: $NFILT_NOMISS)" >> $FILTSTATS
[[ $SKIP_9 == FALSE ]] && printf "\n"
[[ $SKIP_2 == FALSE ]] && echo "Nr of inds - prior to filtering: $NIND_ALL" >> $FILTSTATS
[[ $SKIP_2 == FALSE ]] && [[ $FILTER_INDS_BY_MISSING == TRUE ]] && echo "Nr of inds filtered - missing data round 1: $NIND_EXCL_S2R1" >> $FILTSTATS
[[ $SKIP_2 == FALSE ]] && [[ $FILTER_INDS_BY_MISSING == TRUE ]] && echo "Nr of inds filtered - missing data round 2: $NIND_EXCL_S2R2" >> $FILTSTATS
[[ $SKIP_2 == FALSE ]] && [[ $FILTER_INDS_BY_MISSING == TRUE ]] && echo "Nr of inds filtered - missing data round 3: $NIND_EXCL_S2R3" >> $FILTSTATS
[[ $SKIP_6 == FALSE ]] && [[ $FILTER_INDS_BY_MISSING == TRUE ]] && echo "Nr of inds filtered - missing data round 4: $NIND_EXCL_S6" >> $FILTSTATS
[[ $SKIP_6 == FALSE ]] && [[ $FILTER_INDS_BY_MISSING == TRUE ]] && echo "Nr of inds - after all 4 rounds of ind-filtering: $NIND_S6" >> $FILTSTATS
[[ $SKIP_2 == FALSE ]] && [[ $FILTER_INDS_BY_MISSING == TRUE ]] && echo "IDs of indiduals removed in round 1:" >> $FILTSTATS
[[ $SKIP_2 == FALSE ]] && [[ $FILTER_INDS_BY_MISSING == TRUE ]] && cat $FILTFILE.HiMissInds1 >> $FILTSTATS
[[ $SKIP_2 == FALSE ]] && [[ $FILTER_INDS_BY_MISSING == TRUE ]] && echo "IDs of indiduals removed in round 2:" >> $FILTSTATS
[[ $SKIP_2 == FALSE ]] && [[ $FILTER_INDS_BY_MISSING == TRUE ]] && cat $FILTFILE.HiMissInds2 >> $FILTSTATS
[[ $SKIP_2 == FALSE ]] && [[ $FILTER_INDS_BY_MISSING == TRUE ]] && echo "IDs of indiduals removed in round 3:" >> $FILTSTATS
[[ $SKIP_2 == FALSE ]] && [[ $FILTER_INDS_BY_MISSING == TRUE ]] && cat $FILTFILE.HiMissInds3 >> $FILTSTATS
[[ $SKIP_6 == FALSE ]] && [[ $FILTER_INDS_BY_MISSING == TRUE ]] && echo "IDs of indiduals removed in round 4:" >> $FILTSTATS
[[ $SKIP_6 == FALSE ]] && [[ $FILTER_INDS_BY_MISSING == TRUE ]] && cat $FILTFILE.HiMissInds4 >> $FILTSTATS
	
echo -e "\n#### filterVCF_FS6.sh: Filter stats stored in $FILTSTATS"
echo "#### filterVCF_FS6.sh: Printing filter stats file:"
printf "\n"
cat $FILTSTATS

echo -e "\n\n###################################################################"
if [ $SKIP_8 == FALSE ]
then
	echo "#### filterVCF_FS6.sh: Final VCF file (FS6):"
	ls -lh $VCF_FS6.gz
	printf "\n"
	
	echo "#### filterVCF_FS6.sh: VCF file without final round of missing data removal (FS7):"
	ls -lh $VCF_FS7.gz
	printf "\n"
	
	echo "#### filterVCF_FS6.sh: VCF file with no missing data (FS8):"
	ls -lh $VCF_FS8.gz
	printf "\n"
else
	echo "#### filterVCF_FS6.sh: Final VCF file:"
	ls -lh $VCF_OUT_ALT
	printf "\n"
fi

echo "#### filterVCF_FS6.sh: Done with script filterVCF_FS6.sh"
date
