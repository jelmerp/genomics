#!/bin/bash
set -e
set -o pipefail
set -u

################################################################################
#### SET-UP #####
################################################################################

## Software & scripts:
JAVA=/datacommons/yoderlab/programs/java_1.8.0/jre1.8.0_144/bin/java
GATK3=/datacommons/yoderlab/programs/gatk-3.8-0/GenomeAnalysisTK.jar
GATK4_EXC=/datacommons/yoderlab/programs/gatk-4.0.7.0/gatk
BCFTOOLS=/datacommons/yoderlab/programs/bcftools-1.6/bcftools
VCFTOOLS=/dscrhome/rcw27/programs/vcftools/vcftools-master/bin/vcftools
MAWK=/datacommons/yoderlab/programs/mawk-1.3.4-20171017/mawk

SCR_QCVCF=/datacommons/yoderlab/users/jelmer/scripts/qc/qc_vcf.sh

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
MEM=$1
shift
REF=$1
shift
INDFILE=$1
shift
DP_MEAN=$1
shift
MAC=$1
shift
FILTER_INDS_BY_MISSING=$1
shift
SELECT_INDS_BY_FILE=$1
shift
INDSEL_ID=$1
shift

SKIP_1='FALSE'
SKIP_2='FALSE'
SKIP_3='FALSE'
SKIP_4='FALSE'
SKIP_5='FALSE'
SKIP_6='FALSE'
SKIP_7='FALSE'
SKIP_8='FALSE'
SKIP_9='FALSE'
SKIP_10='FALSE'
SKIP_11='FALSE'
SKIP_12='FALSE'

while getopts '123456789tew' flag; do
  case "${flag}" in
    1) SKIP_1='TRUE' ;;
    2) SKIP_2='TRUE' ;;
    3) SKIP_3='TRUE' ;;
    4) SKIP_4='TRUE' ;;
    5) SKIP_5='TRUE' ;;
    6) SKIP_6='TRUE' ;;
    7) SKIP_7='TRUE' ;;
    8) SKIP_8='TRUE' ;;
    9) SKIP_9='TRUE' ;;
    t) SKIP_10='TRUE' ;;
    e) SKIP_11='TRUE' ;;
    w) SKIP_12='TRUE' ;;
    *) error "Unexpected option ${flag}" ;;
  esac
done

## Process variables:
VCF_IN=$IN_DIR/$INPUT_NAME.vcf
[[ $SELECT_INDS_BY_FILE == TRUE ]] && VCF_INDSEL=$IN_DIR/$INPUT_NAME.$INDSEL_ID.indselOnly.vcf.gz
ID=$IN_DIR/$OUTPUT_NAME
VCF_HIGHDEPTH=$IN_DIR/$OUTPUT_NAME.TooHighDepth.vcf
VCF_FS6=$OUT_DIR/$OUTPUT_NAME.FS6.vcf
VCF_FS7=$OUT_DIR/$OUTPUT_NAME.FS7.vcf
VCF_FS8=$IN_DIR/$OUTPUT_NAME.FS8.vcf
[[ $SKIP_10 == TRUE ]] && VCF_OUT_ALT=$IN_DIR/$OUTPUT_NAME.vcf

FILTSTATS=$QC_DIR/filtering/$OUTPUT_NAME.filterstats
FILTFILE=$QC_DIR/filtering/$OUTPUT_NAME

## Create QC dir if needed:
[[ ! -d $QC_DIR/filtering ]] && mkdir -p $QC_DIR/filtering 
## Unzip vcf if needed:
[[ ! -e $VCF_IN ]] && [[ -e $VCF_IN.gz ]] && echo "#### filterVCF_FS6.sh: unzipping input VCF" && gunzip $VCF_IN.gz  
## Report if input file not present:
[[ ! -e $VCF_IN ]] && [[ ! -e $VCF_IN.gz ]] && echo -e "\n\n\n#### filterVCF_FS6.sh: ERROR: CANT FIND INPUT FILE #####\n\n\n"

## Report:
echo -e "\n#####################################################################"
date
echo "#### filterVCF_FS6.sh: Script: filterVCF_FS6.sh"
echo "#### filterVCF_FS6.sh: Input name: $INPUT_NAME"
echo "#### filterVCF_FS6.sh: Output name: $OUTPUT_NAME"
printf "\n"
echo "#### filterVCF_FS6.sh: Source dir: $IN_DIR"
echo "#### filterVCF_FS6.sh: Target dir: $OUT_DIR"
echo "#### filterVCF_FS6.sh: Filter stats dir: $QC_DIR"
echo "#### filterVCF_FS6.sh: Filter stats file: $FILTSTATS"
echo "#### filterVCF_FS6.sh: Assigned memory: $MEM GB"
echo "#### filterVCF_FS6.sh: Reference genome: $REF"
echo "#### filterVCF_FS6.sh: Filter inds using file TRUE/FALSE: $SELECT_INDS_BY_FILE"
echo "#### filterVCF_FS6.sh: Indiv selection ID: $INDSEL_ID"
echo "#### filterVCF_FS6.sh: File with inds to keep: $INDFILE"
echo "#### filterVCF_FS6.sh: Filter inds by missing data: $FILTER_INDS_BY_MISSING"
printf "\n"
[[ $SKIP_4 == FALSE ]] && echo -e "#### filterVCF_FS6.sh: Filtering by minor allele count (MAC)...\n"
echo "#### filterVCF_FS6.sh: Skip step 1 (Select SNPs)...............: $SKIP_1"
echo "#### filterVCF_FS6.sh: Skip step 2 (Annotate with AB)..........: $SKIP_2"
echo "#### filterVCF_FS6.sh: Skip step 3 (Filter by DP, Q)...........: $SKIP_3"
echo "#### filterVCF_FS6.sh: Skip step 4 (MAC).......................: $SKIP_4"
echo "#### filterVCF_FS6.sh: Skip step 5 (Filter by missing data)....: $SKIP_5"
echo "#### filterVCF_FS6.sh: Skip step 6 (Soft-filter GATK filters)..: $SKIP_6"
echo "#### filterVCF_FS6.sh: Skip step 7 (Select biallelic SNPs only): $SKIP_7"
echo "#### filterVCF_FS6.sh: Skip step 8 (Hard-filter GATK filters)..: $SKIP_8"
echo "#### filterVCF_FS6.sh: Skip step 9 (High depth):................ $SKIP_9"
echo "#### filterVCF_FS6.sh: Skip step 10 (Filter by missing data)...: $SKIP_10"
echo "#### filterVCF_FS6.sh: Skip step 11 (File organization)........: $SKIP_11"
echo "#### filterVCF_FS6.sh: Skip step 12 (QC).......................: $SKIP_12"

