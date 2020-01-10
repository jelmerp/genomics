
SOURCE_ID=msp3proj.mac3.FS6
TARGET_ID=msp3proj_noMur.mac3.FS6
INDIR=/work/jwp37/msp3/seqdata/vcf/map2msp3.gatk4.paired.joint/final/
OUTDIR=/work/jwp37/msp3/seqdata/vcf/map2msp3.gatk4.paired.joint/final/split/
INDFILE=metadata/indsel/msp3_noMur.txt
sbatch -p yoderlab,common,scavenger -o slurm.splitVCF.$TARGET_ID \
	/datacommons/yoderlab/users/jelmer/scripts/conversion/splitVCFbyInd_vcftools.sh $SOURCE_ID $TARGET_ID $INDIR $OUTDIR $INDFILE


################################################################################
# rsync -avr --no-perms /home/jelmer/Dropbox/sc_lemurs/msp3/metadata/ jwp37@dcc-slogin-02.oit.duke.edu:/datacommons/yoderlab/users/jelmer/msp3/metadata/
# rsync -avr --no-perms /home/jelmer/Dropbox/sc_lemurs/scripts/ jwp37@dcc-slogin-02.oit.duke.edu:/datacommons/yoderlab/users/jelmer/scripts/