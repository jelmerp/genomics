library(tidyverse)
library(reshape2)
library(data.table)

################################################################################
##### GET DFs ######
################################################################################
indmiss.get <- function(indmiss.file) {
  # indmiss.file <- indmiss.files[2]

  print(indmiss.file)

  inds.miss <- readLines(indmiss.file)

  if(length(inds.miss) == 0) cat("Empty file\n")

  if(length(inds.miss) > 0) {
    software <- ifelse(grepl('gatk', indmiss.file), 'gatk', 'ipyrad')
    assembly <- ifelse(grepl('mapped2mmur|refb_Mmur', indmiss.file), 'M2M',
                       ifelse(grepl('mapped2cmed|refb_Cmed', indmiss.file), 'M2C',
                              ifelse(grepl('denovo', indmiss.file), 'denovo', NA)))
    reads <- ifelse(grepl('R1', indmiss.file), 'R1',
                    ifelse(grepl('paired', indmiss.file), 'paired', NA))
    inds <- ifelse(grepl('Microcebus', indmiss.file), 'Mic',
                   ifelse(grepl('Cheirogaleus|Cmed', indmiss.file), 'Che',
                          ifelse(grepl('allInds', indmiss.file), 'all', NA)))
    mac <- gsub('.*(mac[0-9]).*', '\\1', indmiss.file)
    round <- as.integer(gsub('.*HiMissInds([0-9])$', '\\1', indmiss.file))

    runID <- indmiss.file %>%
      gsub(pattern = '.*\\/filtering\\/(.*).HiMissInds.', replacement = '\\1') %>%
      gsub(pattern = '.mac[0-9]', replacement = '')
    runID <- gsub('.*\\/filtering\\/(.*).HiMissInds.', '\\1', indmiss.file)
    runID <- paste0(software, '.', reads, '.', assembly, '.', runID)

    indmiss.df <- data.frame(runID, reads, assembly, inds, software, mac, round, inds.miss)
    indmiss.df <- indmiss.df %>% mutate_if(sapply(indmiss.df, is.factor), as.character)

    return(indmiss.df)
  }
}

lmiss.get <- function(lmiss.file) {
  # lmiss.file <- lmiss.files[35]
  miss.site <- fread(lmiss.file, stringsAsFactors = FALSE) %>%
    pull(F_MISS) %>%
    round(digits = 2)

  software <- ifelse(grepl('gatk', lmiss.file), 'gatk', 'ipyrad')
  assembly <- ifelse(grepl('mapped2mmur|refb_Mmur', lmiss.file), 'M2M',
                     ifelse(grepl('mapped2cmed|refb_Cmed', lmiss.file), 'M2C',
                            ifelse(grepl('denovo', lmiss.file), 'denovo', NA)))
  reads <- ifelse(grepl('R1', lmiss.file), 'R1',
                  ifelse(grepl('paired', lmiss.file), 'paired', NA))
  inds <- ifelse(grepl('Microcebus', lmiss.file), 'Mic',
                 ifelse(grepl('Cheirogaleus|Cmed', lmiss.file), 'Che',
                        ifelse(grepl('allInds', lmiss.file), 'all', NA)))
  runID <- paste0(software, '.', assembly, '.', reads, '.', inds)

  lmiss.df <- data.frame(runID, software, assembly, reads, inds, miss.site)
  lmiss.df <- lmiss.df %>% mutate_if(sapply(lmiss.df, is.factor), as.character)

  if(any(grepl('ipyrad.M2C.R1.NA', lmiss.df$runID)))
    lmiss.df$runID[which(lmiss.df$runID == 'ipyrad.M2C.R1.NA')] <- 'ipyrad.M2C.R1.Che'

  return(lmiss.df)
}

