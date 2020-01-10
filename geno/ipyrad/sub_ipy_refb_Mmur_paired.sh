##### SET-UP #####
## Directories:
BASEDIR=/datacommons/yoderlab/users/jelmer/radseq
cd $BASEDIR
SCRIPTDIR=$BASEDIR/scripts/genotyping/ipyrad
IPYRAD_DIR=$BASEDIR/analyses/ipyrad
REF_FOR_PARAMS="\/work\/jwp37\/singlegenomes\/seqdata\/reference\/GCF_000165445.2_Mmur_3.0_genomic.fna"
FASTQ_DIR="\/work\/jwp37\/radseq\/seqdata\/fastq\/demult_dedup_trim2"
IFS=$'\n' read -d '' -a IDs < $BASEDIR/metadata/sampleIDs.txt

## Variables:
SET_ID=refb_Mmur_paired
FINAL_ASSEMBLY=${SET_ID}_merged
WORKDIR=$IPYRAD_DIR/$SET_ID
VCF_TARGETDIR=seqdata/vcf/ipyrad/mapped2mmur/paired/
OTHERVAR_TARGETDIR=seqdata/vcf/variants_otherFormats/ipyrad/mapped2mmur/paired/

## Settings:
DATATYPE=pairddrad
FORCE=FALSE
ASSEMBLY_METHOD="denovo+reference"


##### PREP #####
## Rename fastq reads (they have /1/1 and /2/2 as suffices for R1 and R2, which cutadapt doesn't accept: only one /1 needed)
#sbatch -p yoderlab,common,scavenger --mem 8G -o slurm.renameFastqReadsR1 scripts/qc/renameFastqReads_R1.sh
#sbatch -p yoderlab,common,scavenger --mem 8G -o slurm.renameFastqReadsR2 scripts/qc/renameFastqReads_R2.sh


##### STEPS 1-5 (SEPARATELY FOR EACH IND) #####
[[ ! -f $IPYRAD_DIR/params-dummy.txt ]] && echo "Creating dummy param file..." && cd $IPYRAD_DIR && ipyrad -n dummy && cd $BASEDIR
mkdir -p $WORKDIR

#IDs=($(ls ipyrad_Mmur_failed/ | sed "s/slurm.ipyrad.refb_Mmur_paired.12345.//"))
STEPS=12345
for ID in ${IDs[@]} #${IDs[@]:0:3}
do
	#ID=${IDs[1]}
	PARFILE=$WORKDIR/params-$ID.txt
	
	rm -fr $WORKDIR/$ID*
	
	sed "s/dummy/$ID/g" $IPYRAD_DIR/params-dummy.txt | \
	sed "s/## \[4\]/${FASTQ_DIR}\/$ID*fastq.gz ## \[4\]/" | \
	sed "s/^denovo/${ASSEMBLY_METHOD}/" | \
	sed "s/^rad/${DATATYPE}/" | \
	sed "s/## \[6\]/${REF_FOR_PARAMS} ## \[6\]/" > $PARFILE
	
	#NODES_TO_EXCLUDE=dcc-compeb-02,dcc-dhvi-01,dcc-dhvi-02,dcc-yoderlab-03 # --exclude $NODES_TO_EXCLUDE \
	sbatch -p yoderlab,common,scavenger -o slurm.ipyrad.$SET_ID.$STEPS.$ID -N 1-1 --ntasks 1 --mem-per-cpu 8G \
	$SCRIPTDIR/run_ipy.sh $PARFILE $STEPS $WORKDIR $FORCE
done


#### MERGE ASSEMBLIES #####
cd $WORKDIR
ipyrad -m $FINAL_ASSEMBLY params*
cd /datacommons/yoderlab/users/jelmer/radseq


