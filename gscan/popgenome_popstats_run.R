#!/usr/bin/env Rscript

## TO DO:
# https://cran.r-project.org/web/packages/PopGenome/vignettes/Whole_genome_analyses_using_VCF_files.pdf
# Add GFF file
# CLR sweep test
# Missing sites correction
# SFS!


##### SET-UP #####
options(scipen = 999)

if(grepl('Ubuntu', sessionInfo()[4]) == TRUE) {
  cat('Running on laptop...', '\n')
  library(PopGenome)
  setwd('/home/jelmer/Dropbox/sc_lemurs/radseq/')

  file.id.in <- commandArgs()[1]
  scaffold <- commandArgs()[2]
  pop1 <- commandArgs()[3]
  pop2 <- commandArgs()[4]
  pop3 <- commandArgs()[5]
  do.allpops <- commandArgs()[6]
  windowsize <- as.integer(commandArgs()[7])
  stepsize <- as.integer(commandArgs()[8])

  triplet <- c(pop1, pop2, pop3)

} else {
  cat('Running on cluster...', '\n')

  file.id.in <- args[1]
  scaffold <- args[2]
  do.allpops <- args[3]
  triplet.nr <- args[4]
  windowsize <- args[5]
  stepsize <- args[6]

  library(PopGenome)
}

cat('File ID:', file.id.in, '\n')
cat('Scaffold:', scaffold, '\n')
cat('Triplet:', triplet, '\n')
cat('Do all pops:', do.allpops, '\n')
cat('Window size:', windowsize, '\n')
cat('Step size:', stepsize, '\n')


##### FUNCTIONS #####

## Change population names from "pop1" etc to actual names, in a df with stats:
namepops <- function(df, stat) {
  for(i in 1:length(pops)) {
    tofind <- paste0('pop ', i, '|pop', i)
    colnames(df) <- gsub(tofind, pops[i], colnames(df))
  }
  colnames(df) <- gsub('/', '.', colnames(df))
  colnames(df) <- paste0(stat, '_', colnames(df))

  return(df)
}

##### SET-UP2 #####
library(PopGenome)
setwd('/home/jelmer/Dropbox/sc_lemurs/radseq/')
file.id.in <- 'Microcebus.r01.FS8.mac3.griseoBeza'
scaffold <- 'NC_033660.1'
do.allpops <- FALSE
windowsize <- 50000
stepsize <- 50000

## Individuals and populations:
pop1 <- 'galry'
pop2 <- 'ihazo'
pop3 <- 'spiny'
pops <- c(pop1, pop2, pop3)

triplet <- c(pop1, pop2, pop3)
triplet.name <- paste0(triplet, collapse = '-')
file.id <- paste0(file.id.in, '.win', windowsize, '.step', stepsize, '.',
                  scaffold, '.', triplet.name)

outgroup <- 'XXX'

source('scripts/metadata/metadata_beza.R')
inds.pop1 <- gris.Beza.df$ID[gris.Beza.df$loc.short == 'Beza_gallery']
inds.pop2 <- gris.Beza.df$ID[gris.Beza.df$loc.short == 'Beza_ihazoara']
inds.pop3 <- gris.Beza.df$ID[gris.Beza.df$loc.short == 'Beza_spiny']

## Scaffolds:
scafs <- read.table('../metadata/scaffolds_withLength.txt',
                    colClasses = c('character', 'integer'), header = TRUE)
scaffold.length <- scafs$scaffold.length[scafs$scaffold.name %in% scaffold]


##### READ VCF #####
## Read vcf:
vcf.file <- paste0('seqdata/vcf/', file.id.in, '.vcf.gz')
vcf.tabix <- paste0(vcf.file, '.tbi')
if(!file.exists(vcf.tabix)) system(paste('tabix', vcf.file))

vcf <- readVCF(vcf.file, numcols = 10000, include.unknown = TRUE,
               tid = scaffold, frompos = 1, topos = scaffold.length)

#concatenate.regions

# vcf.dir <- paste0('seqdata/vcf/tmp')
# vcf <- readData(vcf.dir, format = 'VCF') # DOES NOT WORK!

## Populations:
vcf.inds <- unlist(vcf@region.data@populations2)
vcf.inds <- vcf.inds[-grep('\\.2', vcf.inds)]

inds.pop1 <- inds.pop1[inds.pop1 %in% vcf.inds]
inds.pop2 <- inds.pop2[inds.pop2 %in% vcf.inds]
inds.pop3 <- inds.pop3[inds.pop3 %in% vcf.inds]

pops.list <- list(inds.pop1, inds.pop2, inds.pop3)

## Set the populations & outgroup:
vcf <- set.outgroup(vcf, outgroup.inds, diploid = TRUE)
vcf <- set.populations(vcf, pops.list, diploid = TRUE)
#vcf@populations

## Transform the data into windows:
slide <- sliding.window.transform(vcf, windowsize, stepsize, type = 2)
# type=1 - only biallelic positions

