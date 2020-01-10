#!/usr/bin/env Rscript

################################################################################
#### SET-UP #####
################################################################################
cat('\n#### stacksfa_filter.R: Starting script.\n\n')
suppressMessages(library(tidyverse))
options(scipen=999)

## Command-line args:
options(warn = 1)
args <- commandArgs(trailingOnly = TRUE)

setID <- args[1]
indfile <- args[2]
dir_lstats <- args[3]
maxmiss_ind <- as.integer(args[4]) / 100
maxmiss_mean <- as.integer(args[5]) / 100
mindist <- as.integer(args[6])
minlength <- as.integer(args[7])
length_quantile <- as.integer(args[8]) / 100
maxindmiss <- as.integer(args[9]) / 100

################################################################################
# setID <- 'berrufmyo.gphocs1'
# indfile <- '/datacommons/yoderlab/users/jelmer/proj/sisp/seqdata/stacks//berrufmyo//gphocs1//final/indlist.txt'
# dir_lstats <- '/datacommons/yoderlab/users/jelmer/proj/sisp/seqdata/stacks/berrufmyo/gphocs1/final/loci/'
# maxmiss_ind <- 0.1
# maxmiss_mean <- 0.1
# mindist <- 10000
# minlength <- 100
# length_quantile <- 0.1
# maxindmiss <- 0.1
################################################################################

## Process args:
outfile_lstats <- paste0(dir_lstats, '/', setID, '.locusstats_filtered.txt')

inds <- as.character(readLines(indfile))
inds <- inds[inds != ""]

## Report:
cat('\n#### stacksfa_filter.R: Set ID:', setID, '\n')
cat('#### stacksfa_filter.R: Indfile:', indfile, '\n')
cat('#### stacksfa_filter.R: Input dir with locusstats:', dir_lstats, '\n')
cat('#### stacksfa_filter.R: Max miss - ind:', maxmiss_ind, '\n')
cat('#### stacksfa_filter.R: Max miss - mean:', maxmiss_mean, '\n')
cat('#### stacksfa_filter.R: Min distance between loci:', mindist, '\n')
cat('#### stacksfa_filter.R: Min length of loci:', minlength, '\n')
cat('#### stacksfa_filter.R: Length quantile:', length_quantile, '\n')
cat('#### stacksfa_filter.R: Max % missing inds per locus:', maxindmiss, '\n')
cat('#### stacksfa_filter.R: Outfile - locusstats:', outfile_lstats, '\n')
cat('#### stacksfa_filter.R: Individuals:', inds, '\n\n')


################################################################################
#### FUNCTIONS ####
################################################################################
## Get locus-stats for one ind:
getlocstats <- function(ind) {

  cat('\n#### stacksfa_filter.R: getlocstats function for ind:', ind, '\n')
  infile_lstats1 <- paste0(dir_lstats, '/', ind, '.locusstats1.txt')
  infile_lstats2 <- paste0(dir_lstats, '/', ind, '.locusstats2.txt')

  lstats1 <- read.delim(infile_lstats1, as.is = TRUE, header = FALSE,
                        col.names = c('scaffold', 'start.org', 'end.org', 'strand', 'locusID'))

  lstats2 <- read.delim(infile_lstats2, as.is = TRUE, header = FALSE,
                        col.names = c('locusID', 'length', 'nmiss')) %>%
    mutate(locusID = gsub('>(L[0-9]+)_.*', '\\1', locusID))

  lstats <- merge(lstats1, lstats2, by = 'locusID')
  cat('#### stacksfa_filter.R: Number of loci before filters:', nrow(lstats), '\n')

  lstats <- lstats %>%
    mutate(ind = ind,
           pmiss = round(nmiss / length, 3)) %>% ## Filter for pmiss
    distinct(locusID, .keep_all = TRUE) %>% # Some loci are duplicated ##!!! CHECK
    select(scaffold, start.org, end.org, length, strand, nmiss, pmiss, locusID, ind) %>%
    filter(length >= minlength)
  cat('#### stacksfa_filter.R: Number of loci after length filter:', nrow(lstats), '\n')

  lstats <- lstats %>%
    filter(pmiss < maxmiss_ind)
  cat('#### stacksfa_filter.R: Number of loci after pmiss filter:', nrow(lstats), '\n')

  return(lstats)
}

