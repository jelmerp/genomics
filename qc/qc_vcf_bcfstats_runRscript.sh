## Run R script on bctoolsStats output:

cd Dropbox/sc_lemurs/radseq

##### VCFs FROM GATK #####
## mapped2mmur - R1:
scripts/qc/qc_vcf_bcftoolsStats.R gat mapped2mmur R1 joint allInds allInds FALSE analyses/qc/vcf/mapped2mmur/R1/joint/
scripts/qc/qc_vcf_bcftoolsStats.R gat mapped2mmur R1 joint Microcebus Microcebus FALSE analyses/qc/vcf/mapped2mmur/R1/joint/
#scripts/qc/qc_vcf_bcftoolsStats.R gat mapped2mmur R1 joint Microcebus Microcebus.DP5.GQ20.MAXMISS0.5.MAF0.1.INDMISS0.7 FALSE analyses/qc/vcf/mapped2mmur/R1/joint/

## mapped2mmur - paired:
scripts/qc/qc_vcf_bcftoolsStats.R gat mapped2mmur paired joint allInds allInds FALSE analyses/qc/vcf/mapped2mmur/paired/joint/
scripts/qc/qc_vcf_bcftoolsStats.R gat mapped2mmur paired joint Microcebus Microcebus FALSE analyses/qc/vcf/mapped2mmur/paired/joint/

## mapped2cmed:
scripts/qc/qc_vcf_bcftoolsStats.R gat mapped2cmed R1 joint Cheirogaleus Cheirogaleus FALSE analyses/qc/vcf/mapped2cmed/R1/joint/
scripts/qc/qc_vcf_bcftoolsStats.R gat mapped2cmed paired joint Cheirogaleus Cheirogaleus FALSE analyses/qc/vcf/mapped2cmed/paired/joint/


##### VCFs FROM IPYRAD #####
## denovo -- allInds, Microcebus, Cheirogaleus:
scripts/qc/qc_vcf_bcftoolsStats.R ipy denovo R1 joint allInds R1_merged2 FALSE analyses/qc/ipyrad/denovo_R1_allInds
scripts/qc/qc_vcf_bcftoolsStats.R ipy denovo R1 joint Microcebus R1_Microcebus FALSE analyses/qc/ipyrad/denovo_R1_Microcebus
scripts/qc/qc_vcf_bcftoolsStats.R ipy denovo R1 joint Cheirogaleus R1_Cheirogaleus FALSE analyses/qc/ipyrad/denovo_R1_Cheirogaleus

## mapped2mmur -- allInds, Microcebus:
scripts/qc/qc_vcf_bcftoolsStats.R ipy mapped2mmur R1 joint allInds refb_Mmur_R1_allInds FALSE analyses/qc/ipyrad/refb_Mmur_R1_allInds
scripts/qc/qc_vcf_bcftoolsStats.R ipy mapped2mmur R1 joint Microcebus refb_Mmur_R1_Microcebus FALSE analyses/qc/ipyrad/refb_Mmur_R1_Microcebus

## mapped2cmed -- Cheirogaleus:
scripts/qc/qc_vcf_bcftoolsStats.R ipy mapped2cmed R1 joint Cheirogaleus refb_Cmed_R1_merged FALSE analyses/qc/ipyrad/refb_Cmed_R1_merged


################################################################################
################################################################################
# rsync -r --verbose /home/jelmer/Dropbox/sc_lemurs/radseq/scripts/ jwp37@dcc-slogin-02.oit.duke.edu:/datacommons/yoderlab/users/jelmer/radseq/scripts/
# rsync -r --verbose jwp37@dcc-slogin-02.oit.duke.edu:/datacommons/yoderlab/users/jelmer/radseq/analyses/qc/vcf/ /home/jelmer/Dropbox/sc_lemurs/radseq/analyses/qc/vcf/
# rsync -r jwp37@dcc-slogin-02.oit.duke.edu:/datacommons/yoderlab/users/jelmer/radseq/analyses/qc/ /home/jelmer/Dropbox/sc_lemurs/radseq/analyses/qc/

## Arguments to qc_vcf_bcftoolsStats.R script:
# ref: denovo / mapped2mmur / mapped2cmed
# read.type: R1 / paired
# vcf.type: ind / joint / joint_ind
# whichInds: allInds / Microcebus / Cheirogaleus
# fileID.prefix: e.g. R1_merged2 / Microcebus.DP5.GQ20.MAXMISS0.5.MAF0.1.INDMISS0.7
# depthDist.ind: TRUE / FALSE # Whether or not to plot distribution of per-site read depth for each individual
# basedir: analyses/qc/ipyrad/denovo_R1_allInds