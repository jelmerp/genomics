#!/bin/bash
set -e
set -o pipefail
set -u

## Command-line arguments:
VCF_ID=$1
WINDOW_SIZE=$2

VCFDIR=/proj/cmarlab/users/jelmer/cichlids/seqdata/vcf_split
VCF=$VCFDIR/$VCF_ID.SNPs.GATKfilt.biallelic.vcf.gz
PI_DIR=/proj/cmarlab/users/jelmer/cichlids/analyses/sumstats/pi

date
echo "SCRIPT: pi_vcftools.sh"
echo "VCF: $VCF"
echo "Window size: $WINDOW_SIZE"

#printf "\n \n"
#echo "Calculating pi per site..."
#vcftools --gzvcf $VCF --site-pi --out $PI_DIR/$VCF_ID

printf "\n \n"
echo "Calculating pi per window..."
vcftools --gzvcf $VCF --window-pi $WINDOW_SIZE --out $PI_DIR/$VCF_ID

printf "\n \n"
echo "Done with script"
date



#########################################################
## Copying files:
#scp jelmerp@killdevil.unc.edu:/proj/cmarlab/users/jelmer/cichlids/analyses/sumstats/pi/* /home/jelmer/Dropbox/sc_fish/cichlids/analyses/sumstats/pi/

## Usage:
#scripts/sumstats/pi_vcftools.sh Cdec 50000