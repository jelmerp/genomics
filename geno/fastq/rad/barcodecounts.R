library(tidyverse)
setwd('/home/jelmer/Dropbox/sc_lemurs/radseq/')

################################################################
##### L1_redo #####
################################################################
bc.L1.list.file <- 'metadata/r02/barcodes_L1_redo.txt'
bc.L1.list <- read.delim(bc.L1.list.file, header = FALSE, as.is = TRUE) %>% pull(V1)
L1.totalReads <- 422246780 / 4

## R1 - barcodeCounts:
bc.L1.R1.file <- 'analyses/qc/fastq/fastq_process/barcodeCounts_L1_redo_S2.R1.txt'
bc.L1.R1 <- read.delim(bc.L1.R1.file, header = FALSE, as.is = TRUE) %>%
  mutate(V1 = gsub('^ +', '', V1)) %>%
  separate(V1, sep = " ", into = c('count', 'barcode')) %>%
  mutate(count = as.integer(count))

bc.L1.R1 %>% summarise(sum = sum(count)) # 42,438,056
bc.L1.R1 %>% filter(! barcode %in% bc.L1.list) %>% summarise(sum = sum(count)) # 250,834
bc.L1.R1 %>% filter(barcode %in% bc.L1.list) %>% summarise(sum = sum(count)) # 42,187,222
# perc wrong barcodes = 250834 / 42187222 = 0.595%
42187222 / (L1.totalReads) # 0.400 is prop of reads with correct cutsite-seq

## R1 - nCounts:
nCounts.L1.R1.file <- 'analyses/qc/fastq/fastq_process/nCounts_L1_redo_S2.R1.txt'
(nCounts.L1.R1 <- read.delim(nCounts.L1.R1.file, header = FALSE) %>%
  mutate(V1 = gsub('^ +', '', V1)) %>%
  separate(V1, sep = " ", into = c('position', 'nCount')) %>%
  mutate(nCount = as.integer(nCount),
         nPerThousand = round(nCount / (L1.R1.totalReads / 1000), 3)))

## R2 - barcodeCounts:
bc.L1.R2.file <- 'analyses/qc/fastq/fastq_process/barcodeCounts_L1_redo_S2.R2.txt'
bc.L1.R2 <- read.delim(bc.L1.R2.file, header = FALSE, as.is = TRUE) %>%
  mutate(V1 = gsub('^ +', '', V1)) %>%
  separate(V1, sep = " ", into = c('count', 'barcode')) %>%
  mutate(count = as.integer(count))

bc.L1.R2 %>% summarise(sum = sum(count)) # 34,795,874
bc.L1.R2 %>% filter(! barcode %in% bc.L1.list) %>% summarise(sum = sum(count)) # 1,545,175
bc.L1.R2 %>% filter(barcode %in% bc.L1.list) %>% summarise(sum = sum(count)) # 33,250,699
# perc wrong barcodes = 1545175 / 33250699 = 4.64%
33250699 / L1.totalReads # 0.315 is prop of reads with correct cutsite-seq

## R2 - nCounts:
nCounts.L1.R2.file <- 'analyses/qc/fastq/fastq_process/nCounts_L1_redo_S2.R2.txt'
(nCounts.L1.R2 <- read.delim(nCounts.L1.R2.file, header = FALSE) %>%
    mutate(V1 = gsub('^ +', '', V1)) %>%
    separate(V1, sep = " ", into = c('position', 'nCount')) %>%
    mutate(nCount = as.integer(nCount),
           nPerThousand = round(nCount / (L1.totalReads / 1000), 3)))

################################################################
##### newLib_failedInds #####
################################################################
bc.L4.list.file <- 'metadata/r02/barcodes_newLib_failedInds.txt'
bc.L4.list <- read.delim(bc.list.file, header = FALSE, as.is = TRUE) %>% pull(V1)
L4.totalReads <- 1071753420 / 4

## R1 - barcodeCounts:
bc.L4.file <- 'analyses/qc/fastq/fastq_process/barcodeCounts_newLib_failedInds.R1.txt'
bc.L4 <- read.delim(bc.L4.file, header = FALSE, as.is = TRUE) %>%
  mutate(V1 = gsub('^ +', '', V1)) %>%
  separate(V1, sep = " ", into = c('count', 'barcode')) %>%
  mutate(count = as.integer(count))

bc.L4 %>% summarise(sum = sum(count)) # 81,334,444
bc.L4 %>% filter(! barcode %in% bc.L4.list) %>% summarise(sum = sum(count)) # 438,651
bc.L4 %>% filter(barcode %in% bc.L4.list) %>% summarise(sum = sum(count)) # 80,895,793
# perc wrong barcodes = 438651 / 80895793 = 0.542%
80895793 / L4.totalReads  # 0.302 is prop of reads with correct cutsite-seq

## R1 - nCounts:
nCounts.L4.R1.file <- 'analyses/qc/fastq/fastq_process/nCounts_newLib_failedInds.R1.txt'
(nCounts.L4.R1 <- read.delim(nCounts.L4.R1.file, header = FALSE) %>%
    mutate(V1 = gsub('^ +', '', V1)) %>%
    separate(V1, sep = " ", into = c('position', 'nCount')) %>%
    mutate(nCount = as.integer(nCount),
           nPerThousand = round(nCount / (L4.totalReads / 1000), 3)))

## R2 - barcodeCounts:
bc.L4.R2.file <- 'analyses/qc/fastq/fastq_process/barcodeCounts_newLib_failedInds.R2.txt'
bc.L4.R2 <- read.delim(bc.L4.R2.file, header = FALSE, as.is = TRUE) %>%
  mutate(V1 = gsub('^ +', '', V1)) %>%
  separate(V1, sep = " ", into = c('count', 'barcode')) %>%
  mutate(count = as.integer(count))

bc.L4.R2 %>% summarise(sum = sum(count)) # 67,853,063
bc.L4.R2 %>% filter(! barcode %in% bc.L4.list) %>% summarise(sum = sum(count)) # 2,310,938
bc.L4.R2 %>% filter(barcode %in% bc.L4.list) %>% summarise(sum = sum(count)) # 65,542,125
# perc wrong barcodes = 2310938 / 65542125 = 3.5%
65542125 / L4.totalReads # 0.245 is prop of reads with correct cutsite-seq

## R2 - nCounts:
nCounts.L4.R2.file <- 'analyses/qc/fastq/fastq_process/nCounts_newLib_failedInds.R2.txt'
(nCounts.L4.R2 <- read.delim(nCounts.L4.R2.file, header = FALSE) %>%
    mutate(V1 = gsub('^ +', '', V1)) %>%
    separate(V1, sep = " ", into = c('position', 'nCount')) %>%
    mutate(nCount = as.integer(nCount),
           nPerThousand = round(nCount / (L4.totalReads / 1000), 3)))
