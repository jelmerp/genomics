#!/bin/bash
set -e
set -o pipefail
set -u

################################################################################
#### SET-UP ####
################################################################################
## Software:
SAMTOOLS=/datacommons/yoderlab/programs/samtools-1.10/samtools

## Command-line args:
ID=$1
PREFIX_IN=$2
PREFIX_OUT=$3
BAM_DIR=$4
BAMSTATS_DIR=$5
REGION_FILE=$6

## Output files:
STATSFILE=$BAMSTATS_DIR/$ID.bamfilterstats.txt
BAM_IN=$BAM_DIR/$ID.$PREFIX_IN.bam
BAM_OUT=$BAM_DIR/$ID.$PREFIX_OUT.bam

## Temporary files_
BAM_REGIONSEL=$BAM_DIR/$ID.regionsel.bam
FIXED_HEADER=$BAM_DIR/tmp.head.$ID.sam

## Make statsdir if needed:
[[ ! -d $BAMSTATS_DIR ]] && mkdir -p $BAMSTATS_DIR

## Report:
date
echo "#### Script: $0.sh"
printf "\n"
echo "#### $0: Bam input file: $BAM_IN"
echo "#### $0: Bam output file: $BAM_OUT"
echo "#### $0: File with genomic regions to select: $REGION_FILE"
echo "#### $0: Bamstats dir: $BAMSTATS_DIR"
echo "#### $0: Bamstats file: $STATSFILE"
printf "\n"


################################################################################
#### SELECT REGIONS ####
################################################################################
echo "#### $0: Selecting only specified regions..."
$SAMTOOLS view -b -L $REGION_FILE $BAM_IN > $BAM_REGIONSEL


################################################################################
#### REHEADER ####
################################################################################
echo -e "\n#### $0: Reheading bamfile..."

## Create new (fixed) header:
$SAMTOOLS view -H $BAM_REGIONSEL | egrep -v "NW_|Super_Scaffold|NC_028718.1" > $FIXED_HEADER
	
## Replace header:
cat $FIXED_HEADER <($SAMTOOLS view $BAM_REGIONSEL) | $SAMTOOLS view -bo $BAM_OUT -

#echo -e "\n#### $0: Showing bam header:"
#$SAMTOOLS view -H $BAM_OUT

## Remove temp files:
rm -f $FIXED_HEADER
rm -f $BAM_REGIONSEL


################################################################################
#### REPORT ####
################################################################################
NRSEQS_IN=$($SAMTOOLS view -c $BAM_IN)
NRSEQS_OUT=$($SAMTOOLS view -c $BAM_OUT)
NRSEQS_REMOVED=$(($NRSEQS_IN - $NRSEQS_OUT))

echo -e "\n#### $0: Nr of sequences in: $NRSEQS_IN"
echo -e "#### $0: Nr of sequences removed: $NRSEQS_REMOVED"
echo -e "#### $0: Nr of sequences out: $NRSEQS_OUT"
echo -e "#### Nr of sequences before extracting specified scaffolds: $NRSEQS_IN" >> $STATSFILE
echo -e "#### Nr of sequences after extracting specified scaffolds: $NRSEQS_OUT" >> $STATSFILE

echo -e "\n#### $0: Listing files:"
ls -lh $BAM_DIR/$ID*bam

echo -e "\n#### $0: Done with script $0"
date


################################################################################
################################################################################
#REGION_FILE_ORG=/datacommons/yoderlab/users/jelmer/seqdata/reference/mmur/scaffolds_mapped_autosomal.samtools.bed
#FAI=/datacommons/yoderlab/users/jelmer/seqdata/reference/mmur/GCF_000165445.2_Mmur_3.0_genomic_stitched.fasta.fai
#awk '/^NC_03.*\t/ {printf("%s\t0\t%s\n",$1,$2);}' $FAI > $REGION_FILE 

#$JAVA -jar $PICARD ReplaceSamHeader I=$BAM_REGIONSEL HEADER=$FIXED_HEADER O=$BAM_OUT # Header must be in bam?