#!/bin/bash
set -e
set -o pipefail
set -u

################################################################################
#### SET-UP ####
################################################################################
## Software:
# faidx needs to be available using "faidx" command

## Command-line args:
FILE_ID=$1
shift
FASTADIR=$1
shift
LOCUSDIR=$1
shift
GPHOCS_INPUT=$1
shift

## Process:
INPUTDIR=$(dirname $GPHOCS_INPUT)

[[ ! -d $LOCUSDIR ]] && mkdir -p $LOCUSDIR
[[ ! -d $INPUTDIR ]] && mkdir -p $INPUTDIR

## Report:
echo -e "\n####  gphocs_prepinput.sh: Starting script."
date
echo -e "#### gphocs_prepinput.sh: File ID: $FILE_ID"
echo -e "#### gphocs_prepinput.sh: Fasta dir: $FASTADIR"
echo -e "#### gphocs_prepinput.sh: Dir for indiv loci: $LOCUSDIR"
echo -e "#### gphocs_prepinput.sh: Dir for final G-PhoCS input file: $INPUTDIR"
echo -e "\n#### gphocs_prepinput.sh: Gphocs input file (to create): $GPHOCS_INPUT"

## Remove pre-existing files:
rm -f $LOCUSDIR/*$FILE_ID*


################################################################################
#### CONVERT FASTA TO GPHOCS INPUT FORMAT FOR EACH LOCUS ####
################################################################################
NLOCI_1=$(find $FASTADIR -maxdepth 1 -type f -name '*fa' | wc -l)
echo -e "\n#### gphocs_prepinput.sh: Number of loci: $NLOCI_1"

COUNT=0
echo -e "\n#### gphocs_prepinput.sh: Cycling through loci..."

for FASTA_ID_LONG in $(find $FASTADIR -maxdepth 1 -type f -name '*fa')
do
	FASTA_ID=$(basename $FASTA_ID_LONG)
	BASEFILE=$LOCUSDIR/$FILE_ID.$FASTA_ID
	
	sed 's/__.*//' $FASTADIR/$FASTA_ID | sed -e 's/.*_\(.*_A[01]\)_.*/>\1/' > $BASEFILE.tmp1
	faidx --transform transposed $BASEFILE.tmp1 | tee $BASEFILE.tmp2 | cut -f 1,4 > $BASEFILE.tmp3
	
	SEQLEN=$(cut -f 3 $BASEFILE.tmp2 | head -n 1)
	NRSEQS=$(cat $BASEFILE.tmp2 | wc -l)
	
	if [ NRSEQS != 0 ]
	then
		echo "$FASTA_ID $NRSEQS $SEQLEN"
		if [ SEQLEN != 0 ]
		then
			echo "$FASTA_ID $NRSEQS $SEQLEN" > $BASEFILE.locus
			cat $BASEFILE.tmp3 >> $BASEFILE.locus
		else
			echo "#### gphocs_prepinput.sh: Skipping locus (seqlength=0)..."
		fi
	else
		echo "#### gphocs_prepinput.sh: Skipping locus (no sequences)..."
	fi
done

## Remove temp files:
rm -f $LOCUSDIR/*tmp*
rm -f $LOCUSDIR/*fai

################################################################################
#### COMBINE LOCI INTO FINAL GPHOCS INPUT FILE ####
################################################################################
echo -e "\n#### gphocs_prepinput.sh: Combining single-locus files..."

## Get rid of empty loci:
#NREMPTY=$(grep " 0 " $LOCUSLIST | wc -l)
#echo -e "#### gphocs_prepinput.sh: Number of loci with no sequences: $NREMPTY"
#echo -e "#### gphocs_prepinput.sh: Showing loci with no sequences:"
#grep " 0 " $LOCUSLIST

## Count and print number of loci:
NLOCI_2=$(find $FASTADIR -maxdepth 1 -type f -name '*fa' | wc -l) 
printf "${NLOCI_2}\n\n" > $GPHOCS_INPUT
echo -e "#### Number of loci: $NLOCI_2"

## Add loci to file:
find $LOCUSDIR -maxdepth 1 -name "$FILE_ID.*locus" -type f -exec cat {} + >> $GPHOCS_INPUT

## Get rid of unexplained whitespace:
NRSEQS=$(grep -E "[ACGTRWSYKN] +[ACGTRWSYKN]" $GPHOCS_INPUT | wc -l)
echo -e "\n#### gphocs_prepinput.sh: Number of seqs with whitespace: $NRSEQS"

cat $GPHOCS_INPUT | \
	sed -E "s/([ACGTRWSYKN]) ([ACGTRWSYKN])/\1N\2/g" | \
	sed -E "s/([ACGTRWSYKN]) ([ACGTRWSYKN])/\1N\2/g" | \
	sed -E "s/([ACGTRWSYKN])  ([ACGTRWSYKN])/\1NN\2/g" | \
	sed -E "s/([ACGTRWSYKN])   ([ACGTRWSYKN])/\1NNN\2/g" | \
	sed -E "s/([ACGTRWSYKN])    ([ACGTRWSYKN])/\1NNNN\2/g" > $GPHOCS_INPUT.tmp

NRSEQS=$(grep -E "[ACGTRWSYKN] +[ACGTRWSYKN]" $GPHOCS_INPUT.tmp | wc -l)
echo "#### gphocs_prepinput.sh: Number of seqs with whitespace after removal: $NRSEQS"

## Remove temp files:
rm -f $GPHOCS_INPUT.tmp


################################################################################
#### REPORT ####
################################################################################
echo -e "\n#### gphocs_prepinput.sh: Final file:"
ls -lh $GPHOCS_INPUT

echo -e "\n#### gphocs_prepinput.sh: Done with script."
date



################################################################################
## Remove empty locus files:
#EMPTY_LOCI=( $(grep " 0 " $LOCUSLIST | cut -d " " -f 1) )
#for EMPTY_LOCUS in ${EMPTY_LOCI[@]}
#do
#	rm $LOCUSDIR/$FILE_ID.$EMPTY_LOCUS.locus
#done
#mv $LOCUSLIST $LOCUSLIST.tmp
#grep -v " 0 " $LOCUSLIST.tmp > $LOCUSLIST
#rm $LOCUSLIST.tmp

## Get rid of empty loci:
# NREMPTY=$(grep " 0 " $GPHOCS_INPUT.tmp | wc -l)
# echo -e "#### gphocs_prepinput.sh: Number of loci with no sequences: $NREMPTY"
# grep -v " 0 " $GPHOCS_INPUT.tmp > $GPHOCS_INPUT