## Get the genomic positions for each window:
cat('Getting window positions:\n')
win.pos <- sapply(slide@region.names, function(x){
  split <- strsplit(x, " ")[[1]][c(1, 3)]
  val <- mean(as.numeric(split))
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
cat('Individuals:\n'); print(vcf.inds)
vcf.pops <- substr(sapply(slide@populations, '[', 1), 1, 16)
cat('First inds for each population:\n'); print(vcf.pops)


##### NEUTRALITY STATS ##### # Doesnt work, try with include.unknown = FALSE when reading vcf file
vcf <- neutrality.stats(vcf) #, FAST = TRUE)
neutrality.stats <- get.neutrality(vcf)
neutrality.stats[[1]] # For first population
vcf@Tajima.D

slide <- neutrality.stats(slide)
slide.neut <- get.neutrality(slide)
slide.neut[[1]]


##### DIFFERENTIATION #####
## Fst, overall:
vcf <- F_ST.stats(vcf, mode = 'nucleotide')
vcf@nuc.F_ST.pairwise
vcf@nuc.F_ST.vs.all

## Fst, by window:
slide <- F_ST.stats(slide, mode = 'nucleotide')
#slide <- F_ST.stats(slide, mode = 'nucleotide', new.populations = allpops)
fst.pr <- namepops(t(slide@nuc.F_ST.pairwise), stat = 'fst')
fst.sl <- namepops(slide@nuc.F_ST.vs.all, stat = 'fst')

fst.pr.mean <- round(apply(fst.pr, 2, mean, na.rm = TRUE), 4)
cat('mean pairwise fst:\n'); print(fst.pr.mean)

#if(do.allpops == TRUE) {
#   print(fst.pr.mean[mam.columns])
#   print(fst.pr.mean[gui.columns])
# }

fst.sl.mean <- round(apply(fst.sl, 2, mean, na.rm = TRUE), 4)
cat('mean single pop fst:\n'); print(fst.sl.mean)

## Dxy, by window:
slide <- diversity.stats.between(slide)
dxy <- namepops((slide@nuc.diversity.between / windowsize) * 100, stat = 'dxy')
dxy.mean <- round(apply(dxy, 2, mean, na.rm = TRUE), 4)
cat('mean dxy:\n'); print(dxy.mean)

#if(do.allpops == TRUE) {
#  print(dxy.mean[mam.columns])
#  print(dxy.mean[gui.columns])
#}


#### DIVERSITY ####
## Overall:
vcf <- diversity.stats(vcf)
div <- get.diversity(vcf)
vcf@nuc.diversity.within / scaffold.length

## By window:
slide <- diversity.stats(slide)
nucdiv <- namepops((slide@nuc.diversity.within / windowsize) * 100, stat = 'nucdiv')
nucdiv.mean <- round(apply(nucdiv, 2, mean, na.rm = TRUE), 4)
cat('mean nucleotide diversity:\n'); print(nucdiv.mean)

slide <- diversity.stats(slide, pi = TRUE)
pi <- namepops((slide@Pi / windowsize) * 100, stat = 'pi')
pi.mean <- round(apply(pi, 2, mean, na.rm = TRUE), 4)
cat('mean nucleotide diversity pi:\n'); print(pi.mean)

#### D, df, BDF ####

## Overall:
vcf <- introgression.stats(vcf, do.D = TRUE)
vcf@D
vcf@f
vcf <- introgression.stats(vcf, do.BDF = TRUE)
vcf@BDF

## By window:
slide <- introgression.stats(slide, do.BDF = TRUE)
BDF <- slide@BDF; head(BDF)

slide <- introgression.stats(slide, do.D = TRUE)
D <- slide@D; head(D)
f <- slide@f; head(f)
f[f > 1] <- 1
f[f < -1] <- -1

mean.bdf <- mean(BDF, na.rm = TRUE)
mean.D <- mean(D, na.rm = TRUE)
mean.f <- mean(f, na.rm = TRUE)
cat('Mean BDF:', mean.bdf, '\n')
cat('Mean D:', mean.D, '\n')
cat('Mean Fd:', mean.f, '\n')

#BDF_bayes <- slide@BDF_bayes # Doesnt exist
# B-dbf = Pr(D|M1) / Pr(D|M2) # M1 = 2 & 3 introgression; M2 = 1 & 3 introgression

## Bayescan
if(perform.bayescan == TRUE) {
  bayescan.input <- getBayes(vcf, snps = TRUE)
  bayescan.output <- BayeScanR(bayescan.input,
                               nb.pilot = 10, pilot.runtime = 2500,
                               main.runtime = 100000, discard = 50000)
}



#### DATA OUTPUT #####
allstats <- cbind(pi, fst.sl, fst.pr, dxy)
if(do.allpops == FALSE) {
  introgstats <- cbind(BDF, f, D)
  colnames(introgstats) <- c('BDF', 'fd', 'D')
  allstats <- cbind(introgstats, allstats)
}

allstats.filename <- paste0('analyses/windowstats/popgenome/output/', file.id, '.txt')
write.table(allstats, allstats.filename,
            quote = FALSE, row.names = FALSE, sep = '\t')
