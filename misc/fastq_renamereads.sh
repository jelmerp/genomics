#!/bin/bash
set -e
set -o pipefail
set -u

date
echo "Script: renameFastqReads.sh"

for FASTQ in /work/jwp37/radseq/seqdata/fastq/demult_dedup_trim/*R1.fastq.gz
do
	#FASTQ=/work/jwp37/radseq/seqdata/fastq/demult_dedup_trim/mzaz005_r01_p3h04.1.1_R1.fastq.gz
	NEWNAME="${FASTQ/demult_dedup_trim/demult_dedup_trim2}"
	echo "Old: $FASTQ"
	echo "New: $NEWNAME"
	zcat $FASTQ | sed "s,\/1\/1$,\/1,g" | gzip > $NEWNAME
	printf "\n"
done

for FASTQ in /work/jwp37/radseq/seqdata/fastq/demult_dedup_trim/*R2.fastq.gz
do
	NEWNAME="${FASTQ/demult_dedup_trim/demult_dedup_trim2}"
	echo "Old: $FASTQ"
	echo "New: $NEWNAME"
	zcat $FASTQ | sed "s,\/2\/2$,\/2,g" | gzip > $NEWNAME
	printf "\n"
done


echo "Done with script."
date