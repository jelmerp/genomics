## Functions to process bcftools stats output:

#### PLOTS ---------------------------------------------------------------------
## Plot depth distribution:
plot.depth.dist <- function(df, plotdir, fileID = NULL) {
  p <- ggplot(data = df)
  p <- p + geom_line(aes(x = DP, y = percent, colour = ID),
                     size = 2, linetype = 'solid')
  p <- p + scale_x_continuous(limits = c(0, 10), expand = c(0, 0))
  p <- p + scale_y_continuous(expand = c(0, 0))
  p <- p + theme(legend.position = "right")
  p <- p + theme_bw()
  p <- p + theme(axis.text.x = element_text(size = 16),
                 axis.text.y = element_text(size = 18),
                 axis.title.x = element_text(size = 18),
                 axis.title.y = element_text(size = 18))
  p <- p + theme(plot.title = element_text(size = 18, hjust = 2))
  p <- p + theme(legend.title = element_text(size = 16, face = 'bold'),
                 legend.text = element_text(size = 16))

  filename <- paste0(plotdir, '/bcftoolsStats_DepthDist', fileID, '.png')
  ggsave(filename, p, height = 6, width = 8)

  return(p)
}

## Plot depth:
plot.depth <- function(df, figdir, fileID, ID.start, nr.IDs,
                       save.plot = TRUE, legend = TRUE, open.plot = TRUE) {
  # ID.start = 1; nr.IDs = 50; save.plot = TRUE

  if(save.plot == TRUE) {
    filename <- paste0(figdir, '/', fileID, '_depth_', ID.start, '.png')
    png(filename)
  }
  par(mar = c(5.1, 7, 4.1, 2.1))
  ID.range <- rev(ID.start:(ID.start + nr.IDs - 1))
  barplot(df$depth[ID.range], names.arg = df$ID[ID.range],
          space = 1, horiz = TRUE, las = 1, cex.names = 0.7,
          main = "Depth")
  if(save.plot == TRUE) dev.off()
  if(open.plot == TRUE) system(paste('xdg-open', filename))
}

## Plot nr of non-reference bases:
plot.muts <- function(df, figdir, fileID, ID.start, nr.IDs,
                      save.plot = TRUE, legend = TRUE, open.plot = TRUE) {
  # ID.start = 1; nr.IDs = 50; save.plot = TRUE

  if(save.plot == TRUE) {
    filename <- paste0(figdir, '/', fileID, '_nrMut_', ID.start, '.png')
    png(filename)
  }
  par(mar = c(5.1, 7, 4.1, 2.1))
  ID.range <- rev(ID.start:(ID.start + nr.IDs - 1))
  to.plot <- rbind(df$nRefHom[ID.range] / 1000000,
                   df$nNonRefHom[ID.range] / 1000000,
                   df$nHets[ID.range] / 1000000)
  barplot(to.plot, names.arg = df$ID[ID.range],
          col = c('gray80', 'gray50', 'gray30'),
          space = 1, horiz = TRUE, las = 1, cex.names = 0.7,
          main = 'Ref hom, non-ref hom, and hets',
          xlab = 'number of positions (in millions)')
  if(legend == TRUE) legend("topleft", cex = 0.8, title = "Position type",
                            legend = c("ref. hom.", "non-ref. hom.", "het."),
                            fill = c('gray80', 'gray50', 'gray30'))
  if(save.plot == TRUE) dev.off()
  if(open.plot == TRUE) system(paste('xdg-open', filename))
}

## Plot the number of proper pairs
plot.goodpairs <- function(plotdata,
                           TitleIsSpecies = FALSE,
                           saveplot = TRUE,
                           FilenameIsSpecies = FALSE,
                           filename = 'aap') {

  plot.title <- NULL
  if(TitleIsSpecies == TRUE) plot.title <- unique(plotdata$sp.long)

  ymax <- ifelse(max(plotdata$value) < 10000000, 10, 1.1 * (max(plotdata$value) / 1000000 ))

  plotdata$ID <- factor(plotdata$ID)

  p <- ggplot(data = plotdata)
  p <- p + geom_col(aes(ID, value / 1000000), colour = 'grey20')

  p <- p + geom_hline(yintercept = median.global / 1000000, colour = 'grey20', linetype = 'dashed')
  p <- p + geom_hline(yintercept = median(plotdata$value) / 1000000, colour = 'grey20')

  p <- p + coord_flip()

  p <- p + labs(y = 'Nr of read pairs (in millions)')
  if(!is.null(plot.title)) p <- p + labs(title = plot.title)
  p <- p + theme_bw()
  p <- p + theme(axis.text.x = element_text(size = 15),
                 axis.text.y = element_text(size = 10),
                 axis.title.x = element_text(size = 18),
                 axis.title.y = element_blank(),
                 plot.title = element_text(size = 20, face = 'italic', hjust = 0.5),
                 plot.margin = margin(0.5, 1, 0.5, 0.5, "cm"))
  p <- p + scale_x_discrete(limits = rev(levels(plotdata$ID)))
  p <- p + scale_y_continuous(expand = c(0, 0), limits = c(0, ymax))

  if(saveplot == TRUE) {
    if(FilenameIsSpecies == TRUE) filename <- unique(plotdata$sp.short)
    filename.full <- paste0('analyses/qc/figures/', filename, '.png')
    cat('Saving file as', filename.full, '\n')
    ggsave(filename.full, p, width = 7, height = 7)
  }

  print(p)
  return(p)
}

