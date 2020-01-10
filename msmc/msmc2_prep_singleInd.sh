#!/bin/bash
set -e
set -o pipefail
set -u

##### SET-UP: SOFTWARE #####
MSMCTOOLS=/datacommons/yoderlab/programs/msmc-tools
PYTHON3=/datacommons/yoderlab/programs/Python-3.6.3/python

##### SET-UP: COMMAND-LINE ARGUMENTS #####
VCF=$1
MSMC_INPUT_BASEDIR=$2
MASK_INDIV_DIR=$3
MASK_REPEATS=$4


##### SET-UP: PROCESS COMMAND-LINE ARGUMENTS #####
IFS='.' read -ra SUBSTRINGS <<< "$VCF"
IFS='/' read -ra SUBSTRINGS2 <<< "${SUBSTRINGS[0]}"

TOT=`echo ${#SUBSTRINGS2[@]}`
IND_NR=`expr $TOT - 1`
IND=${SUBSTRINGS2[$IND_NR]}

SCAFFOLD=${SUBSTRINGS[1]}.${SUBSTRINGS[2]}
PHASING=${SUBSTRINGS[3]}
METHOD=${SUBSTRINGS[4]}

MSMC_INPUT_DIR=$MSMC_INPUT_BASEDIR/$METHOD/ind
[[ ! -d $MSMC_INPUT_DIR ]] && mkdir -p $MSMC_INPUT_DIR
MSMC_INPUT=$MSMC_INPUT_DIR/msmc_input.$METHOD.$IND.$SCAFFOLD.txt

printf "\n \n \n \n"
date
echo "Script: msmsc2_prep_singleInd"
echo "Individual: $IND"
echo "Scaffold: $SCAFFOLD"
echo "Phasing: $PHASING"
echo "Method: $METHOD"
echo "MSMC input file: $MSMC_INPUT"
echo "Individual mask directory: $MASK_INDIV_DIR"
echo "VCF: $VCF"


##### GENERATE MSMC INPUT FILES  #####
if [ $METHOD == samtools ]
   then
   MASK_INDIV=`ls -d $MASK_INDIV_DIR/mask_indiv.$IND.$SCAFFOLD.bed.gz` # store indiv.mask file path
   echo "MASK: $MASK_INDIV"
   echo "Creating MSMC input file WITH individual mask (samtools)"
   [[ $MASK_REPEATS != none ]] && $PYTHON3 $MSMCTOOLS/generate_multihetsep.py --negative_mask=$MASK_REPEATS --mask=$MASK_INDIV $VCF > $MSMC_INPUT # with repeat mask
   [[ $MASK_REPEATS == none ]] && $PYTHON3 $MSMCTOOLS/generate_multihetsep.py --mask=$MASK_INDIV $VCF > $MSMC_INPUT # without repeat mask
elif [ $METHOD == gatk ]
   then
   echo "Creating MSMC input file WITHOUT individual mask (gatk)"
   [[ $MASK_REPEATS == none ]] && $PYTHON3 $MSMCTOOLS/generate_multihetsep.py --negative_mask=$MASK_REPEATS $VCF > $MSMC_INPUT.tmp # with repeat mask
   [[ $MASK_REPEATS == none ]] && $PYTHON3 $MSMCTOOLS/generate_multihetsep.py $VCF > $MSMC_INPUT # without repeat mask
fi

#echo "Editing scaffold names in input files.." # Remove .1 from scaffold names, msmc program won't accept this
#sed s/\\.1//g $MSMC_INPUT.tmp > $MSMC_INPUT
#rm $MSMC_INPUT.tmp

echo "Done with script."
date
