#!/bin/bash
set -e
set -o pipefail
set -u

MSMC_INPUT_BASEDIR=$1
shift
MASK_INDIV_DIR=$1
shift
MASK_REPEATS=$1
shift

echo "Script: scripts/msmc/msmc2_prep_singleInd_wrap.sh"
echo "Repeatmask: $MASK_REPEATS"
printf "\n \n \n"

count=0; while [ "$*" != "" ]; do VCFS[$count]=$1; shift; count=`expr $count + 1`; done

echo "VCFs: ${VCFS[@]}"
printf "\n \n \n"

for VCF in ${VCFS[@]}
do
	# VCF=${VCFS[0]}
	echo "VCF file: $VCF"
	scripts/msmc/msmc2_prep_singleInd.sh $VCF $MSMC_INPUT_BASEDIR $MASK_INDIV_DIR $MASK_REPEATS
done


printf "\n \n \n"
echo "Done with wrapper script."