##### STEPS 6-7 (ALL INDS TOGETHER) #####
STEPS=67
PARFILE=params-$FINAL_ASSEMBLY.txt
sbatch -p yoderlab,common -o slurm.ipyrad.$STEPS.$FINAL_ASSEMBLY -N 1-1 --ntasks 12 --mem-per-cpu 4G \
$SCRIPTDIR/run_ipy.sh $PARFILE $STEPS $WORKDIR $FORCE


##### QC ON VCF #####
VCF_DIR=analyses/ipyrad/$SET_ID/${FINAL_ASSEMBLY}_outfiles/
VCF_QCDIR=analyses/qc/ipyrad/$FINAL_ASSEMBLY/bcftoolsStats/
sbatch -p yoderlab,common,scavenger -o slurm.qc.ipyrad.$FINAL_ASSEMBLY --mem 4G \
scripts/qc/qc_vcf.sh $FINAL_ASSEMBLY $VCF_DIR $VCF_QCDIR TRUE 

mkdir -p analyses/qc/ipyrad/$SET_ID/
mv $WORKDIR/${FINAL_ASSEMBLY}_outfiles/${FINAL_ASSEMBLY}_stats.txt analyses/qc/ipyrad/$SET_ID/
mkdir -p $VCF_TARGETDIR
mv $WORKDIR/${FINAL_ASSEMBLY}_outfiles/${FINAL_ASSEMBLY}.vcf.gz $VCF_TARGETDIR
mkdir -p $OTHERVAR_TARGETDIR
mv $WORKDIR/${FINAL_ASSEMBLY}_outfiles/${FINAL_ASSEMBLY}* $OTHERVAR_TARGETDIR


################################################################################
##### MOVING SLURM REPORTS #####
#IDs=($(ls ipyrad_failed/ | sed "s/slurm.ipyrad.paired.12345.//"))

#for f in analyses/ipyrad/byInd/*/*/*s5_consens_stats.txt; do (cat "${f}"; echo) >> ipyrad.s5_output.txt; done
#grep -l -Z 'IOError' slurm* | xargs -0 -I{} mv {} ipyrad_failed
#grep -l -Z 'CANCELLED' slurm* | xargs -0 -I{} mv {} ipyrad_failed
#grep -l -Z 'PREEMPTION' slurm* | xargs -0 -I{} mv {} ipyrad_failed

#grep -l -Z 'Done with script' slurm*Cmed* | xargs -0 -I{} mv {} ipyrad_Cmed_done
#grep -l -Z 'Done with script' slurm*Mmur* | xargs -0 -I{} mv {} ipyrad_Mmur_done

for FILE in slurm*Mmur*
do
	ls -lh $FILE
	grep -v "%" $FILE | cat
	printf "\n\n\n\n\n\n"
done

#grep -l -Z 'sufficient depth' ipyrad_Mmur_worked/slurm*Mmur* | xargs -0 -I{} mv {} ipyrad_Mmur_noClusters/
#grep -l -Z 'ipcluster' ipyrad_Mmur_worked/slurm*Mmur* | xargs -0 -I{} mv {} ipyrad_Mmur_failed/
#grep -l -Z 'unexpected error' ipyrad_Mmur_worked/slurm*Mmur* | xargs -0 -I{} mv {} ipyrad_Mmur_failed/
#grep -l -Z 'ipcluster' slurm*Mmur* | xargs -0 -I{} mv {} ipyrad_Mmur_failed

#IDs=($(ls ipyrad_Mmur_failed/ | sed "s/slurm.ipyrad.refb_Mmur_paired.12345.//"))


################################################################################
##### COPY FILES #####
# rsync -r /home/jelmer/Dropbox/sc_lemurs/radseq/scripts/* jwp37@dcc-slogin-02.oit.duke.edu:/datacommons/yoderlab/users/jelmer/radseq/scripts/
# rsync jwp37@dcc-slogin-02.oit.duke.edu:/datacommons/yoderlab/users/jelmer/radseq/analyses/ipyrad/params* /home/jelmer/Dropbox/sc_lemurs/radseq/analyses/ipyrad/parfiles