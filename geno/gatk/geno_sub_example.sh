################################################################################
#### FASTQ -> GVCF ####
################################################################################
SCR_IGENO=/datacommons/yoderlab/users/jelmer/scripts/geno/gatk/igeno_pip.sh
REF_DIR=/datacommons/yoderlab/users/jelmer/seqdata/reference/mmur/
REF_ID=GCF_000165445.2_Mmur_3.0_genomic_stitched
REF=$REF_DIR/$REF_ID.fasta
LOOKUP=/datacommons/yoderlab/users/jelmer/radseq/metadata/lookup_IDlong.txt
FASTQ_DIR=/datacommons/yoderlab/data/radseq/fastq/linksToAllProcessed/
BAM_DIR=/datacommons/yoderlab/data/radseq/bam/map2mmur/
VCF_DIR=/datacommons/yoderlab/data/radseq/vcf/map2mmur.gatk.ind/
QC_DIR_VCF=/datacommons/yoderlab/users/jelmer/radseq/qc/vcf/map2mmur.gatk.ind/
QC_DIR_BAM=/datacommons/yoderlab/users/jelmer/radseq/qc/bam/map2mmur/
MINMAPQUAL=30
DP_MEAN=5
MEM=12
NCORES=4
REGION_FILE=notany
REGION_SEL=notany #"EXCLUDE" # Bad scaffolds are excluded during joint genotyping
BAM_SUFFIX=notany
SKIP_FLAGS="-A" # M: no mapping / P: no bam processing / m: no bam merging / A: no region sel. / V: no vardisc / G: no genotyping / F: no VCF filtering / -D: no dedup 

IDs=( $(cat $LOOKUP | cut -f 2 | sort | uniq | egrep "mgri|mmur|mhyb|mgan") )

for ID_SHORT in ${IDs[@]}
do
	echo -e "\n#### Sample ID: $ID_SHORT"
	
	LANE=$(grep $ID_SHORT $LOOKUP | cut -f 8 | head -n 1)
	LIBRARY=$(grep $ID_SHORT $LOOKUP | cut -f 9 | head -n 1)
	READGROUP_STRING="@RG\tID:${LANE}\tSM:${ID_SHORT}\tPL:ILLUMINA\tLB:$LIBRARY"
	
	[[ ! -d metadata/replicates ]] && mkdir -p metadata/replicates
	ID_LONG_FILE=metadata/replicates/$ID_SHORT.txt
	grep $ID_SHORT $LOOKUP | cut -f 1 > $ID_LONG_FILE
	
	echo "#### Lane: $LANE // Library: $LIBRARY"
	echo "#### Readgroup string: $READGROUP_STRING"
	echo "#### File with long IDs:"; cat $ID_LONG_FILE
	
	SEQTYPE=$(grep $ID_SHORT $LOOKUP | cut -f 14 | head -n 1)
	[[ $SEQTYPE == "pe" ]] && USE_R2=TRUE
	[[ $SEQTYPE == "se" ]] && USE_R2=FALSE
	echo "#### Use R2: $USE_R2"
	
	echo "#### Submitting job for $ID_SHORT"
	sbatch -p yoderlab,common,scavenger -N 1-1 --ntasks 4 --mem-per-cpu 4G --job-name=igeno -o slurm.igeno.$ID_SHORT \
	$SCR_IGENO $ID_SHORT $ID_LONG_FILE $USE_R2 $REF \
	$FASTQ_DIR $BAM_DIR $VCF_DIR $QC_DIR_VCF $QC_DIR_BAM $MINMAPQUAL $DP_MEAN $BAM_SUFFIX \
	$READGROUP_STRING $REGION_FILE $REGION_SEL $MEM $NCORES $SKIP_FLAGS
done


################################################################################
#### JOINT GENOTYPING ####
################################################################################
SCR_JGENO=/datacommons/yoderlab/users/jelmer/scripts/geno/gatk/jgeno_pip.sh
REF_DIR=/datacommons/yoderlab/users/jelmer/seqdata/reference/mmur/
REF_ID=GCF_000165445.2_Mmur_3.0_genomic_stitched
REF=$REF_DIR/$REF_ID.fasta
SCAFFOLD_FILE=$REF_DIR/$REF_ID.scaffoldList_NC.txt # Only do mapped (NC_) scaffolds + exclude mtDNA + exclude sex chrom
GVCF_DIR=/datacommons/yoderlab/data/radseq/vcf/map2mmur.gatk.ind/gvcf
VCF_DIR=/datacommons/yoderlab/data/radseq/vcf/map2mmur.gatk.joint/
QC_DIR_VCF=radseq/analyses/qc/vcf/map2mmur.gatk.joint
ADD_COMMANDS="none"
MEM_JOB=36
MEM_GATK=24
NCORES=1
SKIP_GENO=FALSE
LOOKUP=/datacommons/yoderlab/users/jelmer/radseq/metadata/lookup_IDlong.txt

FILE_ID=micro
IDs=( $(grep "Microcebus" $LOOKUP | cut -f 2) )

$SCR_GJOINT $FILE_ID $SCAFFOLD_FILE $GVCF_DIR $VCF_DIR $QC_DIR_VCF \
	$REF "$ADD_COMMANDS" $MEM_JOB $MEM_GATK $NCORES $SKIP_GENO ${IDs[@]}
