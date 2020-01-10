#!/bin/bash
set -e
set -o pipefail
set -u

################################################################################
#### SET_UP ####
################################################################################

## Scripts:
SCRIPT_LOCUSBED=/datacommons/yoderlab/users/jelmer/scripts/radseq/vcf2loci/vcf2loci2a_makelocusbed.R
SCRIPT_LOCUSFASTA=/datacommons/yoderlab/users/jelmer/scripts/radseq/vcf2loci/vcf2loci2b_locusfasta.sh
SCRIPT_LOCUSSTATS=/datacommons/yoderlab/users/jelmer/scripts/radseq/vcf2loci/vcf2loci2c_locusstats.sh
SCRIPT_FILTERLOCI_SUB=/datacommons/yoderlab/users/jelmer/scripts/radseq/vcf2loci/vcf2loci2d_filterloci_sub.sh
module load R/3.4.4

## Command-line args:
ID_VCF=$1
shift
ID_VCF2FASTA=$1
shift
FILE_INDS=$1
shift
FILE_LD=$1
shift
DIR_BED=$1
shift
DIR_FASTA=$1
shift
VCF_FILTERED_INTERSECT=$1
shift
VCF_HIGHDEPTH=$1
shift
TESTRUN=$1
shift

SKIP_LOCUSBED='FALSE'
SKIP_INTERSECTVCF='FALSE'
SKIP_MERGEDFASTA='FALSE'
SKIP_LOCUSFASTA='FALSE'
SKIP_LOCUSSTATS1='FALSE'
SKIP_FILTERLOCI='FALSE'
SKIP_LOCUSSTATS2='FALSE'

while getopts 'BIMLSsF' flag; do
  case "${flag}" in
    B) SKIP_LOCUSBED='TRUE' ;;
    I) SKIP_INTERSECTVCF='TRUE' ;;
    M) SKIP_MERGEDFASTA='TRUE' ;;
    L) SKIP_LOCUSFASTA='TRUE' ;;
    S) SKIP_LOCUSSTATS1='TRUE' ;;
    s) SKIP_LOCUSSTATS2='TRUE' ;;
    F) SKIP_FILTERLOCI='TRUE' ;;
    *) error "Unexpected option ${flag}" ;;
  esac
done

## Other variables:
MIN_ELEMENT_OVERLAP="0.9"
MIN_ELEMENT_OVERLAP_TRIM="0.8"
MIN_LOCUS_SIZE="100"
MAX_DIST_WITHIN_INDS="10"
MAX_DIST_BETWEEN_INDS="0"
MIN_ELEMENT_SIZE="25"
MAXMISS="10"
MIN_LOCUSDIST="1000"
MAX_LD="0.3"
	
## Process args:
ID_FULL=$ID_VCF.$ID_VCF2FASTA

JOBNAME=vcf2loci.$ID_FULL

DIR_INDFASTA=$DIR_FASTA/$ID_FULL.byInd/
DIR_LOCUSFASTA_INTERMED=$DIR_FASTA/$ID_FULL.byLocus.intermed/
DIR_LOCUSFASTA_FINAL=$DIR_FASTA/$ID_FULL.byLocus.final/

LOCUSBED_INTERMED=$DIR_BED/$ID_FULL.loci.intermed.bed
LOCUSBED_FINAL=$DIR_BED/$ID_FULL.loci.all.bed
LOCUSLIST=$DIR_BED/locusList.txt
FASTA_MERGED=$DIR_INDFASTA/$ID_FULL.merged.fasta

FILE_LOCUSSTATS_INTERMED=$DIR_BED/$ID_FULL/$ID_FULL.locusstats.all.txt
FILE_LOCUSSTATS_FINAL=$DIR_BED/$ID_FULL/$ID_FULL.locusstats.filtered.txt

[[ $TESTRUN == TRUE ]] && NR_TESTLOCI=200

[[ ! -e $VCF_FILTERED_INTERSECT ]] && [[ -e $VCF_FILTERED_INTERSECT.gz ]] && echo -e "#### vcf2loci2.sh: Unzipping VCF_FILTERED_INTERSECT...\n" && gunzip -c $VCF_FILTERED_INTERSECT.gz > $VCF_FILTERED_INTERSECT 
[[ ! -e $VCF_HIGHDEPTH ]] && [[ -e $VCF_HIGHDEPTH.gz ]] && echo -e "#### vcf2loci_pip.sh: Unzipping VCF_HIGHDEPTH...\n" && gunzip -c $VCF_HIGHDEPTH.gz > $VCF_HIGHDEPTH 

