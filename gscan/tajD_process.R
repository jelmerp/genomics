##### SET-UP #####
setwd('/home/jelmer/Dropbox/sc_fish/cichlids/')
library(data.table); library(dplyr)

pops <- c('Cdec', 'Ceja', 'Cfus', 'Cgui') # Cmam doesn't work - only one individual

read.tajD <- function(pop, winsize = 50000, file.id = 'EjaC.Cgal.Cgui.DP5.GQ20.MAXMISS0.5.MAF0.01') {
  cat('Population:', pop, '\n')
  filename <- paste0('analyses/windowstats/tajD/tajD.vcftools.', file.id, '.', pop, '.win', winsize, '.txt.Tajima.D')
  tajD <- fread(filename)
  colnames(tajD) <- c('scaffold', 'start', 'nsites', 'tajD')
  tajD$pop <- pop
  return(tajD)
}

##### RUN #####
## Set variables:
file.id = 'EjaC.Cgal.Cgui.DP5.GQ20.MAXMISS0.5.MAF0.01'
winsize <- 10000

## Run:
tajD <- do.call(rbind, lapply(pops, read.tajD, file.id = file.id, winsize = winsize))
filename <- paste0('analyses/windowstats/tajD/tajD.combined.', file.id, '.win', winsize, '.txt')
write.table(tajD, filename, sep = '\t', quote = FALSE, row.names = FALSE)

tajD %>% group_by(pop) %>% summarise(mean = round(mean(tajD, na.rm = TRUE), 2))

# source('scripts/windowstats/manplot_fun.R')
# ggman(tajD, yvar = 'tajD', scaffold = 'NC_022205.1', pop = 'Cdec', drawline = TRUE, cols.points = 'grey40')
# ggman(tajD, yvar = 'tajD', scaffold = 'NC_022205.1', pop = 'Ceja', drawline = TRUE, cols.points = 'grey40')
# ggman(tajD, yvar = 'tajD', scaffold = 'NC_022205.1', pop = 'Cfus', drawline = TRUE, cols.points = 'grey40')
# ggman(tajD, yvar = 'tajD', scaffold = 'NC_022205.1', pop = 'Cgui', drawline = TRUE, cols.points = 'grey40')
#
# ggman(tajD, yvar = 'tajD', scaffold = 'all', pop = 'Cdec', drawline = TRUE, cols.points = 'grey40')
# ggman(tajD, yvar = 'tajD', scaffold = 'all', pop = 'Ceja', drawline = TRUE, cols.points = 'grey40')
# ggman(tajD, yvar = 'tajD', scaffold = 'all', pop = 'Cfus', drawline = TRUE, cols.points = 'grey40')
# ggman(tajD, yvar = 'tajD', scaffold = 'all', pop = 'Cgui', drawline = TRUE, cols.points = 'grey40')
