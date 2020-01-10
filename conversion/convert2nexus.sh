#!/bin/bash
set -e
set -o pipefail
set -u


### SOFTWARE & SCRIPTS ###
PGDS=/datacommons/yoderlab/programs/PGDSpider_2.1.1.3/PGDSpider2-cli.jar


### COMMANDLINE ARGS ###
INFILE=$1
OUTFILE=$2
INFORMAT=$3
SPIDFILE=$4 #scripts/conversion/fasta2nexus.spid
MEM=$5

date
echo "Script: $SLURM_JOB_NAME"
echo "Job ID: $SLURM_JOB_ID"
echo "Input file: $INFILE"
echo "Output file: $OUTFILE"
echo "Input format: $INFORMAT"
echo "SPID file: $SPIDFILE"


### RUN PGDSPIDER ###
java -Xmx${MEM}G -Xms${MEM}G -jar $PGDS -inputfile $INFILE -inputformat $INFORMAT -outputfile $OUTFILE.tmp -outputformat NEXUS -spid $SPIDFILE && \


### REMOVE TAXON SETS BLOCK FROM NEXUS ###
cat $OUTFILE.tmp | head -n -1 | grep -v "BEGIN SETS" | grep -v "TaxSet" | grep -v "TaxPartition" | grep -v pop_1 > $OUTFILE && \
rm $OUTFILE.tmp && \
rm *log


echo "Done with script."
date
