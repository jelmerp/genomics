##### SET-UP #####
setwd('/home/jelmer/Dropbox/sc_fish/cichlids/')
library(data.table); library(dplyr)

triplets <- read.table('analyses/windowstats/popgenome/input/triplets.txt', as.is = TRUE)
triplets <- paste0(triplets$V1, '.', triplets$V2, '.', triplets$V3)
scaffolds <- readLines('metadata/scaffolds.txt')[1:500]


##### FUNCTIONS #####

read.bdf <- function(triplet, scaffold, file.id = 'EjaC.Dstat.DP5.GQ20.MAXMISS0.5.MAF0.01',
                     winsize = 50000, stepsize = 5000) {
  # triplet <- triplets[1]; file.id = 'EjaC.Dstat.DP5.GQ20.MAXMISS0.5.MAF0.01'; winsize = 50000; stepsize = 5000; scaffold = 'NC_022214.1'

  bdf.file <- paste0('analyses/windowstats/popgenome/output/popgenome.dstats',
                     file.id, '.win', winsize, '.step', stepsize, '.', scaffold, '.', triplet, '.txt')

  if(file.exists(bdf.file)) {
    bdf <- fread(bdf.file)

    bdf$BDF <- round(bdf$BDF, 5)
    bdf$fd <- round(bdf$fd, 5)
    bdf$D <- round(bdf$D, 5)

    bdf <- bdf %>% select(pop, scaffold, start, BDF, fd, D)

    return(bdf)
  } else {
    cat('File does not exist:', bdf.file, '\n')
    write(scaffold, 'analyses/windowstats/popgenome/missingScafs.txt', append = TRUE)
  }
}

collect.scaffold <- function(scaffold, file.id, winsize, stepsize) {
  cat('Scaffold:', scaffold, '\n')
  bdf.scaf <- lapply(triplets, read.bdf, scaffold = scaffold, file.id = file.id, winsize = winsize, stepsize = stepsize)
  bdf.scaf <- do.call(rbind, bdf.scaf)
  return(bdf.scaf)
}

##### APPLY #####
## Set variables:
file.id = 'EjaC.Dstat.DP5.GQ20.MAXMISS0.5.MAF0.01'
winsize <- 50000
stepsize <- 5000

## Run:
file.create('analyses/windowstats/popgenome/missingScafs.txt')
bdf <- lapply(scaffolds, collect.scaffold, file.id = file.id, winsize = winsize, stepsize = stepsize)
bdf <- do.call(rbind, bdf)
#bdf <- collect.scaffold(scaffold = 'NC_022214.1')

filename <- paste0('analyses/windowstats/popgenome/bdf.combined.', file.id, '.win', winsize, '.step', stepsize, '.txt')
write.table(bdf, filename, sep = '\t', quote = FALSE, row.names = FALSE)

missing <- write(unique(readLines('analyses/windowstats/popgenome/missingScafs.txt')), 'analyses/windowstats/popgenome/missingScafs2.txt')

##### SUMMARIZE #####
bdf %>% group_by(pop) %>% summarise(bdf.mean = round(mean(BDF, na.rm = TRUE), 2),
                                    fd.mean = round(mean(fd, na.rm = TRUE), 2),
                                    D.mean = round(mean(D, na.rm = TRUE), 2))

