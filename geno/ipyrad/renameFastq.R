#!/usr/bin/env Rscript

options(warn = 1)

args <- commandArgs(trailingOnly = TRUE)

indir.base <- args[1] # indir.base <- "/work/gpt4/radseq/demultiplexed_data_2/"
outdir.base <- args[2] # outdir.base <- "/work/jwp37/radseq/seqdata/fastq/demultiplexed/"
library <- args[3]

cp.nameChange <- function(library, indir.base, outdir.base) {
  cat('Library:', library, '\n', 'Indir:', indir.base, '\n', 'Outdir:', outdir.base, '\n')

  indir <- paste0(indir.base, '/', library)
  outdir <- paste0(outdir.base, '/', library)

  if(!dir.exists(outdir)) dir.create(outdir, recursive = TRUE)

  oldnames <- list.files(indir, pattern = "fq.gz")
  newnames <- gsub('\\.1\\.fq.gz', "_R1.fastq.gz", oldnames)
  newnames <- gsub('\\.2\\.fq.gz', "_R2.fastq.gz", newnames)

  oldnames.full <- paste0(indir, '/', oldnames)
  newnames.full <- paste0(outdir, '/', newnames)

  cat('Changing names, e.g.:\n', oldnames.full[1], '\nto\n', newnames.full[2], '\n\n')

  file.copy(oldnames.full, newnames.full, overwrite = TRUE)
}

cp.nameChange(library, indir.base, outdir.base)
#sapply(paste0('L', 2:6), cp.nameChange, indir.base, outdir.base)