[[ ! -d $DIR_INDFASTA ]] && echo "#### vcf2loci2.sh: Creating dir DIR_INDFASTA" && mkdir $DIR_INDFASTA
[[ ! -d $DIR_INDFASTA ]] && echo "#### vcf2loci2.sh: Creating dir DIR_INDFASTA" && mkdir $DIR_INDFASTA
[[ ! -d $DIR_LOCUSFASTA_INTERMED ]] && echo "#### vcf2loci2.sh: Creating dir DIR_LOCUSFASTA_INTERMED" && mkdir $DIR_LOCUSFASTA_INTERMED
[[ ! -d $DIR_LOCUSFASTA_FINAL ]] && echo "#### vcf2loci2.sh: Creating dir DIR_LOCUSFASTA_FINAL" && mkdir $DIR_LOCUSFASTA_FINAL
[[ ! -d $DIR_BED/$ID_FULL ]] && echo "#### vcf2loci2.sh: Creating dir DIR_BED" && mkdir $DIR_BED/$ID_FULL

## Report:
echo -e "\n#####################################################################"
date
echo "#### vcf2loci2.sh: Starting script."
echo "#### vcf2loci2.sh: Testrun (TRUE/FALSE): $TESTRUN"
printf "\n"
echo "#### vcf2loci2.sh: Full setID: $ID_VCF"
echo "#### vcf2loci2.sh: vcf2loci ID: $ID_VCF2FASTA"
printf "\n"
echo "#### vcf2loci2.sh: Dir for bedfiles (etc): $DIR_BED"
echo "#### vcf2loci2.sh: Dir for fasta files: $DIR_FASTA"
echo "#### vcf2loci2.sh: [Input] File with individual IDs: $FILE_INDS"
echo "#### vcf2loci2.sh: [Input] VCF - filtered (to intersect): $VCF_FILTERED_INTERSECT"
echo "#### vcf2loci2.sh: [Input] VCF - with sites with excessive coverage: $VCF_HIGHDEPTH"
echo "#### vcf2loci2.sh: [Output] Bedfile with loci - intermediate: $LOCUSBED_INTERMED"
echo "#### vcf2loci2.sh: [Output] Bedfile with loci - final: $LOCUSBED_FINAL"
printf "\n"
echo "#### vcf2loci2.sh: Skip makeLocusBed step: $SKIP_LOCUSBED"
echo "#### vcf2loci2.sh: Skip intersectVCF step: $SKIP_INTERSECTVCF"
echo "#### vcf2loci2.sh: Skip mergedFasta step: $SKIP_MERGEDFASTA"
echo "#### vcf2loci2.sh: Skip locusFasta step: $SKIP_LOCUSFASTA"
echo "#### vcf2loci2.sh: Skip locusStats1 step: $SKIP_LOCUSSTATS1"
echo "#### vcf2loci2.sh: Skip filterLoci step: $SKIP_FILTERLOCI"
echo "#### vcf2loci2.sh: Skip locusStats2 step: $SKIP_LOCUSSTATS2"
printf "\n"
echo "#### vcf2loci2.sh: PARAMETERS:"
echo "#### vcf2loci2.sh: Min element overlap for locus creation (MIN_ELEMENT_OVERLAP): $MIN_ELEMENT_OVERLAP"
echo "#### vcf2loci2.sh: Min element overlap for trimming (MIN_ELEMENT_OVERLAP_TRIM): $MIN_ELEMENT_OVERLAP_TRIM"
echo "#### vcf2loci2.sh: Min locus size (MIN_LOCUS_SIZE): $MIN_LOCUS_SIZE"
echo "#### vcf2loci2.sh: Max percentage of missing data (MAXMISS): $MAXMISS"
echo "#### vcf2loci2.sh: Min distance between loci (MIN_LOCUSDIST): $MIN_LOCUSDIST"
echo "#### vcf2loci2.sh: Max LD between loci (MAX_LD): $MAX_LD"
printf "\n"
echo "#### vcf2loci2.sh: Contents of file ID list:"; cat $FILE_INDS


################################################################################
#### CREATE LOCUS-BEDFILE ####
################################################################################
echo -e "\n#####################################################################"

if [ $SKIP_LOCUSBED == FALSE ]
then
	echo "#### vcf2loci2.sh: Creating locus-bedfile with R script...."
	
	[[ $TESTRUN == TRUE ]] && LASTROW=$NR_TESTLOCI
	[[ $TESTRUN == FALSE ]] && LASTROW=0
	echo -e "#### vcf2loci2.sh: Last row: $LASTROW \n\n"
	
	Rscript $SCRIPT_LOCUSBED $ID_VCF $FILE_INDS $DIR_BED $LOCUSBED_INTERMED \
	$MAX_DIST_WITHIN_INDS $MAX_DIST_BETWEEN_INDS $MIN_ELEMENT_OVERLAP $MIN_ELEMENT_OVERLAP_TRIM $MIN_ELEMENT_SIZE $MIN_LOCUS_SIZE $LASTROW
	
	echo -e "\n\n#### vcf2loci2.sh:Output file: $LOCUSBED_INTERMED"
	ls -lh $LOCUSBED_INTERMED
