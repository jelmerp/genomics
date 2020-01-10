#!/bin/bash
set -e
set -o pipefail
set -u

################################################################################
##### SET-UP #####
################################################################################
date
echo "##### Script: stitchScaffolds.sh"
printf "\n"

## Software:
PYTHON3=/datacommons/yoderlab/programs/Python-3.6.3/python
JAVA=/datacommons/yoderlab/programs/java_1.8.0/jre1.8.0_144/bin/java
PICARD=/datacommons/yoderlab/programs/picard_2.13.2/picard.jar
SAMTOOLS=/datacommons/yoderlab/programs/samtools-1.6/samtools
SCAFFOLD_STITCHER=/datacommons/yoderlab/users/jelmer/software/scaffoldStitcher/ScaffoldStitcher.py # https://bitbucket.org/dholab/scaffoldstitcher/src

## Command-line args:
ID_IN=$1
shift
ID_OUT=$1
shift
NR_N=$1
shift
MAXLENGTH=$1
shift
IDENTIFIER=$1
shift
REF_DIR=$1
shift
SCAF_EXCLUDE_INFILE=$1
shift
SCAF_SIZES_INFILE=$1
shift

## Process args:
FASTA_IN=$REF_DIR/$ID_IN.fasta
FASTA_OUT=$REF_DIR/$ID_OUT.fasta

SCAF_INDEX_INFILE=$REF_DIR/$ID_OUT.scaffoldIndex.txt # Created by scaffoldStitcher
SCAF_INDEX_OUTFILE=$REF_DIR/$ID_OUT.scaffoldIndexLookup.txt # Created by stitchScaffolds_extract.R
SCAF_EXCLUDE_OUTFILE=$REF_DIR/$ID_OUT.nonAutosomalCoords.bed # Created by stitchScaffolds_extract.R
SCAFLIST_FILE=$REF_DIR/$ID_OUT.scaffoldList.txt # Created by stitchScaffolds_extract.R

## Report:
echo "##### Ref dir: $REF_DIR"
echo "##### ID in: $ID_IN"
echo "##### ID out: $ID_OUT"
echo "##### Nr Ns between scaffolds: $NR_N"
echo "##### Max length of superscaffold: $MAXLENGTH"
echo "##### Identifier to distinguish scaffolds that should be merged: $IDENTIFIER"
printf "\n"
echo "##### Fasta in: $FASTA_IN"
echo "##### Fasta out: $FASTA_OUT"
printf "\n"
echo "##### Infile with scaffold sizes: $SCAF_SIZES_INFILE"
echo "##### Infile with index of superscaffolds-to-scaffolds: $SCAF_INDEX_INFILE"
echo "##### Infile with scaffolds to exclude: $SCAF_EXCLUDE_INFILE"
echo "##### Outfile with lookup for superscaffolds-to-scaffolds $SCAF_INDEX_OUTFILE"
echo "##### Outfile (bed) with regions to exclude from bam: $SCAF_EXCLUDE_OUTFILE"
echo "##### Outfile with list of scaffolds: $SCAFLIST_FILE"
printf "\n\n"


################################################################################
##### STITCH SCAFFOLDS #####
################################################################################

## Stitch scaffolds in new reference fasta:
echo "#### Creating stitched ref genome..."
$PYTHON3 $SCAFFOLD_STITCHER -fasta $FASTA_IN -identifier $IDENTIFIER -nlength $NR_N -maxlength $MAXLENGTH > $FASTA_OUT
# nlength = N spacer length between scaffolds; maxlength = max. super scaffold length
printf "\n\n\n"

mv $REF_DIR/${ID_IN}_scaffold_index.txt $SCAF_INDEX_INFILE


################################################################################
##### INDEX NEW FASTA #####
################################################################################

## Index new fasta with samtools, picard, and bwa:
echo "#### Indexing ref genome with samtools..."
$SAMTOOLS faidx $FASTA_OUT
printf "\n"

echo "#### Indexing ref genome with picard..."
[[ -f $REF_DIR/$ID_OUT.dict ]] && echo "Deleting old dictionary file..." && rm $REF_DIR/$ID_OUT.dict
$JAVA -Xmx4g -jar $PICARD CreateSequenceDictionary R=$FASTA_OUT O=$REF_DIR/$ID_OUT.dict
printf "\n"

echo "#### Indexing ref genome with bwa..."
scripts/misc/indexGenome.sh $FASTA_OUT
printf "\n\n\n"


################################################################################
##### CREATE BEDFILE AND LOOKUP TABLE #####
################################################################################

## Create bedfile with regions to exclude, and superscaffold-to-scaffold location lookup table:
echo "#### Running R script for superscaffold-to-scaffold location lookup table..."
module load R
Rscript scripts/pipeline_misc/stitchScaffolds_extract.R $SCAF_SIZES_INFILE $SCAF_INDEX_INFILE \
	$SCAF_EXCLUDE_INFILE $SCAF_INDEX_OUTFILE $SCAF_EXCLUDE_OUTFILE $SCAFLIST_FILE $NR_N


## Report:
echo "Done with script stitchScaffolds.sh"
date