echo -e "\n#####################################################################"
echo "#### filterVCF_FS6.sh: File ID: $ID"
echo "#### filterVCF_FS6.sh: VCF - in:"
ls -lh $VCF_IN

echo -e "\n#### filterVCF_FS6.sh: VCF-TooHighDepth: $VCF_HIGHDEPTH"
[[ $SKIP_10 == FALSE ]] && echo "#### filterVCF_FS6.sh: VCF - FS6: $VCF_FS6"
[[ $SKIP_10 == FALSE ]] && echo "#### filterVCF_FS6.sh: VCF - FS7: $VCF_FS7"
[[ $SKIP_10 == FALSE ]] && echo "#### filterVCF_FS6.sh: VCF - FS8: $VCF_FS8"
[[ $SKIP_10 == TRUE ]] && echo "#### filterVCF_FS6.sh: VCF - out: $VCF_OUT_ALT"
[[ $SELECT_INDS_BY_FILE == TRUE ]] && echo "#### filterVCF_FS6.sh: VCF - indsel: $VCF_INDSEL"

echo -e "\n#####################################################################"

## Filter settings:
DP_MIN=5
QUAL=20

MAXMISS_GENO_1=0.5
MAXMISS_GENO_2=0.6
MAXMISS_GENO_3=0.7
MAXMISS_GENO_4=0.95

MAXMISS_IND_1=0.9
MAXMISS_IND_2=0.7
MAXMISS_IND_3=0.5
MAXMISS_IND_4=0.25

echo "#### filterVCF_FS6.sh: min DP: $DP_MIN"
echo "#### filterVCF_FS6.sh: min Qual: $QUAL"
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
echo -e "\n###################################################################"


################################################################################
#### STEP 0: PRE-SELECT SAMPLES ####
################################################################################
if [ $SELECT_INDS_BY_FILE == FALSE ]
then
	echo -e "#### filterVCF_FS6.sh: Skipping Step 0: Pre-select samples..."
	VCF_STEP0=$VCF_IN
else
	[[ ! -e $INDFILE ]] && echo -e "\n\n\n#### filterVCF_FS6.sh: ERROR: INDFILE $INDFILE CANNOT BE FOUND\n\n\n"

	echo -e "\n\n###############################################################"
	echo "#### filterVCF_FS6.sh: Step 0: Selecting individuals from file: $INDFILE"
	date
	
	KEEP_COMMAND="--keep $INDFILE"
	VCF_STEP0=$ID.vcf
	echo -e "\n#### filterVCF_FS6.sh: Outputting to file $VCF_STEP0 \n"
	echo -e "\n#### filterVCF_FS6.sh: Keep command: $KEEP_COMMAND"
	echo -e "\n#### filterVCF_FS6.sh: Indfile contents:"
	cat $INDFILE
	
	## Run Vcftools
	$VCFTOOLS --vcf $VCF_IN --recode --recode-INFO-all $KEEP_COMMAND --stdout > $VCF_STEP0
	
	## Report:
	NR_INDS_REQUESTED=$(cat $INDFILE | wc -l)
	NR_INDS_PRESENT=$($BCFTOOLS query -l $VCF_STEP0 | wc -l)
	echo -e "\n#### filterVCF_FS6.sh: Number of individuals requested by indfile: $NR_INDS_REQUESTED"
	echo -e "#### filterVCF_FS6.sh: Number of individuals present in VCF: $NR_INDS_PRESENT \n"
	
	[[ $NR_INDS_REQUESTED != $NR_INDS_PRESENT ]] && \
	echo -e "\n\n\n\n#### filterVCF_FS6.sh: WARNING: NR OF INDS REQUESTED ($NR_INDS_REQUESTED) DOES NOT MATCH NR PRESENT ($NR_INDS_PRESENT) IN VCF\n\n\n\n" 
	
	echo "#### filterVCF_FS6.sh: Saving a copy of individual-selected file..."
	gzip -c $VCF_STEP0 > $VCF_INDSEL
	ls -lh $VCF_INDSEL
	
	echo -e "\n\n###############################################################"
fi


################################################################################
#### STEP 1: SELECT SNPS ONLY #####
################################################################################
if [ $SKIP_1 == TRUE ]
then
	echo -e "#### filterVCF_FS6.sh: Skipping Step 1 (Selecting only SNPS)..."
	VCF_STEP1=$VCF_STEP0
	NVAR_ALLVARS=NA
else
	echo -e "\n\n###############################################################"
	echo -e "#### filterVCF_FS6.sh: Step 1: Selecting only SNPS..."
	date

	VCF_STEP1=$ID.rawSNPs.vcf
	
	## Select SNPs using GATK:
	$JAVA -Xmx${MEM}g -jar $GATK3 -T SelectVariants -R $REF -V $VCF_STEP0 -o $ID.rawSNPs.tmp.vcf -selectType SNP 

	echo -e "\n#### filterVCF_FS6.sh: Removing non-variable SNPs: $NVAR_ALLVARS"
	$VCFTOOLS --vcf $ID.rawSNPs.tmp.vcf --recode --recode-INFO-all --max-non-ref-af 0.99 --min-alleles 2 --stdout > $VCF_STEP1
	
	## Report:
	NVAR_ALLVARS=$(grep -v "##" $VCF_STEP0 | wc -l)
	NVAR_ALLSNPS=$(grep -v "##" $ID.rawSNPs.tmp.vcf | wc -l)
	NVAR_ALLSNPS_VAR=$(grep -v "##" $VCF_STEP1 | wc -l)
	echo -e "\n#### filterVCF_FS6.sh: Number of total variants (SNPs + indels): $NVAR_ALLVARS"
	echo "#### filterVCF_FS6.sh: Number of SNPs prior to filtering: $NVAR_ALLSNPS"
	echo "#### filterVCF_FS6.sh: Number of variable SNPs: $NVAR_ALLSNPS_VAR"
	
	[[ -e $VCF_STEP1 ]] && rm -f $ID.rawSNPs.tmp.vcf
	
	echo -e "\n###############################################################"
fi
echo -e "\n#### filterVCF_FS6.sh: VCF_STEP1 (after step 1): $VCF_STEP1 \n"


################################################################################
#### STEP 2: ANNOTATE SNPS WITH ALLELE BALANCE #####
################################################################################
if [ $SKIP_2 == TRUE ]
then
	echo -e "#### filterVCF_FS6.sh: Skipping Step 2 (Annotating SNPs with Allele Balance statistic)..."
	VCF_STEP2=$VCF_STEP1
