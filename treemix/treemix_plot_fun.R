################################################################################
#### PLOT TREE FIGURE ####
################################################################################
plot.tree <- function(nmig,
                      file.ID,
                      root = TRUE,
                      dir.output = 'output',
                      dir.fig = 'figures',
                      my.xmax = NULL,
                      png.background = 'transparent',
                      filetype = 'eps',
                      file.open = FALSE) {

  if(!dir.exists(dir.fig)) dir.create(dir.fig)

  treemix.out <- paste0(dir.output, '/', file.ID,
                        '.treemixOutput.k1000.mig', nmig, '.root', root)
  figure.file <- paste0(dir.fig, '/', file.ID, '.nmig', nmig,
                        '.root', root, '.', filetype)

  if(filetype == 'eps') {
    setEPS()
    postscript(figure.file, width = 6.5, height = 6.5)
  }
  if(filetype == 'png') png(figure.file, width = 6.5, height = 6.5, units = 'in', res = 200, bg = png.background)
  if(filetype == 'pdf') pdf(figure.file, width = 6.5, height = 6.5)

  par(mar = c(5, 1, 1, 4))
  if(!is.null(my.xmax)) p <- plot_tree(stem = treemix.out,
                                       mbar = FALSE,
                                       scale = FALSE,
                                       cex = 1,
                                       lwd = 2,
                                       xmax = my.xmax)
  if(is.null(my.xmax)) p <- plot_tree(stem = treemix.out,
                                      mbar = FALSE,
                                      scale = FALSE,
                                      cex = 1,
                                      lwd = 2)
  # scale = FALSE removes s.e. scale; mbar = FALSE removes colour heatmap

  dev.off()

  if(file.open == TRUE) system(paste("xdg-open", figure.file))

  return(p)
}


################################################################################
#### LIKELIHOODS ####
################################################################################
## Get likelihoods:
get.llh.line <- function(nmig, llh.files) {
  cat('Nr of migration events:', nmig, '\n')

  llh.file <- llh.files[grep(paste0('mig', nmig, '.root'), llh.files)]
  llh.line <- tail(readLines(llh.file), n = 1)
  llh <- as.numeric(gsub(".*events: ", "", llh.line))

  return(data.frame(nmig, llh))
}

get.llh.df <- function(file.ID, root, nmig.vector = 0:20, dir.output = 'output') {
  llh.files <- list.files(dir.output, full.names = TRUE,
                          pattern = paste0(file.ID, '.treemix.*root', root, '.*llik'))

  llh.df <- do.call(rbind,
                    lapply(nmig.vector, get.llh.line, llh.files = llh.files))

  lrtest.res <- do.call(rbind, lapply(1:(nrow(llh.df) - 1), lrtest, llh.df))
  cat('Likelihood ratio test: \n')
  print(lrtest.res)
  lrtest.file <- paste0('LRT/', file.ID, 'LRT_nrMigEvents.txt')
  write.table(lrtest.res, lrtest.file,
              sep = '\t', quote = FALSE, row.names = FALSE)

  llh.df <- merge(llh.df, lrtest.res[, c('nmig1', 'pval')],
                  by.x = 'nmig', by.y = 'nmig1', all.x = TRUE)
  llh.df$pval[1] <- 1

  llh.df$sig <- ifelse(llh.df$pval < 0.05, 'yes', 'no')

  return(llh.df)
}

## Plot likelihoods:
plot.llh <- function(llh.df, file.ID, dir.fig = 'figures', file.open = TRUE) {

  p <- ggplot(data = llh.df) +
    geom_point(aes(x = nmig, y = llh, colour = sig)) +
    geom_line(aes(x = nmig, y = llh), colour = "grey40") +
    labs(x = 'Number of migration events', y = 'likelihood') +
    scale_x_continuous(breaks = 0:10) +
    scale_color_manual(name = 'LRT p-value',
                       values = c('black','red'),
                       labels = c('p>0.05', 'p<0.05')) +
    theme(legend.position = 'top')

  figfile <- paste0(dir.fig, '/', file.ID, '_likelihoods.png')
  ggsave(figfile, p, width = 5, height = 5)

  if(file.open == TRUE) system(paste("xdg-open", figfile))
  print(p)
  return(p)
}

## Likelihood-ratio test:
library(extRemes)
lrtest <- function(n, llh) {
  comp <- lr.test(llh$llh[n + 1], llh$llh[n], df = 1)
  result <- data.frame(nmig1 = n,
                       nmig2 = n - 1,
                       statistic = comp$statistic,
                       pval = comp$p.value,
                       row.names = NULL)
  return(result)
}


################################################################################
#### PROPORTION OF VARIANCE EXPLAINED ####
################################################################################
get.propVar <- function(nmig, file.ID, dir.output, root) {
  stem.focal <- paste0(dir.output, '/',
                       file.ID, '.treemixOutput.k1000.mig', nmig, '.root', root)
  propVar <- get_f(stem = stem.focal)
  return(c(nmig, propVar))
}

get.propVar.df <- function(file.ID, dir.output, root, nmig.max = 10) {
  propVar.df <- sapply(0:nmig.max, get.propVar,
                       file.ID = file.ID, dir.output = dir.output, root = root)
  propVar.df <- data.frame(t(propVar.df))
  colnames(propVar.df) = c('nmig', 'propVar')
  return(propVar.df)
}

plot.propVar <- function(propVar.df, file.ID,
                         dir.fig = 'figures', file.open = TRUE) {

  p <- ggplot(data = propVar.df) +
    geom_point(aes(x = nmig, y = propVar)) +
    geom_line(aes(x = nmig, y = propVar), colour = "grey40") +
    labs(x = 'Number of migration events', y = 'Prop. of variance explained') +
    scale_x_continuous(breaks = 0:10)

  figfile <- paste0(dir.fig, '/', file.ID, '_propVar.png')
  ggsave(figfile, p, width = 5, height = 5)

  if(file.open == TRUE) system(paste("xdg-open", figfile))
  print(p)
  return(p)
}


################################################################################
#### PLOT RESIDUALS ####
################################################################################
plot.residuals <- function(nmig, file.ID, poporder.file,
                           dir.output, dir.figs, file.open = TRUE) {
  stem.focal <- paste0(dir.output, '/', file.ID, '.treemixOutput.k1000.mig',
                       nmig, '.root', root)

  figure.file <- paste0(dir.fig, '/', file.ID, '.nmig', nmig, '_residuals.png')
  png(figure.file, width = 6.5, height = 6.5, units = 'in', res = 200)
  plot_resid(stem.focal, pop_order = poporder.file)
  dev.off()

  if(file.open == TRUE) system(paste("xdg-open", figure.file))
}
