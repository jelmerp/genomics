#!/bin/bash
set -e
set -o pipefail
set -u

################################################################################
#### SET-UP ####
################################################################################
## Software and scripts:
chmod -R +x /datacommons/yoderlab/users/jelmer/scripts/

SCR_GENOMEFASTA=/datacommons/yoderlab/users/jelmer/scripts/geno/stacks/stacksfa_fullgenome.R
module load R

VCF2BED=/datacommons/yoderlab/programs/bedops/bin/vcf2bed
BEDTOOLS=/datacommons/yoderlab/programs/bedtools2.27.1/bin/bedtools
JAVA=/datacommons/yoderlab/programs/java_1.8.0/jre1.8.0_144/bin/java
GATK=/datacommons/yoderlab/programs/gatk-3.8-0/GenomeAnalysisTK.jar

## Command-line args:
IND=$1
shift
FASTA_RAW=$1
shift
BAM=$1
shift
VCF_RAW=$1
shift
VCF_FILT=$1
shift
VCF_HIDEPTH=$1
shift
BED_EXONS=$1
shift
REF=$1
shift
SCAF_FILE=$1
shift
BASEDIR=$1
shift
CALLABLE_COMMAND="$1"
shift

## Additional args - flip with flags:
MAKEMASK_CALLABLE='TRUE'
MAKEMASK_VCF='TRUE'
DO_WGFASTA='TRUE'
MASKFASTA='TRUE'
FILTER_HIGHDEPTH='TRUE'
EXTRACT_LOCUSFASTA='TRUE'
LOCUSSTATS='TRUE'
while getopts 'ZCVWMDES' flag; do
  case "${flag}" in
  	C) MAKEMASK_CALLABLE='FALSE' ;;  
  	V) MAKEMASK_VCF='FALSE' ;;
  	W) DO_WGFASTA='FALSE' ;;
  	M) MASKFASTA='FALSE' ;;
  	D) FILTER_HIGHDEPTH='FALSE' ;;
  	E) EXTRACT_LOCUSFASTA='FALSE' ;;
  	S) LOCUSSTATS='FALSE' ;;
  esac
done

## Additional args:
if [ -s $BED_EXONS ]
then
	MASK_EXONS=TRUE
else
	MASK_EXONS=FALSE
fi

REMOVE_MINUS="FALSE"

## Process - output files:
CALLABLE_SUMMARY=$BASEDIR/bed/$IND.callable_summary.txt
BED_CALLABLE_RAW=$BASEDIR/bed/$IND.callable_raw.bed
BED_CALLABLE=$BASEDIR/bed/$IND.callable.bed
BED_NOTCALLABLE=$BASEDIR/bed/$IND.notcallable.bed
BED_FILTVCF=$BASEDIR/bed/$IND.filtVCF.bed
BED_RAWVCF=$BASEDIR/bed/$IND.rawVCF.bed
BEDMASK_VCF=$BASEDIR/bed/$IND.badVCFsites.bed

WGFASTA_RAW=$BASEDIR/fasta/byInd/$IND.wg.raw
WGFASTA_MASKED=$BASEDIR/fasta/byInd/$IND.wg.masked
LOCUSFASTA_MASKED=$BASEDIR/fasta/byInd/$IND.locus.masked
LOCUSFASTA_TRIMMED=$BASEDIR/fasta/byInd/$IND.locus.trimmed

LOCUSSTATS1=$BASEDIR/loci/$IND.locusstats1 #.bed and .txt versions will be written
LOCUSSTATS2=$BASEDIR/loci/$IND.locusstats2.txt

TMP=$BASEDIR/fasta/byInd/tmp/$IND

