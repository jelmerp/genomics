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
SPIDFILE=$3
MEM=$4

## Report:
echo -e "\n################################################################################"
date
echo "##### convert2newhybrids.sh: Starting script."
echo "##### convert2newhybrids.sh: Slurm Job ID: $SLURM_JOB_ID"
echo "##### convert2newhybrids.sh: Input file: $INFILE"
echo "##### convert2newhybrids.sh: Output file: $OUTFILE"
echo "##### convert2newhybrids.sh: SPID file: $SPIDFILE"
echo "##### convert2newhybrids.sh: Memory: $MEM"
printf "\n"


################################################################################
##### CONVERT TO NEWHYBRIDS FORMAT #####
################################################################################
## Run PGDS-Spider:
echo "##### convert2newhybrids.sh: Converting with PGDS-Spider..."
java -Xmx${MEM}G -Xms${MEM}G -jar $PGDS -inputfile $INFILE -inputformat VCF -outputfile $OUTFILE.tmp -outputformat NEWHYBRIDS -spid $SPIDFILE
printf "\n"

## Get sample IDs into first column instead of numbers:
echo "##### convert2newhybrids.sh: Editing sample names..."
head -n 5 $OUTFILE.tmp > $OUTFILE.tmp.firstlines 
tail -n +6 $OUTFILE.tmp > $OUTFILE.tmp.cut
bcftools query -l $INFILE | paste - <( cut -d ' ' -f 2- $OUTFILE.tmp.cut ) > $OUTFILE.tmp.replaced
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

echo "##### convert2newhybrids.sh: Showing first three columns of Newhybrids input file:"
cat $OUTFILE | cut -f 1,2,3 -d " "
printf "\n"

echo "##### convert2newhybrids.sh: Done with script."
date
printf "\n"
