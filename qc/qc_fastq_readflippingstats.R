setwd('Dropbox/sc_lemurs/radseq/')
library(tidyverse)

## Check if adapters are the same:
#r01 <- readLines('labwork/r01/r01_adapters.txt')
#r02 <- readLines('labwork/r02/r02_adapters.txt')
#r03 <- readLines('labwork/r03/r03_adapters.txt')
#r01 %in% r02
#r01 %in% r03

## Compare nr of reads before and after flipping:
flipfile <- 'analyses/qc/fastq/fastq_process/flippingStats_linenumbers_r01.r02.txt'
flip <- read.delim(flipfile, header = FALSE, as.is = TRUE,
                   col.names = c('nlines', 'filename'))
flip$flipped <- ifelse(grepl('flipped', flip$filename), 'yes', 'no')
flip$filename <- gsub('R1_.*', 'R1', flip$filename)
flip <- flip[!grepl('_R2', flip$filename), ]
flip$filename <- gsub('R2_.*', 'R2', flip$filename)
flip <- spread(flip, key = flipped, value = nlines)
flip$prop <- round(flip$yes / flip$no, 3)
flip %>% arrange(prop)

## Per lane output in billions of reads:
flip$lane <- gsub('.*(L00[0-9])_R1', '\\1', flip$filename)
flip %>%
  group_by(lane) %>%
  summarise(mean.unflipped = round(sum(no) / 1000000000, 3),
            mean.flipped = round(sum(yes) / 1000000000, 3))