## Report:
echo -e "\n#####################################################################"
date
echo "#### stacksfa_ind.sh: Starting script."
echo "#### stacksfa_ind.sh: Individual: $IND"
echo "#### stacksfa_ind.sh: Raw Stacks fasta (input): $FASTA_RAW"
echo "#### stacksfa_ind.sh: Bamfile: $BAM"
echo "#### stacksfa_pip.sh: VCF - raw: $VCF_RAW"
echo "#### stacksfa_pip.sh: VCF - filtered: $VCF_FILT"
echo "#### stacksfa_pip.sh: VCF - high-depth: $VCF_HIDEPTH"
echo "#### stacksfa_ind.sh: Ref genome: $REF"
echo "#### stacksfa_ind.sh: Scaffold file: $SCAF_FILE"
echo "#### stacksfa_ind.sh: Base (Stacks) dir: $BASEDIR"
echo "#### stacksfa_ind.sh: Callable command: $CALLABLE_COMMAND"
printf "\n"
echo "#### stacksfa_ind.sh: Masked fasta (output): $WGFASTA_MASKED"
echo "#### stacksfa_ind.sh: Callable summary: $CALLABLE_SUMMARY"
echo "#### stacksfa_ind.sh: Bed- callable - raw: $BED_CALLABLE_RAW"
echo "#### stacksfa_ind.sh: Bed- callable: $BED_CALLABLE"
echo "#### stacksfa_ind.sh: Bed- not-callable (*mask*): $BED_NOTCALLABLE"
echo "#### stacksfa_ind.sh: Bed- filtered vcf: $BED_FILTVCF"
echo "#### stacksfa_ind.sh: Bed- raw vcf: $BED_RAWVCF"
echo "#### stacksfa_ind.sh: Bed- mask for vcf (*mask*): $BEDMASK_VCF"
echo "#### stacksfa_ind.sh: Bed- exons (*mask*): $BED_EXONS"
echo "#### stacksfa_ind.sh: Raw by-ind fasta: $WGFASTA_RAW"
printf "\n"
echo "#### stacksfa_ind.sh: Locusstats1: $LOCUSSTATS1"
echo "#### stacksfa_ind.sh: Locusstats2: $LOCUSSTATS2"
printf "\n"
echo "#### stacksfa_ind.sh: Remove loci on minus strand: $REMOVE_MINUS"
echo "#### stacksfa_ind.sh: Mask exons: $MASK_EXONS"
printf "\n"
echo "#### stacksfa_ind.sh: MAKEMASK_CALLABLE: $MAKEMASK_CALLABLE"
echo "#### stacksfa_ind.sh: MAKEMASK_VCF: $MAKEMASK_VCF"
echo "#### stacksfa_ind.sh: WGFASTA: $DO_WGFASTA"
echo "#### stacksfa_ind.sh: MASKFASTA: $MASKFASTA"
echo "#### stacksfa_ind.sh: FILTER_HIGHDEPTH: $FILTER_HIGHDEPTH"
echo "#### stacksfa_ind.sh: EXTRACT_LOCUSFASTA: $EXTRACT_LOCUSFASTA"
echo "#### stacksfa_ind.sh: LOCUSSTATS: $LOCUSSTATS"
printf "\n"

## Vcf files:
[[ -e $VCF_RAW.gz ]] && [[ ! -e $VCF_RAW ]] && echo -e "\n#### Unzipping VCF_RAW..." && gunzip -f $VCF_RAW.gz
[[ -e $VCF_FILT.gz ]] && [[ ! -e $VCF_FILT ]] && echo -e "\n#### Unzipping VCF_FILT..." && gunzip -f $VCF_FILT.gz
[[ -e $VCF_HIDEPTH.gz ]] && [[ ! -e $VCF_HIDEPTH ]] && echo -e "\n#### Unzipping VCF_HIDEPTH..." && gunzip -f $VCF_HIDEPTH.gz

echo "#### stacksfa_ind.sh: Listing VCF files..."
ls -lh $VCF_RAW
printf "\n"
ls -lh $VCF_FILT
printf "\n"
ls -lh $VCF_HIDEPTH
printf "\n"

## Make temporary dir.
[[ ! -d tmpdir ]] && mkdir tmpdir

