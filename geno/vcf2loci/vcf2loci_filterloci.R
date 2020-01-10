#!/usr/bin/env Rscript

################################################################################
#### SET-UP ####
################################################################################
cat('\n\n#### vcf2fullfa_filterloci.R: Starting script.\n\n')

## Libraries:
library(valr)
library(tidyverse)

## Command-line args:
options(warn = 1)
args <- commandArgs(trailingOnly = TRUE)
infile_locusstats <- args[1]
infile_LD <- args[2]
maxmiss <- as.integer(args[3])
mindist <- as.integer(args[4])
maxLD <- as.numeric(args[5])
indir_fasta <- args[6]
outdir_fasta <- args[7]

cat('\n#### vcf2fullfa_filterloci.R: Input file with locus stats:', infile_locusstats, '\n')
cat('#### vcf2fullfa_filterloci.R: Input file with LD stats:', infile_LD, '\n')
cat('#### vcf2fullfa_filterloci.R: Maximum prop of missing data (maxmiss):', maxmiss, '\n')
cat('#### vcf2fullfa_filterloci.R: Minimum distance (bp) between loci (mindist):', mindist, '\n')
cat('#### vcf2fullfa_filterloci.R: Maximum LD (r2) between loci (maxLD):', maxLD, '\n')
cat('#### vcf2fullfa_filterloci.R: Fasta input dir:', indir_fasta, '\n')
cat('#### vcf2fullfa_filterloci.R: Fasta output dir:', outdir_fasta, '\n')

## Other vars:
if(!dir.exists(outdir_fasta)) dir.create(outdir_fasta, recursive = TRUE)

nrfiles <- length(list.files(indir_fasta))
cat("\n#### vcf2fullfa_filterloci.R: Number of files in indir_fasta:", nrfiles, '\n')


################################################################################
#### PROCESS INPUT FILES ####
################################################################################
## Locus stats:
lstats <- read.delim(infile_locusstats, as.is = TRUE) %>%
  select(1:12)
colnames(lstats) <-  c('locus.full', 'nInd', 'bp', 'nCells', 'nN', 'pN',
                      'nvar', 'pvar', 'nPars', 'pPars', 'AT', 'GC')
lstats <- lstats %>%
  mutate(locus = gsub('.fa', '', locus.full)) %>%
  separate(locus, into = c('scaffold', 'pos'), sep = ':') %>%
  separate(pos, into = c('start', 'end'), sep = '-') %>%
  mutate(start = as.integer(start), end = as.integer(end)) %>%
  select(locus.full, scaffold, start, end, nInd, bp, nN, pN, nvar, pvar, nPars,
         pPars, AT, GC) %>%
  #filter(scaffold != 'Super_Scaffold0') %>%
  arrange(scaffold, start) %>%
  group_by(scaffold) %>%
  mutate(distToNext = lead(start) - (start + bp), # Include distance-to-next locus
         calledSites = round((bp * nInd) * (100 - pN)))

lstats.bed <- lstats %>%
  dplyr::select(scaffold, start, end, locus.full) %>%
  dplyr::rename(chrom = scaffold)

## LD stats:
LD <- read.delim(gzfile(infile_LD), as.is = TRUE, row.names = NULL) %>%
  dplyr::rename(scaffold = X.chr, site1 = Site1, site2 = Site2, r2 = r.2, dist = Dist) %>%
  dplyr::mutate(pair = as.character(paste0(scaffold, ':', site1, '-', site2))) %>%
  dplyr::arrange(dist, site1)

cat('\n#### vcf2fullfa_filterloci.R: Quantiles of locus length:\n')
quantile(lstats$bp)


################################################################################
#### FILTER - MISSING DATA #####
################################################################################
## Nr of loci with certain amount of missing data:
nrow.filter <- function(threshold) {
  lstats %>% filter(pN < threshold) %>% nrow()
}
cat('\n#### vcf2fullfa_filterloci.R: Nr of loci:', nrow(lstats), '\n')
cat('#### vcf2fullfa_filterloci.R: Nr of loci with <10% N:', nrow.filter(10), '\n')
cat('#### vcf2fullfa_filterloci.R: Nr of loci with <5% N:', nrow.filter(5), '\n')
cat('#### vcf2fullfa_filterloci.R: Nr of loci with <1% N:', nrow.filter(1), '\n')
cat('#### vcf2fullfa_filterloci.R: Nr of loci with no Ns:', nrow.filter(0.001), '\n')

