library(RColorBrewer)

################################################################################
##### DENSITY PLOT #####
################################################################################
densplot <- function(d = winstats,
                     mystat,
                     xvar = 'val',
                     fill_var = 'pop',
                     fill_name = 'species',
                     fill_vals = NULL,
                     fill_labs = NULL,
                     fill_legend = TRUE,
                     xlab = NULL,
                     xlims = NULL,
                     ylims = NULL) {

  d <- as.data.frame(d) %>%
    filter(stat == !!(quo(mystat)))


  if(mystat == 'fst') xlab <- expression(F[ST])
  if(mystat == 'dxy') xlab <- expression(d[xy])
  if(mystat == 'fd') xlab <- expression(f[d])
  if(mystat == 'pi') xlab <- expression(pi)
  if(mystat == 'tajD') xlab <- "Tajima's D"
  if(is.null(mystat)) xlab <- mystat

  p <- ggplot(data = d) +
    geom_density(aes_string(x = xvar, fill = fill_var),
                 alpha = 0.3) +
    theme_bw() +
    scale_fill_manual(values = fill_vals,
                      labels = fill_labs,
                      name = fill_name) +
    geom_vline(xintercept = 0) +
    labs(x = xlab) +
    theme(axis.title.y = element_blank(),
          axis.text.y = element_blank(),
          axis.title.x = element_text(size = 18),
          axis.text.x = element_text(size = 16),
          axis.ticks.y = element_blank(),
          legend.position = 'top',
          legend.title = element_text(size = 14, face = 'bold'),
          legend.text = element_text(size = 14),
          plot.margin = margin(0.1, 0.4, 0.1, 0.4, unit = 'cm'))

  if(!is.null(xlims)) p <- p + scale_x_continuous(expand = c(0, 0), limits = xlims)
  if(!is.null(ylims)) p <- p +scale_y_continuous(expand = c(0, 0), limits = ylims)
  if(is.null(xlims)) p <- p + scale_x_continuous(expand = c(0, 0))
  if(is.null(ylims)) p <- p + scale_y_continuous(expand = c(0, 0))

  if(fill_legend == FALSE) p <- p + guides(fill = FALSE)

  print(p)
  return(p)
}


