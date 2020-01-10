#!/bin/bash
set -e
set -o pipefail
set -u

## Software:
VCFTOOLS=/dscrhome/rcw27/programs/vcftools/vcftools-master/bin/vcftools
BCFTOOLS=/datacommons/yoderlab/programs/bcftools-1.6/bcftools
SMARTPCA=/nas02/home/j/e/jelmerp/software/EIG-master/bin
module load Plink

## Command-line arguments:
FILE_ID=$1
VCF_DIR=$2
PLINK_DIR=$3
PCA_DIR=$4

mkdir -p $PCA_DIR/eigensoft_input
mkdir $PCA_DIR/tmp.$FILE_ID
cd $PCA_DIR/tmp.$FILE_ID

## Report:
date
echo "Script: PCA.sh"
echo "File ID: $FILE_ID"
echo "Vcf dir: $VCF_DIR"
echo "Plink dir: $PLINK_DIR"
echo "PCA dir: $PCA_DIR"


## Create Eigenstrat indfile: ### CHANGE ###
$BCFTOOLS query -l $VCF_DIR/$FILE_ID.vcf.gz | \
sed ':a;N;$!ba;s/\n/ U U\n/g' | sed 's/\([0-9]\)$/\1 U U/g' | sed 's/NOL$/NOL U U/g' > $PCA_DIR/eigensoft_input/eigensoft.indfile.$FILE_ID.txt 

echo "Eigenstrat ind:"
cat $PCA_DIR/eigensoft_input/eigensoft.indfile.$FILE_ID.txt
printf "\n\n\n"


## Create Eigenstrat parfile:
printf "\n \n \n \n"
echo "Creating Eigenstrat parfile..."
printf "genotypename:\t$PLINK_DIR/$FILE_ID.SNPs.GATKfilt.biallelic.LDpruned.ped\n" > $PCA_DIR/eigensoft_input/eigensoft.parfile.$FILE_ID.txt
printf "snpname:\t$PLINK_DIR/$FILE_ID.SNPs.GATKfilt.biallelic.LDpruned.map\n" >> $PCA_DIR/eigensoft_input/eigensoft.parfile.$FILE_ID.txt
printf "indivname:\t$PCA_DIR/eigensoft_input/eigensoft.indfile.$FILE_ID.txt\n" >> $PCA_DIR/eigensoft_input/eigensoft.parfile.$FILE_ID.txt
printf "evecoutname:\t$PCA_DIR/eigensoft_output/$FILE_ID.evec\n" >> $PCA_DIR/eigensoft_input/eigensoft.parfile.$FILE_ID.txt
printf "evaloutname:\t$PCA_DIR/eigensoft_output/$FILE_ID.eval\n" >> $PCA_DIR/eigensoft_input/eigensoft.parfile.$FILE_ID.txt

echo "Eigenstrat parfile:"
cat $PCA_DIR/eigensoft_input/eigensoft.parfile.$FILE_ID.txt
printf "\n\n\n"


## Perform PCA using Eigenstrat:
printf "\n \n \n \n"
echo "Performing PCA with Eigenstrat..."
$SMARTPCA -p $PCA_DIR/eigensoft_input/eigensoft.parfile.$FILE_ID.txt


## Remove temporary directory:
rm -r $PCA_DIR/tmp.$FILE_ID

printf "\n \n \n \n"
echo "Done with script."
date