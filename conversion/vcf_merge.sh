#!/bin/bash
set -e
set -o pipefail
set -u

################################################################################
##### SET-UP #####
################################################################################
## Software:
BCFTOOLS=/datacommons/yoderlab/programs/bcftools-1.6/bcftools
VCFTOOLS=/dscrhome/rcw27/programs/vcftools/vcftools-master/bin/vcftools
TABIX=/datacommons/yoderlab/programs/htslib-1.6/tabix

## Command-line args:
OUTFILE=$1
shift
SCAFFOLD=$1
shift
MAXMISS=$1
shift

count=0
while [ "$*" != "" ]
  do INFILES[$count]=$1
  shift
  count=`expr $count + 1`
done

## Report:
date
echo "##### mergeVcf.sh: Starting script."
echo "##### mergeVcf.sh: Output file: $OUTFILE"
echo "##### mergeVcf.sh: Scaffold: $SCAFFOLD"
echo "##### mergeVcf.sh: Input files: ${INFILES[@]}"

## Tmp file:
[[ ! -d tmpdir ]] && mkdir tmpdir
TMPFILE_EXT=$(basename $OUTFILE)
TMPFILE=tmpdir/$TMPFILE_EXT
echo "##### mergeVcf.sh: Temp file: $TMPFILE"
printf "\n"

## Process - scaffold command:
if [ $SCAFFOLD != "ALL" ]
then
	echo "##### mergeVcf.sh: Scaffold != ALL, creating scaffold-command..."
	SCAFFOLD_COMMAND="-r $SCAFFOLD"
	echo "##### mergeVcf.sh: Scaffold command: $SCAFFOLD_COMMAND"
	printf "\n"
fi

## Process - index VCFs if necessary:
for INFILE in ${INFILES[@]}
do
	[[ ! -e $INFILE.tbi ]] && echo "##### mergeVcf.sh: Indexing $INFILE..." && $TABIX -p vcf $INFILE && printf "\n"
done


################################################################################
##### MERGE VCFS #####
################################################################################
echo "##### mergeVcf.sh: Starting merge with bcftools..."
$BCFTOOLS merge $SCAFFOLD_COMMAND -O z ${INFILES[@]} | $BCFTOOLS view -m2 -M2 -v snps -O z > $TMPFILE
printf "\n"

date
echo "##### mergeVcf.sh: Filtering with vcftools..."
$VCFTOOLS --gzvcf $TMPFILE --recode --recode-INFO-all --max-missing $MAXMISS --stdout | gzip > $OUTFILE
#rm -f $TMPFILE
printf "\n"


################################################################################
##### REPORT #####
################################################################################
NVAR=$(zgrep -v "##" $OUTFILE | wc -l)
echo "##### mergeVcf.sh: Number of variants in output VCF: $NVAR"
printf "\n"

echo "##### mergeVcf.sh: Listing output file:"
ls -lh $OUTFILE
printf "\n"

date
echo "##### mergeVcf.sh: Done with script."


#bcftools filter -O z -e "F_MISSING < 0.5" test.vcf.gz > test2.vcf.gz #not working