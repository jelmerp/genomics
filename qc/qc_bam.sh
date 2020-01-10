#!/bin/bash
set -e
set -o pipefail
set -u

################################################################################
##### SET-UP #####
################################################################################
## Command-line args:
ID=$1
INPUT=$2
OUTDIR=$3
REF=$4
MEM=$5
UNSORTED=$6

## Software:
JAVA=/datacommons/yoderlab/programs/java_1.8.0/jre1.8.0_144/bin/java
GATK=/datacommons/yoderlab/programs/gatk-3.8-0/GenomeAnalysisTK.jar
SAMTOOLS=/datacommons/yoderlab/programs/samtools-1.6/samtools
EAUTILS_SAMSTATS=/datacommons/yoderlab/programs/ExpressionAnalysis-ea-utils-bd148d4/clipper/sam-stats

## Report:
printf "\n"
date
echo "##### qc_bam.sh: Starting script."
echo "##### qc_bam.sh: ID: $ID"
echo "##### qc_bam.sh: Input: $INPUT"
echo "##### qc_bam.sh: Outdir: $OUTDIR"
echo "##### qc_bam.sh: Reference fasta: $REF"
echo "##### qc_bam.sh: Mem: $MEM"


################################################################################
##### RUN #####
################################################################################
if [ $UNSORTED == TRUE ]
then
	echo -e "\n##### qc_bam.sh: Sorting bam file..."
	BAM_ID=$(basename -s .bam $INPUT)
	BAM_DIR=$(dirname $INPUT)
	SORTED_FILE=$BAM_DIR/$BAM_ID.sort.bam
	$SAMTOOLS sort -@ 1 -m 4G -T tmp -O bam $INPUT > $SORTED_FILE
	INPUT=$SORTED_FILE
	echo "##### qc_bam.sh: Input is now: $INPUT"
fi

[[ ! -f $INPUT.bai ]] && echo -e "\n##### qc_bam.sh: Indexing bam file..." && $SAMTOOLS index -b $INPUT

echo -e "\n##### qc_bam.sh: Bam input file:"
ls -lh $INPUT

## Depth/coverage:
echo -e "\n##### qc_bam.sh: Checking coverage..."
$SAMTOOLS depth $INPUT > $OUTDIR/$ID.depth_samtools.txt
MEANDEPTH=`cat $OUTDIR/$ID.depth_samtools.txt | awk '{sum+=$3} END {print sum/NR}'`

echo "##### qc_bam.sh: Coverage for $ID is: $MEANDEPTH"
echo "$ID $MEANDEPTH" > $OUTDIR/$ID.meandepth_samtools.txt

rm $OUTDIR/$ID.depth_samtools.txt

## Samtools flagstat:
echo -e "\n##### qc_bam.sh: Running samtools flagstat..."
$SAMTOOLS flagstat $INPUT > $OUTDIR/$ID.samtools-flagstat.txt
echo -e "\n##### qc_bam.sh: samtools flagstat output file:..."
ls -lh $OUTDIR/$ID.samtools-flagstat.txt

## ea-utils samstats:
echo -e "\n##### qc_bam.sh: Running ea-utils samstats..."
$EAUTILS_SAMSTATS -D -B $INPUT > $OUTDIR/$ID.ea-utils-samstats.txt
echo -e "\n##### qc_bam.sh: ea-utils output file:..."
ls -lh $OUTDIR/$ID.ea-utils-samstats.txt


## GATK CountLoci:
#echo "Running GATK CountLoci..."
#$JAVA -Xmx${MEM}G -jar $GATK -T CountLoci -R $REF -I $INPUT -o $OUTDIR/$ID.$PREFIX.countloci.txt
#printf "\n"


################################################################################
echo -e "\n##### qc_bam.sh: Done with script qc_bam.sh"
date
printf "\n"
