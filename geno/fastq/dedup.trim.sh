#!/bin/bash
set -e
set -o pipefail
set -u

################################################################################
#### SET-UP ####
################################################################################
## Command-line args:
R1=$1
R2=$2
PREFIX=$3
OUTDIR=$4
DIR_STATS=$5
ADAPTER_FILE=$6
NCORES=$7
SKIP_DEDUP=$8
SKIP_TRIM=$9

## Scripts & software:
TRIMMOMATIC=/datacommons/yoderlab/programs/Trimmomatic-0.36/trimmomatic-0.36.jar
STACKS_DEDUP=/datacommons/yoderlab/programs/stacks-2.0b/clone_filter
export LD_LIBRARY_PATH=/datacommons/yoderlab/users/gtiley/compilers/gccBin/lib64/:$LD_LIBRARY_PATH

## Prep:
[[ ! -d $OUTDIR/discarded ]] && echo -e "#### dedup.trim.sh: Creating dir $OUTDIR/discarded \n" && mkdir -p $OUTDIR/discarded
DEDUPSTATS_FILE=$DIR_STATS/$PREFIX.dedupstats.txt
TRIMSTATS_FILE=$DIR_STATS/$PREFIX.trimstats.txt

## Report:
printf "\n"
date
echo "#### dedup.trim.sh: Input R1: $R1"
echo "#### dedup.trim.sh: Input R2: $R2"
echo "#### dedup.trim.sh: Outdir: $OUTDIR"
echo "#### dedup.trim.sh: Prefix (ID): $PREFIX"
echo "#### dedup.trim.sh: Adapter file: $ADAPTER_FILE"
echo "#### dedup.trim.sh: Number of cores: $NCORES"
printf "\n"
echo "#### dedup.trim.sh: Dedup-stats file: $DEDUPSTATS_FILE"
echo "#### dedup.trim.sh: Trim-stats file: $TRIMSTATS_FILE"
printf "\n"
echo "#### dedup.trim.sh: Skip dedup (TRUE/FALSE): $SKIP_DEDUP"
echo "#### dedup.trim.sh: Skip trimming (TRUE/FALSE): $SKIP_TRIM"
printf "\n"


################################################################################
#### 1. DEDUP ####
################################################################################
echo -e "\n\n###################################################################"
if [ $R2 != "NONE" ] && [ $SKIP_DEDUP == "FALSE" ]
then
	echo -e "#### dedup.trim.sh: Dedup step...\n"
	
	echo -e "#### dedup.trim.sh: Running stacks..."
	$STACKS_DEDUP -1 $R1 -2 $R2 -o $OUTDIR -i gzfastq 2>&1 | tee $DEDUPSTATS_FILE
	
	R1_IN=$OUTDIR/$PREFIX*1.1.fq.gz
	R2_IN=$OUTDIR/$PREFIX*2.2.fq.gz
elif [ $R2 == "NONE" ]
then
	echo "#### dedup.trim.sh: Single-end sequences - skipping dedup step."
	R1_IN=$R1
	R2_IN=""
elif [ $SKIP_DEDUP == "TRUE" ]
then
	echo "#### dedup.trim.sh: Skipping dedup step."
	R1_IN=$R1
	R2_IN=$R2
fi


################################################################################
#### 2. TRIM #####
################################################################################
echo -e "\n\n###################################################################"
echo -e "#### dedup.trim.sh: Trimming step...\n"

if [ $R2 != "NONE" ] && [ $SKIP_TRIM == "FALSE" ]
then
	echo "#### dedup.trim.sh: Trimming step - paired-end sequences."
	
	R1_OUT=$OUTDIR/$PREFIX.R1.fastq.gz
	R2_OUT=$OUTDIR/$PREFIX.R2.fastq.gz
	R1_DISCARD=$OUTDIR/discarded/$PREFIX.U1.fastq.gz
	R2_DISCARD=$OUTDIR/discarded/$PREFIX.U2.fastq.gz
	
	echo "#### dedup.trim.sh: Trimming step - input R1: $R1_IN"
	echo "#### dedup.trim.sh: Trimming step - input R2: $R2_IN"
	echo "#### dedup.trim.sh: Trimming step - output R1: $R1_OUT"
	echo "#### dedup.trim.sh: Trimming step - output R2: $R2_OUT"
	echo "#### dedup.trim.sh: Trimming step - discarded R1 seqs: $R1_DISCARD"
	echo "#### dedup.trim.sh: Trimming step - discarded R2 seqs: $R2_DISCARD"
	
	echo -e "\n#### dedup.trim.sh: Running trimmomatic..."
	java -jar $TRIMMOMATIC PE -threads $NCORES -phred33 $R1_IN $R2_IN \
		$R1_OUT $R1_DISCARD $R2_OUT $R2_DISCARD \
		ILLUMINACLIP:$ADAPTER_FILE:2:30:10 \
		AVGQUAL:20 SLIDINGWINDOW:4:15 LEADING:3 TRAILING:3 MINLEN:60 2>&1 | tee $TRIMSTATS_FILE
elif [ $R2 == "NONE" ] && [ $SKIP_TRIM == "FALSE" ]
then
	echo "#### dedup.trim.sh: Trimming step - single-end sequences."
	
	R1_OUT=$OUTDIR/$PREFIX.R0.fastq.gz
	
	echo "#### dedup.trim.sh: Trimming step - input R0: $R1_IN"
	echo "#### dedup.trim.sh: Trimming step - output R0: $R1_OUT"
	
	echo -e "\n#### dedup.trim.sh: Running trimmomatic..."
	java -jar $TRIMMOMATIC SE -threads $NCORES -phred33 $R1_IN $R1_OUT \
		ILLUMINACLIP:$ADAPTER_FILE:2:30:10 \
		AVGQUAL:20 SLIDINGWINDOW:4:15 LEADING:3 TRAILING:3 MINLEN:60 2>&1 | tee $TRIMSTATS_FILE
else
	echo "#### dedup.trim.sh: Skipping trimming step."
fi

echo -e "\n#### dedup.trim.sh: Removing intermediate files:"
[[ -s $R1_OUT ]] && rm -f $R1_IN
[[ -s $R2_OUT ]] && rm -f $R2_IN


################################################################################
echo -e "\n#### dedup.trim.sh: Done with script dedup.trim.sh"
date