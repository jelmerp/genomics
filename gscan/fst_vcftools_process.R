##### SET-UP #####
setwd('/home/jelmer/Dropbox/sc_lemurs/radseq/')
source('scripts/windowstats/manplots_fun.R')

popcombs <- read.table('analyses/windowstats/fst.vcftools/input/popcombs.txt')
popcombs <- paste0(popcombs$V1, '.', popcombs$V2)

read.fst <- function(popcomb, file.id, winsize = 50000, stepsize = 50000) {
  cat('Pop comb:', popcomb, '\n')
  filename <- paste0('analyses/windowstats/fst.vcftools/output/fst_', file.id, '_', popcomb,
                     '_win', winsize, '.step', stepsize, '.txt.windowed.weir.fst')
  fst <- fread(filename)
  colnames(fst) <- c('scaffold', 'start', 'end', 'nsites', 'weighted.fst', 'fst')

  fst$weighted.fst[fst$weighted.fst < 0] <- 0
  fst$fst[fst$fst < 0] <- 0

  fst <- fst %>% transform(weighted.fst = round(weighted.fst, 4), fst = round(fst, 4))

  fst$pop <- popcomb

  return(fst)
}

##### RUN #####
## Set variables:
file.id = 'Microcebus.r01.FS9.mac3.griseorufus'
winsize <- 50000; winsize.out <- '50k'
stepsize <- 50000; stepsize.out <- '50k'

## Get df:
fst <- do.call(rbind,
               lapply(popcombs, read.fst, file.id = file.id,
                      winsize = winsize, stepsize = stepsize))

fst$pop <- gsub('beza_gallery', 'Gal', fst$pop)
fst$pop <- gsub('beza_ihazoara', 'Ihazo', fst$pop)
fst$pop <- gsub('beza_spiny', 'Spiny', fst$pop)

filename <- paste0('analyses/windowstats/fst.vcftools/output/fst.combined.',
                   file.id, '.win', winsize.out, '.step', stepsize.out, '.txt')
write.table(fst, filename, sep = '\t', quote = FALSE, row.names = FALSE)


##### CHECK RESULTS #####
## Summarize:
fst %>%
  group_by(pop) %>%
  summarise(mean.fst = round(mean(fst, na.rm = TRUE), 2),
            mean.wfst = round(mean(weighted.fst, na.rm = TRUE), 2))

## Boxplot of fst:
p <- ggplot(data = fst) +
  geom_boxplot(aes(x = pop, y = fst), outlier.colour = NA) +
  geom_jitter(aes(x = pop, y = fst),
              width = 0.1, colour = 'grey30', size = 0.5) +
  scale_y_continuous(expand = c(0, 0)) +
  #scale_x_discrete(labels = xlabs) +
  labs(x = "", y = 'FST') +
  theme_bw()
p

## Plot nr of sites versus Fst:
plot(fst$nsites, fst$fst, xlab = 'nr of sites', ylab = 'FST')

## Manhattan plot:
for(fpop in unique(fst$pop)) {
  ggman(fst, yvar = 'fst', scaffold = 'all', pop = fpop,
      drawline = FALSE, drawpoints = TRUE,
      my.ymin = 0, my.ymax = 0.8, plot.title = fpop)
}

yticks <- seq(0, 0.05, by = 0.05/10)
ggman(fst, yvar = 'fst', colvar.lines = 'pop', scaffold = 'all',
      drawline = TRUE, cols.lines = c('red', 'blue', 'green'), drawpoints = FALSE,
      my.ymin = 0, my.ymax = 0.05, my.yticks = yticks, xlab = 'window index',
      plot.title = FALSE)
