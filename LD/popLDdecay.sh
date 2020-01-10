## TO: LD BY GROUP

################################################################################
##### SET-UP #####
################################################################################
## Software:
POPLD=/datacommons/yoderlab/programs/PopLDdecay/PopLDdecay

## Command-line args:
VCF=$1
FILE_ID=$2
OUTDIR=$3
OUTPUT_MODE=$4
MAXDIST=$5

## Process args:
OUTFILE=$OUTDIR/$FILE_ID.popLDdecay.$OUTPUT_MODE

## Report:
echo "##### popLDdecay.sh: Starting script."
echo "##### popLDdecay.sh: Input VCF file: $VCF"
echo "##### popLDdecay.sh: File ID: $FILE_ID"
echo "##### popLDdecay.sh: Output dir: $OUTDIR"
echo "##### popLDdecay.sh: Output mode: $OUTPUT_MODE"
echo "##### popLDdecay.sh: Output file: $OUTFILE"
echo "##### popLDdecay.sh: Max distance (in kb): $MAXDIST"
printf "\n"

[[ ! -d $OUTDIR ]] && echo -e "##### popLDdecay.sh: Creating output dir...\n" && mkdir -p $OUTDIR


################################################################################
##### RUN POP-LD-DECAY #####
################################################################################
echo -e "##### popLDdecay.sh: Running popLDdecay...\n"
$POPLD -InVCF $VCF -OutStat $OUTFILE -OutType $OUTPUT_MODE -MAF 0.01 -MaxDist $MAXDIST

printf "\n"
echo "##### popLDdecay.sh: Done with script." 
date