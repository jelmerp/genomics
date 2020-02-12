#!/bin/bash
set -e
set -o pipefail
set -u

## Script to edit readgroup info in bamfiles using Picardtools.
## Positional arguments:
## 1: Input file (bam)
## 2: Output file (bam)
## 3: Sample ID (RGSM tag)
## 4: Lane ID (RGID tag)
## 5: Library ID (RGLB tag)
## RGPL (Sequencing Platform) and RGPU (barcode) are hardcoded.

## Software:
JAVA=/datacommons/yoderlab/programs/java_1.8.0/jre1.8.0_144/bin/java
PICARD=/datacommons/yoderlab/programs/picard_2.13.2/picard.jar

## Command-line args:
INPUT=$1
OUTPUT=$2
ID=$3
LANE=$4
LIBRARY=$5

## Report:
date
echo "#### readgroup_edit.sh: Starting script."
echo "#### readgroup_edit.sh: Input file name: $INPUT"
echo "#### readgroup_edit.sh: Output file name: $OUTPUT"
echo "#### readgroup_edit.sh: Individual/sample ID: $ID"
echo "#### readgroup_edit.sh: Lane: $LANE"
echo "#### readgroup_edit.sh: Library: $LIBRARY"
printf "\n\n"

## Run Picard:
$JAVA -jar $PICARD AddOrReplaceReadGroups VALIDATION_STRINGENCY=SILENT \
INPUT=$INPUT OUTPUT=$OUTPUT RGID=$LANE RGLB=$LIBRARY RGPL=illumina RGSM=$ID RGPU=barcode1

## Report:
echo "#### readgroup_edit.sh: Done with script."
date