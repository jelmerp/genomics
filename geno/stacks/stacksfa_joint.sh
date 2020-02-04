#!/bin/bash
set -e
set -o pipefail
set -u

################################################################################
#### SET-UP ####
################################################################################
## Software and scripts:
module load R
BEDTOOLS=/datacommons/yoderlab/programs/bedtools2.27.1/bin/bedtools
SAMTOOLS=/datacommons/yoderlab/programs/samtools-1.6/samtools
FASTASORT=/datacommons/yoderlab/programs/exonerate-2.2/bin/fastasort

SCR_FILTER_LOCI=/datacommons/yoderlab/users/jelmer/scripts/genomics/geno/stacks/stacksfa_filter.R

## Command-line args:
SET_ID_FASTA=$1
shift
INDFILE=$1
shift
BASEDIR=$1
shift
MAXMISS_IND=$1
shift
MAXMISS_MEAN=$1
shift
MINDIST=$1
shift
MINLENGTH=$1
shift
LENGTH_QUANTILE=$1
shift
MAXINDMISS=$1
shift

FILTER_LOCI='TRUE'
EXTRACT_LOCI='TRUE'
MERGE_FASTA='TRUE'
SPLIT_FASTA='TRUE'
while getopts 'ZFEMS' flag; do
  case "${flag}" in
  	F) FILTER_LOCI='FALSE' ;;
  	E) EXTRACT_LOCI='FALSE' ;;
  	M) MERGE_FASTA='FALSE' ;;
  	S) SPLIT_FASTA='FALSE' ;;
  esac
done

## Process args:
DIR_INDFASTA=$BASEDIR/fasta/byInd
DIR_LSTATS=$BASEDIR/loci/
DIR_LFASTA=$BASEDIR/fasta/byLocus

FASTA_MERGED=$BASEDIR/fasta/$SET_ID_FASTA.filtered.fasta

INDS=( $(cut -f 1 $INDFILE) ) #INDS=( mmyo006 mber013 mruf011 )

## Report:
echo -e "\n#####################################################################"
date
echo "#### stacksfa_joint.sh: Starting script."
echo "#### stacksfa_joint.sh: Full Set ID: $SET_ID_FASTA"
echo "#### stacksfa_joint.sh: File with individuals: $INDFILE"
echo "#### stacksfa_joint.sh: Base (Stacks) dir: $BASEDIR"
echo "#### stacksfa_joint.sh: Max. % missing per ind per locus: $MAXMISS_IND"
echo "#### stacksfa_joint.sh: Max. % missing across inds per locus: $MAXMISS_MEAN"
echo "#### stacksfa_joint.sh: Min. dist between loci: $MINDIST"
echo "#### stacksfa_joint.sh: Min. locus length: $MINLENGTH"
echo "#### stacksfa_joint.sh: Length quantile: $LENGTH_QUANTILE"
echo "#### stacksfa_joint.sh: Max. % missing inds per locus: $MAXINDMISS"
printf "\n"
echo "#### stacksfa_joint.sh: Merged fasta: $FASTA_MERGED"
echo "#### stacksfa_joint.sh: Individuals: ${INDS[@]}"
printf "\n"
echo "#### stacksfa_joint.sh: Filter loci: $FILTER_LOCI"
echo "#### stacksfa_joint.sh: Extract loci: $EXTRACT_LOCI"
echo "#### stacksfa_joint.sh: Merge fasta (across inds): $MERGE_FASTA"
echo "#### stacksfa_joint.sh: Split fasta (by locus): $SPLIT_FASTA"


################################################################################
#### JOINT LOCUS FILTERING ####
################################################################################
echo -e "\n\n###############################################################"
if [ $FILTER_LOCI == TRUE ]
then
	echo -e "#### stacksfa_joint: Submitting R script to filter loci..."
	$SCR_FILTER_LOCI $SET_ID_FASTA $INDFILE $DIR_LSTATS $MAXMISS_IND $MAXMISS_MEAN $MINDIST $MINLENGTH $LENGTH_QUANTILE $MAXINDMISS
else
	echo -e "#### stacksfa_joint: SKIPPING filter loci\n"
