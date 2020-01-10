##### SET-UP #####
BASEDIR=/datacommons/yoderlab/users/jelmer/radseq
cd $BASEDIR
SCRIPTDIR=$BASEDIR/scripts/genotyping/ipyrad
IPYRAD_DIR=$BASEDIR/analyses/ipyrad
REF_FOR_PARAMS="\/work\/jwp37\/singlegenomes\/seqdata\/reference\/GCF_000165445.2_Mmur_3.0_genomic.fna"
FASTQ_DIR="\/work\/jwp37\/radseq\/seqdata\/fastq\/demult_dedup_trim2"
IFS=$'\n' read -d '' -a IDs < $BASEDIR/metadata/sampleIDs.txt # Sequence file IDs

## Variables:
SET_ID=refb_Mmur_R1
WORKDIR=$IPYRAD_DIR/$SET_ID
VCF_TARGETDIR=seqdata/vcf/ipyrad/mapped2mmur/R1/
OTHERVAR_TARGETDIR=seqdata/vcf/variants_otherFormats/ipyrad/mapped2mmur/R1/

## Settings:
ASSEMBLY_METHOD="denovo+reference"
DATATYPE=rad # Default, doesn't need to be changed
FORCE=FALSE


##### STEPS 1-5 (SEPARATELY FOR EACH IND) #####                                  
[[ ! -f $IPYRAD_DIR/params-dummy.txt ]] && echo "Creating dummy param file..." && cd $IPYRAD_DIR && ipyrad -n dummy && cd $BASEDIR
mkdir -p $WORKDIR
STEPS=12345

for ID in ${IDs[@]}
do
	#ID=${IDs[2]} #ID=atri001_r01_p1f07
	PARFILE=$WORKDIR/params-$ID.txt
	sed "s/dummy/$ID/g" $IPYRAD_DIR/params-dummy.txt | \
	sed "s/## \[4\]/${FASTQ_DIR}\/$ID*_R1*fastq.gz ## \[4\]/" | \
	sed "s/^denovo/${ASSEMBLY_METHOD}/" | \
	sed "s/^rad/${DATATYPE}/" | \
	sed "s/## \[6\]/${REF_FOR_PARAMS} ## \[6\]/" > $PARFILE
	
	NODES_TO_EXCLUDE=dcc-compeb-02,dcc-dhvi-01,dcc-dhvi-02
	sbatch -p yoderlab,common,scavenger -o slurm.ipy.$SET_ID.$STEPS.$ID --exclude=$NODES_TO_EXCLUDE -N 1-1 --ntasks 1 --mem-per-cpu 8G \
	$SCRIPTDIR/run_ipy.sh $PARFILE $STEPS $WORKDIR $FORCE
done


#### MERGE ASSEMBLIES #####
## All together:
FINAL_ASSEMBLY=refb_Mmur_R1_allInds; cd ${WORKDIR}; ipyrad -m $FINAL_ASSEMBLY params*_r01_*; cd $BASEDIR

## Microcebus:
MICROCEBUS_FILES=$(find $WORKDIR -maxdepth 1 -name "params-m*_r01_*" -not -name "*mzaz*")
FINAL_ASSEMBLY=refb_Mmur_R1_Microcebus; cd ${WORKDIR}; ipyrad -m $FINAL_ASSEMBLY $MICROCEBUS_FILES; cd $BASEDIR


##### STEPS 6-7 (ALL INDS TOGETHER) #####
## All together:
STEPS=67
FINAL_ASSEMBLY=refb_Mmur_R1_allInds
PARFILE=params-$FINAL_ASSEMBLY.txt
sbatch -p yoderlab,common -o slurm.ipyrad.$STEPS.$FINAL_ASSEMBLY -N 1-1 --ntasks 8 --mem-per-cpu 4G \
$SCRIPTDIR/run_ipy.sh $PARFILE $STEPS $WORKDIR $FORCE

## Microcebus:
STEPS=67
FINAL_ASSEMBLY=refb_Mmur_R1_Microcebus
PARFILE=params-$FINAL_ASSEMBLY.txt
sbatch -p yoderlab,common -o slurm.ipyrad.$STEPS.$FINAL_ASSEMBLY -N 1-1 --ntasks 8 --mem-per-cpu 4G \
$SCRIPTDIR/run_ipy.sh $PARFILE $STEPS $WORKDIR $FORCE


##### QC ON VCF #####
## All together:
SET_ID=refb_Mmur_R1
FINAL_ASSEMBLY=refb_Mmur_R1_allInds
VCF_DIR=analyses/ipyrad/$SET_ID/${FINAL_ASSEMBLY}_outfiles/
VCF_QCDIR=analyses/qc/ipyrad/$FINAL_ASSEMBLY
sbatch -p yoderlab,common,scavenger -o slurm.qc.ipyrad.$FINAL_ASSEMBLY --mem 4G \
scripts/qc/qc_vcf.sh $FINAL_ASSEMBLY $VCF_DIR $VCF_QCDIR TRUE 

mkdir -p analyses/qc/ipyrad/$FINAL_ASSEMBLY/
mv $WORKDIR/${FINAL_ASSEMBLY}_outfiles/${FINAL_ASSEMBLY}_stats.txt analyses/qc/ipyrad/$FINAL_ASSEMBLY/
mv $WORKDIR/${FINAL_ASSEMBLY}_outfiles/${FINAL_ASSEMBLY}.vcf.gz $VCF_TARGETDIR
mv $WORKDIR/${FINAL_ASSEMBLY}_outfiles/${FINAL_ASSEMBLY}* $OTHERVAR_TARGETDIR

## Microcebus:
SET_ID=refb_Mmur_R1
FINAL_ASSEMBLY=refb_Mmur_R1_Microcebus
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



##### MISC #####
#grep -l -Z 'IOError' slurm* | xargs -0 -I{} mv {} ipyrad_failed/
#grep -l -Z 'Traceback' slurm* | xargs -0 -I{} mv {} ipyrad_failed/
#grep -l -Z 'Encountered' slurm* | xargs -0 -I{} mv {} ipyrad_failed/
#grep -l -Z 'Done with script' slurm* | xargs -0 -I{} mv {} analyses/ipyrad/aa_all/logfiles
#IDs=($(ls ipyrad_failed/ | sed "s/slurm.ipy.refb_Mmur_R1.12345.//"))
#for f in analyses/ipyrad/byInd/*/*/*s5_consens_stats.txt; do (cat "${f}"; echo) >> ipyrad.s5_output.txt; done


################################################################################
################################################################################
rsync -r /home/jelmer/Dropbox/sc_lemurs/radseq/scripts/* jwp37@dcc-slogin-02.oit.duke.edu:/datacommons/yoderlab/users/jelmer/radseq/scripts/
rsync jwp37@dcc-slogin-02.oit.duke.edu:/datacommons/yoderlab/users/jelmer/radseq/analyses/ipyrad/params* /home/jelmer/Dropbox/sc_lemurs/radseq/analyses/ipyrad/parfiles

scp jwp37@dcc-slogin-02.oit.duke.edu:/datacommons/yoderlab/users/jelmer/radseq/analyses/ipyrad/R1_merged_outfiles/R1_merged_stats.txt /home/jelmer/Dropbox/sc_lemurs/radseq/analyses/ipyrad/output_stats
scp jwp37@dcc-slogin-02.oit.duke.edu:/datacommons/yoderlab/users/jelmer/radseq/analyses/ipyrad/R1_Microcebus_outfiles/R1_Microcebus_stats.txt /home/jelmer/Dropbox/sc_lemurs/radseq/analyses/ipyrad/output_stats