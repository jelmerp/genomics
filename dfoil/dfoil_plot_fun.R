#### READ DFOIL IN- AND OUTPUT -------------------------------------------------
read.dfoil.out <- function(fileID, id.short = 'pop', alt = FALSE) {
  suffix <- ifelse(alt == FALSE, '.dfoil.out', '.altMode.dfoil.out')
  filename <- paste0('analyses/dfoil/output/', fileID, suffix)

  dfoil <- read.delim(filename, header = TRUE, as.is = TRUE)
  dfoil$coord <- NULL
  dfoil <- dplyr::rename(dfoil, id.short = X.chrom)
  dfoil$id.short <- id.short

  dfoil <- mutate(dfoil,
                  T12 = round(T12, 4), T34 = round(T34, 4), T1234 = round(T1234, 4),
                  DFO = round(DFO_stat, 3), DFO_chisq = round(DFO_chisq),
                  DIL = round(DIL_stat, 3), DIL_chisq = round(DIL_chisq),
                  DFI = round(DFI_stat, 3), DFI_chisq = round(DFI_chisq),
                  DOL = round(DOL_stat, 3), DOL_chisq = round(DOL_chisq),
                  DFO.p = round(DFO_Pvalue, 4), DIL.p = round(DIL_Pvalue, 4),
                  DFI.p = round(DFI_Pvalue, 4), DOL.p = round(DOL_Pvalue, 4)) %>%
    select(id.short, introgression, total, dtotal, T12, T34, T1234,
           DFO, DFO.p, DIL, DIL.p,
           DFI, DFI.p, DOL, DOL.p)

  return(dfoil)
}

read.dfoil.in <- function(fileID, id.short = 'pop') {
  filename <- paste0('analyses/dfoil/input/', fileID, '.dfoil.in')
  dfoil <- read.delim(filename, header = TRUE, as.is = TRUE)
  dfoil$position <- NULL
  dfoil <- dplyr::rename(dfoil, id.short = X.chrom)
  dfoil$id.short <- id.short
  return(dfoil)
}


##### PLOT ---------------------------------------------------------------------
plot.dfoil <- function(dfoil.df, fileID.suffix, save.plot = TRUE) {

  dfoil.df.plot <- dfoil.df %>%
    select(DFO, DIL, DFI, DOL) %>%
    melt(measure.vars = c('DFO', 'DIL', 'DFI', 'DOL'))

  p <- ggplot(dfoil.df.plot, aes(variable, value))
  p <- p + geom_col()
  p <- p + scale_fill_discrete(name = 'statistic')
  p <- p + labs(title = fileID.suffix, x = "DFOIL statistic", y = 'value')
  p <- p + theme_bw()
  p <- p + theme(axis.text.x = element_text(size = 16),
                 axis.text.y = element_text(size = 16),
                 axis.title.x = element_text(size = 18),
                 axis.title.y = element_text(size = 18),
                 legend.position = 'top',
                 legend.title = element_text(size = 15, face = 'bold'),
                 legend.text = element_text(size = 15),
                 legend.key.height = unit(0.5, "cm"),
                 legend.key.width = unit(0.5, "cm"))

  if(save.plot == TRUE) {
    plotfile <- paste0('analyses/dfoil/figures/', fileID.suffix, '.png')
    ggsave(plotfile, plot = p, width = 5, height = 6)
    system(paste("xdg-open", plotfile))
  }
}


#### INFO ----------------------------------------------------------------------
# DFO: P1/P3 & P1/P4
# DIL: P2/P3 & P2/P4
# DFI: P1/P3 & P2/P3
# DOL: P1/P4 & P2/P4
