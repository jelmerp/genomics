setwd('/home/jelmer/Dropbox/sc_fish/cichlids/')
library(dplyr)

##### FUNCTIONS #####
read.pg <- function(triplet, file.id = 'EjaC.Dstat', DP = 5, GQ = 20, MAXMISS = 0.9, MAF = 0.01,
                    winsize = 100000, stepsize = 100000, scaffold = 'NC_022205.1') {

  pg.basename <- paste0(file.id, '.DP', DP, '.GQ', GQ, '.MAXMISS', MAXMISS,
                        '.MAF', MAF, '.win', winsize, '.step', stepsize, '.', scaffold)
  pg.filename <- paste0('analyses/popgenome/output/', pg.basename, '.', triplet, '.txt')
  df <- read.table(pg.filename, header = TRUE)
  return(df)
}

smr.pg <- function(triplet) {
  df <- read.pg(triplet)
  smr <- get.dstats(df, triplet)
  return(smr)
}

get.dstats <- function(df, triplet) {
  dstats <- data.frame(t(round(apply(df, 2, mean, na.rm = TRUE), 4)[1:3]))
  dstats$triplet <- triplet
  return(dstats)
}

##### APPLY #####
triplet <- 'Cgui-Cmam-Cdec'
g20.5 <- read.pg(triplet, GQ = 20, MAXMISS = 0.5)
g20.9 <- read.pg(triplet, GQ = 20, MAXMISS = 0.9)
g30.5 <- read.pg(triplet, GQ = 30, MAXMISS = 0.5)
g30.9 <- read.pg(triplet, GQ = 30, MAXMISS = 0.9)

g20.5.mean <- round(apply(g20.5, 2, mean, na.rm = TRUE), 3)
g20.9.mean <- round(apply(g20.9, 2, mean, na.rm = TRUE), 3)
g30.5.mean <- round(apply(g30.5, 2, mean, na.rm = TRUE), 3)
g30.9.mean <- round(apply(g30.9, 2, mean, na.rm = TRUE), 3)

rbind(g20.5.mean, g20.9.mean, g30.5.mean, g30.9.mean)



triplets <- c('Cdec-Cfus-Cgui', 'Cdec-Cfus-Cmam', 'Cdec-Cgui-Cmam', 'Cgui-Cmam-Cdec')
do.call(rbind, lapply(triplets, smr.pg))

round(apply(read.pg('Cdec-Cgui-Cmam'), 2, mean, na.rm = TRUE), 3)



#### PLOTS ####

## Manhattan plot:
manplot(pi, var = 'pi', my.ylim = c(0, 0.3), plot.id = 'pi', win.pos = win.pos)
manplot(fst.sl, 'single-pop Fst', my.ylim = c(-1, 1), plot.id = 'fst.singlepop', win.pos = win.pos)

if(do.allpops == FALSE) {
  manplot(fst.pr, 'between-pop Fst', plot.id = 'fst', my.ylim = c(-1, 1), win.pos = win.pos)
  manplot(dxy, var = 'dxy', plot.id = 'dxy', my.ylim = c(0, 0.2), win.pos = win.pos)

  manplot(BDF, plot.id = 'BDF', var = 'BDF', win.pos = win.pos)
  manplot(introgstats, plot.id = 'introgressionStats',
          legnames = colnames(introgstats), var = 'introgression', win.pos = win.pos)
}

if(do.allpops == TRUE) {
  manplot(pi[, c('Cdec', 'Ceja', 'Cfus')], var = 'pi', plot.title = 'pi.eja', plot.id = 'pi.eja', my.ylim = c(0, 0.3), win.pos = win.pos)
  manplot(fst.pr[, mam.columns], 'Fst', plot.title = 'fst.mam', plot.id = 'fst.mam', my.ylim = c(-1, 1), win.pos = win.pos)
  manplot(fst.pr[, gui.columns], 'Fst', plot.title = 'fst.gui', plot.id = 'fst.gui', my.ylim = c(-1, 1), win.pos = win.pos)
  manplot(fst.pr[, ejac.columns], 'Fst', plot.title = 'fst.eja', plot.id = 'fst.eja', my.ylim = c(-1, 1), win.pos = win.pos)
  manplot(dxy[, mam.columns], var = 'dxy', plot.title = 'dxy.mam', plot.id = 'dxy.mam', my.ylim = c(0, 0.2), win.pos = win.pos)
  manplot(dxy[, gui.columns], var = 'dxy', plot.title = 'dxy.gui', plot.id = 'dxy.gui', my.ylim = c(0, 0.2), win.pos = win.pos)
  manplot(dxy[, ejac.columns], var = 'dxy', plot.title = 'dxy.eja', plot.id = 'dxy.eja', my.ylim = c(0, 0.2), win.pos = win.pos)
}

## D, Df, BDF:
png(paste0('analyses/popgenome/manhattan/', file.id, '.D_points.png'), width = 700, height = 500)
plot(win.pos, D, pch = 19, ylab = "D", xlab = "genomic position", main = triplet.name, ylim = c(-1, 1))
abline(h = 0)
dev.off()

png(paste0('analyses/popgenome/manhattan/', file.id, '.f_points.png'), width = 700, height = 500)
plot(win.pos, f, pch = 19, ylab = "f", xlab = "genomic position", main = triplet.name, ylim = c(-1, 1))
abline(h = 0)
dev.off()

png(paste0('analyses/popgenome/manhattan/', file.id, '.BDF_points.png'), width = 700, height = 500)
plot(win.pos, BDF, pch = 19, ylab = "Bd-fraction", xlab = "genomic position", main = triplet.name, ylim = c(-1, 1))
abline(h = 0)
dev.off()
