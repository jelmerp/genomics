#!/usr/bin/env Rscript

## Process raw output files:
#commandArgs <- function() c('EjaC.Dstat.DP5.GQ20.MAXMISS0.5.MAF0.01.winsize50000.stepsize50000'); source('scripts/windowstats/pgwin_process.R')
#commandArgs <- function() c('EjaC.Dstat.DP5.GQ20.MAXMISS0.5.MAF0.01.winsize50000.stepsize5000'); source('scripts/windowstats/pgwin_process.R')
#commandArgs <- function() c('EjaC.Dstat.DP5.GQ20.MAXMISS0.5.MAF0.01.winsize100000.stepsize10000'); source('scripts/windowstats/pgwin_process.R')
#commandArgs <- function() c('EjaC.Dstat.DP5.GQ30.MAXMISS0.5.MAF0.01.winsize50000.stepsize5000'); source('scripts/windowstats/pgwin_process.R')
#commandArgs <- function() c('EjaC.Dstat.DP5.GQ30.MAXMISS0.5.MAF0.01.winsize100000.stepsize10000'); source('scripts/windowstats/pgwin_process.R')


file.id <- commandArgs()[1] # file.id = 'ABBABABAoutput_EjaC.Dstat'

##### FUNCTIONS #####
read.pgwin <- function(duo.line, file.id = 'EjaC.Dstat.DP5.GQ20.MAXMISS0.5.MAF0.01.winsize50000.stepsize50000') {

  popA.string <- get(duos[duo.line, 1])
  popB.string <- get(duos[duo.line, 2])

  filename <- paste0('popgenwindows_', file.id, '.', popA.string, '.', popB.string, '.txt')
  cat('Reading file:', filename, '\n')
  pg <- fread(paste0('analyses/windowstats/smartin.pg/output/', filename))

  getpopname <- function(inds) {
    pop <- substr(inds, 1, 4)
    pop <- gsub('Sgal', 'Cmam', pop)
    pop <- gsub('Tgui', 'Cgui', pop)
    return(pop)
  }

  pg$popA <- getpopname(popA.string)
  pg$popB <- getpopname(popB.string)
  colnames(pg) <- gsub('_popA_popB', '', colnames(pg))

  pg <- pg %>% select(popA, popB, scaffold, start, end, mid, sites, pi_popA, pi_popB, dxy, Fst)
  pg <- pg %>% rename(fst = Fst)

  pg$fst[pg$fst < 0] <- 0

  return(as.data.frame(pg))
}

combine.pgwin <- function(file.id) {
  fd <- lapply(1:nrow(duos), read.pgwin, file.id = file.id)
  fd <- do.call(rbind, fd)
  return(fd)
}

##### APPLY #####
Cdec <- 'Cdec088,Cdec328'
Ceja <- 'Ceja262,Ceja408'
Cfus <- 'Cfus085,Cfus350,Cfus503'
Cgal <- 'SgalMA1'
Cgui <- 'TguiNG2,TguiNG5'
duos <- read.table('analyses/windowstats/smartin.pg/input/popcombs.txt', as.is = TRUE)

pg <- combine.pgwin(file.id)
pg.filename <- paste0('analyses/windowstats/smartin.pg/pg.collected_', file.id, '.txt')
pg.filename <- gsub('000\\.', 'k.', pg.filename)
pg.filename <- gsub('winsize', 'win', pg.filename)
pg.filename <- gsub('stepsize', 'step', pg.filename)
write.table(pg, pg.filename, sep = '\t', quote = FALSE, row.names = FALSE)

cat('Dimensions of pgstats:', dim(pg), '\n')
cat('Writing file:', pg.filename, '\n')

