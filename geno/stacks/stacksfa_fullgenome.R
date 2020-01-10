#!/usr/bin/env Rscript

################################################################################
#### SET-UP #####
################################################################################
cat('\n######################################################################\n')
cat('#### stacksfa_fullgenome.R: Starting script.\n\n')
suppressMessages(library(tidyverse))
suppressMessages(library(valr))
suppressMessages(library(seqRFLP))

## Command-line args:
options(warn = 1)
args <- commandArgs(trailingOnly = TRUE)

ID_indallele <- args[1]
infile_loci <- args[2]
infile_seqs <- args[3]
infile_scafs <- args[4]
outdir_fasta <- args[5]
outfile_loci_raw <- args[6]

# ID_indallele <- 'cmed001.A0'
# infile_loci <- '/datacommons/yoderlab/users/jelmer/proj/hybridzone/seqdata/stacks//hzproj//grimurche.og//bed/cmed001.A0.raw.bed'
# infile_seqs <- '/datacommons/yoderlab/users/jelmer/proj/hybridzone/seqdata/stacks//hzproj//grimurche.og//bed/cmed001.A0.raw.seqs'
# infile_scafs <-  '/datacommons/yoderlab/users/jelmer/seqdata/reference/mmur/scaffoldLength_NC.txt'
# outdir_fasta <- '/datacommons/yoderlab/users/jelmer/proj/hybridzone/seqdata/stacks//hzproj//grimurche.og//fasta/byInd/byScaf/'
# outfile_loci_raw <- '/datacommons/yoderlab/users/jelmer/proj/hybridzone/seqdata/stacks//hzproj//grimurche.og//loci/cmed001.locusstats1'

## process:
outfile_loci_txt <- paste0(outfile_loci_raw, '.txt')
outfile_loci_bed <- paste0(outfile_loci_raw, '.bed')

## Report:
cat('#### stacksfa_fullgenome.R: Set ID:', ID_indallele, '\n')
cat('#### stacksfa_fullgenome.R: Infile - locus bed:', infile_loci, '\n')
cat('#### stacksfa_fullgenome.R: Infile - seqs:', infile_seqs, '\n')
cat('#### stacksfa_fullgenome.R: Infile - scaffolds:', infile_scafs, '\n')
cat('#### stacksfa_fullgenome.R: Output dir:', outdir_fasta, '\n')
cat('#### stacksfa_fullgenome.R: Outfile - loci - txt:', outfile_loci_txt, '\n')
cat('#### stacksfa_fullgenome.R: Outfile - loci - bed:', outfile_loci_bed, '\n')

## Df with scaffolds:
scafs <- read.delim(infile_scafs, as.is = TRUE)
colnames(scafs) <- c('scaffold', 'length')


################################################################################
#### CREATE AND WRITE LOCUS-STATS DF #####
################################################################################
loci <- read.delim(infile_loci, as.is = TRUE, header = FALSE,
                   col.names = c('scaffold', 'start1', 'strand', 'ID', 'length')) %>%
  mutate(end1 = ifelse(strand == '+',
                       start1 + (length - 1),
                       start1 - (length - 1)),
         start = ifelse(end1 > start1, start1, end1),
         end = ifelse(end1 > start1, end1, start1)) %>%
  filter(scaffold %in% scafs$scaffold) %>%
  select(scaffold, start, end, strand, ID)

cat('\n#### stacksfa_fullgenome.R: Nr of initial loci:', nrow(loci), '\n')

## Exclude overlapping loci:
loci_plus <- loci %>%
  filter(strand == '+') %>%
  rename(chrom = scaffold) %>%
  as.tbl_interval(.)
loci_minus <- loci %>%
  filter(strand == '-') %>%
  rename(chrom = scaffold) %>%
  as.tbl_interval(.)

loci_minus_remain <- bed_subtract(loci_minus, loci_plus, any = TRUE)
loci_minus_remain <- merge(loci_minus_remain, loci_minus,
                           by = c('chrom', 'start', 'end'))
print(head(loci_minus_remain))

loci <- loci_minus_remain %>%
  as.data.frame() %>%
  rbind(., loci_plus) %>%
  rename(scaffold = chrom) %>%
  arrange(scaffold, start)

cat('\n#### stacksfa_fullgenome.R: Nr of loci after removing overlap:', nrow(loci), '\n')
cat('\n#### stacksfa_fullgenome.R: Nr of loci per strand:\n')
print(table(loci$strand))

## Write files (one per ind, so only for allele 0):
if(grepl('A0', ID_indallele)) {
  cat('\n#### stacksfa_fullgenome.R: Allele is 0, writing outfile_loci\n')

  ## Write full locusstats df:
  write.table(loci, outfile_loci_txt,
              sep = '\t', quote = FALSE, row.names = FALSE, col.names = FALSE)

  ## Write bed-style df:
  loci_bed <- loci %>%
    mutate(name = paste0(ID, '_', scaffold, '_', start, '_', end, '_strand', strand)) %>%
    select(scaffold, start, end, name)

  write.table(loci_bed, outfile_loci_bed,
              sep = '\t', quote = FALSE, row.names = FALSE, col.names = FALSE)
}


################################################################################
#### CREATE FULL-GENOME FASTA SCAFFOLD-BY-SCAFFOLD #####
################################################################################
for(scaf_idx in 1:nrow(scafs)) {
  #scaf_idx <- 16

  scaf_ID <- scafs$scaffold[scaf_idx]
  outfile_scaffoldfasta <- paste0(outdir_fasta, '/', ID_indallele, '_', scaf_ID, '.fa')
  #cat('\n#### stacksfa_fullgenome.R: Scaffold:', scaf_ID, '\n')

  scaf <- rep('N', scafs$length[scaf_idx])

  sloci <- filter(loci, scaffold == scaf_ID)

  seqs <- read.delim(infile_seqs, as.is = TRUE, header = FALSE,
                     col.names = c('ID', 'seq')) %>%
    filter(ID %in% sloci$ID)

  for(loc_idx in 1:nrow(sloci)) {
    strand <- sloci$strand[loc_idx]
    seq <- seqs$seq[which(seqs$ID == sloci$ID[loc_idx])]
    if(strand == '-') seq <- revComp(seq)
    scaf[sloci$start[loc_idx]:sloci$end[loc_idx]] <- unlist(strsplit(seq, split = ''))
  }

  ## Report number of called (not-N) bases:
  ncalled <- sum(grepl('[ACGT]', scaf))
  cat('#### stacksfa_fullgenome.R: Nr of called bases in', scaf_ID, ':', ncalled, '\n')

  ## Write scaffold fasta:
  fasta_header <- paste0('>', scaf_ID)
  fasta_seq <- paste0(scaf, collapse = '')
  writeLines(c(fasta_header, fasta_seq), outfile_scaffoldfasta)
}

cat('\n#### stacksfa_fullgenome.R: Done with script.\n')
cat('#####################################################################\n\n')