else
	echo -e "#### vcf2loci2.sh: Skipping createLoci step...\n\n"
fi


################################################################################
#### INTERSECT LOCUS-BEDFILE WITH HIGH-DEPTH VCF ####
################################################################################
echo -e "\n\n###################################################################"

if [ $SKIP_INTERSECTVCF == FALSE ]
then
	echo "#### vcf2loci2.sh: Intersecting loci-bedfile with too-high-depth VCF to remove loci with excessive depth..."
	bedtools intersect -v -a $LOCUSBED_INTERMED -b $VCF_HIGHDEPTH > $LOCUSBED_FINAL
	
	echo -e "\n#### vcf2loci2.sh: Bed output file: $LOCUSBED_FINAL"
	ls -lh $LOCUSBED_FINAL
	
	NR_LOCI=$(cat $LOCUSBED_FINAL | wc -l)
	echo -e "\n#### vcf2loci2.sh: Number of loci after removing too-high-depth variants: $NR_LOCI"
	
	echo -e "\n#### vcf2loci2.sh: Checking how many high-qual SNPs are lacking from loci:"
	NR_SNPS_IN_LOCI=$(bedtools intersect -u -a $VCF_FILTERED_INTERSECT -b $LOCUSBED_FINAL | grep -v "##" | wc -l)
	NR_SNPS_IN_VCF=$(cat $VCF_FILTERED_INTERSECT | grep -v "##" | wc -l)
	NR_SNPS_LOST=$(($NR_SNPS_IN_VCF - $NR_SNPS_IN_LOCI)) 
	echo "#### vcf2loci2.sh: Number of lost SNPs (in VCF but not in loci): $NR_SNPS_LOST"
	echo "#### vcf2loci2.sh: Total number of SNPs in VCF: $NR_SNPS_IN_VCF"
	echo "#### vcf2loci2.sh: Total number of SNPs in loci: $NR_SNPS_IN_LOCI"
	
else
	echo -e "#### vcf2loci2.sh: Skipping intersection with VCF...\n\n"
fi

                                  
################################################################################
#### GET FASTA WITH ALL LOCI AND ALL INDS ####
################################################################################
echo -e "\n#####################################################################"

if [ $SKIP_MERGEDFASTA == FALSE ]
then
	
	## 1: Intersect locus-bedfile with by-individual fasta files:
	echo "#### vcf2loci2.sh: For each individual, extract loci in locus-bedfile from altRefMasked fasta..."
	for IND in $(cat $FILE_INDS)
	do
		echo -e "\n#### vcf2loci2.sh: Ind: $IND"
		
		FASTA_IN=$DIR_INDFASTA/$IND.altRefMasked.fasta
		FASTA_OUT=$DIR_INDFASTA/$IND.allLoci.fasta
		echo "#### vcf2loci2.sh: Fasta input file:"; ls -lh $FASTA_IN
		echo "#### vcf2loci2.sh: Bed input file:"; ls -lh $LOCUSBED_FINAL
		echo "#### vcf2loci2.sh: Running bedtools..."
		
		bedtools getfasta -fi $FASTA_IN -bed $LOCUSBED_FINAL > $FASTA_OUT
		
		echo "#### vcf2loci2.sh: Fasta output file:"
		ls -lh $FASTA_OUT
	done
	
	## 2: Make list with loci:
	echo -e "\n\n#### vcf2loci2.sh: Creating list with loci..."
	IND_1=$(cat $FILE_INDS | head -n 1)
	FASTA_1=$DIR_INDFASTA/$IND_1.allLoci.fasta
	
	grep ">" $FASTA_1 | sed 's/>//' > $LOCUSLIST
	
	[[ $TESTRUN == TRUE ]] && head -n $NR_TESTLOCI $LOCUSLIST > $LOCUSLIST.small && mv $LOCUSLIST.small $LOCUSLIST 
	
	echo -e "\n#### vcf2loci2.sh: Resulting locus list:"
	ls -lh $LOCUSLIST
	
	## 3: Merge by-individual fasta files:
	echo -e "\n\n#### vcf2loci2b_locusStats.sh: Creating merged fasta file:\n"
	
	> $FASTA_MERGED
	for IND in $(cat $FILE_INDS)
	do
		echo "#### vcf2loci2b_locusStats.sh: Individual: $IND"
		FASTA=$DIR_INDFASTA/$IND.allLoci.fasta
		sed "s/>/>${IND}__/g" $FASTA | sed 's/:/,/g' >> $FASTA_MERGED # Replacing ":" by "," for compatibility with faidx
	done
	
	echo -e "\n#### vcf2loci2.sh: Indexing merged fasta file...."
	samtools faidx $FASTA_MERGED
	
	echo -e "\n#### vcf2loci2.sh: Resulting merged fasta file (FASTA_MERGED):"
	ls -lh $FASTA_MERGED

