#!/bin/bash
set -e
set -o pipefail
set -u

################################################################################
##### SET-UP #####
################################################################################
## Command-line args:
FILE_ID=$1
shift
OUTDIR=$1
shift
SCAFFOLD_FILE=$1
shift
MAXMISS=$1
shift

count=0
while [ "$*" != "" ]
  do INFILES[$count]=$1
  shift
  count=`expr $count + 1`
done

OUTFILE_CONCAT=$OUTDIR/$FILE_ID.allScaffolds.vcf.gz

## Report:
date
echo "##### mergeVcf_pip.sh: Starting script."
echo "##### mergeVcf_pip.sh: File ID: $FILE_ID"
echo "##### mergeVcf_pip.sh: Output dir: $OUTDIR"
echo "##### mergeVcf_pip.sh: Scaffold file: $SCAFFOLD_FILE"
echo "##### mergeVcf_pip.sh: Input files: ${INFILES[@]}"
echo "##### mergeVcf_pip.sh: Final ouput file: $OUTFILE_CONCAT"
printf "\n"

SCAFFOLDS=( $(cat $SCAFFOLD_FILE) )
echo "##### mergeVcf_pip.sh: Scaffolds: ${SCAFFOLDS[@]}"
printf "\n"


################################################################################
##### SUBMIT SCRIPT FOR EACH SCAFFOLD #####
################################################################################
for SCAFFOLD in ${SCAFFOLDS[@]}
do
	echo "##### mergeVcf_pip.sh: Scaffold: $SCAFFOLD"
	OUTFILE=$OUTDIR/$FILE_ID.$SCAFFOLD.vcf.gz
	
	sbatch -p yoderlab,common,scavenger --mem=16G --job-name=mergeVcf.$FILE_ID -o slurm.mergeVcf.$SCAFFOLD \
	/datacommons/yoderlab/users/jelmer/scripts/genomics/conversion/mergeVcf_pip.sh $OUTFILE $SCAFFOLD $MAXMISS ${INFILES[@]}
done


################################################################################
##### CONCATENATE SINGLE-SCAFFOLD VCFS #####
################################################################################
INFILES_CONCAT=( $(ls $OUTDIR/$FILE_ID*vcf.gz) )

sbatch -p yoderlab,common,scavenger --mem=16G --job-name=mergeVcf.$FILE_ID --dependency=singleton -o slurm.mergeVcf.$SCAFFOLD \
/datacommons/yoderlab/users/jelmer/scripts/genomics/conversion/concatVcf.sh $OUTFILE_CONCAT ${INFILES_CONCAT[@]}

#bcftools concat seqdata/vcf/merged.NC*vcf.gz -O z > seqdata/vcf/merged.5scaf.vcf.gz


################################################################################
##### REPORT #####
################################################################################
date
echo "##### mergeVcf_pip.sh: Done with script."