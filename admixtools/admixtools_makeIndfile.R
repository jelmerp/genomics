#!/usr/bin/env Rscript

#### SET-UP --------------------------------------------------------------------
cat("\n#####################################################################\n")
cat("#### admixtools_makeIndfile.R: Starting with script.\n")

library(tidyverse)
options(warn = 1)
args <- commandArgs(trailingOnly = TRUE)

inds.focal.file <- args[1]
inds.metadata.file <- args[2]
indfile.out <- args[3]
IDcolumn <- args[4]
groupby <- args[5]

# inds.focal.file <- 'indlist.borsim.all.mac1.FS6.tmp'
# inds.metadata.file <- '/datacommons/yoderlab/users/jelmer/proj/sisp/metadata/lookup_ext.txt'
# IDcolumn <- 'ID'
# groupby <- 'pop'

cat('#### admixtools_makeIndfile.R: inds.focal.file:', inds.focal.file, '\n')
cat('#### admixtools_makeIndfile.R: inds.metadata.file:', inds.metadata.file, '\n')
cat('#### admixtools_makeIndfile.R: indfile.out:', indfile.out, '\n')
cat('#### admixtools_makeIndfile.R: ID column:', IDcolumn, '\n')
cat('#### admixtools_makeIndfile.R: groupby column:', groupby, '\n')


#### CREATE INPUT FILE ---------------------------------------------------------
## Read files:
inds.focal <- readLines(inds.focal.file)

inds.df <- read.delim(inds.metadata.file, as.is = TRUE)
inds.df <- inds.df[inds.df[, IDcolumn] %in% inds.focal, ]
inds.df <- inds.df[, c(IDcolumn, groupby)]
print(inds.df)
stopifnot(all(inds.focal %in% inds.df[, IDcolumn]))

## Create input file:
getLine <- function(ind.ID) {
  group <- inds.df[, groupby][inds.df[, IDcolumn] == ind.ID]
  line <- data.frame(ind.ID, U = 'U', group)
  return(line)
}

indfile.df <- do.call(rbind, lapply(inds.focal, getLine))
indfile.df <- indfile.df %>% arrange(group)


#### REPORT AND WRITE FILE -----------------------------------------------------
cat('#### admixtools_makeIndfile.R: Resulting indfile.df:\n')
print(indfile.df)

write.table(indfile.df, indfile.out,
            sep = '\t', quote = FALSE, row.names = FALSE, col.names = FALSE)

cat('\n\n#### admixtools_makeIndfile.R: Done with script.\n')