else
	echo -e "\n\n###############################################################"
	echo -e "#### filterVCF_FS6.sh: Step 2: Annotating SNPs with Allele Balance statistic..."
	date
	
	VCF_STEP2=$ID.rawSNPs.ABHet.vcf
	
	$JAVA -Xmx${MEM}G -jar $GATK3 -T VariantAnnotator -R $REF -V $VCF_STEP1 -o $VCF_STEP2 -A AlleleBalance
		
	echo -e "\n###############################################################"
fi
echo -e "\n#### filterVCF_FS6.sh: VCF_STEP2 (after step 2): $VCF_STEP2 \n"


################################################################################
#### STEP 3: FILTER BY MINIMUM DEPTH AND QUALITY ####
################################################################################
if [ $SKIP_3 == TRUE ]
then
	echo -e "#### filterVCF_FS6.sh: Skipping Step 2 (filtering by DP and Q)..."
	VCF_STEP3=$VCF_STEP2
else
	echo -e "\n\n###############################################################"
	echo -e "#### filterVCF_FS6.sh: Step 3: filtering genotypes by minDP, meanDP and minQ...\n"
	date
	
	VCF_STEP3=$ID.S3.vcf
	
	NVAR_ALLSNPS=$(grep -v "##" $VCF_STEP2 | wc -l)
	echo "#### filterVCF_FS6.sh: Number of SNPs prior to filtering: $NVAR_ALLSNPS"
	
	## A) Filter by min DP and min Qual: [ALL REMOVED SNPs WILL BE DUE TO QUAL - MINDP FILTER SETS INDIV GENOTYPES TO MISSING]
	$VCFTOOLS --vcf $VCF_STEP2 --recode --recode-INFO-all --minDP $DP_MIN --minQ $QUAL --out $ID.S3a
	
	## B) Filter by min-meanDP:
	$VCFTOOLS --vcf $ID.S3a.recode.vcf --recode --recode-INFO-all --min-meanDP $DP_MEAN --stdout > $VCF_STEP3
	
	## Report:
	NVAR_3A=$(grep -v "##" $ID.S3a.recode.vcf | wc -l)
	NFILT_3A=$(($NVAR_ALLSNPS - $NVAR_3A))
	NVAR_3B=$(grep -v "##" $VCF_STEP3 | wc -l)
	NFILT_3B=$(($NVAR_3A - $NVAR_3B))
	
	printf "\n"
	echo "#### filterVCF_FS6.sh: Number of SNPs filtered by min qual $QUAL: $NFILT_3A"
	echo "#### filterVCF_FS6.sh: Number of SNPs filtered by min mean-DP $DP_MEAN: $NFILT_3B"
	echo "#### filterVCF_FS6.sh: Number of SNPs left after step 3: $NVAR_3B"
	
	echo -e "\n###############################################################"
fi
echo -e "\n#### filterVCF_FS6.sh: VCF_STEP3 (after step 3): $VCF_STEP3  \n"


################################################################################
#### STEP 4: FILTER BY MAC ####
################################################################################
if [ $SKIP_4 == TRUE ]
then
	echo -e "#### filterVCF_FS6.sh: Skipping Step 4 (Filter by MAC)..."
	VCF_STEP4=$VCF_STEP3
else
	echo -e "\n\n###############################################################"
	echo -e "#### filterVCF_FS6.sh: Step 4: Filtering by MAC...."
	date
	
	VCF_STEP4=$ID.S4.vcf
	
	$VCFTOOLS --vcf $VCF_STEP3 --recode --recode-INFO-all --mac $MAC --stdout > $VCF_STEP4
	
	NVAR_3=$(grep -v "##" $VCF_STEP3 | wc -l)
	NVAR_4=$(grep -v "##" $VCF_STEP4 | wc -l)
	NFILT_4=$(($NVAR_3 - $NVAR_4))
	echo -e "\n#### filterVCF_FS6.sh: Number of SNPs filtered by MAC $MAC: $NFILT_4"
	echo "#### filterVCF_FS6.sh: Number of SNPs left after step 4: $NVAR_4"
	echo -e "\n###############################################################"
fi
echo -e "\n#### filterVCF_FS6.sh: VCF_STEP3 (after step 4): $VCF_STEP4 \n"


################################################################################
#### STEP 5: FILTER BY MISSING DATA - FIRST THREE ROUNDS ####
################################################################################

if [ $SKIP_5 == TRUE ]
then
	echo -e "#### filterVCF_FS6.sh: Skipping Step 5 (Filter by missing data - first three rounds)..."
	VCF_STEP5=$VCF_STEP4