## Filter by proximity:
filter_proxim <- function(my.lstats, my.mindist) {

  my.lstats <- my.lstats %>%
    arrange(scaffold, start) %>%
    group_by(scaffold) %>%
    mutate(distToNext = lead(start) - (start + length)) %>% # Include distance-to-next locus
    ungroup()

  close.loc1.idx <- which(my.lstats$distToNext < my.mindist)
  # cat("#### Nr loci too close:", length(close.loc1.idx), "\n")
  close.loc2.idx <- close.loc1.idx + 1

  close <- cbind(my.lstats[close.loc1.idx, c("locusID", "pmiss_mean")],
                 my.lstats[close.loc2.idx, c("locusID", "pmiss_mean")])
  colnames(close) <- c('loc1', 'pmiss1', 'loc2', 'pmiss2')
  close$pmiss1[is.na(close$pmiss1)] <- 0
  close$pmiss2[is.na(close$pmiss2)] <- 0

  close.rm <- unique(c(close$loc1[which(close$pmiss1 > close$pmiss2)],
                       close$loc2[which(close$pmiss1 <= close$pmiss2)]))

  my.lstats_filt <- my.lstats %>% filter(! locusID %in% close.rm)

  #cat("\n#### Nr loci input:", nrow(my.lstats), '\n')
  #cat("#### Nr loci output:", nrow(my.lstats_filt), '\n')
  cat("#### Nr loci removed:", length(close.rm), '\n')

  return(my.lstats_filt)
}


################################################################################
#### PROCESS LOCUS-STATS AND FILTER ####
################################################################################
cat('\n#### stacksfa_filter.R: Combining per-ind locusstats into single df...\n')
lstats_long_raw <- do.call(rbind, lapply(inds, getlocstats))

## Pivot to wide for stats:
lstats_wide <- lstats_long_raw %>%
  pivot_wider(names_from = ind, values_from = c(length, pmiss, nmiss))
cat('\n\n#### stacksfa_filter.R: Nr loci - merged across inds - before filtering:',
    nrow(lstats_wide), '\n')
cat('#### stacksfa_filter.R: Nr of loci - per strand:\n')
print(table(lstats_wide$strand))

## Compute min/median locus length and recompute pmiss ind:
means.df <- lstats_long_raw %>%
  group_by(locusID) %>%
  summarize(length_adj = round(quantile(length, probs = length_quantile)))

lstats_long <- merge(lstats_long_raw, means.df, by = 'locusID') %>%
  mutate(nmiss_adj = ifelse(length < length_adj, nmiss + (length_adj - length), nmiss)) %>%
  mutate(pmiss_adj = ifelse(length < length_adj, round(nmiss_adj / length_adj, 3), pmiss))

## Filter for maxmiss_ind:
lstats_long <- lstats_long %>%
  filter(pmiss_adj < maxmiss_ind)

## Compute maxmiss_mean:
means.df <- lstats_long %>%
  group_by(locusID) %>%
  summarize(pmiss_mean = round(mean(pmiss_adj), 3),
            length_adj = round(quantile(length, probs = length_quantile))) %>%
  filter(pmiss_mean < maxmiss_mean)
cat('#### stacksfa_filter.R: Nr loci after filtering for maxmiss_ind and maxmiss_mean:', nrow(means.df), '\n')

## Pivot back to wide:
lstats_wide2 <- lstats_long %>%
  select(-nmiss, -pmiss) %>%
  rename(length_org = length,
         length = length_adj,
         nmiss = nmiss_adj,
         pmiss = pmiss_adj) %>%
  pivot_wider(names_from = ind, values_from = c(length_org, pmiss, nmiss))

