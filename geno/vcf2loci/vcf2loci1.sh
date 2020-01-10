#!/bin/bash
set -e
set -o pipefail
set -u

################################################################################
#### SET-UP ####
################################################################################
## Software:
JAVA=/datacommons/yoderlab/programs/java_1.8.0/jre1.8.0_144/bin/java
GATK=/datacommons/yoderlab/programs/gatk-3.8-0/GenomeAnalysisTK.jar
BEDTOOLS=/datacommons/yoderlab/programs/bedtools2.27.1/bin/bedtools
SAMTOOLS=/datacommons/yoderlab/programs/samtools-1.6/samtools
BGZIP=/datacommons/yoderlab/programs/htslib-1.6/bgzip

## Command-line args:
IND=$1
shift
ID_VCF=$1
shift
BAM=$1
shift
VCF_ALTREF=$1
shift
BED_REMOVED_SITES=$1
shift
DIR_INDFASTA=$1
shift
DIR_BED=$1
shift
REF=$1
shift
CALLABLE_COMMAND="$1"
shift
MEM=$1
shift

SKIP_CALLABLE='FALSE'
SKIP_ALTREF='FALSE'
SKIP_MASKFASTA='FALSE'

while getopts 'CAM' flag; do
  case "${flag}" in
    C) SKIP_CALLABLE='TRUE' ;;
    A) SKIP_ALTREF='TRUE' ;;
    M) SKIP_MASKFASTA='TRUE' ;;
    *) error "Unexpected option ${flag}" ;;
  esac
done

## Process args:
[[ ! -d $DIR_INDFASTA ]] && echo "Creating fasta dir $DIR_INDFASTA" && mkdir -p $DIR_INDFASTA
[[ ! -d $DIR_BED ]] && echo "Creating bed dir $DIR_BED" && mkdir -p $DIR_BED/

CALLABLE_SUMMARY=$DIR_BED/$IND.callableLoci.sumtable.txt

BED_OUT=$DIR_BED/$IND.callableLociOutput.bed
BED_NOTCALLABLE=$DIR_BED/$IND.nonCallable.bed
BED_CALLABLE=$DIR_BED/$IND.callable.bed

FASTA_ALTREF=$DIR_INDFASTA/$IND.altRef.fasta
FASTA_MASKED=$DIR_INDFASTA/$IND.altRefMasked.fasta

## Report:
echo -e "\n\n###################################################################"
date
echo "#### vcf2loci1.sh: Starting script."
echo "#### vcf2loci1.sh: Sample ID: $IND"
echo "#### vcf2loci1.sh: VCF ID: $ID_VCF"
echo "#### vcf2loci1.sh: Bam file: $BAM"
printf "\n"
echo "#### vcf2loci1.sh: Vcf file - for producing altref: $VCF_ALTREF"
echo "#### vcf2loci1.sh: Bedfile with sites removed by filtering: $BED_REMOVED_SITES"
printf "\n"
echo "#### vcf2loci1.sh: Fasta dir: $DIR_INDFASTA"
echo "#### vcf2loci1.sh: Bed dir: $DIR_BED"
echo "#### vcf2loci1.sh: Reference genome: $REF"
echo "#### vcf2loci1.sh: Memory allocation: $MEM"
echo "#### vcf2loci1.sh: Additional GATK commands: $CALLABLE_COMMAND"
printf "\n"
echo "#### vcf2loci1.sh: Skip CallableLoci step (TRUE/FALSE): $SKIP_CALLABLE"
echo "#### vcf2loci1.sh: Skip AltRef step (TRUE/FALSE): $SKIP_ALTREF"
echo "#### vcf2loci1.sh: Skip MaskFasta step (TRUE/FALSE): $SKIP_MASKFASTA"
printf "\n"

[[ ! -e $BAM.bai ]] && echo "#### vcf2loci1.sh: Indexing bam..." && $SAMTOOLS index $BAM

################################################################################
#### STEP 1 -- RUN GATK CALLABLE-LOCI ####
################################################################################
## Using ref genome and bamfiles, produce bedfile for sites that are (non-)callable for a single sample
if [ $SKIP_CALLABLE == FALSE ]                        
then
	echo -e "\n#################################################################"
	echo "#### vcf2loci1.sh: Running GATK CallableLoci..."
	echo "#### vcf2loci1.sh: CallableLoci output - summary table: $CALLABLE_SUMMARY"
	echo "#### vcf2loci1.sh: CallableLoci output - bed file: $BED_CALLABLE"
	printf "\n"
	
	## Run CallableLoci:
	$JAVA -Xmx${MEM}G -jar $GATK -T CallableLoci \
		-R $REF \
		-I $BAM \
		-summary $CALLABLE_SUMMARY \
		$CALLABLE_COMMAND -o $BED_OUT
	
	echo -e "\n#### vcf2loci1.sh: Resulting bedfile (BED_OUT): $BED_OUT:"; ls -lh $BED_OUT
	
	## Edit bedfile to include only non-callable loci:
	echo -e "\n#### vcf2loci1.sh: Editing bedfile to include only non-callable loci..."
	grep -v "CALLABLE" $BED_OUT > $BED_NOTCALLABLE
	grep "CALLABLE" $BED_OUT > $BED_CALLABLE
	
	echo -e "\n#### vcf2loci1.sh: Resulting bedfile with non-callable sites (BED_NOTCALLABLE): $BED_NOTCALLABLE:"
	ls -lh $BED_NOTCALLABLE
	echo -e "\n#### vcf2loci1.sh: Resulting bedfile with callable sites (BED_CALLABLE): $BED_CALLABLE:"
	ls -lh $BED_CALLABLE
