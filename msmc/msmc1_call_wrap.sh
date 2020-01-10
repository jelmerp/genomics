#!/bin/bash
set -e
set -o pipefail
set -u

## Variables:
BAMDIR=$1
shift
SCAFFOLD=$1
shift
PHASING=$1
shift
REF=$1
shift
MASK_INDIV_DIR=$1
shift
VCF_DIR=$1
shift
count=0; while [ "$*" != "" ]; do INDS[$count]=$1; shift; count=`expr $count + 1`; done

echo "Bamfile directory: $BAMDIR"
echo "Scaffold: $SCAFFOLD"
echo "Phasing: $PHASING"
echo "Reference genome: $REF"
echo "Mask dir: $MASK_DIR"
echo "VCF dir: $VCF_DIR"
echo "Individuals: ${INDS[@]}"

## Run script:
for IND in ${INDS[@]}
do
	# IND=mrav01; SCAFFOLD=NC_033691.1
	echo "Starting script for $IND"
	BAMFILE=$BAMDIR/$IND.dedup.bam
	echo "Bamfile: $BAMFILE"
	ls -lh $BAMFILE
	scripts/msmc/msmc1_call.sh $BAMFILE $SCAFFOLD $IND $PHASING $REF $MASK_INDIV_DIR $VCF_DIR
done

echo "Done with script"
date