## Integrate pmiss_mean and adjusted locus length into main df:
lstats <- merge(lstats_wide2, means.df, by = 'locusID') %>%
  mutate(end = ifelse(strand == '+', start.org + (length - 1), end.org), # For plus strand, update "end" position
         start = ifelse(strand == '-', end.org - (length - 1), start.org)) %>% # For minus strand, update "start" position
  select(locusID, scaffold, start, end, start.org, end.org, strand, length,
         contains('pmiss'), contains('length_org')) %>%
  arrange(scaffold, start)

## Filter loci that are absent in too many inds:
lstats_pmiss <- lstats %>% select(contains('pmiss_'))

lstats <- lstats %>%
  mutate(propindmiss = round(rowSums(is.na(lstats_pmiss)) / length(inds), 3)) %>%
  filter(propindmiss <= maxindmiss)
cat('#### stacksfa_filter.R: Nr loci after filtering for maxindmiss:', nrow(lstats), '\n')


################################################################################
##### FILTER BY PROXIMITY ####
################################################################################
if(mindist > 0) {
  cat('\n#### stacksfa_filter.R: Filtering by proximity in several rounds...\n')
  lstats <- filter_proxim(lstats, my.mindist = mindist)
  lstats <- filter_proxim(lstats, my.mindist = mindist)
  lstats <- filter_proxim(lstats, my.mindist = mindist)
  lstats <- filter_proxim(lstats, my.mindist = mindist)
} else {
  cat('\n#### stacksfa_filter.R: SKIPPING proximity filtering\n')
}


################################################################################
##### PREPARE BEDFILE ####
################################################################################
cat('\n#### stacksfa_filter.R: Writing bedfiles for each indiv and final loci in:',
    dir_lstats, '\n')

for(ind in inds) for(allele in c('A0', 'A1')) {
  lstats_bed <- lstats %>%
    mutate(name = paste0(locusID, '_', ind, '_', allele, '_', scaffold,
                         '_', start, '_', end, '_strand', strand)) %>%
    select(scaffold, start, end, name, contains(ind)) %>%
    drop_na() %>%
    select(scaffold, start, end, name)

  cat('#### stacksfa_filter.R: Number of loci for', ind, ':', nrow(lstats_bed), '\n')

  ## Write bed-style df:
  outfile_lstats_bed <- paste0(dir_lstats, '/', ind, '.', allele, '.', setID, '.filteredloci.bed')
  cat('#### stacksfa_filter.R: Writing:', outfile_lstats_bed, '\n')
  write.table(lstats_bed, outfile_lstats_bed,
              sep = '\t', quote = FALSE, row.names = FALSE, col.names = FALSE)
}


################################################################################
#### HOUSEKEEPING ####
################################################################################
## Report:
cat('\n#### stacksfa_filter.R: Final nr of loci:', nrow(lstats), '\n')
cat('#### stacksfa_filter.R: Mean locus length:', round(mean(lstats$length, na.rm = TRUE)), '\n')
if(mindist > 0) cat('#### stacksfa_filter.R: Mean dist to next:',
                    round(mean(lstats$distToNext, na.rm = TRUE)), '\n')

miss_mean <- lstats %>% select(contains('pmiss')) %>% summarise_if(is.numeric, mean, na.rm = TRUE)
cat('\n#### stacksfa_filter.R: Mean missing data per ind:\n')
print(as.data.frame(miss_mean))

cat('\n#### stacksfa_filter.R: Nr of loci per strand:\n')
print(table(lstats$strand))

cat('\n#### stacksfa_filter.R: Nr of loci per scaffold:\n')
print(table(lstats$scaffold))

## Write main df:
cat('\n#### stacksfa_filter.R: Writing outfile_lstats:', outfile_lstats, '\n')
write.table(lstats, outfile_lstats,
            sep = '\t', quote = FALSE, row.names = FALSE)

cat('\n#### stacksfa_filter.R: Done with script.\n')
