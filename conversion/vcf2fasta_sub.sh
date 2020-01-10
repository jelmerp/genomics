## vcf2fasta:
for FILE_ID in Microcebus.DP5.GQ20.MAXMISS0.5.MAF0.1.INDMISS0.7 Microcebus.DP5.GQ20.MAXMISS0.75.MAF0.05.INDMISS0.5 \
Microcebus_griseorufus.DP5.GQ20.MAXMISS0.5.MAF0.05.INDMISS0.5 Microcebus_LehMitMar.DP5.GQ20.MAXMISS0.5.MAF0.05.INDMISS0.5 \
Microcebus_MurGanMan.DP5.GQ20.MAXMISS0.5.MAF0.05.INDMISS0.5
do
	# FILE_ID=Cheirogaleus.r01r99.FS6.mac0
	echo $FILE_ID
	#INDIR=/work/jwp37/radseq/seqdata/vcf/mapped2mmur/R1/joint/final
	INDIR=/work/jwp37/radseq/seqdata/vcf/gatk/mapped2cmed/paired/joint/final/
	OUTDIR=/work/jwp37/radseq/seqdata/fasta/
	SCAFFOLD=ALL
	sbatch --mem 8G -p yoderlab,common,scavenger -o slurm.vcf2fasta.$FILE_ID.txt \
	scripts/conversion/vcf2fasta.sh $FILE_ID $INDIR $OUTDIR $SCAFFOLD
done





################################################################################
################################################################################
## Cichlid stuff:

## For single scaffolds:
IFS=$'\n' read -d '' -a SCAFFOLDS < /proj/cmarlab/users/jelmer/cichlids/metadata/scaffolds.txt
INDIR=seqdata/vcf_split;
FILE_ID=EjaC.Dstat
for SCAFFOLD in ${SCAFFOLDS[@]:0:50}
do
	bsub -q day -o slurm.vcf2fasta.$FILE_ID.txt scripts/conversion/vcf2fasta.sh $FILE_ID $INDIR $SCAFFOLD
done

## varfasta2fullfasta:
IFS=$'\n' read -d '' -a SCAFFOLDS < /proj/cmarlab/users/jelmer/cichlids/metadata/scaffolds.txt
FILE_ID=EjaC.Dstat.DP5.GQ20.MAXMISS0.5.MAF0.01 #SCAFFOLD=NT_167388.1
for SCAFFOLD in ${SCAFFOLDS[@]:0:25}
do
	bsub -M 8 -q hour -o slurm.varFasta2fullFasta.$FILE_ID.$SCAFFOLD.txt Rscript scripts/conversion/varFasta2fullFasta.R $FILE_ID $SCAFFOLD
done