imiss.get <- function(imiss.file) {

  miss.ind <- fread(imiss.file) %>%
    select(INDV, F_MISS) %>%
    dplyr::rename(ID = INDV, miss.ind = F_MISS) %>%
    mutate(miss.ind = round(miss.ind, 3))

  software <- ifelse(grepl('gatk', imiss.file), 'gatk', 'ipyrad')
  assembly <- ifelse(grepl('mapped2mmur|refb_Mmur', imiss.file), 'M2M',
                     ifelse(grepl('mapped2cmed|refb_Cmed', imiss.file), 'M2C',
                            ifelse(grepl('denovo', imiss.file), 'denovo', NA)))
  reads <- ifelse(grepl('R1', imiss.file), 'R1',
                  ifelse(grepl('paired', imiss.file), 'paired', NA))
  inds <- ifelse(grepl('Microcebus', imiss.file), 'Mic',
                 ifelse(grepl('Cheirogaleus|Cmed', imiss.file), 'Che',
                        ifelse(grepl('allInds', imiss.file), 'all', NA)))
  runID <- paste0(software, '.', assembly, '.', reads, '.', inds)

  imiss.df <- cbind(miss.ind, runID, software, assembly, reads, inds) %>%
    select(runID, software, assembly, reads, inds, ID, miss.ind)

  imiss.df <- imiss.df %>% mutate_if(sapply(imiss.df, is.factor), as.character)

  imiss.df$ID <- gsub('\\.1\\.1$', '', imiss.df$ID)

  if(any(grepl('ipyrad.M2C.R1.NA', imiss.df$runID)))
    imiss.df$runID[which(imiss.df$runID == 'ipyrad.M2C.R1.NA')] <- 'ipyrad.M2C.R1.Che'

  return(imiss.df)
}

ldepth.get <- function(ldepth.file) {
  depth.site <- fread(ldepth.file) %>%
    select(MEAN_DEPTH, VAR_DEPTH) %>%
    rename(depth.mean = MEAN_DEPTH, depth.var = VAR_DEPTH)

  software <- ifelse(grepl('gatk', ldepth.file), 'gatk', 'ipyrad')
  assembly <- ifelse(grepl('mapped2mmur|refb_Mmur', ldepth.file), 'M2M',
                     ifelse(grepl('mapped2cmed|refb_Cmed', ldepth.file), 'M2C',
                            ifelse(grepl('denovo', ldepth.file), 'denovo', NA)))
  reads <- ifelse(grepl('R1', ldepth.file), 'R1',
                  ifelse(grepl('paired', ldepth.file), 'paired', NA))
  inds <- ifelse(grepl('Microcebus', ldepth.file), 'Mic',
                 ifelse(grepl('Cheirogaleus|Cmed', ldepth.file), 'Che',
                        ifelse(grepl('allInds', ldepth.file), 'all', NA)))
  runID <- paste0(software, '.', assembly, '.', reads, '.', inds)

  ldepth.df <- cbind(runID, software, assembly, reads, inds, depth.site)
  ldepth.df <- ldepth.df %>%  mutate_if(sapply(ldepth.df, is.factor), as.character)

  if(any(grepl('ipyrad.M2C.R1.NA', ldepth.df$runID)))
    ldepth.df$runID[which(ldepth.df$runID == 'ipyrad.M2C.R1.NA')] <- 'ipyrad.M2C.R1.Che'

  return(ldepth.df)
}

idepth.get <- function(idepth.file) {
  # idepth.file <- idepth.files[1]

  depth.site <- fread(idepth.file) %>%
    select(INDV, MEAN_DEPTH) %>%
    rename(ID = INDV, depth.mean = MEAN_DEPTH) %>%
    mutate(depth.mean = round(depth.mean, 3))

  software <- ifelse(grepl('gatk', idepth.file), 'gatk', 'ipyrad')
  assembly <- ifelse(grepl('mapped2mmur|refb_Mmur', idepth.file), 'M2M',
                     ifelse(grepl('mapped2cmed|refb_Cmed', idepth.file), 'M2C',
                            ifelse(grepl('denovo', idepth.file), 'denovo', NA)))
  reads <- ifelse(grepl('R1', idepth.file), 'R1',
                  ifelse(grepl('paired', idepth.file), 'paired', NA))
  inds <- ifelse(grepl('Microcebus', idepth.file), 'Mic',
                 ifelse(grepl('Cheirogaleus|Cmed', idepth.file), 'Che',
                        ifelse(grepl('allInds', idepth.file), 'all', NA)))
  runID <- paste0(software, '.', assembly, '.', reads, '.', inds)

  idepth.df <- cbind(runID, software, assembly, reads, inds, depth.site)
  idepth.df <- idepth.df %>%
    mutate_if(sapply(idepth.df, is.factor), as.character)

  idepth.df$ID <- gsub('\\.1\\.1$', '', idepth.df$ID)

  if(any(grepl('ipyrad.M2C.R1.NA', idepth.df$runID)))
    idepth.df$runID[which(idepth.df$runID == 'ipyrad.M2C.R1.NA')] <- 'ipyrad.M2C.R1.Che'

  return(idepth.df)
}

