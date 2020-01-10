#!/bin/bash
set -e
set -o pipefail
set -u

################################################################################
#### SET-UP ####
################################################################################
## Software and scripts:
export LD_LIBRARY_PATH=/datacommons/yoderlab/users/gtiley/compilers/gccBin/lib64/ #:$LD_LIBRARY_PATH
STACKS_EXEC_DIR=/datacommons/yoderlab/programs/stacks-2.41/
PATH=$PATH:$STACKS_EXEC_DIR

## Command-line args:
OUTDIR=$1
BAMDIR=$2
BAMSUFFIX=$3
POPMAP=$4
ADD_OPS=$5
NCORES=$6

## Process:
[[ ! -d $OUTDIR ]] && mkdir -p $OUTDIR 
BAMSTATS=$OUTDIR/stacks_bamstats.txt
COVSTATS=$OUTDIR/stacks_covstats.txt
DUPSTATS=$OUTDIR/stacks_dupstats.txt
PHASINGSTATS=$OUTDIR/stacks_phasingstats.txt

## Report:
date
echo "##### runGstacks.sh: Starting with script."
echo "##### runGstacks.sh: Node name: $SLURMD_NODENAME"
echo "##### runGstacks.sh: Number of cores: $NCORES"
printf "\n"
echo "##### runGstacks.sh: Out dir: $OUTDIR"
echo "##### runGstacks.sh: Bam dir: $BAMDIR"
echo "##### runGstacks.sh: Popmap file: $POPMAP"
echo "##### runGstacks.sh: Bam suffix: $BAMSUFFIX"
echo "##### runGstacks.sh: Additional commands for gstacks: $ADD_OPS"
printf "\n"
echo "##### runGstacks.sh: Output bam-stats: $BAMSTATS"
echo "##### runGstacks.sh: Output coverage stats: $COVSTATS"
echo "##### runGstacks.sh: Output pcr-dup stats: $DUPSTATS"
echo "##### runGstacks.sh: Output phasing stats: $PHASINGSTATS"
printf "\n\n"


################################################################################
#### RUN STACKS ####
################################################################################
gstacks -I $BAMDIR -M $POPMAP -O $OUTDIR -S $BAMSUFFIX -t $NCORES --details $ADD_OPS 


################################################################################
#### PROCESS OUTPUT ####
################################################################################
## Processing output stats:
$STACKS_EXEC_DIR/scripts/stacks-dist-extract $OUTDIR/gstacks.log.distribs bam_stats_per_sample > $BAMSTATS
$STACKS_EXEC_DIR/scripts/stacks-dist-extract $OUTDIR/gstacks.log.distribs effective_coverages_per_sample > $COVSTATS
$STACKS_EXEC_DIR/scripts/stacks-dist-extract $OUTDIR/gstacks.log.distribs pcr_clone_size_distrib > $DUPSTATS
$STACKS_EXEC_DIR/scripts/stacks-dist-extract $OUTDIR/gstacks.log.distribs phasing_rates_per_sample > $PHASINGSTATS 

## Coverage stats:
cat $COVSTATS

## Report:
echo -e "\n\n##### runGstacks.sh: Done with script."
date


################################################################################
################################################################################
## Installation:
# module load GCC/7.4.0 # Needed before running configure