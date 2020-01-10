read.poplddecay <- function(fileID, output.type = 3,
                            binsize = 400, return.summary = TRUE) {

  if(output.type != 3) file.type <- 'stat'
  if(output.type == 3) file.type <- 'LD'

  infile_LD <- paste0('analyses/LD/popLDdecay.output/', fileID,
                      '.popLDdecay.', output.type, '.', file.type, '.gz')

  LD <- read.delim(gzfile(infile_LD), as.is = TRUE, row.names = NULL)

  if(output.type != 3) {
    LD <- LD %>%
      dplyr::rename(dist = X.Dist, r2 = Mean_r.2, npairs = NumberPairs) %>%
      dplyr::select(dist, r2, npairs)
  }

  if(output.type == 3) {
    LD <- LD %>%
      dplyr::rename(scaffold = X.chr, site1 = Site1, site2 = Site2, r2 = r.2, dist = Dist) %>%
      dplyr::filter(scaffold != 'Super_Scaffold0') %>%
      dplyr::mutate(pair = as.character(paste0(scaffold, ':', site1, '-', site2))) %>%
      dplyr::arrange(dist, site1)

    if(return.summary == TRUE) {

      if(table(LD$dist)[1] > binsize) {
        toobig <- which(table(LD$dist) > binsize)
        toobigmax <- which(! 1:max(toobig) %in% toobig)[1] - 1
        if(!is.na(toobigmax)) toobig <- 1:toobigmax

        LDkeep <- LD %>%
          dplyr::filter(dist %in% toobig)
        LDdivide <- LD %>%
          dplyr::filter(!dist %in% toobig)

        LDbinDiv <- LDdivide %>%
          dplyr::mutate(dist.group = ntile(as.numeric(rownames(LDdivide)), nrow(LD) / binsize)) %>%
          dplyr::group_by(dist.group) %>%
          dplyr::summarise(r2mean = mean(r2), meandist = mean(dist)) %>%
          dplyr::select(r2mean, meandist)

        LDbinKeep <- LDkeep %>%
          dplyr::group_by(dist) %>%
          dplyr::summarise(r2mean = mean(r2), meandist = mean(dist)) %>%
          dplyr::select(meandist, r2mean)

        LD <- rbind(LDbinKeep, LDbinDiv) %>%
          dplyr::rename(r2 = r2mean, dist = meandist)
      }

      if(table(LD$dist)[1] <= binsize) {
        LD <- LD %>%
          dplyr::mutate(dist.group = ntile(as.numeric(rownames(LD)), nrow(LD) / binsize)) %>%
          dplyr::group_by(dist.group) %>%
          dplyr::summarise(r2mean = mean(r2), meandist = mean(dist)) %>%
          dplyr::rename(r2 = r2mean, dist = meandist)
      }
    }
  }
  return(LD)
}

decayplot <- function(LD.df, xmax = NULL,
                      save.plot = FALSE, fileID = NULL,
                      plotfile = paste0(plotdir, '/', fileID, '.LDdecayPlot.png')) {
  # LD.df <- murSE; xmax <- 1000

  ymax <- max(LD.df$r2) + (0.05 * max(LD.df$r2))

  p <- ggplot(data = LD.df) +
    geom_line(aes(x = dist, y = r2), size = 2) +
    labs(x = 'pairwise distance (bp)', y = expression(paste("r"^"2"))) +
    scale_x_continuous(expand = c(0, 0)) +
    scale_y_continuous(expand = c(0, 0), breaks = seq(0, 1, by = 0.05),
                       limits = c(0, ymax)) +
    theme_bw() +
    theme(axis.title = element_text(size = 20),
          axis.text = element_text(size = 18),
          plot.margin = unit(c(1, 1, 0.2, 0.2), 'cm'))

  if(!is.null(xmax)) p <- p + xlim(0, xmax)

  if(save.plot == TRUE) {
    ggsave(plotfile, width = 6, height = 6)
    system(paste("xdg-open", plotfile))
  }

  print(p)
  return(p)
}


plotwrap <- function(fileID, binsize.long = 250, binsize.short = 100,
                     xmax.short = 500) {
  #fileID = 'murclade.murW.mac2.FS6'; binsize = 100; xmax = 2000

  LDlong <- read.poplddecay(fileID = fileID, binsize = binsize.long)
  A <- decayplot(LDlong, fileID = fileID) +
    theme(plot.margin = unit(c(1.5, 1, 0.2, 0.2), 'cm'))

  LDshort <- read.poplddecay(fileID = fileID, binsize = binsize.short)
  B <- decayplot(LDshort, xmax = xmax.short) +
    theme(plot.margin = unit(c(1.5, 1, 0.2, 0.2), 'cm'))

  figfile <- paste0(dir.plot, '/', fileID, '.LDdecayPlots.png')

  p <- ggarrange(A, B, ncol = 2, nrow = 1, widths = c(1, 1))
  p <- p + draw_plot_label(label = fileID, size = 24, x = 0, y = 1)

  ggexport(p, filename = figfile, width = 800, height = 400)
  system(paste('xdg-open', figfile))
}
