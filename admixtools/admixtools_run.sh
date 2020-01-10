#!/bin/bash
set -e
set -o pipefail
set -u

################################################################################
##### SET-UP #####
################################################################################
## Software:
ATOOLS_DSTAT=/datacommons/yoderlab/programs/AdmixTools-master/bin/qpDstat
ATOOLS_F3=/datacommons/yoderlab/programs/AdmixTools-master/bin/qp3Pop
ATOOLS_F4RATIO=/datacommons/yoderlab/programs/AdmixTools-master/bin/qpF4ratio

## Command-line arguments:
FILE_ID_FULL=$1
shift
POPFILE_LINE=$1
shift
PARFILE=$1
shift
OUTPUT=$1
shift
ATOOLS_MODE=$1
shift

## Report:
echo -e "\n################################################################################"
date
echo "##### admixtools_run.sh: Starting with script."
echo "##### admixtools_run.sh: File ID: $FILE_ID_FULL"
echo "##### admixtools_run.sh: Line of popfile to process: $POPFILE_LINE"
echo "##### admixtools_run.sh: Parfile: $PARFILE"
echo "##### admixtools_run.sh: Output file: $OUTPUT"
echo "##### admixtools_run.sh: Admixtools mode: $ATOOLS_MODE"


################################################################################
##### RUN ADMIXTOOLS #####
################################################################################
echo -e "\n################################################################################"
if [ $ATOOLS_MODE == D ]
then

	if [ $POPFILE_LINE == ALL ]
	then
		echo "##### admixtools_run.sh: Running all popfile POPFILE_LINEs at once..."
		
		echo "##### admixtools_run.sh: Running qpDstat in D-mode..."
		$ATOOLS_DSTAT -p $PARFILE > $OUTPUT
	else
		echo "##### admixtools_run.sh: Running one popfile POPFILE_LINE: $POPFILE_LINE"
		printf "\n"
		
		echo "##### admixtools_run.sh: Running qpDstat in D-mode..."
		LINEWISE_OUTPUT=$OUTPUT.line${POPFILE_LINE}
		
		$ATOOLS_DSTAT -l $POPFILE_LINE -h $POPFILE_LINE -p $PARFILE > $LINEWISE_OUTPUT
		
		echo "##### admixtools_run.sh: Output file: $LINEWISE_OUTPUT"
		cat $LINEWISE_OUTPUT
		printf "\n"
	fi
	
fi

if [ $ATOOLS_MODE == "F3" ]
then
	echo "##### admixtools_run.sh: Running qpf3..."
	$ATOOLS_F3 -p $PARFILE > $OUTPUT
	printf "\n"

	echo "##### admixtools_run.sh: Output file $OUTPUT:"
	cat $OUTPUT
	printf "\n"
fi

if [ $ATOOLS_MODE == "F4RATIO" ]
then
	echo "##### admixtools_run.sh: Running f4-ratio test..."
	$ATOOLS_F4RATIO -p $PARFILE > $OUTPUT.raw
	grep "result" $OUTPUT.raw  > $OUTPUT
	printf "\n"

	#echo "##### admixtools_run.sh: Output file $OUTPUT:"
	#cat $OUTPUT
	printf "\n"
fi

#if [ $ATOOLS_MODE == F4 ]
#then
	#echo "##### admixtools_run.sh: Running qpDstat in F-mode..."
	#$ATOOLS_DSTAT -p $PARFILE_FMODE > $OUTDIR/$FILE_ID_FULL.fmode.out
	
	#echo "##### Running qpDstat in F-mode..."
	#FMODE_OUTPUT=$OUTDIR/$FILE_ID_FULL.$POPFILE_ID_FULL.line${POPFILE_LINE}.fmode.out
	#$ATOOLS_DSTAT -l $POPFILE_LINE -h $POPFILE_LINE -p $PARFILE_FMODE > $FMODE_OUTPUT 
	#echo "Output file: $FMODE_OUTPUT"
	#cat $FMODE_OUTPUT
	#printf "\n"
#fi


################################################################################
date
echo -e "\n##### admixtools_run.sh: Done with script.\n"