else
	echo -e "\n\n###############################################################"
	echo -e "#### filterVCF_FS6.sh: Step 5: filtering genotypes & individuals by missing data in 3 rounds..."
	date
	
	VCF_STEP5=$ID.S5.vcf
	
	## Round 1:
	if [ $FILTER_INDS_BY_MISSING == TRUE ]
	then
		echo -e "\n#### filterVCF_FS6.sh: Filtering genotypes by missing data - round 1...."
		$VCFTOOLS --vcf $VCF_STEP4 --recode --recode-INFO-all --max-non-ref-af 0.99 --min-alleles 2 --max-missing $MAXMISS_GENO_1 \
			--out $ID.S5R1a
		
		echo -e "\n\n#### filterVCF_FS6.sh: Filtering individuals by missing data - round 1...."
		$VCFTOOLS --vcf $ID.S5R1a.recode.vcf --missing-indv --out $FILTFILE.round1 ## Get amount of missing data per indv
		tail -n +2 $FILTFILE.round1.imiss | awk -v var="$MAXMISS_IND_1" '$5 > var' | cut -f1 > $FILTFILE.HiMissInds1 ## Get list of inds with too much missing data
		$VCFTOOLS --vcf $ID.S5R1a.recode.vcf --recode --recode-INFO-all --remove $FILTFILE.HiMissInds1 --out $ID.S5R1b ## Remove inds with too much missing data
		
		## Round 2:
		echo -e "\n\n#### filterVCF_FS6.sh: Filtering genotypes by missing data - round 2...."
		$VCFTOOLS --vcf $ID.S5R1b.recode.vcf --recode --recode-INFO-all --max-non-ref-af 0.99 --min-alleles 2 --max-missing $MAXMISS_GENO_2 \
			--out $ID.S5R2a
		
		echo -e "\n\n#### filterVCF_FS6.sh: Filtering individuals by missing data - round 2...."
		$VCFTOOLS --vcf $ID.S5R2a.recode.vcf --missing-indv --out $FILTFILE.round2 ## Get amount of missing data per indv
		tail -n +2 $FILTFILE.round2.imiss | awk -v var="$MAXMISS_IND_2" '$5 > var' | cut -f1 > $FILTFILE.HiMissInds2 ## Get list of inds with too much missing data
		$VCFTOOLS --vcf $ID.S5R2a.recode.vcf --recode --recode-INFO-all --remove $FILTFILE.HiMissInds2 --out $ID.S5R2b ## Remove inds with too much missing data
		
		## Round 3:
		echo -e "\n\n#### filterVCF_FS6.sh: Filtering genotypes by missing data - round 3...."
		$VCFTOOLS --vcf $ID.S5R2b.recode.vcf --recode --recode-INFO-all --max-non-ref-af 0.99 --min-alleles 2 --max-missing $MAXMISS_GENO_3 \
			--out $ID.S5R3a 
		
		echo -e "\n\n#### filterVCF_FS6.sh: Filtering individuals by missing data - round 3...."
		$VCFTOOLS --vcf $ID.S5R3a.recode.vcf --missing-indv --out $FILTFILE.round3 ## Get amount of missing data per indv
		tail -n +2 $FILTFILE.round3.imiss | awk -v var="$MAXMISS_IND_3" '$5 > var' | cut -f1 > $FILTFILE.HiMissInds3 ## Get list of inds with too much missing data
		$VCFTOOLS --vcf $ID.S5R3a.recode.vcf --recode --recode-INFO-all --remove $FILTFILE.HiMissInds3 --out $ID.S5R3b ## Remove inds with too much missing data
		
		mv $ID.S5R3b.recode.vcf $VCF_STEP5
		
		## Report:
		NVAR_S4=$(grep -v "##" $VCF_STEP4 | wc -l)
		NVAR_S5R1=$(grep -v "##" $ID.S5R1a.recode.vcf | wc -l)
		NVAR_S5R2=$(grep -v "##" $ID.S5R2a.recode.vcf | wc -l)
		NVAR_S5R3=$(grep -v "##" $ID.S5R3a.recode.vcf | wc -l)
		
		NFILT_S5R1=$(($NVAR_S4 - $NVAR_S5R1))
		NFILT_S5R2=$(($NVAR_S5R1 - $NVAR_S5R2))
		NFILT_S5R3=$(($NVAR_S5R2 - $NVAR_S5R3))
		
		NIND_EXCL_S5R1=$(cat $FILTFILE.HiMissInds1 | wc -l)
		NIND_EXCL_S5R2=$(cat $FILTFILE.HiMissInds2 | wc -l)
		NIND_EXCL_S5R3=$(cat $FILTFILE.HiMissInds3 | wc -l)
		
		NIND_ALL=$(cat $VCF_STEP4 | awk '{if ($1 == "#CHROM"){print NF-9; exit}}')
		NIND_S5=$(cat $VCF_STEP5 | awk '{if ($1 == "#CHROM"){print NF-9; exit}}')
		
		echo -e "\n#### filterVCF_FS6.sh: Number of individuals prior to filtering by missing data: $NIND_ALL"
		echo -e "#### filterVCF_FS6.sh: Number of individuals filtered in round 1: $NIND_EXCL_S5R1"
		echo -e "#### filterVCF_FS6.sh: Number of individuals filtered in round 2: $NIND_EXCL_S5R2"
		echo -e "#### filterVCF_FS6.sh: Number of individuals filtered in round 3: $NIND_EXCL_S5R3"
		echo -e "#### filterVCF_FS6.sh: Number of individuals left after ind-filtering: $NIND_S5"
		echo -e "\n#### filterVCF_FS6.sh: Number of SNPs prior to filtering by missing data: $NVAR_S4"
		echo -e "#### filterVCF_FS6.sh: Number of SNPs filtered in round 1: $NFILT_S5R1"
		echo -e "#### filterVCF_FS6.sh: Number of SNPs filtered in round 2: $NFILT_S5R2"
		echo -e "#### filterVCF_FS6.sh: Number of SNPs filtered in round 3: $NFILT_S5R3"
	fi
	
	if [ $FILTER_INDS_BY_MISSING == FALSE ]
	then
		echo -e "\n\n#### filterVCF_FS6.sh: ONLY FILTERING BY MISSING DATA AT GENOTYPE LEVEL - NO INDS WILL BE REMOVED...."
		
		echo -e "\n#### filterVCF_FS6.sh: Filtering genotypes by missing data - all in a single round...."
		$VCFTOOLS --vcf $VCF_STEP4 --recode --recode-INFO-all --max-non-ref-af 0.99 --min-alleles 2 --max-missing $MAXMISS_GENO_3 \
			--out $ID.S5R3b
			
		mv $ID.S5R3b.recode.vcf $VCF_STEP5
		
		NVAR_S4=$(grep -v "##" $VCF_STEP4 | wc -l)
		NVAR_S5=$(grep -v "##" $VCF_STEP5 | wc -l)
		NFILT_S5=$(($NVAR_S4 - $NVAR_S5))
		echo -e "\n#### filterVCF_FS6.sh: Number of SNPs prior to filtering by missing data: $NVAR_S4"
		echo -e "#### filterVCF_FS6.sh: Number of SNPs filtered due to missing data: $NFILT_S5"
		echo -e "#### filterVCF_FS6.sh: Number of SNPs left: $NVAR_S5"
	fi
		
	[[ -e $VCF_STEP5 ]] && rm -f $ID*recode* # Remove intermediate files
	
	echo -e "\n###############################################################"
fi
echo -e "\n#### filterVCF_FS6.sh: VCF_STEP5 (after step 5): $VCF_STEP5 \n"


################################################################################
#### STEP 6: SOFT-FILTER SNPS WITH GATK ####
################################################################################
if [ $SKIP_6 == TRUE ]
then
	echo -e "#### filterVCF_FS6.sh: Skipping Step 6 (soft-filter SNPs)..."
	VCF_STEP6=$VCF_STEP5
