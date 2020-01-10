#!/bin/bash
set -e
set -o pipefail
set -u

##### SET-UP: SOFTWARE #####
MSMCTOOLS=/datacommons/yoderlab/programs/msmc-tools
SAMTOOLS=/datacommons/yoderlab/programs/samtools-1.6/samtools
BCFTOOLS=/datacommons/yoderlab/programs/bcftools-1.6/bcftools
PYTHON3=/datacommons/yoderlab/programs/Python-3.6.3/python

##### SET-UP: COMMAND-LINE ARGUMENTS #####
BAMFILE=$1
SCAFFOLD=$2
IND=$3
PHASING=$4
REF=$5
MASK_INDIV_DIR=$6
VCF_DIR=$7

##### File names for single-sample VCF and a mask-file #####
MASK_IND=$MASK_INDIV_DIR/mask_indiv.$IND.$SCAFFOLD.bed.gz # Individual mask file to be created
VCF=$VCF_DIR/$IND.$SCAFFOLD.$PHASING.samtools.msmcFiltered.vcf # VCF file to be created

printf "\n\n\n"
date
echo "Script: msmc_1_call.sh"
echo "Bamfile: $BAMFILE"
echo "Individual: $IND"
echo "Scaffold: $SCAFFOLD"
echo "Phasing: $PHASING"
echo "Reference genome: $REF"
echo "Mask file to be created: $MASK_IND"
echo "Vcf file to be created: $VCF"


##### Calculate mean coverage (to be used as input for bamCaller.py)#####
echo "Calculating mean coverage..."
MEANCOV=`$SAMTOOLS depth -r $SCAFFOLD $BAMFILE | awk '{sum += $3} END {print sum / NR}' | tr ',' '.'` # calculate mean coverage
echo $IND.$SCAFFOLD $MEANCOV >> analyses/msmc/coverage/coverage_samtoolsDepth.txt # save mean coverage in separate file
echo "Mean coverage for this individual: $MEANCOV"


##### Call SNPs and filter #####
echo "Calling genotypes & creating mask..."
$SAMTOOLS mpileup -q 20 -Q 20 -C 50 -u -r $SCAFFOLD -f $REF $BAMFILE | $BCFTOOLS call -c -V indels | $PYTHON3 $MSMCTOOLS/bamCaller.py $MEANCOV $MASK_IND | gzip -c > $VCF.gz

# -q = min. mapping qual; -Q = min. base qual; -C = coefficient for downgrading mapping qual for reads w/ excessive mismatches;
# -u = generate uncompressed VCF/BCF; -r = only specified region; -f = fasta.


echo "Filtered VCF and mask created."
echo "Done with script."
date