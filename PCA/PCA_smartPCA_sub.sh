
################################################################################
### PERFORM PCA:
FILE_ID=Microcebus.DP5.GQ20.MAXMISS0.5.MAF0.1.INDMISS0.5
VCF_DIR=/work/jwp37/radseq/seqdata/vcf/mapped2mmur/R1/joint/final
PLINK_DIR=/work/jwp37/radseq/seqdata/variants_otherFormats/plink
PCA_DIR=/datacommons/yoderlab/users/jelmer/radseq/analyses/PCA/

sbatch -p common,yoderlab,scavenger -o slurm.filterVCF.$SOURCE_ID.$DP.$GQ.$MAXMISS.$MAF.$NAME_ADDITION \
scripts/PCA/PCA.sh $FILE_ID /lustre/scr/j/e/jelmerp/cichlids/seqdata/variants_combined



## Split VCFs:
FILE_ID=bothPhyl2; bsub -q day -N -o slurm.splitVCF.$FILE_ID.txt scripts/conversion/splitVCF_byIndv.sh bothPhyl.SNPs.GATKfilt.biallelic ^SgalME1 $FILE_ID.SNPs.GATKfilt.biallelic /lustre/scr/j/e/jelmerp/cichlids/seqdata/variants_combined
FILE_ID=outgroups; bsub -q day -N -o slurm.splitVCF.$FILE_ID.txt scripts/conversion/splitVCF_byIndv.sh bothPhyl.SNPs.GATKfilt.biallelic SgalMA1,TguiNG2,TguiNG5,Ckot383,Ckot499,SgalME1,SgalME2,SgalMU1,SgalMU2,TguiMA1,TguiMA2,TguiMA4 $FILE_ID.SNPs.GATKfilt.biallelic /lustre/scr/j/e/jelmerp/cichlids/seqdata/variants_combined/subsetByIndv




################################################################################
#scp jwp37@dcc-slogin-02.oit.duke.edu:/work/jwp37/radseq/seqdata/vcf/mapped2mmur/R1/joint/final/Microcebus.DP5.GQ20.MAXMISS0.5.MAF0.1.INDMISS0.7.vcf.gz /home/jelmer/Dropbox/sc_lemurs/radseq/seqdata/vcf
#scp jwp37@dcc-slogin-02.oit.duke.edu:/work/jwp37/radseq/seqdata/variants_otherFormats/plink/* /home/jelmer/Dropbox/sc_lemurs/radseq/seqdata/plink/


# scp -r /home/jelmer/Dropbox/sc_fish/cichlids/software/EIG-master jwp37@dcc-slogin-02.oit.duke.edu:/datacommons/yoderlab/programs/
# make install OPENBLAS=/datacommons/yoderlab/programs/openblas
# GSL=/datacommons/yoderlab/programs/gsl

## Installing OPENBLAS:
# git clone https://github.com/xianyi/OpenBLAS.git
# cd OpenBLAS
# make
# make PREFIX=/datacommons/yoderlab/programs/openblas install

# make CFLAGS="-I/datacommons/yoderlab/programs/openblas/include/ -I/datacommons/yoderlab/programs/gsl/include/" LDFLAGS="-L/datacommons/yoderlab/programs/openblas/lib/ -L/datacommons/yoderlab/programs/gsl/lib/"

## Try on laptop:
# make PREFIX=/home/jelmer/Dropbox/sc_lemurs/software/OpenBLAS install

# make install OPENBLAS=/home/jelmer/Dropbox/sc_lemurs/software/OpenBLAS
# make CFLAGS="-I/home/jelmer/Dropbox/sc_lemurs/software/OpenBLAS/include/ -I/usr/local/lib/" LDFLAGS="-L/home/jelmer/Dropbox/sc_lemurs/software/OpenBLAS/lib/ -L/usr/local/lib/"
