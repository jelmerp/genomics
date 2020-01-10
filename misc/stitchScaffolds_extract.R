#!/usr/bin/env Rscript

## Set up:
if(grepl('Ubuntu', sessionInfo()$running)) {
  comp <- 'own'
  setwd('/home/jelmer/Dropbox/sc_lemurs/')
} else {
  comp <- 'cluster'
  setwd('/datacommons/yoderlab/users/jelmer/')
}

library(tidyverse)
library(data.table)

if(comp == 'cluster') {
  options(warn = 1)
  args <- commandArgs(trailingOnly = TRUE)

  scaf.sizes.infile <- args[1]
  scaf.index.infile <- args[2]
  scaf.exclude.infile <- args[3]
  scaf.index.outfile <- args[4]
  scaf.exclude.outfile <- args[5]
  scaffoldList.file <- args[6]
  nrNs <- args[7]

  # scaf.sizes.infile <- '/work/rcw27/dovetail/scaffolds_withLength.txt'
  # scaf.index.infile <- '/work/rcw27/dovetail/cmedius_dt_april17_stitched.scaffoldIndex.txt'
  # scaf.exclude.infile <- 'notany'
  # scaf.index.outfile <- '/work/rcw27/dovetail/cmedius_dt_april17_stitched.scaffoldIndexLookup.txt'
  # scaf.exclude.outfile <- 'notany'
  # scaffoldList.file <- '/work/rcw27/dovetail/cmedius_dt_april17_stitched.scaffoldList.txt'
  # nrNs <- 1000
}

if(comp == 'own') {
  scaf.sizes.infile <- '/datacommons/yoderlab/users/jelmer/seqdata/reference/mmur/scaffolds_withLength.txt'
  scaf.index.infile <- '/datacommons/yoderlab/users/jelmer/seqdata/reference/mmur//GCF_000165445.2_Mmur_3.0_genomic_stitched.scaffoldIndex.txt'
  scaf.exclude.infile <- '/datacommons/yoderlab/users/jelmer/seqdata/reference/mmur//scaffolds.nonAutosomal.txt'
  scaf.index.outfile <- '/datacommons/yoderlab/users/jelmer/seqdata/reference/mmur//GCF_000165445.2_Mmur_3.0_genomic_stitched.scaffoldIndexLookup.txt'
  scaf.exclude.outfile <- '/datacommons/yoderlab/users/jelmer/seqdata/reference/mmur//GCF_000165445.2_Mmur_3.0_genomic_stitched.nonAutosomalCoords.bed'
  scaffoldList.file <- '/datacommons/yoderlab/users/jelmer/seqdata/reference/mmur//GCF_000165445.2_Mmur_3.0_genomic_stitched.scaffoldList.txt'
  nrNs <- 1000
  library(tidyverse); library(data.table)
}

cat('\nInfile with original scaffold sizes:', scaf.sizes.infile, '\n' )
cat('Infile with index of superscaffolds-to-scaffolds:', scaf.index.infile, '\n' )
cat('Infile with scaffolds to exclude:', scaf.exclude.infile, '\n' )
cat('Outfile with lookup for superscaffolds-to-scaffolds:', scaf.index.outfile, '\n' )
cat('Outfile (bed) with regions to exclude from bam:', scaf.exclude.outfile, '\n' )
cat('Outfile with list of scaffolds:', scaffoldList.file, '\n' )

cat('Number of Ns between scaffolds:', nrNs, '\n\n' )

## Original scaffold sizes:
scaf.sizes <- read.table(scaf.sizes.infile, header = FALSE)
colnames(scaf.sizes) <- c('scaffold', 'scaffold.length')

## Read index file:
scaf.index <- fread(scaf.index.infile,
                    col.names = c('superscaffold', 'index', 'scaffold'),
                    colClasses = c('character', 'integer', 'character'))
cat('Nr of rows in scaf.index:', nrow(scaf.index), '\n')
scaf.index$scaffold <- gsub('>', '', scaf.index$scaffold)
scaf.index$superscaffold <- gsub('>', '', scaf.index$superscaffold)

scaf.index <- merge(scaf.index, scaf.sizes, by = 'scaffold')
#scaf.index$scaffold.length <- as.integer(gsub('.*size(.*)', '\\1', scaf.index$scaffold))

cat('\nShowing head of scaf.index df...\n')
print(head(scaf.index))
cat('\nShowing class of scaf.index columns...\n\n')
sapply(scaf.index, class)

## Get locations:
scaf.index <- scaf.index %>%
  group_by(superscaffold) %>%
  mutate(start = cumsum(scaffold.length) - scaffold.length + (index * nrNs))

scaf.index$start[which(scaf.index$index == 0)] <- 0

scaf.index <- scaf.index %>%
  mutate(end = start + scaffold.length)

cat('\nShowing head of scaf.index df...\n')
print(head(scaf.index))

## Create bed to exclude:
if(file.exists(scaf.exclude.infile)) {

  scaf.exclude <- readLines(scaf.exclude.infile)
  cat('Nr of scaffolds to exclude:', length(scaf.exclude), '\n')

  scaf.exclude.out <- scaf.index[which(scaf.index$scaffold %in% scaf.exclude), ] %>%
    select(superscaffold, start, end)

  if(nrow(scaf.exclude.out) == 0) {
    cat("WARNING: NO SCAFFOLDS TO EXCLUDE IN INDEX TABLE...")
    cat("scaf.exclude are:", scaf.exclude, '\n')
    cat("Now creating bedfile from original scaffolds to exclude:")
    scaf.exclude.out <- scaf.sizes[scaf.sizes$scaffold.name %in% scaf.exclude, ]
    scaf.exclude.out %>%
      mutate(start = 0) %>%
      select(scaffold.name, start, scaffold.length)
  }

  write.table(scaf.exclude.out, scaf.exclude.outfile,
              col.names = FALSE, row.names = FALSE, sep = '\t', quote = FALSE)
} else {
  cat("\n\nNo scaf.exclude.infile file", scaf.exclude.infile, "... skipping to-exclude.bed\n\n")
}

## List of superscaffolds:
scaffolds <- unique(scaf.index$superscaffold)
scaffolds <- gsub('>', '', scaffolds)

## Write files:
write.table(scaf.index, scaf.index.outfile,
            col.names = TRUE, row.names = FALSE, sep = '\t', quote = FALSE)

writeLines(scaffolds, scaffoldList.file)

cat('Done with script.\n')
Sys.time()