################################################################################
##### PLOTS DFs ######
################################################################################
lmiss.plot <- function(df, figfile.add, open.plot = FALSE) {
  #df <- lmiss.noFilter.df
  xlabs <- gsub('\\.', '\n', sort(unique(df$runID)))

  p <- ggplot(data = df) +
  geom_boxplot(aes(x = runID, y = miss.site, fill = assembly), outlier.colour = NA) +
  scale_y_continuous(expand = c(0, 0)) +
  scale_x_discrete(labels = xlabs) +
  labs(x = "", y = 'Proportion of missing genotypes per site') +
  theme_bw()

  figfile <- paste0('analyses/qc/compGeno/missingBySite_', figfile.add, '.png')
  ggsave(figfile, width = 9, height = 7)
  if(open.plot == TRUE) system(paste('xdg-open', figfile))
}

imiss.plot <- function(df, figfile.add, open.plot = FALSE) {
  xlabs <- gsub('\\.', '\n', sort(unique(df$runID)))

  p <- ggplot(data = df) +
    geom_boxplot(aes(x = runID, y = miss.ind, fill = assembly), outlier.colour = NA) +
    geom_jitter(aes(x = runID, y = miss.ind),
                width = 0.1, colour = 'grey30', size = 0.5) +
    scale_y_continuous(expand = c(0, 0)) +
    scale_x_discrete(labels = xlabs) +
    labs(x = "", y = 'Proportion of missing genotypes per individual') +
    theme_bw()

  figfile <- paste0('analyses/qc/compGeno/missingByInd_', figfile.add, '.png')
  ggsave(figfile, width = 9, height = 7)
  if(open.plot == TRUE) system(paste('xdg-open', figfile))
}

ldepth.plot <- function(df, figfile.add, open.plot = FALSE) {
  # df <- ldepth.df; figfile.add <- 'allFilters'

  xlabs <- gsub('\\.', '\n', sort(unique(df$runID)))

  ## Full y-axis:
  p <- ggplot(data = df) +
    geom_boxplot(aes(x = runID, y = depth.mean, fill = assembly)) +
    scale_x_discrete(labels = xlabs) +
    scale_y_continuous(expand = c(0, 0)) +
    labs(x = "", y = 'Mean depth per site') +
    theme_bw()

  figfile <- paste0('analyses/qc/compGeno/depthBySite_', figfile.add, '_noAxisLimits.png')
  ggsave(figfile, width = 9, height = 7)
  if(open.plot == TRUE) system(paste('xdg-open', figfile))

  ## No outliers:
  ymax <- max(boxplot.stats(df$depth.mean)$stats) * 1.1

  p <- ggplot(data = df) +
    geom_boxplot(aes(x = runID, y = depth.mean, fill = assembly), outlier.color = NA) +
    scale_x_discrete(labels = xlabs) +
    scale_y_continuous(expand = c(0, 0)) +
    labs(x = "", y = 'Mean depth per site') +
    theme_bw() +
    coord_cartesian(ylim = c(0, ymax))

  figfile <- paste0('analyses/qc/compGeno/depthBySite_', figfile.add, '.png')
  ggsave(figfile, width = 9, height = 7)
  if(open.plot == TRUE) system(paste('xdg-open', figfile))
}

idepth.plot <- function(df, figfile.add, open.plot = FALSE) {
  xlabs <- gsub('\\.', '\n', sort(unique(df$runID)))

  p <- ggplot(data = df) +
    geom_boxplot(aes(x = runID, y = depth.mean, fill = assembly), outlier.colour = NA) +
    geom_jitter(aes(x = runID, y = depth.mean),
                width = 0.1, colour = 'grey30', size = 0.5) +
    scale_x_discrete(labels = xlabs) +
    scale_y_continuous(expand = c(0, 0)) +
    labs(x = "", y = 'Mean depth per individual') +
    theme_bw()

  figfile <- paste0('analyses/qc/compGeno/depthByInd_', figfile.add, '.png')
  ggsave(figfile, width = 9, height = 7)
  if(open.plot == TRUE) system(paste('xdg-open', figfile))
}

