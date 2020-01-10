#!/bin/bash
set -e
set -o pipefail
set -u

date
echo "Script: validateBam.sh"

## SOFTWARE
JAVA=/datacommons/yoderlab/programs/java_1.8.0/jre1.8.0_144/bin/java
PICARD=/datacommons/yoderlab/programs/picard_2.13.2/picard.jar

## COMMAND-LINE ARGUMENTS
INPUT=$1
echo "Input file name: $INPUT"

## RUN PICARD
$JAVA -Xmx4g -jar $PICARD ValidateSamFile INPUT=$INPUT MODE=SUMMARY

echo "Done with script."
date