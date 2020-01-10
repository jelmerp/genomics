#!/bin/bash
set -e
set -o pipefail
set -u

PARFILE=$1
STEPS=$2
WORKDIR=$3
FORCE=$4

date
echo "Script: ipyrad_run.sh"
echo "Parameter file: $PARFILE"
echo "ipyrad steps to run: $STEPS"
echo "Work directory (should contain parameter file): $WORKDIR"

printf "\n"
echo "Nr of cores: $SLURM_NTASKS" # SLURM_NTASKS=1
echo "Partition: $SLURM_JOB_PARTITION"
echo "Node name: $SLURMD_NODENAME"
printf "\n"

## Run ipyrad:
cd $WORKDIR

if [ $FORCE == TRUE ]
then
	echo "Running with -f (force)"
	#echo "Starting ipcluster..."
	#ipcluster start --n 20 --daemonize
	#echo "Done. Sleeping 60 s..."
	#sleep 60
	ipyrad -p $PARFILE -c $SLURM_NTASKS -s $STEPS -f #--ipcluster
fi

if [ $FORCE == FALSE ]
then
	echo "Running without -f (force)"
	#echo "Starting ipcluster..."
	#ipcluster start --n 20 --daemonize
	#echo "Done. Sleeping 60 s..."
	#sleep 60
	ipyrad -p $PARFILE -c $SLURM_NTASKS -s $STEPS #--ipcluster
fi

echo "Done with script ipyrad_run.sh"
date

## ipcluster method: http://ipyrad.readthedocs.io/HPC_script.html