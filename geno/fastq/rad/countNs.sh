#!/bin/bash
set -e
set -o pipefail
set -u

FASTQ=$1
OUTFILE=$2

ID=$(basename $FASTQ .fastq.gz)

echo "##### countNs.sh: Starting script."
echo "##### countNs.sh: Fastq file: $FASTQ"
echo "##### countNs.sh: Output file: $OUTFILE"
echo "##### countNs.sh: ID: $ID"

> $OUTFILE

echo "##### countNs.sh: Converting to tab-sep file..."
zcat $FASTQ | grep ^[A-Z] | cut -c-16 | sed 's/\(.\)/\1 /g' > $ID.first16.txt

echo "##### countNs.sh: Looping through columns:"
for i in {1..16}
do
	NR_N=$(cut -d" " -f $i $ID.first16.txt | tr -cd N | wc -c)
	echo "$i $NR_N"
	echo "$i $NR_N" >> $OUTFILE
done

echo "##### countNs.sh: Done with script."
date