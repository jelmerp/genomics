## VCF files need to be tabix'ed!
FILE_ID=EjaC.Dstat.DP2.GQ15.MAXMISS0.75.MAF0.01; VCF=seqdata/vcf_split/$FILE_ID.vcf; bsub -q day -o slurm.tabix.$FILE_ID.txt scripts/misc/tabix.sh $VCF
FILE_ID=EjaC.Dstat.DP5.GQ20.MAXMISS0.5.MAF0.01; VCF=seqdata/vcf_split/$FILE_ID.vcf; bsub -q day -o slurm.tabix.$FILE_ID.txt scripts/misc/tabix.sh $VCF
FILE_ID=EjaC.Dstat.DP5.GQ20.MAXMISS0.9.MAF0.01; VCF=seqdata/vcf_split/$FILE_ID.vcf; bsub -q day -o slurm.tabix.$FILE_ID.txt scripts/misc/tabix.sh $VCF

FILE_ID=EjaC.Cgal.Cgui.DP5.GQ20.MAXMISS0.5.MAF0.01; VCF=seqdata/vcf_split/$FILE_ID.vcf; bsub -q day -o slurm.tabix.$FILE_ID.txt scripts/misc/tabix.sh $VCF
FILE_ID=EjaC.Cgal.Cgui.DP5.GQ20.MAXMISS0.9.MAF0.01; VCF=seqdata/vcf_split/$FILE_ID.vcf; bsub -q day -o slurm.tabix.$FILE_ID.txt scripts/misc/tabix.sh $VCF
FILE_ID=EjaC.Dstat.DP5.GQ30.MAXMISS0.5.MAF0.01; VCF=seqdata/vcf_split/$FILE_ID.vcf; bsub -q day -o slurm.tabix.$FILE_ID.txt scripts/misc/tabix.sh $VCF
FILE_ID=EjaC.Dstat.DP5.GQ30.MAXMISS0.9.MAF0.01; VCF=seqdata/vcf_split/$FILE_ID.vcf; bsub -q day -o slurm.tabix.$FILE_ID.txt scripts/misc/tabix.sh $VCF


## Run all scaffolds sequentially (program gets into trouble if run simultaneously due to created temp files):
#SCAFFOLDSFILE=/proj/cmarlab/users/jelmer/cichlids/metadata/scaffolds.txt # 3 days # subset to 500!
SCAFFOLDSFILE=/proj/cmarlab/users/jelmer/cichlids/analyses/windowstats/popgenome/input/missingScafs2.txt
FILE_ID=EjaC.Dstat.DP5.GQ20.MAXMISS0.5.MAF0.01
WINSIZE=50000; STEPSIZE=5000
TRIPLETFILE=analyses/windowstats/popgenome/input/triplets.txt
bsub -q day -o slurm.popgenome_run.txt scripts/windowstats/popgenome_pip.sh $FILE_ID $TRIPLETFILE $WINSIZE $STEPSIZE $SCAFFOLDSFILE



################################################################################
scp -r /home/jelmer/Dropbox/sc_fish/cichlids/scripts/* jelmerp@killdevil.unc.edu:/proj/cmarlab/users/jelmer/cichlids/scripts/
scp /home/jelmer/Dropbox/sc_fish/cichlids/analyses/windowstats/popgenome/input/* jelmerp@killdevil.unc.edu:/proj/cmarlab/users/jelmer/cichlids/analyses/windowstats/popgenome/input/
scp -r /home/jelmer/Dropbox/sc_fish/cichlids/analyses/windowstats/* jelmerp@killdevil.unc.edu:/proj/cmarlab/users/jelmer/cichlids/analyses/windowstats/

scp jelmerp@killdevil.unc.edu:/proj/cmarlab/users/jelmer/cichlids/analyses/windowstats/popgenome/output/* /home/jelmer/Dropbox/sc_fish/cichlids/analyses/windowstats/popgenome/output


#bcftools view -O z -s Cdec088,Cdec328,Cfus085,Cfus350,Cfus503,SgalMA1,TguiMA1,TguiMA2,TguiMA4 $VCF.gz > test.NT_167580.1.vcf.gz
#scp jelmerp@killdevil.unc.edu:/proj/cmarlab/users/jelmer/cichlids/seqdata/vcf_split/EjaC.Dstat.DP5.GQ30* /home/jelmer/Dropbox/sc_fish/cichlids/seqdata/vcf_split

#scp -r /home/jelmer/Dropbox/sc_fish/software/PopGenome* jelmerp@killdevil.unc.edu:/proj/cmarlab/users/jelmer/software
#install.packages("/proj/cmarlab/users/jelmer/software/PopGenome_2.2.4.tar.gz", lib = "/netscr/jelmerp/Rlibs/", repos = NULL)
#library(PopGenome, lib.loc="/netscr/jelmerp/Rlibs/")