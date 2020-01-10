#!/bin/bash
set -e
set -o pipefail
set -u

################################################################################
#### SET-UP ####
################################################################################
## Scripts:
SCRIPT_FLIP_PERL=/datacommons/yoderlab/users/jelmer/scripts/geno/fastq/flip_trim_sbfI_170601.pl
SCRIPT_FLIP_BASH=/datacommons/yoderlab/users/jelmer/scripts/geno/fastq/flipreads.sh
SCRIPT_DEMULT=/datacommons/yoderlab/users/jelmer/scripts/geno/fastq/demultiplex.sh
SCRIPT_DEDUP_TRIM=/datacommons/yoderlab/users/jelmer/scripts/geno/fastq/dedup.trim.sh
SCRIPT_QC_FASTQ=/datacommons/yoderlab/users/jelmer/scripts/qc/qc_fastq.sh
SCRIPT_STATS_FASTQ=/datacommons/yoderlab/users/jelmer/scripts/qc/qc_fastq.stats.sh
SCRIPT_CHECKBARCODES=/datacommons/yoderlab/users/jelmer/scripts/geno/fastq/checkbarcodes.sh

## Hardcoded variables:
ADAPTER_FILE=/datacommons/yoderlab/programs/Trimmomatic-0.36/adapters/all.fa # For trimmomatic
NCORES_DEDUP=4
CUTSITE="TGCAGG" # sbfI enzyme

## Defaults:
SKIP_QC='FALSE'
SKIP_FLIP='FALSE'
SKIP_DEMULT='FALSE'
SKIP_DEDUP='FALSE'
SKIP_TRIM='FALSE'
SKIP_STATS='FALSE'

## Command-line args:
LIBRARY_ID=$1
shift
DIR_RAW=$1
shift
DIR_FLIPPED=$1
shift
DIR_DEMULT=$1
shift
DIR_FINAL=$1
shift
DIR_STATS=$1
shift
BARCODE_LIST_FILE=$1
shift
BARCODE_TABLE_FILE=$1
shift

while getopts 'QFMDST' flag; do
  case "${flag}" in
    Q) SKIP_QC='TRUE' ;;
    F) SKIP_FLIP='TRUE' ;;
    M) SKIP_DEMULT='TRUE' ;;
    D) SKIP_DEDUP='TRUE' ;;
    T) SKIP_TRIM='TRUE' ;;
    S) SKIP_STATS='TRUE' ;;
    *) error "Unexpected option ${flag}" ;;
  esac
done

## Report:
date
echo "#### fastq.process_pip.sh: Library ID: $LIBRARY_ID"
echo "#### fastq.process_pip.sh: Dir with raw fastqs: $DIR_RAW"
echo "#### fastq.process_pip.sh: Dir with flipped fastqs: $DIR_FLIPPED"
echo "#### fastq.process_pip.sh: Dir with demultiplexed fastqs: $DIR_DEMULT"
echo "#### fastq.process_pip.sh: Dir with final/processed fastqs: $DIR_FINAL"
echo "#### fastq.process_pip.sh: Dir with qc stats: $DIR_STATS"
echo "#### fastq.process_pip.sh: Barcode-list file (only has barcodes): $BARCODE_LIST_FILE"
echo "#### fastq.process_pip.sh: Barcode-table file (has barcodes and matching individuals in columns): $BARCODE_TABLE_FILE"
printf "\n"
echo "#### fastq.process_pip.sh: Skip QC step: $SKIP_QC"
echo "#### fastq.process_pip.sh: Skip flipping step: $SKIP_FLIP"
echo "#### fastq.process_pip.sh: Skip demultiplexing step: $SKIP_DEMULT"
echo "#### fastq.process_pip.sh: Skip dedupping: $SKIP_DEDUP"
echo "#### fastq.process_pip.sh: Skip trimming: $SKIP_TRIM"
printf "\n"

[[ ! -d $DIR_FLIPPED ]] && echo "#### fastq.process_pip.sh: Creating DIR_FLIPPED $DIR_FLIPPED..." && mkdir -p $DIR_FLIPPED
[[ ! -d $DIR_DEMULT ]] && echo "#### fastq.process_pip.sh: Creating DIR_DEMULT $DIR_DEMULT..." && mkdir -p $DIR_DEMULT
[[ ! -d $DIR_FINAL ]] && echo "#### fastq.process_pip.sh: Creating DIR_FINAL $DIR_FINAL..." && mkdir -p $DIR_FINAL
[[ ! -d $DIR_STATS/byInd ]] && echo "#### fastq.process_pip.sh: Creating DIR_STATS $DIR_STATS/byInd..." && mkdir -p $DIR_STATS/byInd