##### BY-IND STATS ######
## Creating summary df:
sumr.df.get <- function(lmiss.df, imiss.df, ldepth.df) {

  if(!is.null(lmiss.df)) {
    sumr.site <- lmiss.df %>%
      group_by(runID) %>%
      summarise(miss.site.mean = round(mean(miss.site), 3))
  }

  sumr.ind <- imiss.df %>%
    group_by(runID) %>%
    summarise(nrInds = n())

  sumr.depth <- ldepth.df %>%
    group_by(runID) %>%
    summarise(nrSNPs = n(), depth.mean = round(mean(depth.mean), 2)) %>%
    mutate(depth.summed = round(nrSNPs * depth.mean))

  if(!is.null(lmiss.df))
    sumr <- merge(sumr.depth, merge(sumr.site, sumr.ind, by = 'runID'), by = 'runID')
  if(is.null(lmiss.df)) {
    sumr <- merge(sumr.depth, sumr.ind, by = 'runID')
    sumr$miss.site.mean <- NA
  }

  sumr$inds <- ifelse(grepl('M2M|Mic', sumr$runID), 'Mic',
                      ifelse(grepl('M2C|Che', sumr$runID), 'Che',
                             ifelse(grepl('all', sumr$runID), 'all', NA)))
  sumr$assembly <- ifelse(grepl('M2M', sumr$runID), 'M2M',
                          ifelse(grepl('M2C', sumr$runID), 'M2C',
                                 ifelse(grepl('denovo', sumr$runID), 'denovo', NA)))
  sumr$nrInds.all <- ifelse(sumr$inds == 'Mic', nrMic,
                            ifelse(sumr$inds == 'Che', nrChe,
                                   ifelse(sumr$inds == 'all', nrAll, NA)))

  sumr <- sumr %>% select(runID, inds, nrInds.all, nrInds,
                          nrSNPs, depth.mean, depth.summed, miss.site.mean)

  return(sumr)
}

## Collect stats by ind:
istats.df.get <- function(imiss.df, idepth.df, sumr.df) {
  imiss.df$nrSNPs.total <- sumr.df$nrSNPs[match(imiss.df$runID, sumr.df$runID)]
  imiss.df <- imiss.df %>%
    mutate(nrSNPs.ind = round((1 - miss.ind) * nrSNPs.total))

  istats <- merge(imiss.df, idepth.df,
                  by = c('runID', 'ID', 'software', 'assembly', 'reads', 'inds'))

  return(istats)
}

## Plots by ind:
istats.plots <- function(istats.df, sumr.df, figfile.add, open.plot = FALSE) {
  xlabs <- gsub('\\.', '\n', sort(unique(istats.df$runID)))

  p <- ggplot(data = istats.df) +
    geom_boxplot(aes(x = runID, y = nrSNPs.ind, fill = assembly), outlier.colour = NA) +
    geom_jitter(aes(x = runID, y = nrSNPs.ind),
                width = 0.2, colour = 'grey30', size = 0.4) +
    scale_x_discrete(labels = xlabs) +
    scale_y_continuous(expand = c(0, 0)) +
    labs(x = "", y = 'Number of SNPs', title = figfile.add) +
    theme_bw()
  figfile <- paste0('analyses/qc/compGeno/nrSNPs_', figfile.add, '.png')
  ggsave(figfile, width = 9, height = 7)
  if(open.plot == TRUE) system(paste('xdg-open', figfile))

  ## Plot nr SNPs * mean depth:
  p <- ggplot(data = istats.df) +
    geom_boxplot(aes(x = runID, y = (depth.mean * nrSNPs.ind) / 1000000,
                     fill = assembly), outlier.size = 0) +
    geom_jitter(aes(x = runID, y = (depth.mean * nrSNPs.ind) / 1000000),
                width = 0.2, colour = 'grey30', size = 0.4) +
    scale_x_discrete(labels = xlabs) +
    scale_y_continuous(expand = c(0, 0)) +
    labs(x = "", y = 'Nr SNPs * mean depth (in M) -- per indv', title = figfile.add) +
    theme_bw()
  figfile <- paste0('analyses/qc/compGeno/nrSNPsXdepth_byInd_', figfile.add, '.png')
  ggsave(figfile, width = 9, height = 7)
  if(open.plot == TRUE) system(paste('xdg-open', figfile))

  ## Plot proportion of inds passed:
  p <- ggplot(data = sumr.df) +
    geom_col(aes(x = runID, y = nrInds / nrInds.all, fill = inds)) +
    scale_x_discrete(labels = xlabs) +
    labs(x = "", y = 'Proportion of inds passed', title = 'allFilters') +
    scale_y_continuous(expand = c(0, 0), limits = c(0, 1)) +
    theme_bw()
  figfile <- paste0('analyses/qc/compGeno/propIndsPassed_', figfile.add, '.png')
  ggsave(figfile, width = 9, height = 7)
  if(open.plot == TRUE) system(paste('xdg-open', figfile))
}


