#!/usr/bin/env Rscript

################################################################################
#### SET-UP #####
################################################################################
cat('#### vcf2fullfa2a_makelocusbed.R: Starting script.\n\n')

## Command-line args:
options(warn = 1)
args <- commandArgs(trailingOnly = TRUE)

setID <- args[1]
infile_inds <- args[2]
indir_bed <- args[3]
outfile_bed <- args[4]

max.dist.withinInd <- as.integer(args[5])
max.dist.betweenInd <- as.integer(args[6])
min.element.ovl <- as.numeric(args[7])
min.element.ovl_trim <- as.numeric(args[8])
min.element.size <- as.integer(args[9])
min.locus.size <- as.integer(args[10])
last.row <- args[11]

## Other scripts and libraries:
library(data.table)
library(tidyverse)
library(valr)
library(IRanges)

## Process command-line args:
IDs <- readLines(infile_inds)
bedfiles <- paste0(indir_bed, '/', IDs, '.callable.bed')

min.element.ovl <- length(bedfiles) * min.element.ovl
min.element.ovl_trim <- length(bedfiles) * min.element.ovl_trim

## Report:
cat('\n#### vcf2fullfa2a_makelocusbed.R: Set ID:', setID, '\n')
cat('#### vcf2fullfa2a_makelocusbed.R: Bedfile dir:', indir_bed, '\n')
cat('#### vcf2fullfa2a_makelocusbed.R: Bedfiles:', bedfiles, '\n')
cat('#### vcf2fullfa2a_makelocusbed.R: Number of bedfiles:', length(bedfiles), '\n')
cat('#### vcf2fullfa2a_makelocusbed.R: Bed output file:', outfile_bed, '\n\n')

cat('#### vcf2fullfa2a_makelocusbed.R: Max distance within inds:', max.dist.withinInd, '\n')
cat('#### vcf2fullfa2a_makelocusbed.R: Max distance between inds:', max.dist.betweenInd, '\n')
cat('#### vcf2fullfa2a_makelocusbed.R: Min element overlap - for locus creation:', min.element.ovl, '\n')
cat('#### vcf2fullfa2a_makelocusbed.R: Min element overlap - for locus trimming:', min.element.ovl_trim, '\n')
cat('#### vcf2fullfa2a_makelocusbed.R: Min element size:', min.element.size, '\n')
cat('#### vcf2fullfa2a_makelocusbed.R: Last row:', last.row, '\n\n')


################################################################################
#### FUNCTIONS #####
################################################################################
getIndLoci <- function(bedfile, max_dist, last.row = 0) {
  cat("#### vcf2fullfa2a_makelocusbed.R: getIndLoci function: bedfile:", bedfile, "\n")

  bed <- fread(bedfile, header = FALSE,
               colClasses = c('character', 'integer', 'integer', 'character'),
               col.names = c('chrom', 'start', 'end', 'status'))
  bed$status <- NULL

  if(last.row == 0) {
    cat("#### vcf2fullfa2a_makelocusbed.R: getIndLoci function: Using all rows...\n")
  } else {
    cat("#### vcf2fullfa2a_makelocusbed.R: getIndLoci function: Selecting rows until last row:",
        last.row, "\n")
    bed <- bed[1:last.row, ]
  }

  bed <- as.tbl_interval(bed)
  bed <- bed_merge(bed, max_dist = max_dist)
  bed <- arrange(bed, start)
  return(bed)
}

collectIndLoci <- function(bedfiles, last.row,
                           max.dist.withinInd, min.element.size) {

  bedlist <- lapply(bedfiles, getIndLoci,
                    max_dist = max.dist.withinInd, last.row = last.row)
  bed.byInd <- do.call(rbind, bedlist)

  # Somehow this step is necessary or bed_merge wont work:
  bed.byInd <- data.frame(chrom = bed.byInd$chrom, start = bed.byInd$start, end = bed.byInd$end) %>%
    as.tbl_interval() %>%
    arrange(start) %>%
    filter(end - start >= min.element.size)

  return(bed.byInd)
}

