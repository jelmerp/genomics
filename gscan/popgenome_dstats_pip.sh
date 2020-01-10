#!/bin/bash
set -e
set -o pipefail
set -u

FILE_ID="$1"
TRIPLETFILE="$2"
WINSIZE="$3"
STEPSIZE="$4"
SCAFFOLDSFILE="$5"

#module load r

date
echo "Script: popgenome_submaster.sh"
echo "File ID: $FILE_ID"
echo "Triplet file: $TRIPLETFILE"
echo "Window size: "$WINSIZE""
echo "Step size: "$STEPSIZE""

IFS=$'\n' read -d '' -a SCAFFOLDS < $SCAFFOLDSFILE

for SCAFFOLD in ${SCAFFOLDS[@]}
do
	for LINENR in $(seq 1 $(cat $TRIPLETFILE | wc -l))
	do
		#FILE_ID=EjaC.Dstat.DP5.GQ20.MAXMISS0.5.MAF0.01; WINSIZE=50000; STEPSIZE=5000; TRIPLETFILE=analyses/windowstats/popgenome/input/triplets.txt
		#LINENR=1; SCAFFOLD=NT_167611.1
		POP1=$(cat $TRIPLETFILE | head -n $LINENR | tail -n 1 | cut -f 1 -d " ")
		POP2=$(cat $TRIPLETFILE | head -n $LINENR | tail -n 1 | cut -f 2 -d " ")
		POP3=$(cat $TRIPLETFILE | head -n $LINENR | tail -n 1 | cut -f 3 -d " ")
		echo "Scaffold: $SCAFFOLD Line nr: $LINENR Pop 1: $POP1 / Pop 2: $POP2 / Pop 3: $POP3"
		Rscript scripts/windowstats/popgenome.dstats_run.R "$FILE_ID" "$SCAFFOLD" "$POP1" "$POP2" "$POP3" "$WINSIZE" "$STEPSIZE"
	done
done
	
	echo "Done with script."
	date