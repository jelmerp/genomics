setwd('/home/jelmer/Dropbox/sc_fish/cichlids/')
library(data.table); library(dplyr)

Cdec <- 'Cdec088,Cdec328'
Ceja <- 'Ceja262,Ceja408'
Cfus <- 'Cfus085,Cfus350,Cfus503'
Cgal <- 'SgalMA1'
Cgui <- 'TguiNG2,TguiNG5'

popcombs <- read.table('analyses/windowstats/smartin.pg/input/popcombs.txt', as.is = TRUE)

##### FUNCTIONS #####
read.pgwin <- function(file.id = 'EjaC.Dstat.DP5.GQ20.MAXMISS0.5.MAF0.01', pop1, pop2,
                         winsize = 50000, stepsize = 50000) {
  filename <- paste0('popgenwindows_', file.id, '.winsize', winsize, '.stepsize', stepsize, '.', pop1, '.', pop2, '.txt')
  pd <- fread(paste0('analyses/windowstats/smartin.pg/output/', filename))
  return(as.data.frame(pd))
}

smr.pgwin <- function(pd) {
  pd$Fst[which(pd$Fst_popA_popB < 0)] <- 0 # Negative Fst to zero

  pi1 <- round(mean(pd$pi_popA, na.rm = TRUE), 4)
  pi2 <- round(mean(pd$pi_popB, na.rm = TRUE), 4)
  fst <- round(mean(pd$Fst_popA_popB, na.rm = TRUE), 4)
  dxy <- round(mean(pd$dxy_popA_popB, na.rm = TRUE), 4)
  return(c(pi1, pi2, fst, dxy))
}

read.smr.pgwin <- function(line.nr, file.id, winsize = 50000, stepsize = 50000) {
  pop1.short <- popcombs[line.nr, 1]
  pop1 <- get(pop1.short)
  pop2.short <- popcombs[line.nr, 2]
  pop2 <- get(pop2.short)

  pd <- read.pgwin(file.id = file.id, pop1 = pop1, pop2 = pop2,
                     winsize = winsize, stepsize = stepsize)
  return(c(pop1.short, pop2.short, smr.pgwin(pd)))
}

compile.smr <- function(file.id, winsize = 50000, stepsize = 50000) {
  smr <- data.frame(do.call(rbind, lapply(1:nrow(popcombs), read.smr.pgwin,
                                          file.id = file.id, winsize = winsize, stepsize = stepsize)))
  colnames(smr) <- c('pop1', 'pop2', 'pi1', 'pi2', 'fst', 'dxy')
  smr[, c('pi1', 'pi2', 'fst', 'dxy')] <- sapply(c('pi1', 'pi2', 'fst', 'dxy'), FUN = function(x) smr[, x] <- as.numeric(as.character(smr[, x])))
  return(as.data.frame(smr))
}

getratio <- function(d) {
  cat('Dxy Gal/Gui:', round(mean(d$dxy[3] / d$dxy[4], d$dxy[6] / d$dxy[7], d$dxy[8] / d$dxy[9]), 2), '\n')
  cat('Fst Gal/Gui:', round(mean(d$fst[3] / d$fst[4], d$fst[6] / d$fst[7], d$fst[8] / d$fst[9]), 2), '\n')
  cat('Pi Gal/Gui:', round(d$pi2[3] / d$pi2[4], 2), '\n')
  cat('Pi Gal/Dec:', round(d$pi2[3] / d$pi1[1], 2), '\n')
}


##### CHECK EFFECTS OF GQ AND MAXMISS #####
#(d1_1_0.5 <- compile.smr('EjaC.Dstat.DP1.GQ1.MAXMISS0.5.MAF0.01'))
(d5_20_0.5 <- compile.smr('EjaC.Dstat.DP5.GQ20.MAXMISS0.5.MAF0.01'))
(d5_20_0.9 <- compile.smr('EjaC.Dstat.DP5.GQ20.MAXMISS0.9.MAF0.01', winsize = 250000, stepsize = 250000))
(d5_30_0.5 <- compile.smr('EjaC.Dstat.DP5.GQ30.MAXMISS0.5.MAF0.01', winsize = 250000, stepsize = 250000))
(g5_20_0.5 <- compile.smr('EjaC.Cgal.Cgui.DP5.GQ20.MAXMISS0.5.MAF0.01', winsize = 250000, stepsize = 250000))

getratio(d1_1_0.5)
getratio(d5_20_0.5)
getratio(d5_20_0.9)
getratio(d5_30_0.5)
getratio(g5_20_0.5)