## Remove old index files:
rm -f $WGFASTA_MASKED*fai $WGFASTA_RAW*fai $TMP*fai $BASEDIR/fasta/byInd/*fai


################################################################################
#### STEP 1: CREATE MASK A: NON-CALLABLE SITES ####
################################################################################
echo -e "\n\n###################################################################"
if [ $MAKEMASK_CALLABLE == TRUE ]                        
then
	echo -e "#### stacksfa_ind.sh: Running GATK CallableLoci..."
	echo -e "#### stacksfa_ind.sh: CallableLoci output - summary table: $CALLABLE_SUMMARY"
	echo -e "#### stacksfa_ind.sh: CallableLoci output - bed file: $BED_CALLABLE \n"
	
	## Run CallableLoci:
	$JAVA -Xmx4G -jar $GATK -T CallableLoci -R $REF -I $BAM \
		-summary $CALLABLE_SUMMARY $CALLABLE_COMMAND -o $BED_CALLABLE_RAW
	
	echo -e "\n#### stacksfa_ind.sh: Resulting bedfile (BED_OUT):"
	ls -lh $BED_CALLABLE_RAW
	
	## Edit bedfile to include only non-callable loci:
	echo -e "\n#### stacksfa_ind.sh: Editing bedfile to include only non-callable loci..."
	grep -v "CALLABLE" $BED_CALLABLE_RAW > $BED_NOTCALLABLE
	grep "CALLABLE" $BED_CALLABLE_RAW > $BED_CALLABLE
	
	echo -e "\n#### stacksfa_ind.sh: Resulting bedfile with non-callable sites (BED_NOTCALLABLE):"
	ls -lh $BED_NOTCALLABLE
	echo -e "\n#### stacksfa_ind.sh: Resulting bedfile with callable sites (BED_CALLABLE):"
	ls -lh $BED_CALLABLE
	
	rm -f $BED_CALLABLE_RAW
else
	echo -e "#### stacksfa_ind.sh: SKIPPING step 1: create CallableLoci mask"
fi


################################################################################
#### STEP 2: CREATE MASK B: FILTERED SITES FROM VCF ####
################################################################################
echo -e "\n\n###################################################################"
if [ $MAKEMASK_VCF == TRUE ]
then
	echo -e "#### stacksfa_ind.sh: Step 2: Creating mask from vcf files..."
	$VCF2BED --sort-tmpdir=tmpdir --max-mem=4G < $VCF_FILT | cut -f 1,2,3 > $BED_FILTVCF
	$VCF2BED --sort-tmpdir=tmpdir --max-mem=4G < $VCF_RAW | cut -f 1,2,3 > $BED_RAWVCF
	
	$BEDTOOLS intersect -v -a $BED_RAWVCF -b $BED_FILTVCF > $BEDMASK_VCF
	
	## Report:
	NLINE_UNFILT=$( cat $BED_RAWVCF | wc -l)
	NLINE_FILT=$( cat $BED_FILTVCF | wc -l)
	NLINE_RM=$( cat $BEDMASK_VCF | wc -l)
	echo -e "\n#### stacksfa_ind.sh: Linecount - unfiltered: $NLINE_UNFILT"
	echo "#### stacksfa_ind.sh: Linecount - filtered: $NLINE_FILT"
	echo "#### stacksfa_ind.sh: Linecount - removed-sites: $NLINE_RM"
else
	echo -e "#### stacksfa_ind.sh: SKIPPING step 2: create VCF mask"
fi


################################################################################
#### STEP 3: CREATE WHOLE-GENOME FASTA ####
################################################################################
echo -e "\n\n###################################################################"
if [ $DO_WGFASTA == TRUE ]
then
	echo -e "#### stacksfa_ind.sh: Step 3: preparing the fasta file...\n"
	
	egrep -A 1 "$IND" $FASTA_RAW | grep -v "\-\-" | \
		sed -E 's/>CLocus_([0-9]+)_.*Allele_([0-1]).*; (.*), ([0-9]+), (.).*/>\3:\4:\5:A\2:L\1/' > $TMP.fa # 1:Locus / 2: Allele / 3: Scaffold / 4: start / 5: strand
	
	echo -e "#### stacksfa_ind.sh: Head of fasta file with edited headers:"
	head -n 3 $TMP.fa
	
	NLOCI=$(cat $TMP.fa | wc -l)
	echo -e "\n#### stacksfa_ind.sh: Number of loci: $NLOCI"
	
	if [ $REMOVE_MINUS == "TRUE" ]
	then
		echo -e "#### stacksfa_ind.sh: Removing loci on minus strand..."
		mv $TMP.fa $TMP.tmp.fa
		grep -A 1 ":+:" $TMP.tmp.fa | grep -v "\-\-" > $TMP.fa
		
		NLOCI=$(cat $TMP.fa | wc -l)
		echo -e "\n#### stacksfa_ind.sh: Number of loci after removing minus loci: $NLOCI"
	fi
	
	for ALLELE in A0 A1
	do
		echo -e "\n#### stacksfa_ind.sh: Allele: $ALLELE"
		
		INFILE_BED=$BASEDIR/bed/$IND.$ALLELE.raw.bed
		INFILE_SEQS=$BASEDIR/bed/$IND.$ALLELE.raw.seqs
		
		echo -e "#### stacksfa_ind.sh: Prepping files for genomefasta script..." 
		egrep -A 1 ":$ALLELE:" $TMP.fa | grep -v "\-\-" > $TMP.$ALLELE.fa # Get fasta with only focal allele (chromosome)
		grep ">" $TMP.$ALLELE.fa | sed 's/:/\t/g' | sed 's/>//' | sed 's/\tA[0-1]//' > $TMP.$ALLELE.1.bed # Create locus bedfile
		cut -f 4 $TMP.$ALLELE.1.bed > $TMP.$ALLELE.locusIDs # Get Locus IDs
		grep -v ">" $TMP.$ALLELE.fa > $TMP.$ALLELE.seqs1 # Get just the sequences
		paste $TMP.$ALLELE.locusIDs $TMP.$ALLELE.seqs1 > $INFILE_SEQS # Add locus IDs to sequences
		
		cat $TMP.$ALLELE.seqs1 | awk '{print length}' > $TMP.$ALLLELE.seqlen # Get just the sequence lengths for each locus
		paste $TMP.$ALLELE.1.bed $TMP.$ALLLELE.seqlen > $INFILE_BED # Add sequence lengths to locus bedfile
		
		echo -e "#### stacksfa_ind.sh: Calling genomefasta script..."
		echo -e "#### stacksfa_ind.sh: Locusstats1: $LOCUSSTATS1"
		OUTDIR_FASTA_SCAF=$BASEDIR/fasta/byInd/byScaf/
		[[ ! -d $OUTDIR_FASTA_SCAF ]] && mkdir -p $OUTDIR_FASTA_SCAF 
		
		$SCR_GENOMEFASTA $IND.$ALLELE $INFILE_BED $INFILE_SEQS $SCAF_FILE $OUTDIR_FASTA_SCAF $LOCUSSTATS1
		
		echo -e "#### stacksfa_ind.sh: Concatenating fasta for each scaffold..."
		ls -lh $OUTDIR_FASTA_SCAF/$IND.${ALLELE}_*fa
		cat $OUTDIR_FASTA_SCAF/$IND.${ALLELE}_*fa > $WGFASTA_RAW.$ALLELE.fasta
		
		echo -e "#### stacksfa_ind.sh: Removing temporary files..."
		rm -f $TMP.$ALLELE
		rm -f $OUTDIR_FASTA_SCAF/$IND.${ALLELE}*
		
		echo -e "\n#### stacksfa_ind.sh: Indfasta file:"
		ls -lh $WGFASTA_RAW.$ALLELE.fasta
	done