cat('\n#### vcf2fullfa_filterloci.R: Quantiles of missing data:\n')
quantile(lstats$pN)

missHi.rm <- lstats$locus.full[lstats$pN > maxmiss]


################################################################################
#### FILTER - HIGH LD #####
################################################################################
LDhi <- LD %>%
  filter(dist > mindist & r2 > maxLD)

site1 <- LDhi %>%
  mutate(start = as.integer(site1 - 1), end = site1) %>%
  rename(chrom = scaffold) %>%
  select(chrom, start, end, pair)
site1.ovl <- bed_intersect(site1, lstats.bed)

site2 <- LDhi %>%
  mutate(start = as.integer(site2 - 1), end = site2) %>%
  rename(chrom = scaffold) %>%
  select(chrom, start, end, pair)
site2.ovl <- bed_intersect(site2, lstats.bed)

LDhi$locus1 <- site1.ovl$locus.full.y[match(LDhi$pair, site1.ovl$pair.x)]
LDhi$locus2 <- site2.ovl$locus.full.y[match(LDhi$pair, site2.ovl$pair.x)]

LDhi <- LDhi %>%
  filter(!is.na(locus1), !is.na(locus2)) %>%
  mutate(locus.comb = paste0(locus1, '_', locus2)) %>%
  select(-pair)

LDhi <- LDhi %>%
  distinct(locus.comb, .keep_all = TRUE)

LDhi$calledSites1 <- lstats$calledSites[match(LDhi$locus1, lstats$locus.full)]
LDhi$calledSites2 <- lstats$calledSites[match(LDhi$locus2, lstats$locus.full)]

LDhi.rm <- unique(c(LDhi$locus2[which(LDhi$calledSites1 >= LDhi$calledSites2)],
                    LDhi$locus1[which(LDhi$calledSites2 > LDhi$calledSites1)]))

cat("\n#### vcf2fullfa_filterloci.R: Number of loci to remove due to LD:",
    length(LDhi.rm), '\n')


################################################################################
#### FILTER - CLOSE PROXIMITY #####
################################################################################
tooClose.locus1.index <- which(lstats$distToNext < mindist)
tooClose.locus2.index <- tooClose.locus1.index + 1
tooClose <- cbind(lstats[tooClose.locus1.index, c("locus.full", "calledSites")],
                  lstats[tooClose.locus2.index, c("locus.full", "calledSites")])
colnames(tooClose) <- c('locus1', 'calledSites1', 'locus2', 'calledSites2')

tooClose.rm <- unique(c(tooClose$locus2[which(tooClose$calledSites1 >= tooClose$calledSites2)],
                        tooClose$locus1[which(tooClose$calledSites2 > tooClose$calledSites1)]))

cat("\n#### vcf2fullfa_filterloci.R: Number of loci to remove due to close proximity:",
    length(tooClose.rm), '\n')


################################################################################
#### COPY GOOD LOCI #####
################################################################################
badloci <- unique(c(LDhi.rm, tooClose.rm, missHi.rm))
cat("\n#### vcf2fullfa_filterloci.R: Total number of loci to remove:", length(badloci), '\n')

if(length(badloci) > 0) loci.ok <- lstats %>% filter(! locus.full %in% badloci) %>% pull(locus.full)
if(length(badloci) == 0) loci.ok <- lstats %>% pull(locus.full)
cat("\n#### vcf2fullfa_filterloci.R: Nr of loci selected:", length(loci.ok), '\n')
cat("\n#### vcf2fullfa_filterloci.R: First 10 loci:\n")
print(head(loci.ok))

loci.ok.files <- paste0(indir_fasta, '/', loci.ok)
nrfiles.found <- sum(file.exists(loci.ok.files))
cat("\n#### vcf2fullfa_filterloci.R: Nr of files found:", nrfiles.found, '\n')

cat("\n#### vcf2fullfa_filterloci.R: Copying files to final dir...\n")
loci.copied.files <- paste0(outdir_fasta, '/', loci.ok)
file.copy(from = loci.ok.files, to = loci.copied.files, overwrite = TRUE)

nrfiles <- length(list.files(outdir_fasta))
cat("\n#### vcf2fullfa_filterloci.R: Number of files in indir_fasta:", nrfiles, '\n')

cat('\n\n#### vcf2fullfa_filterloci.R: Done with script.\n')
