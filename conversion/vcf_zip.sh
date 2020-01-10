#!/bin/bash
set -e
set -o pipefail
set -u

## Command-line arguments:
SOURCEDIR=$1

## Report:
date
echo "Script: zipVCFs.sh"
echo "Source dir: $SOURCEDIR"
printf "\n\n\n"

## Zip non-zipped VCFs:
NONZIPPEDS=( $(find $SOURCEDIR -name "*.vcf" -not -name "*rawvariants*") )

for NONZIPPED in ${NONZIPPEDS[@]}
do
	printf "\n"
	echo "Processing file $NONZIPPED"
	[[ -f $NONZIPPED.gz ]] && echo "Zipped version also exists:" && ls -lh $NONZIPPED.gz && \
	echo "Removing $NONZIPPED" && printf "\n" && rm $NONZIPPED 
	
	[[ ! -f $NONZIPPED.gz ]] && echo "Zipping $NONZIPPED..." && gzip $NONZIPPED 
done

## Remove intermediate VCFs:
#printf "\n\n\n"
#echo "Removing GATKfiltSoft VCFs..."
#find $SOURCEDIR -name "*GATKfiltSoft*" -print0 | xargs -0 rm

## Remove intermediate bams:
#find seqdata/bam/ -name "*.sort.MQ30.bam" -print0 | xargs -0 rm

echo "Done with script."
date


## Usage:
#SOURCEDIR=seqdata/vcf
#SOURCEDIR=/work/jwp37/singlegenomes/seqdata/
#sbatch -p yoderlab,common,scavenger -o slurm.zipVCFs scripts/conversion/zipVCFs.sh $SOURCEDIR
