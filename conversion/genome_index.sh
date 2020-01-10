#!/bin/bash
set -e
set -o pipefail
set -u

#### SOFTWARE ####
BWA=/datacommons/yoderlab/programs/bwa-0.7.15/bwa


#### COMMAND-LINE ARGUMENTS ####
REF=$1 # REF=/datacommons/yoderlab/users/jelmer/seqdata/reference/mmur3.0_FINAL_9Aug16.fasta

date
echo "Indexing reference: $REF"
echo "BWA version: $BWA"

#### INDEX WITH BWA #####
$BWA index $REF 

echo "Done with script."
date


################################################################################
## bwa flags:
# -a genome type; "is" for large genomes
# $BWA index -a is $RE



