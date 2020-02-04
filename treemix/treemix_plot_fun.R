## Packages:
suppressPackageStartupMessages(library(extRemes)) # Likelihood-ratio test
suppressPackageStartupMessages(library(tidyverse))

## Set theme:
my_theme <- theme_bw(base_size = 12) %+replace%
  theme(panel.grid.minor = element_blank(),
        legend.background = element_rect(colour = 'grey30', size = 0.25),
        legend.box.margin = margin(0, 0, 0, 0),
        legend.key.size = unit(0.2, "cm"),
        legend.title = element_text(size = 10))
theme_set(my_theme)

#### PLOT TREE FIGURE ----------------------------------------------------------
treeplot <- function(nmig,
                     fileID,
                     root = TRUE,
                     outdir = 'output',
                     figdir = 'figures',
                     my_cex = 1.2,
                     my_lwd  = 3, my_arrow = 0.1,
                     my_xmax = NULL,
                     png_background = 'white', #png_background = 'transparent',
                     filetype = 'png',
                     openfig = FALSE,
                     ...) {

  if(!dir.exists(figdir)) dir.create(figdir)

  treemix_output <- paste0(outdir, '/', fileID,
                        '.treemixOutput.k1000.mig', nmig, '.root', root)
  figfile <- paste0(figdir, '/', fileID, '.nmig', nmig,
                        '.root', root, '.', filetype)

  if(filetype == 'eps') {
    setEPS()
    postscript(figfile, width = 6.5, height = 6.5)
  }
  if(filetype == 'png') png(figfile, width = 6.5, height = 6.5,
                            units = 'in', res = 200, bg = png_background)
  if(filetype == 'pdf') pdf(figfile, width = 6.5, height = 6.5)

  par(mar = c(5, 1, 1, 4))

  ## Use plot_tree function from Treemix script:
  if(!is.null(my_xmax))
    p <- plot_tree(stem = treemix_output,
                   mbar = FALSE, scale = FALSE,
                   cex = my_cex, lwd = my_lwd, arrow = my_arrow,
                   xmax = my_xmax, ...)
  if(is.null(my_xmax))
    p <- plot_tree(stem = treemix_output,
                   mbar = FALSE, scale = FALSE,
                   cex = my_cex, lwd = my_lwd, arrow = my_arrow, ...)
  # scale = FALSE removes s.e. scale
  # mbar = FALSE removes colour heatmap

  dev.off()

  if(openfig == TRUE) system(paste("xdg-open", figfile))

  return(p)
}


#### LIKELIHOODS ---------------------------------------------------------------
## Get likelihoods:
llh_line_get <- function(nmig, llh_files) {
  cat('Nr of migration events:', nmig, '\n')

  llh.file <- llh_files[grep(paste0('mig', nmig, '.root'), llh_files)]
  llh.line <- tail(readLines(llh.file), n = 1)
  llh <- as.numeric(gsub(".*events: ", "", llh.line))

  return(data.frame(nmig, llh))
}

llh_get <- function(fileID, root, nmig_vec = 0:20, outdir = 'output',
                    write_table = TRUE) {
  llh_files <- list.files(outdir, full.names = TRUE,
                          pattern = paste0(fileID, '.treemix.*root', root, '.*llik'))

  llh_df <- do.call(rbind,
                    lapply(nmig_vec, llh_line_get, llh_files = llh_files))

  lrtest_res <- do.call(rbind, lapply(1:(nrow(llh_df) - 1), lrtest, llh_df))
  cat('## Likelihood ratio test: \n')
  print(lrtest_res)

  ## Save LRT result:
  if(write_table == TRUE) {
    lrtest_file <- paste0('LRT/', fileID, '_LRT_nmig.txt')
    write.table(lrtest_res, lrtest_file,
              sep = '\t', quote = FALSE, row.names = FALSE)
  }

  ## llh df:
  llh_df <- merge(llh_df, lrtest_res[, c('nmig1', 'pval')],
                  by.x = 'nmig', by.y = 'nmig1', all.x = TRUE)
  llh_df$pval[1] <- 1
  llh_df$sig <- ifelse(llh_df$pval < 0.05, 'yes', 'no')

  return(llh_df)
}

## Plot likelihoods:
llh_plot <- function(llh_df, fileID,
                     savefig = TRUE, openfig = TRUE,
                     figdir = 'figures') {

  p <- ggplot(data = llh_df) +
    geom_point(aes(x = nmig, y = llh, colour = sig)) +
    geom_line(aes(x = nmig, y = llh), colour = "grey40") +
    labs(x = 'Number of migration events', y = 'likelihood') +
    scale_x_continuous(breaks = 0:10) +
    scale_color_manual(name = 'LRT p-value',
                       values = c('black','red'),
                       labels = c('p>0.05', 'p<0.05')) +
    theme(legend.position = 'top')

  if(savefig == TRUE) {
    figfile <- paste0(figdir, '/', fileID, '_likelihoods.png')
    ggsave(figfile, p, width = 5, height = 5)
    if(openfig == TRUE) system(paste("xdg-open", figfile))
  }
  return(p)
}

## Likelihood-ratio test:
lrtest <- function(n, llh) {
  comp <- lr.test(llh$llh[n + 1], llh$llh[n], df = 1)
  result <- data.frame(nmig1 = n,
                       nmig2 = n - 1,
                       statistic = comp$statistic,
                       pval = comp$p.value,
                       row.names = NULL)
  return(result)
}


#### PROPORTION OF VARIANCE EXPLAINED ------------------------------------------
propvar_get_single <- function(nmig, fileID, outdir, root) {
  stem_focal <- paste0(outdir, '/',
                       fileID, '.treemixOutput.k1000.mig', nmig, '.root', root)
  propvar <- get_f(stem = stem_focal)
  return(c(nmig, propvar))
}

propvar_get <- function(fileID, outdir, root, nmig_max = 10) {
  propvar_df <- sapply(0:nmig_max, propvar_get_single,
                       fileID = fileID, outdir = outdir, root = root)
  propvar_df <- data.frame(t(propvar_df))
  colnames(propvar_df) = c('nmig', 'propvar')
  return(propvar_df)
}

propvar_plot <- function(propvar_df, fileID,
                         savefig = TRUE, openfig = TRUE,
                         figdir = 'figures') {

  p <- ggplot(data = propvar_df) +
    geom_point(aes(x = nmig, y = propvar)) +
    geom_line(aes(x = nmig, y = propvar), colour = "grey40") +
    labs(x = 'Number of migration events', y = 'Prop. of variance explained') +
    scale_x_continuous(breaks = 0:10) +
    theme(panel.grid.major.x = element_blank())

  if(savefig == TRUE) {
    figfile <- paste0(figdir, '/', fileID, '_propvar.png')
    ggsave(figfile, p, width = 5, height = 5)
    if(openfig == TRUE) system(paste("xdg-open", figfile))
  }

  return(p)
}


#### PLOT RESIDUALS ------------------------------------------------------------
resid_plot <- function(nmig, fileID, poporder_file, outdir,
                       figdir, openfig = TRUE) {

  stem_focal <- paste0(outdir, '/', fileID, '.treemixOutput.k1000.mig',
                       nmig, '.root', root)

  figfile <- paste0(figdir, '/', fileID, '.nmig', nmig, '_residuals.png')
  png(figfile, width = 6.5, height = 6.5, units = 'in', res = 200)
  plot_resid(stem_focal, pop_order = poporder_file)
  dev.off()

  if(openfig == TRUE) system(paste("xdg-open", figfile))
}
