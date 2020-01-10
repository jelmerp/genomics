##### SET-UP #####
setwd('/home/jelmer/Dropbox/sc_fish/cichlids/')

triplets <- list(
  c('Cdec', 'Ceja', 'Cmam'),
  c('Cdec', 'Cfus', 'Cmam'),
  c('Ceja', 'Cfus', 'Cmam'),

  c('Cdec', 'Ceja', 'Cgui'),
  c('Cdec', 'Cfus', 'Cgui'),
  c('Ceja', 'Cfus', 'Cgui'),

  c('Cgui', 'Cmam', 'Cdec'),
  c('Cgui', 'Cmam', 'Ceja'),
  c('Cgui', 'Cmam', 'Cfus')
)
allpops <- c('Cdec', 'Ceja', 'Cfus', 'Cmam', 'Cgui')


##### RUN #####
file.id <- 'EjaC.Dstat.DP5.GQ20.MAXMISS0.5.MAF0.01'
scaffold = 'NC_022214.1'
winsize = 50000; stepsize = 5000

for(triplet.nr in c(2, 3, 7, 8, 9)) {
  # triplet.nr <- 2
  cat('Triplet:', triplets[[triplet.nr]], '\n')
  cat('Scaffold:', scaffold, '\n')

  pop1 <- triplets[[triplet.nr]][1]
  pop2 <- triplets[[triplet.nr]][2]
  pop3 <- triplets[[triplet.nr]][3]

  commandArgs <- function() c(file.id, scaffold, pop1, pop2, pop3, winsize, stepsize)
  source('scripts/windowstats/popgenome.dstats_run.R')
}