else
	echo -e "#### stacksfa_ind.sh: SKIPPING step 3: prep fasta"
fi


################################################################################
#### STEP 4: MASK WHOLE-GENOME FASTA FILE ####
################################################################################
echo -e "\n\n###################################################################"
if [ $MASKFASTA == TRUE ]
then
	echo -e "#### stacksfa_ind.sh: Step 4: Running bedtools maskfasta - separately for A0 and A1..."
	
	for ALLELE in A0 A1
	do
		echo -e "\n#### stacksfa_ind.sh: Allelle: $ALLELE"
		
		echo "#### stacksfa_ind.sh: Mask A: Masking non-callable sites..."
		$BEDTOOLS maskfasta -fi $WGFASTA_RAW.$ALLELE.fasta -bed $BED_NOTCALLABLE -fo $TMP.$ALLELE.callablemasked
		
		echo -e "#### stacksfa_ind.sh: Mask B: Masking removed (filtered-out) sites..."
		$BEDTOOLS maskfasta -fi $TMP.$ALLELE.callablemasked -bed $BEDMASK_VCF -fo $TMP.$ALLELE.vcfmasked
		
		if [ $MASK_EXONS == "TRUE" ]
		then
			echo -e "#### stacksfa_ind.sh: Mask C: Masking exons..."
			$BEDTOOLS maskfasta -fi $TMP.$ALLELE.vcfmasked -bed $BED_EXONS -fo $WGFASTA_MASKED.$ALLELE.fasta
		else
			cp $TMP.$ALLELE.vcfmasked $WGFASTA_MASKED.$ALLELE.fasta	
		fi
		
		echo -e "#### stacksfa_ind.sh: Resulting fasta file WGFASTA_MASKED:"
		ls -lh $WGFASTA_MASKED.$ALLELE.fasta
		
		if [ $ALLELE == "A1" ]
		then
			echo -e "\n#### stacksfa_ind.sh: Counting Ns in the different fasta files (for allele A1 only)..."
			
			NCOUNT_FASTA_RAW=$(fgrep -o N $WGFASTA_RAW.$ALLELE.fasta | wc -l)
			NCOUNT_FASTA_CALLABLE=$(fgrep -o N $TMP.$ALLELE.callablemasked | wc -l)
			NCOUNT_FASTA_VCF=$(fgrep -o N $TMP.$ALLELE.vcfmasked | wc -l)
			[[ $MASK_EXONS == "TRUE" ]] && NCOUNT_FASTA_EXONS=$(fgrep -o N $WGFASTA_MASKED.$ALLELE.fasta | wc -l)
			
			echo "#### stacksfa_ind.sh: Number of Ns in FASTA_ALTREF: $NCOUNT_FASTA_RAW"
			echo "#### stacksfa_ind.sh: Number of Ns in after mask A (callable): $NCOUNT_FASTA_CALLABLE"
			echo "#### stacksfa_ind.sh: Number of Ns in after mask B (vcf): $NCOUNT_FASTA_VCF"
			[[ $MASK_EXONS == "TRUE" ]] && echo "#### stacksfa_ind.sh: Number of Ns in after mask C (exons): $NCOUNT_FASTA_EXONS"
		fi
		
		rm -f $TMP* # Remove intermediate files
	done
