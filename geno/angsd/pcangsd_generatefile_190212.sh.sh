#!/bin/bash
set -e
set -o pipefail
set -u
#
#SBATCH --job-name=angsd
#SBATCH --output=/work/rcw27/radseq/data/psangsd/psangsd_generatefile.out
#SBATCH --error=/work/rcw27/radseq/data/psangsd/psangsd_generatefile.err
#SBATCH -c 1
#SBATCH	-p yoderlab,common
#SBATCH --mem=12GB
#SBATCH --mail-user=rcw27@duke.edu
#SBATCH --mail-type=ALL




date

module load Anaconda2/2.7.13

cd /dscrhome/rcw27/programs/angsd/angsd

./angsd -GL 2 -out /work/rcw27/radseq/data/psangsd/genolike -nThreads 10 -doGlf 2 -doMajorMinor 2 -SNP_pval 1e-6 -doMaf 1  -bam /hpchome/yoderlab/rcw27/scripts/radseq/psangsd/bam.filelist

echo "finished generating file"

date