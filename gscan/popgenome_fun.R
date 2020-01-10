## Change population names from "pop1" etc to actual names, in a df with stats:
## FST_gri   FST_mur
## [1,] 0.39 0.39
namepops <- function(df, stat = 'x') {
  for(i in 1:length(pops)) {
    tofind <- paste0('pop ', i, '|pop', i)
    colnames(df) <- gsub(tofind, pops[i], colnames(df))
  }
  colnames(df) <- gsub('/', '.', colnames(df))
  colnames(df) <- paste0(stat, '_', colnames(df))

  return(df)
}

## namepops2() makes separate column with name of statistic
## gri  mur stat
## 0.39 0.39  FST
namepops2 <- function(df, stat = 'x') {
  for(i in 1:length(pops)) {
    tofind <- paste0('pop ', i, '|pop', i)
    colnames(df) <- gsub(tofind, pops[i], colnames(df))
  }
  df <- as.data.frame(df)
  df$stat <- stat

  return(df)
}

namepops_vec <- function(vec) {
  for(i in 1:length(pops))
    vec <- gsub(paste0('pop ', i, '|pop', i), pops[i], vec)
  return(vec)
}

## Extract specific statistic from PopGenome results:
get_stat <- function(popindex, stats_list,
                     stat_name_org, stat_name_new, round_dec = 5) {
  #stats <- neutral_slide; popindex <- 1; stat_name = 'Tajima.D'
  stat <- stats_list[[popindex]] %>%
    data.frame(., row.names = NULL)

  stat <- data.frame(stat[, grep(stat_name_org, colnames(stat))])
  colnames(stat) <- paste0(stat_name_new, '_', pops[popindex])

  stat <- as.data.frame(apply(stat, 2, round, round_dec))

  return(stat)
}

## Wrapper around get_stat to get a df instead of a list:
get_stat_df <- function(stats_list, stat_name_org, stat_name_new) {
  lapply(1:npop, get_stat, stats_list, stat_name_org, stat_name_new) %>%
    do.call(cbind, .)
}

write_table <- function(df, outfile, ...) {
  write.table(df, outfile,
              quote = FALSE, row.names = FALSE, sep = '\t',
              ...)
}


################################################################################
##### OLD STUFF #####
################################################################################
# read.pg <- function(triplet, file.id = 'EjaC.Dstat', DP = 5, GQ = 20, MAXMISS = 0.9, MAF = 0.01,
#                     winsize = 100000, stepsize = 100000, scaffold = 'NC_022205.1') {
#
#   pg.basename <- paste0(file.id, '.DP', DP, '.GQ', GQ, '.MAXMISS', MAXMISS,
#                         '.MAF', MAF, '.win', winsize, '.step', stepsize, '.', scaffold)
#   pg.filename <- paste0('analyses/popgenome/output/', pg.basename, '.', triplet, '.txt')
#   df <- read.table(pg.filename, header = TRUE)
#   return(df)
# }
#
# smr.pg <- function(triplet) {
#   df <- read.pg(triplet)
#   smr <- get.dstats(df, triplet)
#   return(smr)
# }
#
# get.dstats <- function(df, triplet) {
#   dstats <- data.frame(t(round(apply(df, 2, mean, na.rm = TRUE), 4)[1:3]))
#   dstats$triplet <- triplet
#   return(dstats)
# }
#
#
# read.bdf <- function(triplet, scaffold, file.id = 'EjaC.Dstat.DP5.GQ20.MAXMISS0.5.MAF0.01',
#                      winsize = 50000, stepsize = 5000) {
#   # triplet <- triplets[1]; file.id = 'EjaC.Dstat.DP5.GQ20.MAXMISS0.5.MAF0.01'; winsize = 50000; stepsize = 5000; scaffold = 'NC_022214.1'
#
#   bdf.file <- paste0('analyses/windowstats/popgenome/output/popgenome.dstats',
#                      file.id, '.win', winsize, '.step', stepsize, '.', scaffold, '.', triplet, '.txt')
#
#   if(file.exists(bdf.file)) {
#     bdf <- fread(bdf.file)
#
#     bdf$BDF <- round(bdf$BDF, 5)
#     bdf$fd <- round(bdf$fd, 5)
#     bdf$D <- round(bdf$D, 5)
#
#     bdf <- bdf %>% select(pop, scaffold, start, BDF, fd, D)
#
#     return(bdf)
#   } else {
#     cat('File does not exist:', bdf.file, '\n')
#     write(scaffold, 'analyses/windowstats/popgenome/missingScafs.txt', append = TRUE)
#   }
# }
#
# collect.scaffold <- function(scaffold, file.id, winsize, stepsize) {
#   cat('Scaffold:', scaffold, '\n')
#   bdf.scaf <- lapply(triplets, read.bdf, scaffold = scaffold, file.id = file.id,
#                      winsize = winsize, stepsize = stepsize)
#   bdf.scaf <- do.call(rbind, bdf.scaf)
#   return(bdf.scaf)
# }