################################################################################
#### QC ON RAW FILES ####
################################################################################
echo -e "\n\n###################################################################"
if [ $SKIP_QC == "FALSE" ]
then
	for FASTQ in $DIR_RAW/*$LIBRARY_ID*
	do
		ID=$(basename $FASTQ .fastq.gz) 
		echo -e "#### fastq.process_pip.sh: Running qc on raw file $ID..."
		ls -lh $FASTQ
		
		echo -e "#### fastq.process_pip.sh: Submitting fastqc script:..."
		sbatch -p yoderlab,common,scavenger -o slurm.fastqc.$ID \
		$SCRIPT_QC_FASTQ $FASTQ $DIR_STATS
		
		echo -e "#### fastq.process_pip.sh: Submitting check-barcodes script:..."
		OUTFILE=$DIR_STATS/barcodeCounts_$ID.txt
		sbatch -p yoderlab,common,scavenger -o slurm.checkBarcodes.$ID \
		$SCRIPT_CHECKBARCODES $FASTQ $CUTSITE $OUTFILE
		
		printf "\n"
	done
else
	echo "#### fastq.process_pip.sh: Skipping QC step...."
fi


################################################################################
#### 1. FLIP READS ####
################################################################################
echo -e "\n\n###################################################################"
if [ $SKIP_FLIP == "FALSE" ]
then
	echo -e "#### fastq.process_pip.sh: Step 1 -- flip reads...\n"
	
	$SCRIPT_FLIP_BASH $LIBRARY_ID $DIR_RAW $DIR_FLIPPED $DIR_STATS $BARCODE_LIST_FILE $SCRIPT_FLIP_PERL
else
	echo "#### fastq.process_pip.sh: Skipping flipping step...."
fi


################################################################################
#### 2. DEMULTIPLEX ####
################################################################################
echo -e "\n\n###################################################################"

if [ $SKIP_DEMULT == "FALSE" ]
then
	echo -e "#### fastq.process_pip.sh: Step 2 -- demultiplex fastqs...\n"
	
	R1=$(ls $DIR_FLIPPED/*$LIBRARY_ID*_R1_flipped*fastq*)
	R2=$(ls $DIR_FLIPPED/*$LIBRARY_ID*_R2_flipped*fastq*)
	echo "#### fastq.process_pip.sh: R1: $R1"
	echo "#### fastq.process_pip.sh: R2: $R2"
	
	$SCRIPT_DEMULT $R1 $R2 $DIR_DEMULT $DIR_STATS $BARCODE_TABLE_FILE
else
	echo "#### fastq.process_pip.sh: Skipping demupltiplexing step...."
fi


################################################################################
#### 3. REMOVE PCR DUPS & TRIM #####
################################################################################
echo -e "\n\n###################################################################"
if [ $SKIP_DEDUP == "FALSE" ] || [ $SKIP_TRIM == "FALSE" ]
then
	echo -e "#### fastq.process_pip.sh: Step 3 -- dedup & trim fastqs...\n"
	
	## Paired-end:
	for R1 in $DIR_DEMULT/*1.f*q.gz
	do
		if [ -e "$R1" ]
		then
			PREFIX=$(basename $R1 ".1.f*q.gz" | sed 's/.R1.fastq.gz//' | sed 's/.R1.fq.gz//' | sed 's/.1.fq.gz//' | sed 's/.1.fastq.gz//')
			R2=$DIR_DEMULT/$PREFIX*2.f*q.gz
			#R2=$(echo $R1 | sed 's/1\.f/2.f/')
			
			echo "#### fastq.process_pip.sh: Paired-end sequences detected."
			echo "#### fastq.process_pip.sh: Prefix: $PREFIX"
			echo "#### fastq.process_pip.sh: Listing fastqs:"
			ls -lh $R1
			ls -lh $R2
			
			sbatch --job-name=fastq.process.$PREFIX --mem=16G -p yoderlab,common,scavenger -o slurm.dedup.trim.$PREFIX \
			$SCRIPT_DEDUP_TRIM $R1 $R2 $PREFIX $DIR_FINAL $DIR_STATS/byInd $ADAPTER_FILE $NCORES_DEDUP $SKIP_DEDUP $SKIP_TRIM
			
			## Fastqc on final files:
			if [ $SKIP_STATS == "FALSE" ]
			then
				for FASTQ in $DIR_FINAL/*$PREFIX*fastq.gz
				do
					echo -e "#### fastq.process_pip.sh: Running fastqc on raw file $FASTQ..."
					sbatch --dependency=singleton --job-name=fastq.process.$PREFIX --mem=16G -p yoderlab,common,scavenger -o slurm.fastqc.$PREFIX \
					$SCRIPT_QC_FASTQ $FASTQ $DIR_STATS/byInd
				done
			fi
		fi
		printf "\n"
	done
	
	## Single-end:
	for R1 in $DIR_DEMULT/*0.f*q.gz
	do
		if [ -e "$R1" ]
		then
			PREFIX=$(basename $R1 ".0.fq.gz" | sed 's/.R0.fastq.gz//')
			R2="NONE"
			
			echo -e "\n#### fastq.process_pip.sh: Single-end sequences detected."
			echo -e "#### fastq.process_pip.sh: Prefix: $PREFIX"
			echo -e "#### fastq.process_pip.sh: Listing fastq:"
			ls -lh $R1
			
			sbatch --job-name=fastq.process.$PREFIX --mem=16G -p yoderlab,common,scavenger -o slurm.dedup.trim.$PREFIX \
			$SCRIPT_DEDUP_TRIM $R1 $R2 $PREFIX $DIR_FINAL $DIR_STATS/byInd $ADAPTER_FILE $NCORES_DEDUP $SKIP_DEDUP $SKIP_TRIM
			
			## Fastqc on final files:
			if [ $SKIP_STATS == "FALSE" ]
			then
				for FASTQ in $DIR_FINAL/*$PREFIX*fastq.gz
				do
					echo -e "#### fastq.process_pip.sh: Running fastqc on raw file $FASTQ..."
					sbatch --dependency=singleton --job-name=fastq.process.$PREFIX --mem=16G -p yoderlab,common,scavenger -o slurm.fastqc.$PREFIX \
					$SCRIPT_QC_FASTQ $FASTQ $DIR_STATS/byInd
				done
				printf "\n"
			fi
		fi
	done
else
	echo "#### fastq.process_pip.sh: Skipping dedup & trim step...."
fi


################################################################################
#### REPORT ####
################################################################################
echo -e "\n#### fastq.process_pip.sh: Done with script."
date