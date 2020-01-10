#!/bin/bash
set -e
set -o pipefail
set -u

################################################################################
##### SET-UP #####
################################################################################
## Software:
JAVA=/datacommons/yoderlab/programs/java_1.8.0/jre1.8.0_144/bin/java
GATK=/datacommons/yoderlab/programs/gatk-3.8-0/GenomeAnalysisTK.jar
SAMTOOLS=/datacommons/yoderlab/programs/samtools-1.6/samtools

## Command-line args:
ID=$1
INDIR=$2
OUTDIR=$3
PREFIX_IN=$4
PREFIX_OUT=$5
REF=$6
MEM=$7

## Process args:
INPUT=$INDIR/$ID.$PREFIX_IN.bam
OUTPUT=$OUTDIR/$ID.$PREFIX_OUT.bam

## Report:
echo -e "\n#### bam3_realign.sh: Starting script.sh"
date
echo "#### bam3_realign.sh: ID: $ID"
echo "#### bam3_realign.sh: Indir: $INDIR"
echo "#### bam3_realign.sh: Outdir: $OUTDIR"
echo "#### bam3_realign.sh: Prefix_in: $PREFIX_IN"
echo "#### bam3_realign.sh: Prefix_out: $PREFIX_OUT"
echo "#### bam3_realign.sh: Reference fasta: $REF"
echo -e "#### bam3_realign.sh: Mem: $MEM \n"

## Index bam if necessary:
[[ ! -f $INDIR/$ID.$PREFIX_IN*bai ]] && echo "#### Indexing bam file..." && printf "\n" && $SAMTOOLS index -b $INPUT


################################################################################
#### LOCAL REALIGNMENT ####
################################################################################
echo -e "\n#### Performing local realignment - Step 1 - RealignerTargetCreator..."
$JAVA -Xmx${MEM}G -jar $GATK -T RealignerTargetCreator -R $REF -I $INPUT -o $OUTDIR/$ID.intervals

echo -e "\n\n#### Performing local realignment - Step 2 - IndelRealigner..."
$JAVA -Xmx${MEM}G -jar $GATK -T IndelRealigner -R $REF -I $INPUT --targetIntervals $OUTDIR/$ID.intervals -o $OUTPUT

## Report:
date
echo -e "#### bam3_realign.sh: Done with script.\n"