## Correlate per-ind nr of SNPs across approaches:
plot.combrow <- function(combrow, figfile.add) {
  # combrow <- 22

  x.ID <- combs[combrow, 1]
  y.ID <- combs[combrow, 2]
  x.attr <- unlist(strsplit(x.ID, split = '\\.'))[1:3]
  y.attr <- unlist(strsplit(y.ID, split = '\\.'))[1:3]

  skip <- FALSE
  #if(grepl('M2M', x.ID) & grepl('M2C', y.ID)) skip <- TRUE
  #if(grepl('M2C', x.ID) & grepl('M2M', y.ID)) skip <- TRUE
  if(sum(x.attr == y.attr) != 2) skip <- TRUE

  x.diff <- x.attr[which(x.attr != y.attr)]
  y.diff <- y.attr[which(x.attr != y.attr)]

  if(!any(!is.na(istats.wide[, x.ID]) & !is.na(istats.wide[, y.ID]))) skip <- TRUE
  #if(skip == TRUE) cat(combrow, '...skipping\n')

  istats.wide[which(is.na(istats.wide[, x.ID]) & !is.na(istats.wide[, y.ID])), x.ID] <- 0
  istats.wide[which(is.na(istats.wide[, y.ID]) & !is.na(istats.wide[, x.ID])), y.ID] <- 0

  if(skip == FALSE) {
    corr <- round(cor(istats.wide[, x.ID], istats.wide[, y.ID], use = 'complete.obs'), 3)
    cat('Plotting:', combrow, x.ID, y.ID, '...correlation:', corr, '\n')

    failed.x <- istats.wide$ID[which(istats.wide[, x.ID] == 0 & istats.wide[, y.ID] > 0)]
    failed.y <- istats.wide$ID[which(istats.wide[, y.ID] == 0 & istats.wide[, x.ID] > 0)]

    bad.x <- istats.wide$ID[which(istats.wide[, x.ID] < 0.1 * median(istats.wide[, x.ID], na.rm = TRUE))]
    bad.y <- istats.wide$ID[which(istats.wide[, y.ID] < 0.1 * median(istats.wide[, y.ID], na.rm = TRUE))]

    bad.x.remain <- bad.x[which(! bad.x %in% failed.x)]
    bad.y.remain <- bad.y[which(! bad.y %in% failed.y)]

    cat(x.ID, '\n\tfailed:', failed.x, '\n\tpoor:', bad.x.remain, '\n\n')
    cat(y.ID, '\n\tfailed:', failed.y, '\n\tpoor:', bad.y.remain, '\n\n')

    max.x <- max(istats.wide[, x.ID], na.rm = TRUE) +
      (0.05 * max(istats.wide[, x.ID], na.rm = TRUE))
    max.y <- max(istats.wide[, y.ID], na.rm = TRUE) +
      (0.05 * max(istats.wide[, y.ID], na.rm = TRUE))

    p <- ggplot(istats.wide) +
      geom_point(aes_string(x = x.ID, y = y.ID, colour = 'inds')) +
      labs(x = paste0(x.ID, ': n SNPs'),
           y = paste0(y.ID, ': n SNPs'),
           title = paste0(x.ID, ' vs ', y.ID, '\n', x.diff, ' vs ', y.diff)) +
      scale_x_continuous(limits = c(0, max.x)) +
      scale_y_continuous(limits = c(0, max.y)) +
      theme_bw() +
      theme(plot.title = element_text(hjust = 0.5),
            legend.position = 'top') +
      annotate('text', label = paste0('correlation: ', corr),
               x = max.x / 2, y = max.y)

    filename <- paste0('analyses/qc/compGeno/nrSNPs/nrSNPs_',
                       x.ID, '__', y.ID, '_', figfile.add, '.png')
    ggsave(filename, p, width = 6, height = 6)
  }
}