else
	echo -e "\n\n###############################################################"
	echo -e "#### filterVCF_FS6.sh: Step 6: soft-filter SNPS (using GATK)...\n"
	date
	
	VCF_STEP6=$ID.S6.vcf
	
	## Soft-filter SNPs using GATK:
	$GATK4_EXC --java-options "-Xmx${MEM}g" VariantFiltration \
		-R $REF \
		-V $VCF_STEP5 \
		-O $VCF_STEP6 \
		--filter-expression "QD < 2.0" --filter-name "QD_lt2" \
		--filter-expression "FS > 60.0" --filter-name "FS_gt60" \
		--filter-expression "MQ < 40.0" --filter-name "MQ_lt40" \
		--filter-expression "MQRankSum < -12.5" --filter-name "MQRankSum_ltm12.5" \
		--filter-expression "ReadPosRankSum < -8.0" --filter-name "ReadPosRankSum_ltm8" \
		--filter-expression "ABHet > 0.01 && ABHet < 0.2 || ABHet > 0.8 && ABHet < 0.99" --filter-name "ABHet_filt"
		#--filter-expression "SOR > 3.0" --filter-name "SOR_gt3" \ # SOR removed for radseq
	
	NFILT_QD=$(grep "QD_lt2" $VCF_STEP6 | wc -l)
	NFILT_FS=$(grep "FS_gt60" $VCF_STEP6 | wc -l)
	#NFILT_SOR=$(grep "SOR_gt3" $VCF_STEP6 | wc -l)
	NFILT_MQ=$(grep "MQ_lt40" $VCF_STEP6 | wc -l)
	NFILT_MQR=$(grep "MQRankSum_ltm12" $VCF_STEP6 | wc -l)
	NFILT_READPOS=$(grep "ReadPosRankSum_ltm8" $VCF_STEP6 | wc -l)
	NFILT_ABHET=$(grep "ABHet_filt" $VCF_STEP6 | wc -l)
	
	echo -e "\n#### filterVCF_FS6.sh: Nr of SNPs filtered by QD_lt2: $NFILT_QD"
	echo "#### filterVCF_FS6.sh: Nr of SNPs filtered by FS_gt60: $NFILT_FS"
	#echo "#### filterVCF_FS6.sh: Nr of SNPs filtered by SOR_gt3: $NFILT_SOR"
	echo "#### filterVCF_FS6.sh: Nr of SNPs filtered by MQ_lt40: $NFILT_MQ"
	echo "#### filterVCF_FS6.sh: Nr of SNPs filtered by MQRankSum_ltm12: $NFILT_MQR"
	echo "#### filterVCF_FS6.sh: Nr of SNPs filtered by ReadPosRankSum_ltm8: $NFILT_READPOS"
	echo "#### filterVCF_FS6.sh: Nr of SNPs filtered by ABHet_filt: $NFILT_ABHET"
	echo -e "\n###############################################################"
fi

echo -e "\n#### filterVCF_FS6.sh: VCF_STEP6 (after step 6): $VCF_STEP6 \n"


################################################################################
#### filterVCF_FS6.sh: STEP 7: SELECT BIALLELIC SNPS ONLY ####
################################################################################
if [ $SKIP_7 == TRUE ]
then
	echo -e "#### filterVCF_FS6.sh: Skipping Step 7 (filter to biallelic)..."
	VCF_STEP7=$VCF_STEP6
else
	echo -e "\n\n###############################################################"
	echo -e "#### filterVCF_FS6.sh: Step 7: filter SNPS to biallelic only (using bcftools)..."
	date
	
	VCF_STEP7=$ID.S7.vcf

	## Filter using bcftools:
	$BCFTOOLS view -m2 -M2 -v snps $VCF_STEP6 -O v > $VCF_STEP7
	
	## Report:
	NVAR_S6=$(grep -v "##" $VCF_STEP6 | wc -l)
	NVAR_S7=$(zgrep -v "##" $VCF_STEP7 | wc -l)
	NFILT_S7=$(($NVAR_S6 - $NVAR_S7))
	
	echo -e "\n#### filterVCF_FS6.sh: Nr of SNPs filtered due to not being biallelic: $NFILT_S7"
	echo "#### filterVCF_FS6.sh: Number of biallelic SNPs: $NVAR_S7"
	echo -e "\n###############################################################"
fi
echo -e "\n#### filterVCF_FS6.sh: VCF_STEP7 (after step 7): $VCF_STEP7 \n"


################################################################################
#### STEP 8: HARD-FILTER GATK-FILTERS WITH VCFTOOLS ####
################################################################################
if [ $SKIP_8 == TRUE ]
then
	echo -e "#### filterVCF_FS6.sh: Skipping Step 8 (hard-filter gatk-filters with vcftools)..."
	VCF_STEP8=$VCF_STEP7
else
	echo -e "\n\n###############################################################"
	echo -e "#### filterVCF_FS6.sh: Step 8: Hard-filter -- remove SNPS with filtered status (using vcftools)...\n"
	date
	
	VCF_STEP8=$ID.S8.vcf
	
	## Run vcftools:
	$VCFTOOLS --vcf $VCF_STEP7 --remove-filtered-all --max-non-ref-af 0.99 --min-alleles 2 \
		--recode --recode-INFO-all --stdout > $VCF_STEP8
	
	## Report:
	NVAR_S8=$(grep -v "##" $VCF_STEP8 | wc -l)
	NFILT_S8=$(($NVAR_S7 - $NVAR_S8))
	
	echo -e "\n#### filterVCF_FS6.sh: Total number of SNPs filtered by GATK filtering: $NFILT_S8"
	echo "#### filterVCF_FS6.sh: Number of SNPs after GATK filtering: $NVAR_S8"
	echo -e "\n###############################################################"
fi
echo -e "\n#### filterVCF_FS6.sh: VCF_STEP8 (after step 8): $VCF_STEP8 \n"


################################################################################
#### STEP 9: FILTER FOR QUAL/DEPTH RATIO AND MAX DEPTH ####
################################################################################
if [ $SKIP_9 == TRUE ]
then
	echo -e "#### filterVCF_FS6.sh: Skipping Step 9..."
	VCF_STEP9=$VCF_STEP8