else
	echo -e "\n#### vcf2loci1.sh: Skipping CallableLoci step...\n"
fi


################################################################################
#### STEP2 2 -- RUN GATK FASTA-ALTERNATE-REFERENCE-MAKER ####
################################################################################
## Using ref genome and vcf file, produce whole-genome fasta file for a single sample:
if [ $SKIP_ALTREF == FALSE ]
then
	echo -e "\n#################################################################"
	echo -e "#### vcf2loci1.sh: Running GATK FastaAlternateReferenceMaker...\n"
	
	## Unzip VCF:
	[[ ! -e $VCF_ALTREF ]] && [[ -e $VCF_ALTREF.gz ]] && echo "#### Unzipping VCF_ALTREF..." && gunzip $VCF_ALTREF.gz && printf "\n"
	
	## Run GATK:
	$JAVA -Xmx${MEM}G -jar $GATK -T FastaAlternateReferenceMaker \
		-IUPAC $IND \
		-R $REF \
		-V $VCF_ALTREF \
		-o $FASTA_ALTREF.tmp
	
	## Report:
	echo -e "\n#### vcf2loci1.sh: Resulting fasta file (FASTA_ALTREF.tmp):"; ls -lh $FASTA_ALTREF.tmp
	
	## Edit fasta headers:
	echo -e "\n#### vcf2loci1.sh: Editing fasta header..."
	sed 's/:1//g' $FASTA_ALTREF.tmp | sed 's/>[0-9]* />/g' > $FASTA_ALTREF
	
	[[ -e $FASTA_ALTREF ]] && rm $FASTA_ALTREF.tmp
	
	## Report:
	echo "#### vcf2loci1.sh: Resulting fasta file (FASTA_ALTREF):"; ls -lh $FASTA_ALTREF
	
	## Count bases:
	echo -e "\n#### vcf2loci1.sh: Counting bases..."
	N_ACGT=$(egrep -o "A|C|G|T" $FASTA_ALTREF | wc -l)
	N_AMBIG=$(egrep -o "M|R|W|S|Y|K" $FASTA_ALTREF | wc -l)
	echo "#### vcf2loci1.sh: Number of A/C/G/Ts in FASTA_ALTREF: $N_ACGT"
	echo -e "#### vcf2loci1.sh: Number of het sites (as counted by ambig codes) in FASTA_ALTREF: $N_AMBIG \n"
else
	echo -e "\n#### Skipping AltRef step...\n"
fi


################################################################################
#### STEP 4 -- RUN BEDTOOLS MASKFASTA ####
################################################################################
# In whole-genome fasta for a given sample, mask:
# A) Sites identified as non-callable by CallableLoci, and
# B) Sites removed during vcf-filtering.

if [ $SKIP_MASKFASTA == FALSE ]
then
	echo -e "\n#################################################################"
	echo -e "#### vcf2loci1.sh: Running bedtools maskfasta...\n"
	
	echo "#### vcf2loci1.sh: Masking step 1: Masking non-callable sites..."
	echo "#### vcf2loci1.sh: Using bedfile BED_NOTCALLABLE:"; ls -lh $BED_NOTCALLABLE
	$BEDTOOLS maskfasta -fi $FASTA_ALTREF -bed $BED_NOTCALLABLE -fo $FASTA_MASKED.intermed.fasta
	echo -e "\n#### vcf2loci1.sh: Resulting fasta file (FASTA_MASKED.intermed.fasta):"
	ls -lh $FASTA_MASKED.intermed.fasta
	
	echo -e "\n#### vcf2loci1.sh: Masking step 2: Masking removed (filtered-out) sites..."
	echo "#### vcf2loci1.sh: Using bedfile BED_REMOVED_SITES:"; ls -lh $BED_REMOVED_SITES
	$BEDTOOLS maskfasta -fi $FASTA_MASKED.intermed.fasta -bed $BED_REMOVED_SITES -fo $FASTA_MASKED
	
	echo -e "\n#### vcf2loci1.sh: Resulting fasta file FASTA_MASKED:"
	ls -lh $FASTA_MASKED
	
	echo -e "\n#### vcf2loci1.sh: Counting Ns in the different fasta files..."
	NCOUNT_FASTA_ALTREF=$(fgrep -o N $FASTA_ALTREF | wc -l)
	NCOUNT_FASTA_MASKED_INTERMED=$(fgrep -o N $FASTA_MASKED.intermed.fasta | wc -l)
	NCOUNT_FASTA_MASKED=$(fgrep -o N $FASTA_MASKED | wc -l)
	
	echo "#### vcf2loci1.sh: Number of Ns in FASTA_ALTREF: $NCOUNT_FASTA_ALTREF"
	echo "#### vcf2loci1.sh: Number of Ns in FASTA_MASKED_INTERMED (after masking non-callable sites): $NCOUNT_FASTA_MASKED_INTERMED"
	echo "#### vcf2loci1.sh: Number of Ns in FASTA_MASKED (after also masking sites removed by filtering): $NCOUNT_FASTA_MASKED"
	
	rm -f $FASTA_MASKED.intermed.fasta
else
	echo -e "\n#### vcf2loci1.sh: Skipping MaskFasta step...\n"
fi


echo -e "\n#####################################################################"
echo "#### vcf2loci1.sh: Done with script."
date