else
	echo -e "#### vcf2loci2.sh: Skipping mergedFasta step...\n"
fi


################################################################################
#### CREATE BY-LOCUS FASTA FILES ####
################################################################################
echo -e "\n#####################################################################"

if [ $SKIP_LOCUSFASTA == FALSE ]
then
	rm -f $DIR_LOCUSFASTA_INTERMED/*
	
	NR_LOCI=$(cat $LOCUSLIST | wc -l)
	LAST100=$(($(($NR_LOCI / 100)) + 1))
	echo -e "#### vcf2loci2.sh: Creating by-locus fasta files for $NR_LOCI loci...\n"
	
	for HUNDRED in $(seq 1 $LAST100)
	do
		LAST=$(($HUNDRED * 100))
		FIRST=$(($LAST - 99))
		[[ $HUNDRED == $LAST100 ]] && LAST=$NR_LOCI
		
		echo -e "\n#### vcf2loci2.sh: From $FIRST ... to $LAST"
		
		sbatch --job-name=$JOBNAME -p yoderlab,common,scavenger -o slurm.vcf2loci2b.locusfasta.$ID_FULL.start$FIRST \
			$SCRIPT_LOCUSFASTA $LOCUSLIST $DIR_LOCUSFASTA_INTERMED $FASTA_MERGED $FIRST $LAST
	done

else
	echo -e "#### vcf2loci2.sh: Skipping locusFasta step...\n"
fi


################################################################################
#### GET LOCUS-STATS FOR INTERMED LOCI ####
################################################################################
echo -e "\n################################################################################"
if [ $SKIP_LOCUSSTATS1 == FALSE ]
then
	echo -e "#### vcf2loci2.sh: Getting locus stats for ALL loci...\n"
	
	sbatch --job-name=$JOBNAME --dependency=singleton -p yoderlab,common,scavenger -o slurm.vcf2loci2c.locusstats1.$ID_FULL \
		$SCRIPT_LOCUSSTATS $DIR_LOCUSFASTA_INTERMED $FILE_LOCUSSTATS_INTERMED
else
	echo -e "#### vcf2loci2.sh: Skipping locusStats step...\n"
fi


################################################################################
#### FILTER LOCI ####
################################################################################
echo -e "\n#####################################################################"
if [ $SKIP_FILTERLOCI == FALSE ]
then
	echo -e "#### vcf2loci2.sh: Filtering loci...\n"
	echo "#### vcf2loci2.sh: Removing any files already present in final fasta folder..."; rm -f $DIR_LOCUSFASTA_FINAL/*
	
	sbatch --job-name=$JOBNAME --dependency=singleton -p yoderlab,common,scavenger -o slurm.vcf2loci2d.filterloci.$ID_FULL \
		$SCRIPT_FILTERLOCI_SUB $FILE_LOCUSSTATS_INTERMED $FILE_LD $MAXMISS $MIN_LOCUSDIST $MAX_LD $DIR_LOCUSFASTA_INTERMED $DIR_LOCUSFASTA_FINAL
else
	echo -e "#### vcf2loci2.sh: Skipping filterLoci step...\n"
fi


################################################################################
#### GET LOCUS-STATS FOR FINAL LOCI ####
################################################################################
echo -e "\n#####################################################################"
if [ $SKIP_LOCUSSTATS2 == FALSE ]
then
	echo -e "#### vcf2loci2.sh: Getting locus stats for FINAL loci...\n"
	
	sbatch --job-name=$JOBNAME --dependency=singleton -p yoderlab,common,scavenger -o slurm.vcf2loci2e.locusstats2.$ID_FULL \
		$SCRIPT_LOCUSSTATS $DIR_LOCUSFASTA_FINAL $FILE_LOCUSSTATS_FINAL
else
	echo -e "#### vcf2loci2.sh: Skipping locusstats step...\n"
fi

echo -e "\n#####################################################################"
echo "#### vcf2loci2.sh: Done with script."
date