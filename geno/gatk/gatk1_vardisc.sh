#!/bin/bash
set -e
set -o pipefail
set -u

################################################################################
#### SET-UP ####
################################################################################
## Software:
SAMTOOLS=/datacommons/yoderlab/programs/samtools-1.6/samtools
GATK3=/datacommons/yoderlab/programs/gatk-3.8-0/GenomeAnalysisTK.jar
JAVA=/datacommons/yoderlab/programs/java_1.8.0/jre1.8.0_144/bin/java
GATK4=/datacommons/yoderlab/programs/gatk-4.0.7.0/gatk

## Command line args:
REF=$1
INPUT=$2
OUTPUT=$3
MEM=$4
NCORES=$5
GATK_VERSION=$6

## Report:
date
echo "#### gatk1_vardisc.sh: Starting script."
echo "#### gatk1_vardisc.sh: Slurm Job name: $SLURM_JOB_NAME"
echo "#### gatk1_vardisc.sh: Slurm Job ID: $SLURM_JOB_ID"
echo "#### gatk1_vardisc.sh: Slurm number of nodes: $SLURM_JOB_NUM_NODES" # Specify with -N
printf "\n"
echo "#### gatk1_vardisc.sh: Reference sequence: $REF"
echo "#### gatk1_vardisc.sh: Input file name: $INPUT"
echo "#### gatk1_vardisc.sh: Output file name: $OUTPUT"
echo "#### gatk1_vardisc.sh: GATK version: $GATK_VERSION"
echo "#### gatk1_vardisc.sh: Memory: $MEM"
echo "#### gatk1_vardisc.sh: Number of cores: $NCORES"

## Index bamfile:
if [ ! -e $INPUT.bai ]
then
	echo -e "\n#### gatk1_vardisc.sh: Indexing bamfile..." 
	#rm -f $INPUT.bai
	$SAMTOOLS index $INPUT
fi


################################################################################
#### RUN GATK HAPLOTYPECALLER ####
################################################################################
echo -e "\n#### gatk1_vardisc.sh: Starting variant discovery...\n"

if [ $GATK_VERSION == "gatk3" ]
then
	echo -e "#### gatk1_vardisc.sh: Running with GATK version 3... \n"
	
	$JAVA -Xmx${MEM}G -jar $GATK3 -T HaplotypeCaller -R $REF -I $INPUT --genotyping_mode DISCOVERY \
	--emitRefConfidence GVCF -mmq 10 -nct $NCORES -o $OUTPUT
fi

if [ $GATK_VERSION == "gatk4" ]
then
	echo -e "#### gatk1_vardisc.sh: Running with GATK version 4...\n"
	
	$GATK4 --java-options "-Xmx${MEM}g" HaplotypeCaller -R $REF -I $INPUT -O $OUTPUT \
	-ERC GVCF --pairHMM AVX_LOGLESS_CACHING_OMP --native-pair-hmm-threads $NCORES
fi


################################################################################
#### HOUSEKEEPING ####
################################################################################
echo -e "\n#### gatk1_vardisc.sh: Output file:"
ls -lh $OUTPUT

NVAR=$(grep -v "##" $OUTPUT | wc -l)
echo -e "\n#### gatk1_vardisc.sh: Number of variants in gvcf: $NVAR \n"

echo -e "#### gatk1_vardisc.sh: Done with script."
date