else
	echo -e "\n\n###############################################################"
	echo -e "#### filterVCF_FS6.sh: Step 9: Filter for high depth...\n"
	date
	
	VCF=$VCF_STEP8
	VCF_STEP9=$ID.S9.vcf
	
	## Create a file with the original site depth and qual for each locus:
	cut -f8 $VCF | grep -oe "DP=[0-9]*" | sed -s 's/DP=//g' > $FILTFILE.depth
	$MAWK '!/#/' $VCF | cut -f1,2,6 > $FILTFILE.loci.qual
	
	## Calculate the average depth and standard deviation:
	DEPTH_MEAN=$($MAWK '{ sum += $VCF; n++ } END { if (n > 0) print sum / n; }' $FILTFILE.depth | sed 's/,/\./')
	DEPTH_SD=$($MAWK '{delta = $VCF - avg; avg += delta / NR; mean2 += delta * ($VCF - avg); } END { print sqrt(mean2 / NR); }' $FILTFILE.depth | sed 's/,/\./')
	DEPTH_HI=$(perl -e "print int("$DEPTH_MEAN") + int("$DEPTH_SD") + int("$DEPTH_SD")" )
	
	## Filter loci above the mean depth + 1 standard deviation that have quality scores that are less than 2*DEPTH:
	# paste $FILTFILE.loci.qual $FILTFILE.depth | $MAWK -v x=$HIDEPTH '$4 > x'| $MAWK '$3 < 2 * $4' > $FILTFILE.lowQDloci
	# NVAR_LOWQD=$(cat $FILTFILE.lowQDloci | wc -l)
	
	## Recalculate site depth when lowQDloci are not included:
	# $VCFTOOLS --vcf $VCF --exclude-positions $FILTFILE.lowQDloci --site-depth --out $FILTFILE
	# $VCFTOOLS --vcf $VCF --site-depth --out $FILTFILE
	# cut -f3 $FILTFILE.ldepth > $FILTFILE.site.depth
	
	## Calculate number of individuals in VCF file:
	NR_INDS=$($MAWK '/#/' $VCF | tail -1 | wc -w)
	NR_INDS=$(($NR_INDS - 9))
	
	## Calculate a max mean depth cutoff to use for filtering:
	# MAXDEPTH_SUM=$($MAWK '!/SUM/' $FILTFILE.site.depth | sort -rn | perl -e '$d=.05;@l=<>;print $l[int($d*$#l)]' ) # 95% cut-off
	MAXDEPTH=$(perl -e "print int($DEPTH_HI / $NR_INDS)")
	MEANDEPTH=$(perl -e "print int($DEPTH_MEAN / $NR_INDS)")
	
	## Combine all filters to create a final filtered VCF file:
	$VCFTOOLS --vcf $VCF --max-meanDP $MAXDEPTH --recode --recode-INFO-all --stdout > $VCF_STEP9
	
	## Save a separate file with loci with too high depth:
	$VCFTOOLS --vcf $VCF --min-meanDP $MAXDEPTH --recode --recode-INFO-all --stdout > $VCF_HIGHDEPTH
	
	# --exclude-positions $FILTFILE.lowQDloci # removed this: put back to reinstate QD filter
		
	## Report:
	NVAR_S7=$($MAWK '!/#/' $VCF | wc -l)
	NVAR_S9=$(grep -v "##" $VCF_STEP9 | wc -l)
	NFILT_S9=$(($NVAR_S8 - $NVAR_S9))
	# NFILT_MAXDEPTH=$(($NFILT_S9 - $NVAR_LOWQD))
	echo -e "\n#### filterVCF_FS6.sh: Number of SNPs filtered based on maximum mean depth: $NFILT_S9"
	echo "#### filterVCF_FS6.sh: Mean depth: $MEANDEPTH"
	echo "#### filterVCF_FS6.sh: Maximum mean depth prior to dividing by nr of inds: $DEPTH_HI"
	echo "#### filterVCF_FS6.sh: Nr of inds in VCF: $NR_INDS"
	echo "#### filterVCF_FS6.sh: Maximum mean depth cutoff is: $MAXDEPTH"
	# echo "#### filterVCF_FS6.sh: Number of SNPs filtered based on combination of high depth and lower than 2*DEPTH quality score: $NVAR_LOWQD"
	echo -e "\n###############################################################"
fi


################################################################################
#### STEP 10: FILTER BY MISSING DATA - FINAL ROUND #####
################################################################################
if [ $SKIP_10 == TRUE ]
then
	echo -e "#### filterVCF_FS6.sh: Skipping Step 10..."
	VCF_STEP10=$VCF_STEP9
else
	echo -e "\n\n###############################################################"
	echo -e "#### filterVCF_FS6.sh: Step 10: filtering genotypes & individuals by missing data, again..."
	date
	
	VCF_STEP10=$ID.FS6.vcf
	
	if [ $FILTER_INDS_BY_MISSING == TRUE ]
	then
		## Filter individuals:
		echo -e "\n\n#### filterVCF_FS6.sh: Filtering individuals by missing data...."
		$VCFTOOLS --vcf $VCF_STEP9 --missing-indv --out $FILTFILE.round4 ## Get amount of missing data per indv
		
		tail -n +2 $FILTFILE.round4.imiss | awk -v var="$MAXMISS_IND_4" '$5 > var' | cut -f1 > $FILTFILE.HiMissInds4 ## Get list of inds with too much missing data
		
		$VCFTOOLS --vcf $VCF_STEP9 --remove $FILTFILE.HiMissInds4 --recode --recode-INFO-all --out $ID.S10a ## Remove inds with too much missing data
		
		## Report:
		NIND_EXCL_S10=$(cat $FILTFILE.HiMissInds4 | wc -l)
		NIND_S10=$(cat $ID.S10a.recode.vcf | awk '{if ($1 == "#CHROM"){print NF-9; exit}}')
		echo -e "\n#### filterVCF_FS6.sh: Number of individuals filtered in round 4: $NIND_EXCL_S10"
		echo -e "#### filterVCF_FS6.sh: Number of individuals left after round 4 ind-filtering: $NIND_S10"
	fi
	
	[[ $FILTER_INDS_BY_MISSING == FALSE ]] && echo "Skipping filtering by inds..." && cp $VCF_STEP9 $ID.S10a.recode.vcf
	
	## Filter genotypes:
	echo -e "\n#### filterVCF_FS6.sh: Filtering genotypes by missing data..."
	$VCFTOOLS --vcf $ID.S10a.recode.vcf \
		--recode --recode-INFO-all --max-non-ref-af 0.99 --min-alleles 2 --max-missing $MAXMISS_GENO_4 \
		--stdout > $VCF_STEP10
	
	## Report:
	NVAR_S10=$(zgrep -v "##" $VCF_STEP10 | wc -l)
	NFILT_S10=$(($NVAR_S9 - $NVAR_S10))
	echo -e "\n#### filterVCF_FS6.sh: Number of SNPs filtered in round 4: $NFILT_S10"
	echo -e "#### filterVCF_FS6.sh: Number of SNPs left after round 4 geno-filtering: $NVAR_S10"
	
	## Filter genotypes, allowing for NO missing data:
	echo -e "\n#### filterVCF_FS6.sh: Filtering genotypes by missing data - allowing for no missing data..."
	$VCFTOOLS --vcf $VCF_STEP9 \
		--recode --recode-INFO-all --max-non-ref-af 0.99 --min-alleles 2 --max-missing 1 \
		--stdout | gzip > $ID.noMiss.vcf.gz
	
	NVAR_NOMISS=$(zgrep -v "##" $ID.noMiss.vcf.gz | wc -l)
	NFILT_NOMISS=$(($NVAR_S10 - $NVAR_NOMISS))
	echo -e "\n#### filterVCF_FS6.sh: Number of SNPs filtered when not allowing missing data: $NFILT_NOMISS"
	echo -e "#### filterVCF_FS6.sh: Number of SNPs left without missing data: $NVAR_NOMISS"
	echo -e "\n\n###############################################################"
fi


################################################################################
#### STEP 11: CP, GZIP & RM FILES ####
################################################################################
echo -e "\n\n###################################################################"
echo -e "#### filterVCF_FS6.sh: Step 11: Organize files..."
	
