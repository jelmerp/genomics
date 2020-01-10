#!/bin/bash
set -e
set -o pipefail
set -u

################################################################################
##### SETUP #####
################################################################################
## Software & scripts:
PGDS=/datacommons/yoderlab/programs/PGDSpider_2.1.1.3/PGDSpider2-cli.jar

## Positional args:
INFILE=$1
OUTFILE=$2
INFORMAT=$3
SPIDFILE=$4
MEM=$5

## Report:
echo -e "\n################################################################################"
date
echo "##### convert2newhybrids.sh: Starting script."
echo "##### convert2newhybrids.sh: Slurm Job ID: $SLURM_JOB_ID"
echo "##### convert2newhybrids.sh: Input file: $INFILE"
echo "##### convert2newhybrids.sh: Output file: $OUTFILE"
echo "##### convert2newhybrids.sh: Input format: $INFORMAT"
echo "##### convert2newhybrids.sh: SPID file: $SPIDFILE"
printf "\n"


################################################################################
##### CONVERT TO NEWHYBRIDS FORMAT #####
################################################################################
## Run PGDS-Spider:
echo "##### convert2newhybrids.sh: Converting with PGDS-Spider..."
java -Xmx${MEM}G -Xms${MEM}G -jar $PGDS -inputfile $INFILE -inputformat $INFORMAT -outputfile $OUTFILE.tmp -outputformat NEWHYBRIDS -spid $SPIDFILE
printf "\n"

## Get sample IDs into first column instead of numbers:
echo "##### convert2newhybrids.sh: Editing sample names..."
head -n 5 $OUTFILE.tmp > $OUTFILE.tmp.firstlines 
tail -n +6 $NEWHYBRIDS_INPUT > $NEWHYBRIDS_INPUT.tmp.cut
bcftools query -l $INFILE | paste - <( cut -d ' ' -f 2- $NEWHYBRIDS_INPUT.tmp.cut ) > $OUTFILE.tmp.replaced
cat $OUTFILE.tmp.firstlines $OUTFILE.tmp.replaced > $OUTFILE
printf "\n"

################################################################################
##### FINALIZE #####
################################################################################
## Remove temporary files:
echo "##### convert2newhybrids.sh: Removing temporary files..."
rm -f $OUTFILE.tmp*
printf "\n"

## Report:
echo "##### convert2newhybrids.sh: Listing Newhybrids input file: $OUTFILE"
ls -lh $OUTFILE
printf "\n"

echo "##### convert2newhybrids.sh: Done with script."
date
