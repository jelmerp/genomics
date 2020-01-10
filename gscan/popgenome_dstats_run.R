#!/usr/bin/env Rscript

## TO DO:
# https://cran.r-project.org/web/packages/PopGenome/vignettes/Whole_genome_analyses_using_VCF_files.pdf
# Add GFF file
# CLR sweep test
# Missing sites correction

##### SET-UP #####
if(grepl('Ubuntu', sessionInfo()[4]) == TRUE) {
  cat('Running on laptop...', '\n')
  library(PopGenome)
  setwd('/home/jelmer/Dropbox/sc_fish/cichlids/')

  file.id.in <- commandArgs()[1]
  scaffold <- commandArgs()[2]
  pop1 <- commandArgs()[3]
  pop2 <- commandArgs()[4]
  pop3 <- commandArgs()[5]
  windowsize <- as.integer(commandArgs()[6])
  stepsize <- as.integer(commandArgs()[7])

  triplet <- c(pop1, pop2, pop3)

  ## Parameters:
  # file.id.in <- 'EjaC.Dstat.DP5.GQ20.MAXMISS0.5.MAF0.01'
  # scaffold <- 'NT_167844.1'
  # windowsize <- 50000; stepsize <- 50000
  # pop1 <- 'Cdec'; pop2 <- 'Cfus'; pop3 <- 'Cmam'

} else {
 cat('Running on cluster...', '\n')

  args <- commandArgs(trailingOnly = TRUE)
  file.id.in <- args[1]
  scaffold <- args[2]
  pop1 <- args[3]
  pop2 <- args[4]
  pop3 <- args[5]
  windowsize <- as.integer(args[6])
  stepsize <- as.integer(args[7])

  #library(PopGenome)
  library(PopGenome, lib.loc = "/netscr/jelmerp/Rlibs/")
}

cat('File ID:', file.id.in, '\n')
cat('Scaffold:', scaffold, '\n')
cat('Window size:', windowsize, '\n')
cat('Step size:', stepsize, '\n')

Cdec = c("Cdec088", "Cdec328")
Ceja = c("Ceja262", "Ceja408")
Cfus = c("Cfus085", "Cfus350", "Cfus503")
Cmam = c("SgalMA1")
Cgui = c("TguiNG2", "TguiNG5")
Sgui = c('TguiMA1', 'TguiMA2', 'TguiMA4')

triplet <- list(get(pop1), get(pop2), get(pop3))
cat('Triplet list:\n'); print(triplet)

options(scipen = 999)

##### FUNCTIONS #####

## Change population names from "pop1" etc to actual names, in a df with stats:
namepops <- function(df, stat) {
  for(i in 1:length(triplet.names)) {
    tofind <- paste0('pop ', i, '|pop', i)
    colnames(df) <- gsub(tofind, triplet.names[i], colnames(df))
  }
  colnames(df) <- gsub('/', '.', colnames(df))
  colnames(df) <- paste0(stat, '_', colnames(df))

  return(df)
}

##### SET-UP2 #####
## Define populations, triplets, scaffold, and colours:
scafs <- read.table('metadata/scaffolds_withLength.txt', colClasses = c('character', 'integer'), header = TRUE)
scaffold.length <- scafs$scaffold.length[scafs$scaffold.name %in% scaffold]

mam.columns <- c('Cdec/Cmam', 'Ceja/Cmam', 'Cfus/Cmam', 'Cmam/Cgui')
gui.columns <- c('Cdec/Cgui', 'Ceja/Cgui', 'Cfus/Cgui', 'Cmam/Cgui')
ejac.columns <- c('Cdec/Ceja', 'Cdec/Cfus', 'Ceja/Cfus')

triplet.names <- substr(sapply(triplet, '[', 1), 1, 4)
triplet.names <- gsub('Tgui', 'Cgui', triplet.names)
triplet.names <- gsub('Sgal', 'Cmam', triplet.names)
triplet.name <- paste(triplet.names, collapse = ".")

file.id <- paste0(file.id.in, '.win', windowsize, '.step', stepsize, '.', scaffold, '.', triplet.name)


##### READ VCF #####
## Read vcf:
vcf.file <- paste0('seqdata/vcf_split/', file.id.in, '.vcf.gz')
vcf <- readVCF(vcf.file, numcols = 10000, include.unknown = TRUE, tid = scaffold,
               frompos = 1, topos = scaffold.length)
#vcf <- readData(vcf.file, format = 'VCF')

## Set the populations & outgroup:
vcf <- set.outgroup(vcf, Sgui, diploid = TRUE)
vcf <- set.populations(vcf, triplet, diploid = TRUE)

## Transform the data into windows:
slide <- sliding.window.transform(vcf, windowsize, stepsize, type = 2) # type=1 - only biallelic positions

## Get the genomic positions for each window:
cat('Getting window positions:\n')
win.pos <- sapply(slide@region.names, function(x){
  split <- strsplit(x, " ")[[1]][c(1, 3)]
  val <- min(as.numeric(split))
  return(as.numeric(val))
})
names(win.pos) <- NULL

##### BASIC STATS #####
nr.windows <- length(slide@region.names)
smr <- get.sum.data(vcf)
nr.sites <- smr[[1]]
nr.sites.biallelic <- smr[[2]]
cat('Number of windows:', nr.windows, '   Number of sites:', nr.sites,
    '    Number of biallelic sites:', nr.sites.biallelic, '\n')
vcf.inds <- get.individuals(vcf)[[1]]
vcf.inds <- vcf.inds[-grep('.2', vcf.inds)]
cat('Individuals:\n'); print(vcf.inds)
vcf.pops <- substr(sapply(slide@populations, '[', 1), 1, 4)
cat('Populations:\n'); print(vcf.pops)

#### D, df, BDF ####

## By window:
slide <- introgression.stats(slide, do.BDF = TRUE)
BDF <- slide@BDF; head(BDF)

slide <- introgression.stats(slide, do.D = TRUE)
D <- slide@D; head(D)
f <- slide@f; head(f)
f[f > 1] <- 1
f[f < -1] <- -1

mean.bdf <- round(mean(BDF, na.rm = TRUE), 3)
mean.D <- round(mean(D, na.rm = TRUE), 3)
mean.f <- round(mean(f, na.rm = TRUE), 3)
cat('Mean BDF:', mean.bdf, '\n')
cat('Mean D:', mean.D, '\n')
cat('Mean Fd:', mean.f, '\n')

# BDF_bayes <- slide@BDF_bayes # Doesnt exist
# B-dbf = Pr(D|M1) / Pr(D|M2) # M1 = 2 & 3 introgression; M2 = 1 & 3 introgression

#### DATA OUTPUT #####
dstats <- as.data.frame(cbind(win.pos, BDF, f, D))
colnames(dstats) <- c('start', 'BDF', 'fd', 'D')
dstats$scaffold <- scaffold
dstats$pop <- triplet.name
dstats.filename <- paste0('analyses/windowstats/popgenome/output/popgenome.dstats', file.id, '.txt')
write.table(dstats, dstats.filename, quote = FALSE, row.names = FALSE, sep = '\t')
