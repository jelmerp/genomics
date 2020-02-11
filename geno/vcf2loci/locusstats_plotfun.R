## Plot a bed glyph for a locus:
plot.locus <- function(locus.bed,
                       ID = NULL,
                       intersect.bed = bed.byInd) {
  locus.int <- bed_intersect(locus.bed, intersect.bed) %>%
    select(chrom, start.y, end.y) %>%
    rename(start = start.y, end = end.y)

  if(is.null(ID)) ID <- paste0('locus_', locus.bed$chrom, '_', locus.bed$start)

  plotfile <- paste0(plot.dir, '/', ID, '.png')
  p <- bed_glyph(bed_merge(locus.int))
  ggsave(plotfile, p, width = 8, height = 6)
}

## Plot histogram for a single statistic:
oneVarPlot <- function(my.var,
                       xtitle,
                       my.df = stats,
                       xmax = NULL,
                       nbins = 50,
                       save.plot = TRUE) {
  ## Testing:
  ## my.var = 'bp'; xtitle = 'Locus length (bp)'; my.df = stats; xmax = NULL

  p <- ggplot(data = my.df) +
    geom_histogram(aes_(as.name(my.var)), bins = nbins) +
    labs(x = xtitle) +
    scale_y_continuous(expand = c(0, 0)) +
    theme_bw() +
    theme(axis.title = element_text(size = 18),
          axis.text = element_text(size = 16),
          plot.margin = unit(c(0.2, 1, 0.2, 0.2), 'cm'))

  if(is.null(xmax)) p <- p + scale_x_continuous(expand = c(0, 0))
  if(!is.null(xmax)) p <- p + scale_x_continuous(expand = c(0, 0), limits = c(0, xmax))

  if(save.plot == TRUE) {
    plotfile <- paste0(dir.plot, '/', fileID, '_', my.var, '.png')
    ggsave(plotfile, p, width = 6, height = 5)
  }

  return(p)
}

## Violin plot:
byPlot <- function(xvar, yvar,
                   my.df = stats,
                   ymax = NULL,
                   xtitle = NULL, ytitle = NULL,
                   save.plot = TRUE) {
  ## Testing:
  ## my.df <- stats; y.var <- 'bp'; x.var <- 'scaffold'; fill.var <- 'scaffold'

  p <- ggplot(data = my.df) +
    geom_violin(aes_string(x = xvar, y = yvar), fill = 'grey80') +
    labs(x = xtitle, y = ytitle) +
    coord_flip() +
    theme_bw() +
    theme(axis.title = element_text(size = 18),
          axis.text = element_text(size = 10)) +
    guides(fill = FALSE)

  if(is.null(ymax)) p <- p + scale_y_continuous(expand = c(0, 0))
  if(!is.null(ymax)) p <- p + scale_y_continuous(expand = c(0, 0), limits = c(0, ymax))

  if(save.plot == TRUE) {
    plotfile <- paste0(dir.plot, '/', fileID, '_', xvar, '_by_', yvar, '.png')
    ggsave(plotfile, p, width = 6, height = 5)
  }

  return(p)
}