else
	echo -e "#### stacksfa_ind.sh: SKIPPING step 4: bedtools maskfasta"
fi


################################################################################
#### STEP 5: REMOVE HIGH-DEPTH LOCI ####
################################################################################
echo -e "\n\n###################################################################"
if [ $FILTER_HIGHDEPTH == TRUE ]
then
	echo "#### vcf2fullfa2.sh: Removing loci with excessive depth..."
	
	NR_LOCI_BEFORE=$(cat $LOCUSSTATS1.bed | wc -l)
	echo -e "\n#### vcf2fullfa2.sh: Number of loci before removing too-high-depth variants: $NR_LOCI_BEFORE"
	cp $LOCUSSTATS1.bed $LOCUSSTATS1.withHiDp.bed
	
	bedtools intersect -v -a $LOCUSSTATS1.withHiDp.bed -b $VCF_HIDEPTH > $LOCUSSTATS1.bed
	
	NR_LOCI_AFTER=$(cat $LOCUSSTATS1.bed | wc -l)
	echo -e "\n#### vcf2fullfa2.sh: Number of loci after removing too-high-depth variants: $NR_LOCI_AFTER"
else
	echo -e "#### vcf2fullfa2.sh: Skipping step 5: removal of loci with excessive depth..."
fi


################################################################################
#### STEP 6: EXTRACT BY-LOCUS FASTA ####
################################################################################
echo -e "\n\n###################################################################"
if [ $EXTRACT_LOCUSFASTA == TRUE ]
then
	echo -e "#### stacksfa_ind.sh: Step 6: Extract by-locus fasta..."
	
	for ALLELE in A0 A1
	do
		echo -e "\n#### stacksfa_ind.sh: Allelle: $ALLELE"
		
		rm -f $WGFASTA_MASKED*fai $WGFASTA_RAW*fai $TMP*fai $BASEDIR/fasta/byInd/*fai # Remove old index files
		
		echo "#### stacksfa_ind.sh: Running bedtools..."
		$BEDTOOLS getfasta -fi $WGFASTA_MASKED.$ALLELE.fasta -bed $LOCUSSTATS1.bed -name > $LOCUSFASTA_MASKED.$ALLELE.fasta
		
		echo "#### stacksfa_ind.sh: Masked by-locus fasta output file:"
		ls -lh $LOCUSFASTA_MASKED.$ALLELE.fasta
	done
else
	echo -e "#### stacksfa_ind.sh: SKIPPING step 6: extract by-locus fasta."
fi
	

################################################################################
#### STEP 7: TRIM FASTA - REMOVE ALL TRAILING Ns ####
################################################################################
echo -e "\n\n###################################################################"
if [ $LOCUSSTATS == TRUE ]
then
	echo -e "#### stacksfa_ind.sh: Step 7: Trim fasta..."
	
	for ALLELE in A0 A1
	do
		echo -e "\n#### stacksfa_ind.sh: Allelle: $ALLELE"
		
		## Plus-strand:
		grep -A 1 "_strand+" $LOCUSFASTA_MASKED.$ALLELE.fasta | grep -v "\-\-" > $LOCUSFASTA_MASKED.$ALLELE.plus.fasta
		awk '{
			header=$0;
			getline;
			for(five_prime=1;five_prime<length($1)-5;five_prime++) {
				s=substr($1,five_prime,5);
				break;
			}
			for(three_prime=length($1)-4;three_prime>five_prime;three_prime--) {
				s=substr($1,three_prime,5);
				if(index(s,"N")==0) break;
			}
			printf("%s\n%s\n",header,substr($1,five_prime,three_prime-five_prime+5));
		}' $LOCUSFASTA_MASKED.$ALLELE.plus.fasta > $LOCUSFASTA_TRIMMED.$ALLELE.plus.fasta
		
		## Minus-strand:
		grep -A 1 "_strand-" $LOCUSFASTA_MASKED.$ALLELE.fasta | grep -v "\-\-" > $LOCUSFASTA_MASKED.$ALLELE.minus.fasta
		awk '{
			header=$0;
			getline;
			for(five_prime=1;five_prime<length($1)-5;five_prime++) {
				s=substr($1,five_prime,5);
				if(index(s,"N")==0) break;
			}
			for(three_prime=length($1)-4;three_prime>five_prime;three_prime--) {
				s=substr($1,three_prime,5);
				break;
			}
			printf("%s\n%s\n",header,substr($1,five_prime,three_prime-five_prime+5));
		}' $LOCUSFASTA_MASKED.$ALLELE.minus.fasta > $LOCUSFASTA_TRIMMED.$ALLELE.minus.fasta
		
		## Concatenate + and -:
		cat $LOCUSFASTA_TRIMMED.$ALLELE.plus.fasta $LOCUSFASTA_TRIMMED.$ALLELE.minus.fasta > $LOCUSFASTA_TRIMMED.$ALLELE.fasta
		
		echo -e "#### stacksfa_ind.sh: Trimmed by-locus fasta output file:"
		ls -lh $LOCUSFASTA_TRIMMED.$ALLELE.fasta
		
	done
else
	echo -e "#### stacksfa_ind.sh: SKIPPING step 7: trim fasta."
fi	


################################################################################
#### STEP 8: GET LOCUSSTATS2 ####
################################################################################
echo -e "\n\n###################################################################"
if [ $LOCUSSTATS == TRUE ]
then
	echo -e "#### stacksfa_ind.sh: Step 8: Get locus-stats (only for A0 allele)...\n"
	
	ALLELE=A0
	
	## Get locus positions, seqlengths and nmiss for each locus:
	grep ">" $LOCUSFASTA_TRIMMED.$ALLELE.fasta > $TMP.headers # Create locus bedfile
	grep -v ">" $LOCUSFASTA_TRIMMED.$ALLELE.fasta > $TMP.seqs1 # Get just the sequences
	
	cat $TMP.seqs1 | awk '{print length}' > $TMP.seqlen # Get sequence lengths for each locus
	awk -F"N" '{print NF-1}' $TMP.seqs1 > $TMP.nmiss # Get number of Ns for each locus
	paste $TMP.headers $TMP.seqlen $TMP.nmiss > $LOCUSSTATS2 # Add seqlen + nmiss to locus bedfile

	echo "#### stacksfa_ind.sh: Locusstats file:"
	ls -lh $LOCUSSTATS2
	printf "\n"
	head $LOCUSSTATS2
	
	NLOCI_FINAL=$(cat $LOCUSSTATS2 | wc -l)
	echo -e "\n#### stacksfa_ind.sh: Number of final loci: $NLOCI_FINAL"
else
	echo -e "#### stacksfa_ind.sh: SKIPPING step 8: get locus-stats.\n"
fi


## Report:
echo -e "\n\n#### stacksfa_ind.sh: Done with script."
date