## Plot read pair status proportions:
plot.props <- function(plotdata) {
  p <- ggplot(data = plotdata) + geom_col(aes(ID, value, fill = variable))
  p <- p + scale_fill_manual(name = 'Read pair status',
                             values = rev(c('black', 'orangered4', 'orchid4', 'darkgreen')),
                             labels = c('Both OK', 'Forward OK', 'Reverse OK', 'Neither OK'))
  p <- p + coord_flip()
  p <- p + labs(y = 'Proportion of read pairs')
  p <- p + theme_bw()
  p <- p + theme(axis.text.x = element_text(size = 15),
                 axis.text.y = element_text(size = 10),
                 axis.title.x = element_text(size = 18),
                 axis.title.y = element_blank())
  p <- p + scale_y_continuous(expand = c(0, 0))

  return(p)
}


#### EXTRACT STATS ------------------------------------------------------------
## Extract depth stats:
get.dp <- function(filename) {

  if(!file.exists(filename)) cat('ALERT: File not found:', filename, '\n')
  if(file.size(filename) == 0) cat("ALERT: File size is 0 for file:", filename, '\n')

  if(file.exists(filename)) if(file.size(filename) > 0) {
    bcfstats <- readLines(filename)

    df <- gsub('\t', ' ', bcfstats[grep('^DP', bcfstats)])
    df <- as.data.frame(do.call(rbind, strsplit(df, split = ' ')))[, c(3, 6, 7)]

    colnames(df) <- c('DP', 'n', 'percent')
    df$DP <- as.integer(as.character(df$DP))
    df$percent <- as.numeric(as.character(df$percent))
    df$ID <- filename
  }

  return(df)
}

## Extract qual stats:
get.qual <- function(filename) {

  if(!file.exists(filename)) cat('ALERT: File not found:', filename, '\n')
  if(file.size(filename) == 0) cat("ALERT: File size is 0 for file:", filename, '\n')

  if(file.exists(filename)) if(file.size(filename) > 0) {

    bcfstats <- readLines(filename)

    df <- gsub('\t', ' ', bcfstats[grep('^QUAL', bcfstats)])
    df <- as.data.frame(do.call(rbind, strsplit(df, split = ' ')))[, c(3:6)]

    colnames(df) <- c('qual', 'nSNP', 'nTs', 'nTv')
    df$qual <- as.integer(as.character(df$qual))
    df$nSNP <- as.numeric(as.character(df$nSNP))
    df$nTs <- as.numeric(as.character(df$nTs))
    df$nTv <- as.numeric(as.character(df$nTv))
    df$percentSNP <- df$nSNP / sum(df$nSNP)
    df$ID <- as.character(filename)
  }

  return(df)
}

## Extract PSC stats:
get.psc <- function(filename) {

  if(!file.exists(filename)) cat('ALERT: File not found:', filename, '\n')
  if(file.size(filename) == 0) cat("ALERT: File size is 0 for file:", filename, '\n')

  if(file.exists(filename)) if(file.size(filename) > 0) {
    bcfstats <- readLines(filename)
    df <- gsub('\t', ' ', bcfstats[grep('^PSC', bcfstats)])
    df <- data.frame(do.call(rbind, strsplit(df, split = ' ')),
                     stringsAsFactors = FALSE)[, c(3:11)]
    colnames(df) <- c('ID', 'nRefHom', 'nNonRefHom', 'nHets', 'nTransitions',
                      'nTransversions', 'nIndels', 'average depth', 'nSingletons')
    numcols <- c(2:9)
    df[, numcols] <- apply(df[, numcols], 2, function(x) as.numeric(as.character(x)))

    return(df)
  }
}
