#!/bin/bash
set -e
set -o pipefail
set -u

GENO=$1 #seqdata/variants_otherFormats/geno/EjaC.Dstat.NC_022205.1.DP5.geno.gz
RUN_NAME=$2 #NC_022205.1.test
WINSIZE=$3 #10000000
MINSITES=$4 #10000
NCORES=$5 
OUTGROUP=$6 #TguiMA,TguiMA2,TguiMA4
INDS=$7 #Cdec088,Cdec328,Ceja262,Ceja408,Cfus085,Cfus350,Cfus503,Ckot383,Ckot499,TguiNG2,TguiNG5,SgalMA1,TguiMA,TguiMA2,TguiMA4

module load python/2.7.1
RAXML=/proj/cmarlab/users/jelmer/software/standard-RAxML-master/raxmlHPC-SSE3
OUTDIR=/proj/cmarlab/users/jelmer/cichlids/analyses/raxml/output_byWindow

date
echo "Script: raxml.window_run.sh"
echo "Geno file: $GENO"
echo "Run name: $RUN_NAME"
echo "Window size: $WINSIZE"
echo "Minimum number of sites: $MINSITES"
echo "Number of cores: $NCORES"
echo "Outgroup individuals: $OUTGROUP"
echo "All individuals: $INDS"

python scripts/trees/smartin/raxml_sliding_windows.py -g $GENO -p $OUTDIR/$RUN_NAME --log $OUTDIR/$RUN_NAME.raxmllog --raxml $RAXML --genoFormat phased \
	--windType coordinate --windSize $WINSIZE --stepSize $WINSIZE --minSites $MINSITES \
	--model GTRCAT --outgroup $OUTGROUP --individuals $INDS -T $NCORES

gunzip -c $OUTDIR/$RUN_NAME.trees.gz > $OUTDIR/$RUN_NAME.trees.txt
rm $OUTDIR/$RUN_NAME.trees.gz

printf "\n\n"
echo "Done with script."
date

#python scripts/trees/smartin/raxml_sliding_windows.py -g $GENO -p $RUN_NAME --log raxml.log --raxml $RAXML --genoFormat phased \
#	--windType coordinate --windSize $WINSIZE --stepSize $WINSIZE --minSites $MINSITES \
#	--model GTRCAT --outgroup $OUTGROUP --individuals $INDS