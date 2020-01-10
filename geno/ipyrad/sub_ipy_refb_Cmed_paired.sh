##### SET-UP #####
BASEDIR=/datacommons/yoderlab/users/jelmer/radseq
cd $BASEDIR
SCRIPTDIR=$BASEDIR/scripts/genotyping/ipyrad
IPYRAD_DIR=$BASEDIR/analyses/ipyrad
REF_FOR_PARAMS="\/work\/jwp37\/seqdata\/reference\/Cmed\/cmedius_dt_april17.fasta"
FASTQ_DIR="\/work\/jwp37\/radseq\/seqdata\/fastq\/demult_dedup_trim2"
IDs=( $(grep "Cheirogaleus" metadata/samples/samplenames_r01.txt | cut -f 2) ) # Sequence file IDs

## Variables:
SET_ID=refb_Cmed_paired
FINAL_ASSEMBLY=${SET_ID}_merged
WORKDIR=$IPYRAD_DIR/$SET_ID
VCF_TARGETDIR=seqdata/vcf/ipyrad/mapped2cmed/paired/
OTHERVAR_TARGETDIR=seqdata/vcf/variants_otherFormats/ipyrad/mapped2cmed/paired/

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
STEPS=12345

for ID in ${IDs[@]}
#for ID in ${IDs[@]:9:100}
do
	#ID=${IDs[1]}
	PARFILE=$WORKDIR/params-$ID.txt
	
	rm -fr $WORKDIR/$ID*
	
	sed "s/dummy/$ID/g" $IPYRAD_DIR/params-dummy.txt | \
	sed "s/## \[4\]/${FASTQ_DIR}\/$ID*fastq.gz ## \[4\]/" | \
	sed "s/^denovo/${ASSEMBLY_METHOD}/" | \
	sed "s/^rad/${DATATYPE}/" | \
	sed "s/## \[6\]/${REF_FOR_PARAMS} ## \[6\]/" > $PARFILE
	
	#NODES_TO_EXCLUDE=dcc-compeb-02,dcc-dhvi-01,dcc-dhvi-02,dcc-yoderlab-03,dcc-gcb-04,dcc-gcb-03,dcc-econ-21 --exclude $NODES_TO_EXCLUDE
	sbatch -p yoderlab,common,scavenger -o slurm.ipyrad.$SET_ID.$STEPS.$ID -N 1-1 --ntasks 4 --mem-per-cpu 4G \
	$SCRIPTDIR/run_ipy.sh $PARFILE $STEPS $WORKDIR $FORCE
done

## Insufficient depth:
## ccro002_r01_p2e11 ccro004_r01_p2d03 ccro007_r01_p1c10 ccro008_r01_p1b12 ccro018_r01_p1a07 ccro019_r01_p3b01 ccro022_r01_p3b10 ccro024_r01_p3f07
## ccro026_r01_p1b10 clav001_r01_p3d01 clav002_r01_p3c03 clav003_r01_p2a05 clav006_r01_p2a01 clav007_r01_p2f08 clav008_r01_p1d12 clav009_r01_p1e10
## cmaj001_r01_p2f09 cmaj007_r01_p3a06


#### MERGE ASSEMBLIES #####
cd $WORKDIR
ipyrad -m $FINAL_ASSEMBLY params*
cd /datacommons/yoderlab/users/jelmer/radseq


##### STEPS 6-7 (ALL INDS TOGETHER) #####
STEPS=67
PARFILE=params-$FINAL_ASSEMBLY.txt
sbatch -p yoderlab,common -o slurm.ipyrad.$STEPS.$FINAL_ASSEMBLY -N 1-1 --ntasks 8 --mem-per-cpu 4G \
$SCRIPTDIR/run_ipy.sh $PARFILE $STEPS $WORKDIR $FORCE


##### QC ON VCF #####
VCF_DIR=analyses/ipyrad/$SET_ID/${FINAL_ASSEMBLY}_outfiles/
VCF_QCDIR=analyses/qc/ipyrad/$FINAL_ASSEMBLY/bcftoolsStats/
sbatch -p yoderlab,common,scavenger -o slurm.qc.ipyrad.$FINAL_ASSEMBLY --mem 4G \
scripts/qc/qc_vcf.sh $FINAL_ASSEMBLY $VCF_DIR $VCF_QCDIR TRUE

mkdir -p analyses/qc/ipyrad/$FINAL_ASSEMBLY/
mv $WORKDIR/${FINAL_ASSEMBLY}_outfiles/${FINAL_ASSEMBLY}_stats.txt analyses/qc/ipyrad/$FINAL_ASSEMBLY/
mkdir -p $VCF_TARGETDIR
mv $WORKDIR/${FINAL_ASSEMBLY}_outfiles/${FINAL_ASSEMBLY}.vcf.gz $VCF_TARGETDIR
mkdir -p $OTHERVAR_TARGETDIR
mv $WORKDIR/${FINAL_ASSEMBLY}_outfiles/${FINAL_ASSEMBLY}* $OTHERVAR_TARGETDIR


################################################################################
##### MOVING SLURM REPORTS #####
#for f in analyses/ipyrad/byInd/*/*/*s5_consens_stats.txt; do (cat "${f}"; echo) >> ipyrad.s5_output.txt; done
#grep -l -Z 'error' slurm* | xargs -0 -I{} mv {} ipyrad_Cmed_failed
#grep -l -Z 'CANCELLED' slurm* | xargs -0 -I{} mv {} ipyrad_failed

for FILE in ipyrad_Cmed_done/slurm*
do
	ls -lh $FILE
	#grep -v "%" $FILE | cat
	grep -v "%" $FILE | grep "sufficient depth"
	#printf "\n\n\n\n"
	printf "\n"
done

# grep -l -Z 'Sufficient depth' slurm*Cmed* | xargs -0 -I{} mv {} ipyrad_Cmed_noClusters
# IDs=($(ls ipyrad_Cmed_failed/ | sed "s/slurm.ipyrad.refb_Cmed_paired.12345.//"))

NOCLUSTER=($(ls ipyrad_Cmed_noClusters/ | sed "s/slurm.ipyrad.refb_Cmed_paired.12345.//"))
WORKED=($(ls ipyrad_Cmed_worked/ | sed "s/slurm.ipyrad.refb_Cmed_paired.12345.//"))
ISDONE=( "${WORKED[@]}" "${NOCLUSTER[@]}" ) 
ALLIDs=( $(grep "Cheirogaleus" metadata/samples/samplenames_r01.txt | cut -f 2) )
IDs=( $(echo ${ALLIDs[@]} ${ISDONE[@]} | tr ' ' '\n' | sort | uniq -u) )


################################################################################
################################################################################
rsync -r /home/jelmer/Dropbox/sc_lemurs/radseq/scripts/* jwp37@dcc-slogin-02.oit.duke.edu:/datacommons/yoderlab/users/jelmer/radseq/scripts/
rsync -r /home/jelmer/Dropbox/sc_lemurs/radseq/metadata/* jwp37@dcc-slogin-02.oit.duke.edu:/datacommons/yoderlab/users/jelmer/radseq/metadata/
rsync jwp37@dcc-slogin-02.oit.duke.edu:/datacommons/yoderlab/users/jelmer/radseq/analyses/ipyrad/params* /home/jelmer/Dropbox/sc_lemurs/radseq/analyses/ipyrad/parfiles