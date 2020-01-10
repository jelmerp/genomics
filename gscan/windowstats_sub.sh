################################################################################
##### FST with vcftools #####
FILE_ID=Microcebus.r01.FS9.mac3.griseorufus
INDIR=/work/jwp37/radseq/seqdata/vcf/gatk/mapped2mmur/paired/joint/final/
OUTDIR=analyses/windowstats/fst.vcftools/output
WINSIZE=50000
STEPSIZE=50000
POPFILEDIR=analyses/windowstats/fst.vcftools/input
POPCOMBS=$POPFILEDIR/popcombs.txt # file with on each line a pair of pops to compute Fst for

for LINENR in $(seq 1 $(cat $POPCOMBS | wc -l))
do
	#LINENR=1
	POP1=$(cat $POPCOMBS | head -n $LINENR | tail -n 1 | cut -f 1 -d " ")
	POP2=$(cat $POPCOMBS | head -n $LINENR | tail -n 1 | cut -f 2 -d " ")
	echo "Pop 1: $POP1 / Pop 2: $POP2"
	#sbatch -p common,yoderlab,scavenger -o slurm.fst.$FILE_ID.$POP1.$POP2.txt \
	scripts/windowstats/fst_vcftools.sh $INDIR $FILE_ID $POP1 $POP2 $WINSIZE $STEPSIZE $OUTDIR $POPFILEDIR
done

## Popfiles:
grep "Gallery" metadata/r01/samples/samplenames_r01.txt | cut -f 2 > $POPFILEDIR/beza_gallery.txt
grep "Ihazoara" metadata/r01/samples/samplenames_r01.txt | cut -f 2 > $POPFILEDIR/beza_ihazoara.txt
grep "Spiny" metadata/r01/samples/samplenames_r01.txt | cut -f 2 > $POPFILEDIR/beza_spiny.txt

# rsync --verbose -r jwp37@dcc-slogin-02.oit.duke.edu:/datacommons/yoderlab/users/jelmer/radseq/analyses/windowstats/* /home/jelmer/Dropbox/sc_lemurs/radseq/analyses/windowstats


################################################################################
##### Tajima's D with vcftools #####
FILE_ID=EjaC.Cgal.Cgui.DP5.GQ20.MAXMISS0.5.MAF0.01
INDIR=seqdata/vcf_split
OUTDIR=analyses/windowstats/tajD
WINSIZE=10000
POPS=(Cdec Ceja Cfus Cmam Cgui)
INDS=(Cdec088,Cdec328 Ceja262,Ceja408 Cfus085,Cfus350,Cfus503 SgalMA1 TguiNG2,TguiNG5)
for i in $(seq 0 ${#POPS[@]})
do
	bsub -q hour -o slurm.tajD.vcftools.$FILE_ID.$i.txt scripts/windowstats/tajD_vcftools.sh $FILE_ID "${POPS[i]}" "${INDS[i]}" $WINSIZE $INDIR $OUTDIR
done

#scp jelmerp@killdevil.unc.edu:/proj/cmarlab/users/jelmer/cichlids/analyses/windowstats/tajD/* /home/jelmer/Dropbox/sc_fish/cichlids/analyses/windowstats/tajD


################################################################################
##### Dxy etc with S. Martin's script #####

## vcf2geno:
FILE_ID=EjaC.Dstat.DP5.GQ20.MAXMISS0.9.MAF0.01
VCF=seqdata/vcf_split/$FILE_ID.vcf.gz
MINQUAL=20
MINDEPTH=5
OUTPUT=seqdata/variants_otherFormats/geno/$FILE_ID.geno.gz
bsub -q day -o slurm.vcf2geno.$FILE_ID.txt scripts/conversion/vcf2geno.sh $VCF $OUTPUT $MINQUAL $MINDEPTH

## popgenwindows.py:
FILE_ID=EjaC.Dstat.DP5.GQ20.MAXMISS0.5.MAF0.01
WINSIZE=50000
STEPSIZE=5000
MINSITES=100
GENOFILE=seqdata/variants_otherFormats/geno/$FILE_ID.geno.gz
POPFILE=analyses/popdiff/input/popcombs_popgenwindows.txt
NCORES=4
MINDATA=0.5

for LINENR in $(seq 1 $(cat $POPFILE | wc -l))
do
	POP1=$(head -n $LINENR $POPFILE | tail -1 | cut -d " " -f 1)
	POP2=$(head -n $LINENR $POPFILE | tail -1 | cut -d " " -f 2)
	echo "Pop 1: $POP1 / Pop 2: $POP2"
	
	OUTPUT=analyses/windowstats/smartin/output/pgwin_$FILE_ID.win$WINSIZE.step$STEPSIZE.$POP1.$POP2.txt
	sbatch -p common,yoderlab,scavenger -n $NCORES -o slurm.pgwin.$FILE_ID.win$WINSIZE.$POP1.$POP2.txt \
	scripts/windowstats/pgwin.sh $GENOFILE $OUTPUT $NCORES $WINSIZE $STEPSIZE $MINSITES $MINDATA $POP1 $POP2
done


################################################################################
## Per-population pi:
FILE_ID=Cdec
bsub -q hour -N -o slurm.splitVCF.$FILE_ID.txt \
scripts/conversion/splitVCF_byIndv.sh phylB.SNPs.GATKfilt.biallelic Cdec088,Cdec328 $FILE_ID.SNPs.GATKfilt.biallelic

VCF_ID=Cdec
bsub -q hour -N -o slurm.pi.$VCF_ID scripts/sumstats/pi_vcftools.sh $VCF_ID 50000



################################################################################