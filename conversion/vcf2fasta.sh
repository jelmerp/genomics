#!/bin/bash
set -e
set -o pipefail
set -u

################################################################################
##### SET-UP #####
################################################################################
## Software and scripts:
VCFTAB2FASTA=/datacommons/yoderlab/users/jelmer/scripts/genomics/conversion/vcf_tab_to_fasta_alignment.pl
VCFTOOLS=/dscrhome/rcw27/programs/vcftools/vcftools-master/bin/vcftools
VCF2TAB=/dscrhome/rcw27/programs/vcftools/vcftools-master/bin/vcf-to-tab
export PERL5LIB=/dscrhome/rcw27/programs/vcftools/vcftools-master/src/perl/

## Command-line args:
FILE_ID=$1
INDIR=$2
OUTDIR=$3
SCAFFOLD=$4 # Only if specific scaffold should be extracted

## Report:
printf "\n"
date
echo "#### vcf2fasta.sh: Starting script."
echo "#### vcf2fasta.sh: Slurm job name: $SLURM_JOB_NAME.sh"
echo "#### vcf2fasta.sh: Slurm job ID: $SLURM_JOB_ID.sh"
printf "\n"
echo "#### vcf2fasta.sh: Looking for VCF file: $INDIR/$FILE_ID.vcf(.gz)"

## Get VCF:
if [ -e $INDIR/$FILE_ID.vcf.gz ]
then
	echo "#### vcf2fasta.sh: Zipped VCF detected..."
	ZIPPED_VCF=TRUE
	INFILE=$INDIR/$FILE_ID.vcf.gz
elif [ -e $INDIR/$FILE_ID.vcf ]
then
	echo "#### vcf2fasta.sh: Unzipped VCF detected..."
	ZIPPED_VCF=FALSE
	INFILE=$INDIR/$FILE_ID.vcf
else
	printf "\n"; echo "#### vcf2fasta.sh: OOPS! NO VCF FILE FOUND!"; printf "\n"
fi

## Assign "ALL" to $SCAFFOLD if nothing is assigned:
[[ -z $SCAFFOLD ]] && SCAFFOLD=ALL

## Make outdir if it doesn't exist:
[[ ! -d $OUTDIR ]] && echo "#### vcf2fasta.sh: Creating dir $OUTDIR" && mkdir -p $OUTDIR


## Report:
echo "#### vcf2fasta.sh: File ID: $FILE_ID"
echo "#### vcf2fasta.sh: Indir: $INDIR"
echo "#### vcf2fasta.sh: Outdir: $OUTDIR"
echo "#### vcf2fasta.sh: Infile: $INFILE"
echo "#### vcf2fasta.sh: Is infile zipped: $ZIPPED_VCF"
echo "#### vcf2fasta.sh: Scaffold: $SCAFFOLD"
printf "\n"


################################################################################
##### CONVERT VCF TO FASTA #####
################################################################################
if [ $SCAFFOLD != ALL ]
then
	printf "\n"
	echo "#### vcf2fasta.sh: Extracting single scaffold $SCAFFOLD from vcf file..."
	
	FILE_ID=$FILE_ID.$SCAFFOLD
	
	[[ $ZIPPED_VCF == TRUE ]] && VCFTOOLS_COMMAND="--gzvcf"
	[[ $ZIPPED_VCF == FALSE ]] && VCFTOOLS_COMMAND="--vcf"
	
	$VCFTOOLS --gzvcf $INFILE --chr $SCAFFOLD --remove-filtered-all --recode --recode-INFO-all --stdout | \
		$VCF2TAB | sed 's/\./N/g' > $OUTDIR/$FILE_ID.tab
else
	printf "\n"
	echo "#### vcf2fasta.sh: Processing ALL scaffolds / entire vcf file..."
	echo "#### vcf2fasta.sh: Converting vcf to tab-delimited file using vcftools perl utility vcf-to-tab..."
	[[ $ZIPPED_VCF == TRUE ]] && zcat $INFILE | $VCF2TAB | sed 's/\./N/g' > $OUTDIR/$FILE_ID.tab
	[[ $ZIPPED_VCF == FALSE ]] && cat $INFILE | $VCF2TAB | sed 's/\./N/g' > $OUTDIR/$FILE_ID.tab
fi && \

printf "\n"
echo "#### vcf2fasta.sh: Creating varpos file with indices of variable positions...: $OUTDIR/$FILE_ID.varpos"
cat $OUTDIR/$FILE_ID.tab | cut -f 1,2 | tail -n +2 > $OUTDIR/$FILE_ID.varpos && \

printf "\n" && \
echo "#### vcf2fasta.sh: Converting tab to fasta...: $OUTDIR/$FILE_ID.fasta" && \
perl $VCFTAB2FASTA -i $OUTDIR/$FILE_ID.tab > $OUTDIR/$FILE_ID.fasta

printf "\n"
echo "#### vcf2fasta.sh: Outputting varscaffold...: $OUTDIR/$FILE_ID.varscaffold"
cat $OUTDIR/$FILE_ID.fasta | sed ':a;N;$!ba;s/\n/\t/g' | sed 's/\t>/\n/g' | sed 's/\t/ /' | sed 's/\t//g' | sed 's/>//g' > $OUTDIR/$FILE_ID.varscaffold

echo "#### vcf2fasta.sh: Resulting fasta file $OUTDIR/$FILE_ID.fasta:"
ls -lh $OUTDIR/$FILE_ID.fasta

#echo "Removing intermediate tab file..." && \
#rm $OUTDIR/$FILE_ID.tab* && \

printf "\n"
echo "#### vcf2fasta.sh: Done with script."
date
