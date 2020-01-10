## Software:
JBROWSE_DIR=/var/www/html/jbrowse/JBrowse-1.16.6/

## Input files:
REF=/home/jelmer/Dropbox/sc_lemurs/seqdata/reference/mmur/GCF_000165445.2_Mmur_3.0_genomic_stitched.fasta
ANNOT=/home/jelmer/Dropbox/sc_lemurs/seqdata/reference/mmur/GCF_000165445.2_Mmur_3.0_genomic.gff

## Prep fasta:
$JBROWSE_DIR/bin/prepare-refseqs.pl --fasta $REF #docs/tutorial/data_files/volvox.fa

## Annotations:
$JBROWSE_DIR/bin/flatfile-to-json.pl --gff $ANNOT --trackType CanvasFeatures --trackLabel mmur_annot

## Bam:


## Generate indices for searching:
$JBROWSE_DIR/bin/generate-names.pl -v