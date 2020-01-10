#!/bin/bash
set -e
set -o pipefail
set -u

################################################################################
#### SET-UP ####
################################################################################
## Software:
GPHOCS=/datacommons/yoderlab/programs/G-PhoCS/bin/G-PhoCS

## Command-line args:
CFILE=$1 # Path to control file
NCORES=$2 # Number of cores to use

## Report:
echo -e "\n#####################################################################"
date
echo "#### gphocs_run.sh: Starting script."
echo "#### gphocs_run.sh: Control file: $CFILE"
echo "#### gphocs_run.sh: Number of processors: $NCORES"
printf "\n"
echo "#### gphocs_run.sh: Slurm Job ID: $SLURM_JOB_ID"
echo "#### gphocs_run.sh: Slurm Partition: $SLURM_JOB_PARTITION"
echo "#### gphocs_run.sh: Slurm Node name: $SLURMD_NODENAME"

## Copying old logfile:
LOGFILE=$(grep "trace-file" $CFILE | sed 's/trace-file //')
echo -e "\n#### gphocs_run.sh: Logfile: $LOGFILE"

if [ -f $LOGFILE ]
then
	echo -e "#### gphocs_run.sh: Logfile exists: moving to $LOGFILE.autocopy...\n"
	mv $LOGFILE $LOGFILE.autocopy.log
fi

## Editing controlfile to include date:
echo "#### gphocs_run.sh: Editing controlfile..."
DATE=$(date +%Y%m%d-%H%M)
cp $CFILE $CFILE.tmp
#cat $CFILE.tmp | sed -e "s/\(date[0-9]+\).*\.log/\1.$DATE.log/" > $CFILE
cat $CFILE.tmp | sed -e "s/\(date[0-9][0-9][0-9][0-9][0-9][0-9]\).*log/\1.$DATE.log/" > $CFILE 
rm $CFILE.tmp

echo -e "\n#### gphocs_run.sh: Showing top of controlfile:"
head $CFILE


################################################################################
#### RUN GPHOCS ####
################################################################################
export OMP_NUM_THREADS=$NCORES

echo -e "\n\n#### gphocs_run.sh: Starting Gphocs run...\n"
$GPHOCS $CFILE -n $NCORES


## Report:
echo -e "\n#####################################################################"
echo "#### gphocs_run.sh: Done with script."
date
