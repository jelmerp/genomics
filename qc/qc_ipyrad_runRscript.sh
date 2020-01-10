## Run R script on ipyrad output statistics

cd Dropbox/sc_lemurs/radseq

## denovo:
scripts/qc/qc_ipyrad.R denovo R1 allInds FALSE
scripts/qc/qc_ipyrad.R denovo R1 Microcebus TRUE
scripts/qc/qc_ipyrad.R denovo R1 Cheirogaleus TRUE

## mapped2cmed:
scripts/qc/qc_ipyrad.R refb_Cmed R1 merged TRUE
scripts/qc/qc_ipyrad.R refb_Cmed paired merged TRUE

## mapped2mmur:
scripts/qc/qc_ipyrad.R refb_Mmur R1 allInds FALSE
scripts/qc/qc_ipyrad.R refb_Mmur R1 Microcebus TRUE



################################################################################
################################################################################
# rsync -r --verbose jwp37@dcc-slogin-02.oit.duke.edu:/datacommons/yoderlab/users/jelmer/radseq/analyses/qc/vcf/ /home/jelmer/Dropbox/sc_lemurs/radseq/analyses/qc/vcf/
# rsync -r jwp37@dcc-slogin-02.oit.duke.edu:/datacommons/yoderlab/users/jelmer/radseq/analyses/qc/ /home/jelmer/Dropbox/sc_lemurs/radseq/analyses/qc/	