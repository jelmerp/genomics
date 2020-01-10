##### SET-UP #####
BASEDIR=/datacommons/yoderlab/users/jelmer/radseq
cd $BASEDIR
SCRIPTDIR=$BASEDIR/scripts/genotyping/ipyrad
IPYRAD_DIR=$BASEDIR/analyses/ipyrad
REF_FOR_PARAMS="\/work\/jwp37\/seqdata\/reference\/Cmed\/cmedius_dt_april17.fasta"
FASTQ_DIR="\/work\/jwp37\/radseq\/seqdata\/fastq\/demult_dedup_trim2"
IDs=( $(grep "Cheirogaleus" metadata/samplenames.txt | cut -f 27) ) # Sequence file IDs

## Variables:
SET_ID=refb_Cmed_R1
FINAL_ASSEMBLY=refb_Cmed_R1_merged
WORKDIR=$IPYRAD_DIR/$SET_ID
VCF_TARGETDIR=seqdata/vcf/ipyrad/mapped2cmed/R1/
OTHERVAR_TARGETDIR=seqdata/vcf/variants_otherFormats/ipyrad/mapped2cmed/R1/

## Settings:
DATATYPE=rad # Default, doesn't need to be changed
FORCE=FALSE
ASSEMBLY_METHOD="denovo+reference"


##### STEPS 1-5 (SEPARATELY FOR EACH IND) #####
[[ ! -f $IPYRAD_DIR/params-dummy.txt ]] && echo "Creating dummy param file..." && cd $IPYRAD_DIR && ipyrad -n dummy && cd $BASEDIR
mkdir -p $WORKDIR
STEPS=12345

for ID in ${IDs[@]}
do
	#ID=${IDs[0]} #ID=ccro012_r01_p2e06
	
	PARFILE=$WORKDIR/params-$ID.txt
	sed "s/dummy/$ID/g" $IPYRAD_DIR/params-dummy.txt | \
	sed "s/## \[4\]/${FASTQ_DIR}\/$ID*_R1*fastq.gz ## \[4\]/" | \
	sed "s/^denovo/${ASSEMBLY_METHOD}/" | \
	sed "s/^rad/${DATATYPE}/" | \
	sed "s/## \[6\]/${REF_FOR_PARAMS} ## \[6\]/" > $PARFILE
	
	NODES_TO_EXCLUDE=dcc-compeb-02,dcc-dhvi-01,dcc-dhvi-02
	sbatch -p yoderlab,common,scavenger -o slurm.ipy.$SET_ID.$STEPS.$ID.2 --exclude=$NODES_TO_EXCLUDE -N 1-1 --ntasks 4 --mem-per-cpu 4G \
	$SCRIPTDIR/run_ipy.sh $PARFILE $STEPS $WORKDIR $FORCE
done


#### MERGE ASSEMBLIES #####
FINAL_ASSEMBLY=refb_Cmed_R1_merged; cd ${WORKDIR}; ipyrad -m $FINAL_ASSEMBLY params*_r01_*; cd $BASEDIR


##### STEPS 6-7 (ALL INDS TOGETHER) #####
STEPS=67
PARFILE=params-$FINAL_ASSEMBLY.txt
sbatch -p yoderlab,common -o slurm.ipyrad.$STEPS.$FINAL_ASSEMBLY -N 1-1 --ntasks 8 --mem-per-cpu 4G \
$SCRIPTDIR/run_ipy.sh $PARFILE $STEPS $WORKDIR $FORCE


##### QC ON VCF #####
SET_ID=refb_Cmed_R1
FINAL_ASSEMBLY=refb_Cmed_R1_merged
VCF_DIR=analyses/ipyrad/$SET_ID/${FINAL_ASSEMBLY}_outfiles/
VCF_QCDIR=analyses/qc/ipyrad/$FINAL_ASSEMBLY/bcftoolsStats/
sbatch -p yoderlab,common,scavenger -o slurm.qc.ipyrad.$FINAL_ASSEMBLY --mem 4G \
scripts/qc/qc_vcf.sh $FINAL_ASSEMBLY $VCF_DIR $VCF_QCDIR TRUE 

mkdir -p analyses/qc/ipyrad/$FINAL_ASSEMBLY/
cp $WORKDIR/${FINAL_ASSEMBLY}_outfiles/${FINAL_ASSEMBLY}_stats.txt analyses/qc/ipyrad/$FINAL_ASSEMBLY/
mkdir -p $VCF_TARGETDIR
mv $WORKDIR/${FINAL_ASSEMBLY}_outfiles/${FINAL_ASSEMBLY}.vcf.gz $VCF_TARGETDIR
mkdir -p $OTHERVAR_TARGETDIR
mv $WORKDIR/${FINAL_ASSEMBLY}_outfiles/${FINAL_ASSEMBLY}* $OTHERVAR_TARGETDIR

##### MISC #####
#grep -l -Z 'IOError' slurm* | xargs -0 -I{} mv {} ipyrad_failed/
#grep -l -Z 'IPyradError' slurm* | xargs -0 -I{} mv {} ipyrad_failed/
#grep -l -Z 'Encountered' slurm* | xargs -0 -I{} mv {} ipyrad_failed/
#grep -l -Z 'Done with script' slurm.ipy.* | xargs -0 -I{} mv {} ipyrad_worked
#IDs=($(ls ipyrad_failed/ | sed "s/slurm.ipyrad.//"))
#for f in analyses/ipyrad/byInd/*/*/*s5_consens_stats.txt; do (cat "${f}"; echo) >> ipyrad.s5_output.txt; done


################################################################################
################################################################################
rsync -r /home/jelmer/Dropbox/sc_lemurs/radseq/scripts/* jwp37@dcc-slogin-02.oit.duke.edu:/datacommons/yoderlab/users/jelmer/radseq/scripts/
rsync jwp37@dcc-slogin-02.oit.duke.edu:/datacommons/yoderlab/users/jelmer/radseq/analyses/ipyrad/params* /home/jelmer/Dropbox/sc_lemurs/radseq/analyses/ipyrad/parfiles

scp jwp37@dcc-slogin-02.oit.duke.edu:/datacommons/yoderlab/users/jelmer/radseq/analyses/ipyrad/R1_merged_outfiles/R1_merged_stats.txt /home/jelmer/Dropbox/sc_lemurs/radseq/analyses/ipyrad/output_stats
scp jwp37@dcc-slogin-02.oit.duke.edu:/datacommons/yoderlab/users/jelmer/radseq/analyses/ipyrad/R1_Microcebus_outfiles/R1_Microcebus_stats.txt /home/jelmer/Dropbox/sc_lemurs/radseq/analyses/ipyrad/output_stats
scp jwp37@dcc-slogin-02.oit.duke.edu:/datacommons/yoderlab/users/jelmer/radseq/analyses/ipyrad/R1_Cheirogaleus_outfiles/R1_Cheirogaleus_stats.txt /home/jelmer/Dropbox/sc_lemurs/radseq/analyses/ipyrad/output_stats
