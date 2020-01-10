#!/bin/bash
set -e
set -o pipefail
set -u

FASTQ=$1
CUTSITE=$2
OUTFILE=$3

echo "##### checkBarcodes.sh: Starting script."
echo "##### checkBarcodes.sh: Fastq file: $FASTQ"
echo "##### checkBarcodes.sh: Cut site: $CUTSITE"
echo "##### checkBarcodes.sh: Output file: $OUTFILE"

echo "##### checkBarcodes.sh: Starting grepping..."
zgrep $CUTSITE $FASTQ | egrep -o "^[A-Z]{10}$CUTSITE" | sed -E "s/[A-Z][A-Z](.*)$CUTSITE/\1/" | sort | uniq -c > $OUTFILE

echo "##### checkBarcodes.sh: Head of output file:"
head $OUTFILE

echo "##### checkBarcodes.sh: Done with script."
date