#!/bin/bash
set -e
set -o pipefail
set -u

################################################################################
#### SET-UP ####
################################################################################
## Scripts:
SCRIPT_VCF2FASTA=/datacommons/yoderlab/users/jelmer/scripts/genomics/conversion/vcf2fasta.sh
SCRIPT_FASTA2NEXUS=/datacommons/yoderlab/users/jelmer/scripts/genomics/conversion/convert2nexus.sh
SPIDFILE=/datacommons/yoderlab/users/jelmer/scripts/genomics/conversion/fasta2nexus.spid
SCRIPT_SPLITSTREE=/datacommons/yoderlab/users/jelmer/scripts/genomics/splitstree/splitstree_run.sh

## Command-line args:
FILE_ID=$1
VCF_DIR=$2
FASTA_DIR=$3
NEXUS_DIR=$4
OUTDIR=$5
MEM=$6 # At least 20GB for FASTA2NEXUS

## Other variables:
FASTA_FILE=$FASTA_DIR/$FILE_ID.fasta
NEXUS_FILE=$NEXUS_DIR/$FILE_ID.nexus
OUTFILE=$OUTDIR/$FILE_ID.nexus

[[ ! -d $FASTA_DIR ]] && echo -e "#### splitstree_pip.sh: Creating dir $FASTA_DIR \n" && mkdir -p $FASTA_DIR
[[ ! -d $NEXUS_DIR ]] && echo -e "#### splitstree_pip.sh: Creating dir $NEXUS_DIR \n" && mkdir -p $NEXUS_DIR
[[ ! -d $OUTDIR ]] && echo -e "#### splitstree_pip.sh: Creating dir $OUTDIR \n" && mkdir -p $OUTDIR

## Report:
date
echo "#### splitstree_pip.sh: Starting script."
echo "#### splitstree_pip.sh: File ID: $FILE_ID"
echo "#### splitstree_pip.sh: Vcf dir: $VCF_DIR"
echo "#### splitstree_pip.sh: Fasta dir: $FASTA_DIR"
echo "#### splitstree_pip.sh: Nexus dir: $NEXUS_DIR"
echo "#### splitstree_pip.sh: Output dir: $OUTDIR"
echo "#### splitstree_pip.sh: Memory: $MEM"
printf "\n"
echo "#### splitstree_pip.sh: Fasta file: $FASTA_FILE"
echo "#### splitstree_pip.sh: Nexus file: $NEXUS_FILE"
echo "#### splitstree_pip.sh: Output file: $OUTFILE"

################################################################################
#### CONVERSIONS ####
################################################################################
## VCF2FASTA:
echo -e "\n\n###################################################################"
echo "#### splitstree_pip.sh: Submitting VCF2FASTA script..."
SCAFFOLD=ALL
$SCRIPT_VCF2FASTA $FILE_ID $VCF_DIR $FASTA_DIR $SCAFFOLD

## FASTA2NEXUS:
echo -e "\n\n###################################################################"
echo "#### splitstree_pip.sh: Submitting FASTA2NEXUS script..."
INFORMAT=FASTA
$SCRIPT_FASTA2NEXUS $FASTA_FILE $NEXUS_FILE $INFORMAT $SPIDFILE $MEM


################################################################################
#### RUN SPLITSTREE ####
################################################################################
echo -e "\n\n###################################################################"
echo "#### splitstree_pip.sh: Running splitstree..."
$SCRIPT_SPLITSTREE $NEXUS_FILE $OUTFILE

echo -e "\n#### splitstree_pip.sh: Output file..."
ls -lh $OUTFILE

## Report:
echo -e "\n\n###################################################################"
echo "#### splitstree_pip.sh: Done with script."
date