fi


################################################################################
#### EXTRACT FINAL LOCI ####
################################################################################
echo -e "\n\n###############################################################"
if [ $EXTRACT_LOCI == TRUE ]
	then
	echo -e "#### stacksfa_joint: Extract filtered per-locus fasta..."
		
	for IND in ${INDS[@]}
	do
		for ALLELE in A0 A1
		do
			echo -e "\n#### stacksfa_joint: Ind: $IND // Allele: $ALLELE"
			WGFASTA_MASKED=$DIR_INDFASTA/$IND.wg.masked.$ALLELE.fasta
			LOCUSFASTA_FINAL=$DIR_INDFASTA/$IND.$ALLELE.$SET_ID_FASTA.filteredloci.fasta
			LSTATS=$DIR_LSTATS/$IND.$ALLELE.$SET_ID_FASTA.filteredloci.bed
			
			$BEDTOOLS getfasta -fi $WGFASTA_MASKED -bed $LSTATS -name > $LOCUSFASTA_FINAL
			
			echo -e "#### stacksfa_joint: Masked by-locus fasta output file:"
			ls -lh $LOCUSFASTA_FINAL
		done
	done
else
	echo -e "#### stacksfa_joint: SKIPPING extract final loci\n"
fi


################################################################################
#### MERGE BY-IND FASTAS ####
################################################################################
echo -e "\n\n###################################################################"
if [ $MERGE_FASTA == TRUE ]
then
	echo -e "#### stacksfa_joint.sh: Creating merged fasta file with all inds:\n"
	
	echo -e "\n#### stacksfa_joint.sh: Files to merge:"
	ls -lh $DIR_INDFASTA/*.A[0-1].$SET_ID_FASTA.filteredloci.fasta
	
	## Merge fasta's:
	cat $DIR_INDFASTA/*.A[0-1].$SET_ID_FASTA.filteredloci.fasta > $FASTA_MERGED
	
	## Sort fasta: # Aborted - this will divide each sequence across multiple lines
	# $FASTASORT $FASTA_MERGED.tmp > $FASTA_MERGED
	# rm -f $FASTA_MERGED.tmp
	## TO DO: CHANGE LOCUS NAMES FOR PROPER SORTING? & DIFFERENT SORT?
	
	echo -e "\n#### stacksfa_joint.sh: Indexing merged fasta file...."
	$SAMTOOLS faidx $FASTA_MERGED
	
	echo -e "\n#### stacksfa_joint.sh: Resulting merged fasta file (FASTA_MERGED):"
	ls -lh $FASTA_MERGED
	
	#echo -e "\n#### stacksfa_joint.sh: Removing temporary files..."
	#rm -f $DIR_INDFASTA/*.A[0-1].$SET_ID_FASTA.filteredloci.fasta
	#rm -f $DIR_LSTATS/*bed $DIR_LSTATS/*locusstats1* $DIR_LSTATS/*locusstats2* 
else
	echo -e "#### stacksfa_joint: SKIPPING merge fastas\n"
fi


################################################################################
#### SPLIT INTO PER-LOCUS FASTAS ####
################################################################################
echo -e "\n\n###################################################################"

if [ $SPLIT_FASTA == TRUE ]
then
	echo -e "#### stacksfa_joint.sh: Splitting merged fasta file into per-locus fasta files..."
	echo -e "#### stacksfa_joint.sh: Dir for per-locus fasta files: $DIR_LFASTA \n"
	
	LOCI=( $(grep ">" $FASTA_MERGED | sed -E 's/>(L[0-9]+)_.*/\1/' | sort | uniq) )
	echo -e "#### stacksfa_joint.sh: Number of final loci in merged file: ${#LOCI[@]} \n"

	for LOCUS in ${LOCI[@]}
	do
		grep -A 1 ">${LOCUS}_" $FASTA_MERGED | grep -v "\-\-" > $DIR_LFASTA/$LOCUS.fa
	done
else
	echo -e "#### stacksfa_joint: SKIPPING split fasta\n"
fi


echo -e "\n\n#### stacksfa_joint: Done with script."
date