################################################################################
##### MANHATTAN PLOT- SINGLE PLOT USING GGPLOT #####
################################################################################
ggman <- function(d,
                  yvar,
                  xvar = 'win_index',
                  yvar_column = 'val',
                  colvar.lines = NULL,
                  colvar.points = NULL,
                  scaffolds = 'all', # specify scaffold // NULL=first scaffold // 'all'=all scaffolds
                  pop = NULL,
                  drawpoints = TRUE,
                  cols.points = 'brew',
                  point.size = 1.5,
                  point.alpha = 1,
                  line.size = 1,
                  drawlines = TRUE,
                  cols.lines = 'brew',
                  smoothmethod = 'loess',
                  smoothpar = 0.2,
                  my.ymin = 0,
                  my.ymax = NULL,
                  my.xlims = NULL,
                  my.yticks = NULL,
                  blocklims = NULL,
                  hline = NULL,
                  xlab = NULL,
                  ylab = NULL,
                  legplot = TRUE,
                  legpos = 'top',
                  legtextsize = 15,
                  plot.title = FALSE,
                  xann = FALSE,
                  plot.xtitle = FALSE,
                  shade_scaffolds = TRUE,
                  scafcols = c("grey80", "white", 'coral'),
                  scaf_df,
                  shade_xchrom = TRUE,
                  printplot = TRUE,
                  saveplot = FALSE,
                  outfile = NULL,
                  outdir = 'analyses/gscan/figures/',
                  filetype = 'png',
                  file.open = FALSE,
                  drawpoints2 = FALSE,
                  points2 = NULL,
                  cols.points2 = NULL) {

  ## Prepare dataframe:
  d <- filter(d, stat == !!(quo(yvar)))

  if(!is.null(pop)) d <- d[d$pop %in% pop, ]
  if(is.null(pop)) pop <- d$pop[1]
  popnames <- unique(d$pop)

  ## Scaffolds:
  if(is.null(scaffolds)) scaffolds <- 'all'
  if(scaffolds[1] != 'all') d <- d[d$scaffold %in% scaffolds, ]
  if(scaffolds[1] == 'all') d <- arrange(d, pop, scaf_index, start)
  cat("#### D scaffolds:", unique(d$scaffold), '\n')

  ## Index and running site location for selected scaffolds:
  scaf_df <- filter(scaf_df, scaffold %in% unique(d$scaffold))
  scaf_df$scafstart_run <- c(1, cumsum(as.numeric(scaf_df$length)) + 1)[1:nrow(scaf_df)]
  print(scaf_df)

  d <- d %>%
    group_by(pop) %>%
    mutate(win_index = 1:n()) %>%
    ungroup()

  d <- d %>%
    mutate(
      #win_index = 1:n(),
      start_run = scaf_site$scafstart_run[match(scaffold, scaf_df$scaffold)] + start,
      end_run = scaf_site$scafstart_run[match(scaffold, scaf_df$scaffold)] + end
      )

  ## Colours:
  if(drawpoints == TRUE) {
    if(cols.points[1] == 'popcols') cols.points <- cols_df$col[match(popnames, cols_df$pop)]
    if(cols.points[1] == 'brew') cols.points <- brewer.pal(7, "Set1")
    cat("#### cols.points:", cols.points, '\n')
  }
  if(drawlines == TRUE) {
    if(cols.lines[1] == 'popcols') cols.lines <- cols_df$col[match(popnames, cols_df$pop)]
    if(cols.lines[1] == 'brew') cols.lines <- brewer.pal(7, "Set1")
    cat("#### cols.lines:", cols.lines, '\n')
  }

  ## Axis limits:
  if(!is.null(my.xlims)) {
    if(min(d$start) < my.xlims[1]) d <- d[-which(d$start < my.xlims[1]), ]
    if(max(d$start) > my.xlims[2]) d <- d[-which(d$start > my.xlims[2]), ]
  }
  if(is.null(my.ymax)) my.ymax <- max(d[, yvar_column], na.rm = TRUE) * 1.2
  if(is.null(my.ymin)) my.ymin <- min(d[, yvar_column], na.rm = TRUE) * 0.8

  ## Axis tickmarks:
  if(is.null(my.yticks)) {
    my.yspan <- my.ymax - my.ymin
    if(my.yspan < 0.5) my.yticks <- seq(-10, 0.4, by = 0.1)
    if(my.yspan > 0.5) my.yticks <- seq(-10, 10, by = 0.5)
    if(my.yspan > 2) my.yticks <- seq(-10, 10, by = 1)
    if(my.yspan > 5) my.yticks <- seq(-10, 10, by = 5)
  }

  ## Special y labels:
  if(is.null(ylab)) {
    if(yvar == 'fst') ylab <- expression(F[ST])
    if(yvar == 'dxy') ylab <- expression(d[xy])
    if(yvar == 'fd') ylab <- expression(f[d])
    if(yvar == 'pi') ylab <- expression(pi)
    #if(yvar == 'pi') ylab <- expression(paste(pi, ' (nucleotide diversity)'))
    if(yvar == 'pi2') ylab <- expression(paste(pi, ' (nucleotide diversity)'))
    if(yvar == 'tajD') ylab <- "Tajima's D"
    if(yvar == 'fuLiF') ylab <- "Fu & Li's F"
    if(is.null(ylab)) ylab <- yvar
  }

  ## Start plot:
  p <- ggplot()

  ## Scaffold background colours:
  if(shade_scaffolds == TRUE) {

    if(xvar == 'win_index') {
      scafco <- d %>%
        group_by(scaffold) %>%
        summarise(scaf_start = min(win_index),
                  scaf_end = max(win_index))

    } else if(xvar == 'start_run') {
      scaffold <- unique(d$scaffold)
      scaf_start <- scaf_df$scafstart_run[match(scaffold, scaf_df$scaffold)]
      scaf_end <- scaf_df$scafstart_run[match(scaffold, scaf_df$scaffold) + 1] - 1
      scafco <- data.frame(scaffold, scaf_start, scaf_end)

      no_end <- which(is.na(scafco$scaf_end))
      scaflen <- scaf_df$length[match(scafco$scaffold[no_end], scaf_df$scaffold)]
      scafco$scaf_end[no_end] <- scafco$scaf_start[no_end] + scaflen
    } else {
      cat('#### XVAR IS NOT WIN_INDEX OR START_RUN...')
    }
    scafco <- scafco %>%
      mutate(scaf_index = d$scaf_index[match(scaffold, d$scaffold)]) %>%
      arrange(scaf_index)

    #cat('#### scafco:\n')
    #print(scafco)

    scaf_rect <- data.frame(scaffold = scafco$scaffold,
                            xmin = scafco$scaf_start,
                            xmax = scafco$scaf_end,
                            ymin = -Inf,
                            ymax = Inf)
    scaf_rect$scafcol_index <- ifelse(1:nrow(scaf_rect) %% 2 == 0, 1, 2)

    #cat('#### scaf_rect:\n')
    #print(scaf_rect)

    if(shade_xchrom == TRUE) {
      scaf_rect$scafcol_index[scaf_rect$scaffold == xchrom] <- 3
    }

    for(row_nr in 1:nrow(scaf_rect)) {
      scafcol_index <- scaf_rect$scafcol_index[row_nr]
      my_scafcol <- scafcols[scafcol_index]
      scaf_rect_row <- slice(scaf_rect, row_nr)
      p <- p + geom_rect(data = scaf_rect_row,
                         aes(xmin = xmin, xmax = xmax,
                             ymin = ymin, ymax = ymax),
                         fill = my_scafcol)
    }
  }

  ## Draw points:
  if(!is.null(colvar.points)) {

    if(drawpoints == TRUE) {
      p <- p + geom_point(data = d,
                          aes_string(x = xvar,
                                     y = yvar_column,
                                     fill = colvar.points),
                          colour = 'white',
                          shape = 21,
                          size = point.size,
                          stroke = 0,
                          alpha = point.alpha)
      nr_cols <- length(unique(d[, colvar.points]))
      #cat("Nr of cols for points:", nr_cols, '\n')
      #p <- p + scale_fill_manual(values = cols.points[1:nr_cols])
      p <- p + scale_fill_manual(values = cols.points)
    }

    if(drawpoints == 'blocksOnly') {
      cat('##### Drawing points for blocks only...\n')
      p <- p + geom_point(data = subset(d, is.block == TRUE),
                          aes_string(x = xvar,
                                     y = val_column,
                                     fill = colvar.points),
                          colour = 'white',
                          shape = 21,
                          size = point.size,
                          stroke = 0,
                          alpha = point.alpha)
      nr_cols <- length(unique(d[, colvar.points]))
      p <- p + scale_fill_manual(values = cols.points[1:nr_cols])
      p <- p + guides(fill = FALSE)
    }

  }

  if(is.null(colvar.points)) {
    if(drawpoints == TRUE) {
      p <- p + geom_point(data = d,
                          aes_string(x = xvar, y = yvar_column),
                          colour = cols.points[1],
                          shape = 21,
                          size = point.size,
                          alpha = point.alpha)
    }

    if(drawpoints == 'blocksOnly') {
      p <- p + geom_point(data = subset(d, is.block == TRUE),
                          aes_string(x = xvar, y = yvar_column),
                          colour = cols.points[1],
                          shape = 21,
                          size = point.size,
                          alpha = point.alpha)
    }
  }

  ## Draw special points:
  if(drawpoints2 == TRUE) {
    cat("#### Drawing points2...\n")
    d2 <- filter(d, start_run %in% points2)
    p <- p + geom_point(data = d2,
                        aes_string(x = xvar, y = yvar_column),
                        fill = cols.points2,
                        shape = 21,
                        size = point.size,
                        alpha = point.alpha)
  }

  ## Draw lines:
  if(!is.null(colvar.lines) & drawlines == TRUE) {
    p <- p + geom_smooth(data = d,
                         aes_string(x = xvar, y = yvar_column, colour = colvar.lines),
                         se = FALSE,
                         inherit.aes = TRUE,
                         size = line.size,
                         method = smoothmethod,
                         span = smoothpar)

    if(yvar != 'fd') {
      colby.vals <- unique(d[, colvar.lines]) %>% pull(colvar.lines)
      cat("#### colby.vals:", colby.vals, '\n')
      p <- p + scale_color_manual(values = cols.lines[1:length(colby.vals)],
                                  name = '')
    } else {
      rawvals <- unique(d[, colvar.lines])
      popA1 <- sapply(strsplit(rawvals, split = '\\.'), '[', 1)[1]
      popA2 <- sapply(strsplit(rawvals, split = '\\.'), '[', 1)[2]
      popA3 <- sapply(strsplit(rawvals, split = '\\.'), '[', 1)[3]
      popB1 <- sapply(strsplit(rawvals, split = '\\.'), '[', 2)[1]
      popB2 <- sapply(strsplit(rawvals, split = '\\.'), '[', 2)[2]
      popB3 <- sapply(strsplit(rawvals, split = '\\.'), '[', 2)[3]
      popC1 <- sapply(strsplit(rawvals, split = '\\.'), '[', 3)[1]
      popC2 <- sapply(strsplit(rawvals, split = '\\.'), '[', 3)[2]
      popC3 <- sapply(strsplit(rawvals, split = '\\.'), '[', 3)[3]
      nr_cols <- length(unique(d[, colvar.lines]))
      col_labs <- c(bquote(paste(.(popA1), "-", bold(.(popB1)), "-", bold(.(popC1)))),
                    bquote(paste(.(popA2), "-", bold(.(popB2)), "-", bold(.(popC2)))),
                    bquote(paste(.(popA3), "-", bold(.(popB3)), "-", bold(.(popC3)))))

      p <- p + scale_color_manual(values = cols.lines[1:nr_cols],
                                  breaks = unique(d[, colvar.lines]),
                                  labels = col_labs,
                                  name = '')
    }
  }

  if(is.null(colvar.lines) & drawlines == TRUE) {
    p <- p + geom_smooth(data = d,
                         aes_string(x = xvar, y = yvar_column),
                         colour = cols.lines,
                         se = FALSE,
                         fill = "NA",
                         inherit.aes = FALSE,
                         size = line.size,
                         method = smoothmethod,
                         span = smoothpar)
  }

  ## Horizontal and vertical lines:
  if(!is.null(blocklims)) {
    p <- p + geom_vline(xintercept = blocklims[1], colour = 'grey10', linetype = 2)
    p <- p + geom_vline(xintercept = blocklims[2], colour = 'grey10', linetype = 2)
  }

  if(!is.null(hline)) {
    p <- p + geom_hline(yintercept = hline, colour = 'grey10', linetype = 1)
  }

  ## X and Y labels:
  p <- p + labs(title = plot.title)
  if(!is.null(xlab)) p <- p + labs(x = xlab)
  if(!is.null(ylab)) p <- p + labs(y = ylab)

  ## Scale and coords:
  p <- p + scale_x_continuous(expand = c(0, 0))
  p <- p + scale_y_continuous(expand = c(0, 0), breaks = my.yticks)
  p <- p + coord_cartesian(ylim = c(my.ymin, my.ymax))
  if(!is.null(my.xlims)) p <- p + coord_cartesian(xlim = my.xlims)

  ## Formatting (theme):
  p <- p + theme_bw()
  p <- p + theme(axis.text.y = element_text(size = 14),
                 axis.title.y = element_text(size = 18),
                 plot.margin = unit(c(0.2, 0.2, 0.2, 0.2), "cm"))

  if(xann == TRUE) p <- p + theme(axis.text.x = element_text(size = 16))
  if(xann == FALSE) p <- p + theme(axis.text.x = element_blank(),
                                        axis.ticks.x = element_blank())
  if(is.null(xlab)) p <- p + theme(axis.title.x = element_blank())
  if(!is.null(xlab)) p <- p + theme(axis.title.x = element_text(size = 18))
  if(plot.title != FALSE) p <- p + theme(plot.title = element_text(size = 20, hjust = 0.5))
  if(plot.title == FALSE) p <- p + theme(plot.title = element_blank())

  ## Legend:
  if(legplot == TRUE) {
    p <- p + theme(legend.title = element_text(size = legtextsize,
                                               face = 'bold'),
                   legend.text = element_text(size = legtextsize),
                   legend.key.height = unit(0.5, "cm"),
                   legend.key.width = unit(0.5, "cm"),
                   legend.position = legpos,
                   legend.margin = margin(0, 0, 0, 0),
                   legend.box.margin = margin(-5, -5, -5, -5))
  } else {
    p <- p + theme(legend.position = "none")
  }

  ## Save plot:
  if(saveplot == TRUE) {
    pop.filename <- paste0(pop, collapse = '_')
    if(is.null(outfile)) outfile <- paste0(scaffold, '.', yvar, '.', pop.filename)
    outfile.full <- paste0(outdir, '/', outfile, '.', filetype)
    cat('saving:', outfile.full, '\n')
    ggsave(filename = outfile.full, plot = p, width = 10, height = 8)
    if(file.open == TRUE) system(paste("xdg-open", outfile.full))
  }

  if(printplot == TRUE) print(p)
  return(p)
}
