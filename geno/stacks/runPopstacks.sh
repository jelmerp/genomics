#!/bin/bash
set -e
set -o pipefail
set -u

################################################################################
#### SET-UP ####
################################################################################
## Software and scripts:
BGZIP=/datacommons/yoderlab/programs/htslib-1.6/bgzip
TABIX=/datacommons/yoderlab/programs/htslib-1.6/tabix
export LD_LIBRARY_PATH=/datacommons/yoderlab/users/gtiley/compilers/gccBin/lib64/ #:$LD_LIBRARY_PATH
STACKS_EXEC_DIR=/datacommons/yoderlab/programs/stacks-2.41/
PATH=$PATH:$STACKS_EXEC_DIR

## Command-line args:
SET_ID=$1
STACKSDIR=$2
OUTDIR=$3
POPMAP=$4
ADD_OPS=$5
NCORES=$6

## Process:
[[ ! -d $OUTDIR ]] && mkdir -p $OUTDIR 
STANDARD_OPS="--ordered-export --hwe --fstats --vcf"

## Report:
printf "\n"
date
echo "##### runPopstacks.sh: Starting with script."
echo "##### runPopstacks.sh: Node name: $SLURMD_NODENAME"
printf "\n"
echo "##### runPopstacks.sh: Stacks dir (input files for populations: $STACKSDIR"
echo "##### runPopstacks.sh: Output dir: $OUTDIR"
echo "##### runPopstacks.sh: Popmap file: $POPMAP"
echo "##### runPopstacks.sh: Number of cores: $NCORES"
echo "##### runPopstacks.sh: Standard options for stacks-pops: $STANDARD_OPS"
echo "##### runPopstacks.sh: Additional options for stacks-pops: $ADD_OPS \n"

echo -e "\n##### runPopstacks.sh: Showing popmap:"
cat $POPMAP
printf "\n"


################################################################################
#### RUN STACKS ####
################################################################################
populations -P $STACKSDIR -O $OUTDIR -M $POPMAP -t $NCORES $STANDARD_OPS $ADD_OPS


################################################################################
#### PROCESS FILES ####
################################################################################
echo -e "\n##### runPopstacks.sh: Renaming output files..."
for OLDNAME in $OUTDIR/populations*
do
	NEWNAME="${OLDNAME/populations/$SET_ID}"
	echo $OLDNAME
	echo $NEWNAME
	printf "\n"
	mv $OLDNAME $NEWNAME
done

echo -e "\n##### runPopstacks.sh: Moving fst stats..."
mkdir -p $OUTDIR/fst
mv $OUTDIR/*fst_* $OUTDIR/fst/
mv $OUTDIR/*phistats* $OUTDIR/fst/

echo -e "\n##### runPopstacks.sh: Zipping and moving VCF..."
$BGZIP $OUTDIR/$SET_ID.snps.vcf
$TABIX $OUTDIR/$SET_ID.snps.vcf.gz
$BGZIP $OUTDIR/$SET_ID.haps.vcf
$TABIX $OUTDIR/$SET_ID.haps.vcf.gz
mkdir -p $OUTDIR/vcf
mv $OUTDIR/*vcf.gz* $OUTDIR/vcf/

echo -e "\n##### runPopstacks.sh: Moving fasta..."
mkdir -p $OUTDIR/fasta
cp $OUTDIR/*fa $OUTDIR/fasta/

## Report:
echo -e "\n\n##### runPopstacks.sh: Done with script."
date


################################################################################
## Populations options to consider:
# --write-single-snp — restrict data analysis to only the first SNP per locus.
# -R,--min-samples-overall [float] — minimum percentage of individuals across populations required to process a locus.

## NatGen protocol example:
# min_samples=0.80% min_maf=0.05% max_obs_het=0.70%