if [ $SKIP_10 == FALSE ]
then
	## FS6 file (final file):
	gzip -f $VCF_STEP10
	mv $VCF_STEP10.gz $VCF_FS6.gz
	
	## FS7 file (minus last missing data filtering step):
	mv $VCF_STEP9 $VCF_FS7
	gzip -c $VCF_FS7 > $VCF_FS7.gz
	rm $VCF_FS7
	
	## FS8 file (no missing data):
	mv $ID.noMiss.vcf.gz $VCF_FS8.gz
else
	## Final VCF file:
	mv $VCF_STEP10 $VCF_OUT_ALT
	gzip $VCF_OUT_ALT
fi

## Remove intermediate files:
echo -e "\n#### filterVCF_FS6.sh: Gzipping and removing intermediate VCFs & tmp files..."
[[ -e $ID.commonsteps.vcf ]] && echo "#### filterVCF_FS6.sh: Gzipping $ID.commonsteps.vcf..." && gzip -f $ID.commonsteps.vcf
[[ -e $ID.rawSNPs.ABHet.vcf ]] && echo -e "#### filterVCF_FS6.sh: Gzipping $ID.rawSNPs.ABHet.vcf..." && gzip -f $ID.rawSNPs.ABHet.vcf
[[ -e $ID.rawSNPs.ABHet.vcf.gz ]] && rm -f $ID.rawSNPs.vcf
[[ -e $ID.rawvariants.vcf ]] && echo "#### filterVCF_FS6.sh: Gzipping $ID.rawvariants.vcf..." && gzip -f $ID.rawvariants.vcf
[[ -e $ID.S3.vcf ]] && echo "#### filterVCF_FS6.sh: Gzipping $ID.S3.vcf..." && gzip -f $ID.S3.vcf
[[ -e $VCF_HIGHDEPTH ]] && echo "#### filterVCF_FS6.sh: Gzipping $VCF_HIGHDEPTH..." && gzip -f $VCF_HIGHDEPTH
rm -f $ID.S4*vcf $ID.S5*vcf $ID.S6*vcf $ID*S7*vcf $ID*S8*vcf $ID*S9*
rm -f $ID*idx
rm -f $ID*log
rm -f $ID*recode*
rm -f $ID*tmp*
rm -f out.log
rm -f $QC_DIR/filtering/*$OUTPUT_NAME*depth
rm -f $QC_DIR/filtering/*$OUTPUT_NAME*qual
rm -f $QC_DIR/filtering/*$OUTPUT_NAME*QD*
echo -e "\n\n###################################################################"


################################################################################
#### STEP 12: QC ####
################################################################################
if [ $SKIP_12 == TRUE ]
then
	echo -e "#### filterVCF_FS6.sh: Skipping Step 12 (QC)..."
else
	echo -e "\n\n###############################################################"
	echo -e "#### filterVCF_FS6.sh: Step 12: Calling QC scripts..."
	
	RUN_BCF=FALSE
	RUN_BCF_BY_IND=FALSE
	RUN_VCF_SITESTATS=FALSE
	
	$SCR_QCVCF $OUTPUT_NAME.FS6 $OUT_DIR $QC_DIR $RUN_BCF $RUN_BCF_BY_IND $RUN_VCF_SITESTATS
	$SCR_QCVCF $OUTPUT_NAME.FS7 $OUT_DIR $QC_DIR $RUN_BCF $RUN_BCF_BY_IND
fi


################################################################################
#### REPORT ####
################################################################################
echo -e "\n\n###################################################################"
echo -e "#### filterVCF_FS6.sh: Giving final stats:"

[[ $SKIP_11 == FALSE && $SKIP_3 == FALSE ]] && NFILT_TOTAL=$(($NVAR_ALLSNPS - $NFILT_S9))
[[ $SKIP_11 == FALSE && $SKIP_3 == FALSE ]] && echo -e "#### filterVCF_FS6.sh: Total number of sites filtered: $NFILT_TOTAL"
[[ $SKIP_11 == FALSE ]] && echo -e "#### filterVCF_FS6.sh: Remaining SNPs before last round of missing data removal: $NVAR_S9"
[[ $SKIP_11 == FALSE ]] && [[ $SKIP_10 == FALSE ]] && echo -e "#### filterVCF_FS6.sh: Remaining SNPs after all filtering: $NVAR_S10"

## Write to filterstats file:
echo "$OUTPUT_NAME" > $FILTSTATS
[[ $SKIP_1 == FALSE ]] && echo "Nr of total variants (SNPs + indels): $NVAR_ALLVARS" >> $FILTSTATS
[[ $SKIP_1 == FALSE ]] && echo "Nr of SNPs - prior to filtering: $NVAR_ALLSNPS" >> $FILTSTATS
[[ $SKIP_1 == FALSE ]] && echo "Nr of variable SNPs - prior to filtering: $NVAR_ALLSNPS_VAR" >> $FILTSTATS
[[ $SKIP_7 == FALSE ]] && echo "Nr of SNPs - biallelic: $NVAR_S7" >> $FILTSTATS
[[ $SKIP_8 == FALSE ]] && echo "Nr of SNPs - after GATK filtering: $NVAR_S8" >> $FILTSTATS
[[ $SKIP_11 == FALSE ]] && echo "Nr of SNPs - before last round of missing data removal (FS7): $NVAR_S9" >> $FILTSTATS
[[ $SKIP_11 == FALSE ]] && echo "Nr of SNPs - after all filtering (FS6): $NVAR_S10" >> $FILTSTATS
[[ $SKIP_11 == FALSE ]] && echo "Nr of SNPs - no missing data (FS8): $NVAR_NOMISS" >> $FILTSTATS
[[ $SKIP_11 == FALSE ]] && printf "\n"
[[ $SKIP_5 == FALSE ]] && echo "Nr of inds - prior to filtering: $NIND_ALL" >> $FILTSTATS
[[ $SKIP_5 == FALSE ]] && [[ $FILTER_INDS_BY_MISSING == TRUE ]] && echo "Nr of inds filtered - missing data round 1: $NIND_EXCL_S5R1" >> $FILTSTATS
[[ $SKIP_5 == FALSE ]] && [[ $FILTER_INDS_BY_MISSING == TRUE ]] && echo "Nr of inds filtered - missing data round 2: $NIND_EXCL_S5R2" >> $FILTSTATS
[[ $SKIP_5 == FALSE ]] && [[ $FILTER_INDS_BY_MISSING == TRUE ]] && echo "Nr of inds filtered - missing data round 3: $NIND_EXCL_S5R3" >> $FILTSTATS
[[ $SKIP_5 == FALSE ]] && [[ $FILTER_INDS_BY_MISSING == TRUE ]] && echo "Nr of inds filtered - missing data round 4: $NIND_EXCL_S10" >> $FILTSTATS
[[ $SKIP_11 == FALSE ]] && [[ $FILTER_INDS_BY_MISSING == TRUE ]] && echo "Nr of inds - after all 4 rounds of ind-filtering: $NIND_S10" >> $FILTSTATS
[[ $SKIP_11 == FALSE ]] && printf "\n"
[[ $SKIP_11 == FALSE ]] && echo "Maximum mean depth cutoff is: $MAXDEPTH" >> $FILTSTATS
[[ $SKIP_11 == FALSE ]] && printf "\n"
[[ $SKIP_7 == FALSE ]] && echo "Nr of SNPs filtered - not biallelic: $NFILT_S7" >> $FILTSTATS
[[ $SKIP_3 == FALSE ]] && echo "Nr of SNPs filtered - min qual $QUAL: $NFILT_3A" >> $FILTSTATS
[[ $SKIP_3 == FALSE ]] && echo "Nr of SNPs filtered - min mean-DP $DP_MEAN: $NFILT_3B" >> $FILTSTATS
[[ $SKIP_4 == FALSE ]] && echo "Nr of SNPs filtered - MAC $MAC: $NFILT_4" >> $FILTSTATS
[[ $SKIP_5 == FALSE ]] && [[ $FILTER_INDS_BY_MISSING == TRUE ]] && echo "Nr of SNPs filtered - missing data round 1: $NFILT_S5R1" >> $FILTSTATS
[[ $SKIP_5 == FALSE ]] && [[ $FILTER_INDS_BY_MISSING == TRUE ]] && echo "Nr of SNPs filtered - missing data round 2: $NFILT_S5R2" >> $FILTSTATS
[[ $SKIP_5 == FALSE ]] && [[ $FILTER_INDS_BY_MISSING == TRUE ]] && echo "Nr of SNPs filtered - missing data round 3: $NFILT_S5R3" >> $FILTSTATS
[[ $SKIP_5 == FALSE ]] && [[ $FILTER_INDS_BY_MISSING == TRUE ]] && echo "Nr of SNPs filtered - missing data: $NFILT_S4" >> $FILTSTATS
[[ $SKIP_5 == FALSE ]] && [[ $FILTER_INDS_BY_MISSING == FALSE ]] && echo "Nr of SNPs filtered - missing data round 4: $NFILT_S10" >> $FILTSTATS
[[ $SKIP_6 == FALSE ]] && echo "Nr of SNPs filtered - QD_lt2: $NFILT_QD" >> $FILTSTATS
[[ $SKIP_6 == FALSE ]] && echo "Nr of SNPs filtered - FS_gt60: $NFILT_FS" >> $FILTSTATS
[[ $SKIP_6 == FALSE ]] && echo "Nr of SNPs filtered - MQ_lt40: $NFILT_MQ" >> $FILTSTATS
[[ $SKIP_6 == FALSE ]] && echo "Nr of SNPs filtered - MQRankSum_ltm12: $NFILT_MQR" >> $FILTSTATS
[[ $SKIP_6 == FALSE ]] && echo "Nr of SNPs filtered - ReadPosRankSum_ltm8: $NFILT_READPOS" >> $FILTSTATS
[[ $SKIP_6 == FALSE ]] && echo "Nr of SNPs filtered - ABHet_filt: $NFILT_ABHET" >> $FILTSTATS
#[[ $SKIP_9 == FALSE ]] && echo "Nr of SNPs filtered - combination of high depth and lower than 2*DEPTH quality score: $NVAR_LOWQD" >> $FILTSTATS
[[ $SKIP_9 == FALSE ]] && echo "Nr of SNPs filtered - maximum mean depth: $NFILT_S9" >> $FILTSTATS
[[ $SKIP_9 == FALSE && $SKIP_2 == FALSE ]] && echo "Total number of sites filtered: $NFILT_TOTAL" >> $FILTSTATS
[[ $SKIP_9 == FALSE ]] && echo "(Nr of SNPs filtered - not allowing missing data: $NFILT_NOMISS)" >> $FILTSTATS
[[ $SKIP_9 == FALSE ]] && printf "\n"
[[ $SKIP_5 == FALSE ]] && [[ $FILTER_INDS_BY_MISSING == TRUE ]] && echo "IDs of indiduals removed in round 1:" >> $FILTSTATS
[[ $SKIP_5 == FALSE ]] && [[ $FILTER_INDS_BY_MISSING == TRUE ]] && cat $FILTFILE.HiMissInds1 >> $FILTSTATS
[[ $SKIP_5 == FALSE ]] && [[ $FILTER_INDS_BY_MISSING == TRUE ]] && echo "IDs of indiduals removed in round 2:" >> $FILTSTATS
[[ $SKIP_5 == FALSE ]] && [[ $FILTER_INDS_BY_MISSING == TRUE ]] && cat $FILTFILE.HiMissInds2 >> $FILTSTATS
[[ $SKIP_5 == FALSE ]] && [[ $FILTER_INDS_BY_MISSING == TRUE ]] && echo "IDs of indiduals removed in round 3:" >> $FILTSTATS
[[ $SKIP_5 == FALSE ]] && [[ $FILTER_INDS_BY_MISSING == TRUE ]] && cat $FILTFILE.HiMissInds3 >> $FILTSTATS
[[ $SKIP_10 == FALSE ]] && [[ $FILTER_INDS_BY_MISSING == TRUE ]] && echo "IDs of indiduals removed in round 4:" >> $FILTSTATS
[[ $SKIP_10 == FALSE ]] && [[ $FILTER_INDS_BY_MISSING == TRUE ]] && cat $FILTFILE.HiMissInds4 >> $FILTSTATS
	
echo -e "\n#### filterVCF_FS6.sh: Filter stats stored in $FILTSTATS"
echo -e "#### filterVCF_FS6.sh: Printing filter stats file: \n"
cat $FILTSTATS

echo -e "\n\n###################################################################"
if [ $SKIP_10 == FALSE ]
then
	echo "#### filterVCF_FS6.sh: Final VCF file (FS6):"
	ls -lh $VCF_FS6.gz
	
	echo -e "\n#### filterVCF_FS6.sh: VCF file without final round of missing data removal (FS7):"
	ls -lh $VCF_FS7.gz
	
	echo -e "\n#### filterVCF_FS6.sh: VCF file with no missing data (FS8):"
	ls -lh $VCF_FS8.gz
else
	echo -e "\n#### filterVCF_FS6.sh: Final VCF file:"
	ls -lh $VCF_OUT_ALT.gz
fi

echo -e "\n#### filterVCF_FS6.sh: Done with script."
date
