FASTQ_DIR=/work/jwp37/radseq/seqdata/fastq/r02/raw
CUTSITE="TGCAGG"

################################################################################
##### L1_redo #####
################################################################################
LIB=L1_redo_S2

## Check cutsite and barcodes:
#zgrep -n --color=always $CUTSITE $FASTQ_DIR/$LIB*R1*gz | head -n 100
#zgrep -n --color=always ^$ADAPTER $FASTQ_DIR/$LIB*R1*gz | grep --color=always $CUTSITE | head

FASTQ=$FASTQ_DIR/$LIB*R1*gz
OUTFILE=analyses/qc/fastq/barcodeCounts_$LIB.R1.txt
sbatch -p yoderlab,common,scavenger -o slurm.checkBarcodes.$LIB.R1 \
scripts/fastq_process/checkBarcodes.sh $FASTQ $CUTSITE $OUTFILE

FASTQ=$FASTQ_DIR/$LIB*R2*gz
OUTFILE=analyses/qc/fastq/barcodeCounts_$LIB.R2.txt
sbatch -p yoderlab,common,scavenger -o slurm.checkBarcodes.$LIB.R2 \
scripts/fastq_process/checkBarcodes.sh $FASTQ $CUTSITE $OUTFILE

## Check adapters:
ADAPTER_SHORT="AGTACAAG"
ADAPTER="GATCGGAAGAGCACACGTCTGAACTCCAGTCACAGTACAAGATCTCGTAT"
zgrep --color=always $ADAPTER $FASTQ_DIR/$LIB*R1*gz | head -n 100
#zgrep $ADAPTER $FASTQ_DIR/$LIB*R1*gz | wc -l # 920,677 (Fastqc: 883,937)

## Check Ns:
FASTQ=$FASTQ_DIR/$LIB*R1*gz
OUTFILE=analyses/qc/fastq/nCounts_$LIB.R1.txt
sbatch -p yoderlab,common,scavenger -o slurm.countNs.$LIB.R1 scripts/fastq_process/countNs.sh $FASTQ $OUTFILE

FASTQ=$FASTQ_DIR/$LIB*R2*gz
OUTFILE=analyses/qc/fastq/nCounts_$LIB.R2.txt
sbatch -p yoderlab,common,scavenger -o slurm.countNs.$LIB.R2 scripts/fastq_process/countNs.sh $FASTQ $OUTFILE


################################################################################
##### L1_redo #####
################################################################################
LIB=newLib_failedInds

## Check cutsite and barcodes:
#zgrep -n --color=always $CUTSITE $FASTQ_DIR/$LIB*R1*gz | head -n 100
#zgrep -n --color=always ^$ADAPTER $FASTQ_DIR/$LIB*R1*gz | grep --color=always $CUTSITE | head

FASTQ=$FASTQ_DIR/$LIB*R1*gz
OUTFILE=analyses/qc/fastq/barcodeCounts_$LIB.R1.txt
sbatch -p yoderlab,common,scavenger -o slurm.checkBarcodes.$LIB.R1 \
scripts/fastq_process/checkBarcodes.sh $FASTQ $CUTSITE $OUTFILE

FASTQ=$FASTQ_DIR/$LIB*R2*gz
OUTFILE=analyses/qc/fastq/barcodeCounts_$LIB.R2.txt
sbatch -p yoderlab,common,scavenger -o slurm.checkBarcodes.$LIB.R2 \
scripts/fastq_process/checkBarcodes.sh $FASTQ $CUTSITE $OUTFILE

## Check adapters:
ADAPTER_SHORT="ATTGAGGA"
ADAPTER="GATCGGAAGAGCACACGTCTGAACTCCAGTCACATTGAGGAATCTCGTAT"
zgrep --color=always $ADAPTER $FASTQ_DIR/$LIB*R1*gz | head -n 100
#zgrep $ADAPTER $FASTQ_DIR/$LIB*R1*gz | wc -l # 8,014,818 (Fastqc: 7,682,524)

## Check Ns:
FASTQ=$FASTQ_DIR/$LIB*R1*gz
OUTFILE=analyses/qc/fastq/nCounts_$LIB.R1.txt
sbatch -p yoderlab,common,scavenger -o slurm.countNs.$LIB.R1 scripts/fastq_process/countNs.sh $FASTQ $OUTFILE

FASTQ=$FASTQ_DIR/$LIB*R2*gz
OUTFILE=analyses/qc/fastq/nCounts_$LIB.R2.txt
sbatch -p yoderlab,common,scavenger -o slurm.countNs.$LIB.R2 scripts/fastq_process/countNs.sh $FASTQ $OUTFILE


################################################################################
# @K00282:342:H2JCYBBXY:1:1101:27154:1103 1:N:0:ATTGAGGA # ATTGAGGA=library-specific adapter

rsync -r --verbose jwp37@dcc-slogin-02.oit.duke.edu:/datacommons/yoderlab/users/jelmer/radseq/analyses/qc/fastq/aa_* /home/jelmer/Dropbox/sc_lemurs/radseq/analyses/qc/fastq/fastq_process/
rsync -r --verbose jwp37@dcc-slogin-02.oit.duke.edu:/datacommons/yoderlab/users/jelmer/radseq/analyses/qc/fastq/nCounts* /home/jelmer/Dropbox/sc_lemurs/radseq/analyses/qc/fastq/fastq_process/