##### STAT MODELS #####
runModel1 <- function(resp.var, df, runID,
                      plotdir = 'analyses/qc/compGeno/byRunID/') {
  #resp.var <- "miss.ind"

  single.genus <- ifelse(length(unique(df$genus)) == 1, TRUE, FALSE)

  resp.var.data <- df %>% pull(resp.var)
  reads.passed <- df$reads.passed
  resp.var.nls <- nls(formula = resp.var.data ~ a * reads.passed / (b + reads.passed),
                     start = list(a = 1000, b = 1000))

  png(paste0(plotdir, '/', runID, '_model_', resp.var, '.png'))
  plot(reads.passed, resp.var.data, las = 1, main = resp.var)
  lines(reads.passed, fitted(resp.var.nls), col = "red", lty = 2, lwd = 3)
  dev.off()

  df$resp.var.resid <- resid(resp.var.nls)

  if(single.genus == "FALSE")
    resid.lm <- lm(resp.var.resid ~ genus + library + barcode + DNAtype + plate +
                     DNAconcNew + DNAconcOld, data = df)
  if(single.genus == "TRUE")
    resid.lm <- lm(resp.var.resid ~ library + barcode + DNAtype + plate +
                     DNAconcNew + DNAconcOld, data = df)
  anova.res <- anova(resid.lm)
  anova.filename <- paste0(plotdir, '/', runID, '_anova_viaNLS.txt')
  write.table(anova.res, anova.filename, sep = '\t', quote = FALSE)

  signif <- rownames(anova.res)[which(anova.res$`Pr(>F)` < 0.05)]
  signif.value <- anova.res$`Pr(>F)`[which(anova.res$`Pr(>F)` < 0.05)]
  cat(paste("\nSignificant factors for sample performance of", resp.var, ":\n",
            signif, round(signif.value, 5)))
}

runModel2 <- function(resp.var, df, runID,
                      plotdir = 'analyses/qc/compGeno/byRunID/') {
  #resp.var <- "miss.ind"

  cat(resp.var, '\n')

  single.genus <- ifelse(length(unique(df$genus)) == 1, TRUE, FALSE)

  df$resp.var <- df %>% pull(resp.var)

  if(single.genus == "FALSE")
    resid.lm <- lm(resp.var ~ genus + library + barcode + DNAtype + plate +
                     reads.passed + DNAconcNew + DNAconcOld, data = df)
  if(single.genus == "TRUE")
    resid.lm <- lm(resp.var ~ library + barcode + DNAtype + plate +
                     reads.passed + DNAconcNew + DNAconcOld, data = df)
  anova.res <- anova(resid.lm)
  anova.filename <- paste0(plotdir, '/', runID, '_anova_direct.txt')
  write.table(anova.res, anova.filename, sep = '\t', quote = FALSE)

  signif <- rownames(anova.res)[which(anova.res$`Pr(>F)` < 0.05)]
  signif.value <- anova.res$`Pr(>F)`[which(anova.res$`Pr(>F)` < 0.05)]
  cat(paste("\nSignificant factors for sample performance of", resp.var, ":\n",
            signif, round(signif.value, 5)))
  cat('\n\n')
}

plot.vars <- function(df, runID, expl.var = 'DNAtype',
                      resp.vars = c('nrSNPs.ind', 'depth.mean', 'miss.ind'),
                      plotdir) {
  # df <- istats; runID <- 'gatk.M2M.R1.Mic'
  # expl.var = 'DNAtype'; resp.vars = c('nrSNPs.ind', 'depth.mean', 'miss.ind')

  df <- subset(df, !(is.na(df[, expl.var])))

  for(resp.var in resp.vars) {
    # resp.var <- resp.vars[1]
    cat('Plotting', resp.var, '\n')

    p <- ggplot(data = df) +
      geom_boxplot(aes_string(x = expl.var, y = resp.var), outlier.colour = NA) +
      geom_jitter(aes_string(x = expl.var, y = resp.var), width = 0.1)
    filename <- paste0(plotdir, '/', runID, '_', expl.var, '-vs-', resp.var, '_boxplot.png')
    ggsave(filename, p, width = 6, height = 5)
    if(open.plots == TRUE) system(paste('xdg-open', filename))

    p <- ggplot(data = df) +
      geom_point(aes_string(x = "reads.passed", y = resp.var, colour = expl.var)) +
      labs(x = "Nr of reads", y = resp.var, title = runID)
    filename <- paste0(plotdir, '/', runID, '_', resp.var, '-vs-nrReads_by', expl.var, '.png')
    ggsave(filename, p, width = 6, height = 5)
    if(open.plots == TRUE) system(paste('xdg-open', filename))
  }
}

