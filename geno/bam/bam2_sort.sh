#!/bin/bash
set -e
set -o pipefail
set -u

################################################################################
#### SET-UP ####
################################################################################

## Software:
SAMTOOLS=/datacommons/yoderlab/programs/samtools-1.6/samtools

## Command-line args:
ID=$1
INDIR=$2
OUTDIR=$3
INPUT_FORMAT=$4
SUFFIX_OUT=$5
MINMAPQUAL=$6
FILTER_PROPPAIRS=$7
BAMSTATS_DIR=$8
NCORES=$9

## Process args:
INPUT=$INDIR/$ID.$INPUT_FORMAT
OUTPUT=$OUTDIR/$ID.$SUFFIX_OUT.bam
STATSFILE=$BAMSTATS_DIR/$ID.bamFilterStats.txt

NRSEQS_IN=$($SAMTOOLS view -c $INPUT)

## Create dirs if needed:
[[ ! -d $OUTDIR ]] && echo "#### geno3a_sort.sh: Creating output dir $OUTDIR" && mkdir -p $OUTDIR
[[ ! -d $BAMSTATS_DIR ]] && echo "#### geno3a_sort.sh: Creating bamstats dir $BAMSTATS_DIR" && mkdir -p $BAMSTATS_DIR

## Report:
date
echo "#### geno3a_sort.sh: Starting with script."
echo "#### geno3a_sort.sh: ID: $ID"
echo "#### geno3a_sort.sh: Indir: $INDIR"
echo "#### geno3a_sort.sh: Outdir: $OUTDIR"
echo "#### geno3a_sort.sh: Input format (sam or bam): $INPUT_FORMAT"
echo "#### geno3a_sort.sh: Output suffix: $SUFFIX_OUT"
echo "#### geno3a_sort.sh: Input: $INPUT"
echo "#### geno3a_sort.sh: Output: $OUTPUT"
echo "#### geno3a_sort.sh: Minimum mapping quality: $MINMAPQUAL"
echo "#### geno3a_sort.sh: Bamstats dir: $BAMSTATS_DIR"
echo "#### geno3a_sort.sh: Nr of cores: $NCORES"
printf "\n"


################################################################################
#### RUN ####
################################################################################
## Sort & filter by minimum mapping quality:
echo "#### geno3a_sort.sh: Sorting bam file & remove reads with MMQ smaller than $MINMAPQUAL..."
$SAMTOOLS view -bhu -q $MINMAPQUAL -@ $NCORES $INPUT | $SAMTOOLS sort -@ $NCORES -m 4G -T tmp -O bam > $OUTDIR/$ID.$SUFFIX_OUT.MQ-only.bam

NRSEQS_POSTMQ=$($SAMTOOLS view -c $OUTDIR/$ID.$SUFFIX_OUT.MQ-only.bam)
printf "\n\n"

## Filter for properly paired reads:
if [ $FILTER_PROPPAIRS == TRUE ]
then
	echo "#### geno3a_sort.sh: Filtering for properly paired reads..." 
	$SAMTOOLS view -f 0x2 $OUTDIR/$ID.$SUFFIX_OUT.MQ-only.bam -O bam > $OUTPUT
	NRSEQS_POSTPAIR=$($SAMTOOLS view -c $OUTPUT)
else
	echo "#### geno3a_sort.sh: Not filtering for properly paired reads, renaming file..." 
	mv $OUTDIR/$ID.$SUFFIX_OUT.MQ-only.bam $OUTPUT
fi


################################################################################
#### REPORTS STATS ####
################################################################################
echo -e "\n#### geno3a_sort.sh: Nr of sequences in raw bam file: $NRSEQS_IN"
echo "#### geno3a_sort.sh: Nr of sequences in MQ-filtered bam file: $NRSEQS_POSTMQ"
[[ $FILTER_PROPPAIRS == TRUE ]] && echo "#### geno3a_sort.sh: Nr of sequences in properly-paired-filtered bam file: $NRSEQS_POSTPAIR"

echo -e "\n#### geno3a_sort.sh: Listing output file:"
ls -lh $OUTPUT

echo "$INPUT" > $STATSFILE
echo "Nr of sequences in raw bam file: $NRSEQS_IN" >> $STATSFILE 
echo "Nr of sequences in MQ-filtered bam file: $NRSEQS_POSTMQ" >> $STATSFILE
[[ $FILTER_PROPPAIRS == TRUE ]] && echo "Nr of sequences in properly-paired-filtered bam file: $NRSEQS_POSTPAIR" >> $STATSFILE


################################################################################
#### HOUSEKEEPING ####
################################################################################
## Remove temp files:
rm -f $OUTDIR/$ID.$SUFFIX_OUT.MQ-only.bam

## Report:
echo -e "\n#### geno3a_sort.sh: Done with script geno3a_sort.sh"
date