trimLocus <- function(row.nr, locus.df, element.df, min.element.ovl_trim) {
  locus <- locus.df[row.nr, ]
  locus.ID <- paste0(locus$chrom, '_', locus$start)

  locus.elements <- bed_intersect(bed.byInd, locus)
  bed.cov.ir <- IRanges(start = locus.elements$start.x, end = locus.elements$end.x)
  cov <- IRanges::coverage(bed.cov.ir)

  ok <- which(cov@values > min.element.ovl_trim)

  if(length(ok >= 1)) {
    first.ok <- ok[1]
    if(first.ok > 1) first.base <- sum(cov@lengths[1:first.ok]) else
      first.base <- locus$start #cov@lengths[1] + 1

    last.ok <- ok[length(ok)]
    if(last.ok < length(cov@values)) last.base <- sum(cov@lengths[1:last.ok]) else
      last.base <- locus$end #sum(cov@lengths[1:length(cov@lengths)]

    locus.length <- locus$end - locus$start
    trimmed.start <- first.base - locus$start
    trimmed.end <- locus$end - last.base
    locus.length.final <- last.base - first.base

    cat(row.nr, locus.ID, '/ length:', locus.length,
        '/ trimmed start:', trimmed.start, '/ trimmed end:', trimmed.end,
        '/ remaining bases:', locus.length.final, '\n')

    locus.trimmed <- data.frame(chrom = locus$chrom, start = first.base, end = last.base)
    locus.trimmed.length <- locus.trimmed$end - locus.trimmed$start

    if(locus.trimmed.length < min.locus.size) {
      cat(row.nr, 'Locus too small...\n')
      } else {
        return(locus.trimmed)
      }

  } else
    cat(row.nr, 'Coverage too low: skipping locus...\n')
}


################################################################################
#### RUN #####
################################################################################
## Get per-individual bed file and merge loci:
bed.byInd <- collectIndLoci(bedfiles,
                            last.row = last.row,
                            max.dist.withinInd = max.dist.withinInd,
                            min.element.size = min.element.size)

## Merge per-individual loci:
bed.merged <- bed_merge(bed.byInd, max_dist = max.dist.betweenInd)
cat('\n#### vcf2fullfa2a_makelocusbed.R: Nr of initial loci:', nrow(bed.merged), '\n')

## Calculate "coverage" (number of elements) overlapping with each locus:
## Retain only those with "min.elements" number of overlapping elements,
## and "min.frac" fraction of overlap (latter is not very important)
bed.cov <- bed_coverage(bed.merged, bed.byInd) %>%
  filter(.ints >= min.element.ovl)
cat('#### vcf2fullfa2a_makelocusbed.R: Number of loci after filtering by coverage:',
    nrow(bed.cov), '\n\n')

## Trim loci:
cat('#### vcf2fullfa2a_makelocusbed.R: Trimming loci...\n')
bed.trim.list <- lapply(1:nrow(bed.cov), trimLocus,
                        locus.df = bed.cov,
                        element.df = bed.byInd,
                        min.element.ovl_trim = min.element.ovl_trim)
bed.trim <- do.call(rbind, bed.trim.list)
cat('#### vcf2fullfa2a_makelocusbed.R: Trimming done.\n\n')
cat('#### vcf2fullfa2a_makelocusbed.R: Number of loci retained:', nrow(bed.trim), '\n\n')

## Save bedfile:
cat('#### vcf2fullfa2a_makelocusbed.R: Writing bedfile', outfile_bed, '\n')
write.table(bed.trim, outfile_bed,
            sep = '\t', quote = FALSE, row.names = FALSE, col.names = FALSE)

## Report:
cat('\n#### vcf2fullfa2a_makelocusbed.R: Done with script.\n')