checkVariables <- function(frunID, istats = istats_merged.df, expl.var = 'DNAtype',
                           resp.vars = c('nrSNPs.ind', 'depth.mean', 'miss.ind')) {
  #frunID <- runID <- 'gatk.M2M.R1.Mic'; istats <- istats_merged.df
  cat(frunID, '\n')

  plotdir <- paste0('analyses/qc/compGeno/check-', expl.var, '/')

  istats <- istats %>%
    filter(runID == frunID) %>%
    arrange(reads.passed)

  ## Model for nr of SNPs:
  #aap <- sapply(resp.vars, runModel1, df = istats, runID = frunID)
  #aap <- sapply(c('nrSNPs.ind', 'depth.mean'), runModel1, df = istats, runID = frunID)
  aap <- sapply(resp.vars, runModel2, df = istats, runID = frunID, plotdir = plotdir)

  ## Plots:
  plot.vars(istats, runID = frunID, plotdir = plotdir)
}


nrOfReadsCorr.plots <- function(resp.var) {
  # resp.var <- 'nrSNPs.ind'

  f.assembly <- 'M2C'; f.software <- 'gatk'
  df <- istats_merged.df %>% filter(software == f.software, assembly == f.assembly)
  p <- ggplot(data = df) +
    geom_point(aes_string(x = "reads.passed", y = resp.var, colour = "reads")) +
    labs(x = "Nr of reads", y = resp.var, title = paste0(f.software, '_', f.assembly))
  filename <- paste0('analyses/qc/compGeno/nrReads-vs-', resp.var, '_',
                     f.assembly, '.', f.software, '_', filter.setting, '.png')
  ggsave(filename, p, width = 6, height = 5)

  f.assembly <- 'M2M'; f.software <- 'gatk'
  df <- istats_merged.df %>% filter(software == f.software, assembly == f.assembly)
  p <- ggplot(data = df) +
    geom_point(aes_string(x = "reads.passed", y = resp.var, colour = "reads")) +
    labs(x = "Nr of reads", y = resp.var, title = paste0(f.software, '_', f.assembly))
  filename <- paste0('analyses/qc/compGeno/nrReads-vs-', resp.var, '_',
                     f.assembly, '.', f.software, '_', filter.setting, '.png')
  ggsave(filename, p, width = 6, height = 5)

  f.assembly <- 'M2M'; f.reads <- 'R1'
  df <- istats_merged.df %>% filter(reads == f.reads, assembly == f.assembly)
  p <- ggplot(data = df) +
    geom_point(aes_string(x = "reads.passed", y = resp.var, colour = "software")) +
    labs(x = "Nr of reads", y = resp.var, title = paste0(f.reads, '_', f.assembly))
  filename <- paste0('analyses/qc/compGeno/nrReads-vs-', resp.var, '_',
                     f.assembly, '.', f.reads, '_', filter.setting, '.png')
  ggsave(filename, p, width = 6, height = 5)

  f.assembly <- 'M2C'; f.reads <- 'R1'
  df <- istats_merged.df %>% filter(reads == f.reads, assembly == f.assembly)
  p <- ggplot(data = df) +
    geom_point(aes_string(x = "reads.passed", y = resp.var, colour = "software")) +
    labs(x = "Nr of reads", y = resp.var, title = paste0(f.reads, '_', f.assembly))
  filename <- paste0('analyses/qc/compGeno/nrReads-vs-', resp.var, '_',
                     f.assembly, '.', f.reads, '_', filter.setting, '.png')
  ggsave(filename, p, width = 6, height = 5)
}
