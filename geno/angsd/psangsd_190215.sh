#!/bin/bash
set -e
set -o pipefail
set -u
#
#SBATCH --job-name=angsd
#SBATCH --output=/work/rcw27/radseq/data/psangsd/psangsd.out
#SBATCH --error=/work/rcw27/radseq/data/psangsd/psangsd.err
#SBATCH -c 1
#SBATCH	-p yoderlab,common
#SBATCH --mem=120GB
#SBATCH --mail-user=rcw27@duke.edu
#SBATCH --mail-type=ALL


date

module load Anaconda2/2.7.13

cd /work/rcw27/radseq/data/psangsd

python /dscrhome/rcw27/programs/pcangsd/pcangsd.py \
-beagle rad_feb19.beagle.gz -admix -o rad_feb19 -threads 10

echo "finished run"

date
