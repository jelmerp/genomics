#### PACKAGES ------------------------------------------------------------------
library(pacman)
packages <- c('data.table', # fread()
              'TeachingDemos', # Compute HPD
              'RColorBrewer', 'png', 'grid', 'cowplot', 'patchwork', 'ggpubr',
              'here', 'tidyverse')
p_load(char = packages, install = TRUE)


#### VIOLIN PLOT with vplot() --------------------------------------------------
vplot <- function(data,
                  xvar,
                  yvar = 'val',
                  fillvar = 'cn',
                  colvar = 'cn',
                  shapevar = 'cn',
                  linecols = 'grey30',
                  fillcols = NULL,
                  col.labs = NULL,
                  pop.labs = NULL,
                  shade = TRUE,
                  shadecol = 'grey80',
                  shadelinecol = 'grey80',
                  shade_by = 1,
                  y.min = 0,
                  y.max = 'max.hpd',
                  ylims.dft = FALSE,
                  ymax.expand = 0.05,
                  yticks.by = 'auto',
                  rotate.x.ann = FALSE,
                  rm.violins = TRUE,
                  statsum = TRUE,
                  meandot.size = 2,
                  hpdline.width = 1,
                  legpos = 'top',
                  legfillname = NULL,
                  legcolname = NULL,
                  legend.nrow = 1,
                  rm.leg.col = FALSE,
                  rm.leg.fill = FALSE,
                  rm.leg.shape = FALSE,
                  plot.title = NULL,
                  xlab = NULL,
                  ylab = NULL,
                  saveplot = FALSE,
                  filename = NULL,
                  filetype = 'png',
                  plot.width = 7,
                  plot.height = 7,
                  plotdir = NULL,
                  file.open = TRUE) {

  if(nrow(data) == 0) stop("No rows in data")

  ## Convert values:
  if(unique(data$var) %in% c('theta', 'tau') & yvar == 'cval') data$cval <- data$cval / 1000
  if(unique(data$var) == 'm.prop') data$val <- data$val * 100

  data$xvar <- data[, which(colnames(data) == xvar)]
  data$yvar <- data[, which(colnames(data) == yvar)]
  data$colvar <- data[, which(colnames(data) == colvar)]
  data$fillvar <- data[, which(colnames(data) == fillvar)]
  data$shapevar <- data[, which(colnames(data) == shapevar)]

  ## Create base plot:
  p <- ggplot()

  if(rm.violins == FALSE)
    p <- p + geom_violin(data = data,
                         aes(x = xvar, y = yvar, fill = fillvar, colour = colvar))
  if(rm.violins == TRUE)
    p <- p + geom_blank(data = data,
                        aes(x = xvar, y = yvar, fill = fillvar, colour = colvar))

  ## Shading:
  if(shade == TRUE) { # shade_by = 1
    nrvars <- length(unique(data[, xvar]))
    rect_left <- c(seq(from = 0.5, to = nrvars, by = shade_by * 2))
    rectangles <- data.frame(x.min = rect_left, x.max = rect_left + shade_by)
    #rectangles$x.min[1] <- 0
    #rectangles$x.max[nrow(rectangles)] <- Inf
    print(rectangles)
    if(length(shadecol) == 1) shadecol <- rep(shadecol, nrow(rectangles))
    p <- p + geom_rect(data = rectangles,
                       aes(xmin = x.min, xmax = x.max, ymin = -Inf, ymax = Inf),
                       fill = shadecol, colour = shadelinecol, alpha = 0.5)
  }

  ## Plot violins:
  if(rm.violins == FALSE)
    p <- p + geom_violin(
      data = data, aes(x = xvar, y = yvar, fill = fillvar, colour = colvar)
      )
  if(rm.violins == TRUE)
    p <- p + geom_blank(
      data = data, aes(x = xvar, y = yvar, fill = fillvar, colour = colvar)
      )

  ## Fill colours:
  if(fillvar != 'cn') {
    cat("## fillvar:", fillvar, '\n')
    if(length(fillcols) == 1) if(fillcols == 'pop.cols') {
      matches <- sort(match(unique(data[, fillvar]), levels(data[, fillvar])))
      levels.sorted <- levels(data[, fillvar])[matches]
      fillcols <- popcols$col[match(levels.sorted, popcols$pop)]
    }
    if(length(fillcols) == 1) if(fillcols != 'pop.cols') {
      fillcols <- rep(fillcols, length(unique(data[, fillvar])))
    }
    if(is.null(fillcols)) {
      fillcols <- brewer.pal(n = length(unique(data[, colvar])), name = 'Set1')
    }
    p <- p + scale_fill_manual(values = fillcols, name = legfillname)
  }

  ## Line colours:
  if(length(linecols) == 1) if(linecols == 'pop.cols') {
    cat('## Getting popcols...\n')
    matches <- sort(match(unique(data[, colvar]), levels(data[, colvar])))
    levels.sorted <- levels(data[, colvar])[matches]
    cat('## Sorted levels:', levels.sorted, '\n')
    linecols <- popcols$col[match(levels.sorted, popcols$pop)]
    cat('## Line colours:', linecols, '\n')
  }
  if(length(linecols) == 1) if(linecols != 'pop.cols')
    linecols <- rep(linecols, length(unique(data[, colvar])))
  if(is.null(linecols)) {
    ncols <- length(unique(data[, colvar]))
    linecols <- suppressWarnings(brewer.pal(n = ncols, name = 'Set1'))
  }

  if(is.null(col.labs)) col.labs <- levels(data$colvar)
  p <- p + scale_colour_manual(values = linecols, labels = col.labs,
                               name = legcolname)

  ## Compute and show data summaries:
  if(statsum == TRUE) {
    p <- p + stat_summary(
      data = data,
      aes(x = xvar, y = yvar, fill = fillvar, color = colvar, width = 0.4),
      fun.ymin = hpd.min, fun.ymax = hpd.max, geom = "errorbar",
      size = hpdline.width, position = position_dodge(width = 0.9)
      )
    p <- p + stat_summary(
      data = data,
      aes(x = xvar, y = yvar, fill = fillvar, color = colvar, shape = shapevar),
      fun.y = mean, geom = "point", size = meandot.size,
      position = position_dodge(width = 0.9))
  }

  ## Axis limits:
  if(ylims.dft == FALSE) {
    if(y.max %in% c('max.hpd', 'max.value')) {
      if(y.max == 'max.hpd' & yvar == 'val')
        df <- group_by(data, fillvar, colvar, xvar) %>%
          dplyr::summarise(Max = hpd.max(val))
      if(y.max == 'max.value' & yvar == 'val')
        df <- group_by(data, fillvar, colvar, xvar) %>%
          dplyr::summarise(Max = max(val))
      if(y.max == 'max.hpd' & yvar == 'cval')
        df <- group_by(data, fillvar, colvar, xvar) %>%
          dplyr::summarise(Max = hpd.max(cval))
      if(y.max == 'max.value' & yvar == 'cval')
        df <- group_by(data, fillvar, colvar, xvar) %>%
          dplyr::summarise(Max = max(cval))

      max <- as.numeric(max(df$Max))
      y.max <- max + (ymax.expand * max)
    }
    p <- p + coord_cartesian(ylim = c(y.min, y.max))
  }

  if(yticks.by != 'auto') {
    my.ybreaks <- seq(y.min, y.max, by = yticks.by)
    p <- p + scale_y_continuous(expand = c(0, 0), breaks = my.ybreaks)
  } else {
    p <- p + scale_y_continuous(expand = c(0, 0))
  }

  ## Change poplabels:
  if(!is.null(pop.labs)) {
    p <- p + scale_x_discrete(expand = c(0, 0), labels = pop.labs)
  } else {
    p <- p + scale_x_discrete(expand = c(0, 0))
  }

  ## Axis and plot titles/labels:
  if(!is.null(plot.title)) p <- p + labs(title = plot.title)
  p <- p + labs(x = xlab, y = ylab)

  ## General formatting:
  p <- p + theme_bw()
  p <- p + theme(
    axis.text.x = element_text(size = 18, face = 'bold',
                               margin = margin(0.1, 0, 0, 0, 'cm')),
    axis.text.y = element_text(size = 18),
    axis.title.x = element_text(size = 20),
    axis.title.y = element_text(size = 20, margin = margin(0, 0.4, 0, 0, 'cm')),
    plot.title = element_text(size = 26, hjust = 0.5),
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_blank())
  if(rotate.x.ann == TRUE)
    p <- p + theme(axis.text.x = element_text(size = 14, angle = 60, hjust = 1))

  ## Legend formatting:
  p <- p + theme(
    legend.title = element_text(size = 16, face = 'bold'),
    legend.text = element_text(size = 16),
    legend.key.height = unit(0.5, "cm"),
    legend.key.width = unit(0.5, "cm"),
    legend.background = element_rect(fill = "grey90", colour = "grey30"),
    legend.key = element_rect(fill = "grey90"),
    legend.position = legpos)

  ## Edit legend if not plotting violins:
  if(rm.violins == TRUE)
    p <- p + guides(
      colour = guide_legend(override.aes = list(linetype = 1, shape = 16))
      )

  ## Legend across multiple rows:
  p <- p + guides(colour = guide_legend(nrow = legend.nrow, byrow = TRUE))

  ## Remove legend for constants:
  if(colvar == 'cn') rm.leg.col <- TRUE
  if(fillvar == 'cn') rm.leg.fill <- TRUE
  if(shapevar == 'cn') rm.leg.shape <- TRUE

  if(rm.leg.col == TRUE & rm.leg.fill == FALSE & rm.leg.shape == FALSE)
    p <- p + guides(colour = FALSE)
  if(rm.leg.col == FALSE & rm.leg.fill == TRUE & rm.leg.shape == FALSE)
    p <- p + guides(fill = FALSE)
  if(rm.leg.col == FALSE & rm.leg.fill == FALSE & rm.leg.shape == TRUE)
    p <- p + guides(shape = FALSE)
  if(rm.leg.col == FALSE & rm.leg.fill == TRUE & rm.leg.shape == TRUE)
    p <- p + guides(shape = FALSE, fill = FALSE)
  if(rm.leg.col == TRUE & rm.leg.fill == FALSE & rm.leg.shape == TRUE)
    p <- p + guides(shape = FALSE, colour = FALSE)
  if(rm.leg.col == TRUE & rm.leg.fill == TRUE & rm.leg.shape == FALSE)
    p <- p + guides(colour = FALSE, fill = FALSE)
  if(rm.leg.col == TRUE & rm.leg.fill == TRUE & rm.leg.shape == TRUE)
    p <- p + guides(colour = FALSE, fill = FALSE, shape = FALSE)

  ## Save plot:
  if(saveplot == TRUE) {
    if(is.null(plotdir)) plotdir <- paste0('analyses/gphocs/fig/')
    if(!dir.exists(plotdir)) dir.create(plotdir, recursive = TRUE)
    plotfile <- paste0(plotdir, '/', filename, '.', filetype)
    cat('## Saving plot:', plotfile, '\n')
    ggsave(filename = plotfile, plot = p, width = plot.width, height = plot.height)
    if(file.open == TRUE) system(paste("xdg-open", plotfile))
  }
  return(p)
}


#### DEMOGRAPHY PLOT with dplot() ----------------------------------------------
dplot <- function(tt, # theta tau summary table
                  x.min = NULL, y.max = NULL, # x- and y-axis min and max
                  x.even = FALSE, # don't show population sizes: all pops same size on x axis
                  col.scale = TRUE,
                  yticks.by = 'auto', # y-tick every X ka
                  x.extra = 5, # extra space along x-axis
                  rm.y.ann = FALSE, # remove y-axis test?
                  xlab = expression(N[e] ~ "(1 tick mark = 25k)"), # x-axis title
                  ylab = 'time (ka ago)', # y-axis title
                  pops_to_conn = NULL, # draw connectors between pops
                  ann.pops = TRUE, # add text labels for pops?
                  ann.pops.anc = FALSE, # add text label for ancestral pops?
                  popnames.size = 7, # text size of labels for pops
                  popnames.col = 'black', # color of labels for pops
                  popnames.adj.vert = 0.05, # vertical adjustment of labels for pops
                  popnames.adj.horz = 0, # vertical adjustment of labels for pops
                  legend.plot = FALSE, # show legend?
                  legend.labs = NULL, # show legend labels?
                  plot.title = '', # plot title
                  plot.width = 6, plot.height = 6, # plot width and height
                  plotdir = NULL, filename = NULL, # plotting dir and filename of figure
                  filetype = 'eps', # figure filetype
                  saveplot = FALSE, # save plot?
                  file.open = TRUE) { # open figure file using xdg-open?

  ## Base plot:
  p <- ggplot()
  if(x.even == TRUE || col.scale == FALSE) {
    p <- p + geom_rect(data = tt, colour = 'grey20',
                       aes(xmin = x.min, xmax = x.max, ymin = y.min,
                           ymax = y.max, fill = popcol))
  } else {
    p <- p + geom_rect(data = tt,
                       aes(xmin = x.min, xmax = x.max, ymin = y.min, ymax = y.max,
                           fill = popcol, color = factor(NeToScale)))
    p <- p + scale_colour_manual(breaks = c(0, 1), values = c('grey40', 'grey10'))
    p <- p + guides(colour = FALSE)
  }

  ## Legend (only if no popnames in plot):
  if(is.null(legend.labs)) legend.labs <- tt$pop
  if(ann.pops == FALSE | legend.plot == TRUE)
    p <- p + scale_fill_identity(guide = 'legend', name = '', labels = legend.labs)
  if(ann.pops == TRUE | legend.plot == FALSE)
    p <- p + scale_fill_identity(guide = 'none')

  ## General formatting:
  p <- p + theme_bw()
  p <- p + theme(axis.ticks.length.x = unit(0.25, "cm"),
                 axis.text.y = element_text(size = 20),
                 axis.title.y = element_text(size = 20, margin = margin(r = 10)),
                 plot.title = element_text(face = 'bold', size = 22, hjust = 0.5),
                 plot.margin = unit(c(0.2, 0.2, 0.2, 0.2), "cm"),
                 legend.text = element_text(size = 18, margin = margin(b = 8)),
                 legend.title = element_blank(), # top, right, ..
                 legend.background = element_rect(fill = "grey90", colour = "grey30"),
                 legend.key = element_rect(fill = "grey90"))

  ## X-axis annotation:
  if(is.null(xlab))
    p <- p + theme(axis.title.x = element_blank())
  if(!is.null(xlab))
    p <- p + theme(axis.title.x = element_text(size = 20, margin = margin(t = 10)))

  ## Axis breaks:
  my.xbreaks <- seq(from = 0, to = 5000, by = 25)
  p <- p + scale_x_continuous(expand = c(0, 1), breaks = my.xbreaks)

  if(yticks.by != 'auto') {
    my.ybreaks <- seq(y.min, y.max, by = yticks.by)
    p <- p + scale_y_continuous(expand = c(0, 0), breaks = my.ybreaks)
  } else {
    p <- p + scale_y_continuous(expand = c(0, 0))
  }

  ## Connectors between floating pops:
  if(!is.null(pops_to_conn)) for(pop_to_conn in pops_to_conn) {
    con <- getcon(pop_to_conn, poplist, tt)
    print(con)
    p <- p + geom_segment(
      aes(y = con$y_loc, yend = con$y_loc,
          x = con$x_start, xend = con$x_end),
      colour = 'grey50'
    )
  }

  ## Population names:
  if(ann.pops == TRUE) {
    if(ann.pops.anc == FALSE) tt <- tt %>% filter(y.min == 0) # current pops only
    x.locs <- ((tt$x.min + tt$x.max) / 2) + popnames.adj.horz
    y.locs <- tt$y.min + popnames.adj.vert
    p <- p + annotate(geom = "text", x = x.locs, y = y.locs,
                        label = tt$pop, color = popnames.col, size = popnames.size)
    p <- p + theme(axis.text.x = element_blank())
  }
  if(ann.pops == FALSE) p <- p + theme(axis.text.x = element_blank())

  ## Axis labels and titles:
  if(!is.null(plot.title))
    p <- p + labs(title = plot.title)
  if(!is.null(xlab))
    p <- p + labs(x = xlab)
  if(!is.null(ylab))
    p <- p + labs(y = ylab)

  ## Remove y annotation:
  if(rm.y.ann == TRUE) {
    p <- p + theme(axis.title.y = element_blank(),
                   axis.text.y = element_blank())
  }

  ## Axis min and max:
  if(!is.null(x.min) & is.null(y.max))
    p <- p + coord_cartesian(xlim = c(x.min, max(tt$x.max) + x.extra))
  if(!is.null(y.max) & is.null(x.min))
    p <- p + coord_cartesian(ylim = c(0, y.max), xlim = c(0, max(tt$x.max) + x.extra))
  if(!is.null(y.max) & !is.null(x.min))
    p <- p + coord_cartesian(ylim = c(0, y.max), xlim = c(x.min, max(tt$x.max) + x.extra))

  ## Save plot:
  if(saveplot == FALSE) file.open <- FALSE
  if(saveplot == TRUE) {
    if(is.null(plotdir)) plotdir <- paste0('analyses/gphocs/plots')
    plotfile <- paste0(plotdir, '/', filename, '.', filetype)
    ggsave(filename = plotfile, plot = p, width = plot.width, height = plot.height)
    if(file.open == TRUE) system(paste("xdg-open", plotfile))
    plot(p)

    if(filetype != 'pdf') { # Also save a pdf if this is not the selected filetype
      plotfile.pdf <- paste0(plotdir, '/', filename, '.pdf')
      ggsave(filename = plotfile.pdf, plot = p, width = plot.width, height = plot.height)
    }
  }

  return(p)
}

#### HELPER FUNCTIONS ----------------------------------------------------------
## get.midpoint(): get intermediate color
get.midpoint <- function(col1, col2) {
  col <- rgb(red = (col2rgb(col1)[1] + col2rgb(col2)[1]) / 2,
             green = (col2rgb(col1)[2] + col2rgb(col2)[2]) / 2,
             blue = (col2rgb(col1)[3] + col2rgb(col2)[3]) / 2,
             maxColorValue = 255)
  return(col)
}

## hpd.min() and hpd.max(): get HPD interval
# emp.hpd from TeachingDemos package
hpd.min <- function(x) emp.hpd(x)[1]
hpd.max <- function(x) emp.hpd(x)[2]

## cvar(): get converted variable name
# e.g. theta -> Ne
cvar <- function(variable) {
  if(variable == 'theta') return(expression(N[e] ~ "(in 1000s)"))
  if(variable == 'tau') return("divergence time (ka ago)")
}

## m.prep(): summarize migration rates
mprep <- function(Log) {
  m <- filter(Log, !is.na(migpattern)) %>%
    group_by(setID, migtype.run, runID, migfrom, migto, var) %>%
    summarise(value = mean(val, na.rm = TRUE),
              cval = mean(cval, na.rm = TRUE),
              value_min = round(hpd.min(val), 3),
              value_max = round(hpd.max(val), 3))
  return(m)
}

## addmig(): add migration arrows to existing plot
addmig <- function(p, # plot
                   m, # migration summary df
                   tt, # theta and tau summary df
                   poplist, # list with parent=chold combinations
                   from, to, # migration from ... to
                   mig_measure = '2Nm',
                   xmin = 'auto', xmax = 'auto', y = 'auto',
                   nudge_x = 0, # nudge x position of label
                   nudge_y = 0, # nudge y position of arrow and label
                   labpos = 'below', # put lab (=migration rate) 'below' or 'above' arrow
                   labmar = 15, # margin along y-axis between arrow and label
                   labsize = 5, arrowhead_size = 0.2, arrow_lwd = 1,
                   lab_font = 'plain', lab_bg = NA) {
  # from='ber'; to='ruf'; xmin = 'auto'; xmax = 'auto'; y = 'auto'

  #mrate <- m %>%
  #  filter(migfrom == {{from}} & migto == {{to}}) %>% pull(value) %>% round(2)

  focal_m <- m %>% filter(migfrom == {{from}},
                          migto == {{to}},
                          var == {{mig_measure}})
  mrate <- focal_m %>% pull(value) %>% round(2)
  mmin <- focal_m %>% pull(value_min) %>% round(3)
  cat('mmin:', mmin, '\n')
  if(mmin == 0) mrate <- paste0('(', mrate, ')')
  cat('mrate:', mrate, '\n')

  pops_io <- tt[tt$pop %in% c(from, to), ] %>% arrange(x.min) %>% pull(pop)
  pop1 <- pops_io[1]
  pop2 <- pops_io[2]

  if(xmin == 'auto') xmin <- min(tt$x.max[tt$pop == pop1])
  if(xmax == 'auto') xmax <- max(tt$x.min[tt$pop == pop2])

  if(pop1 == from) {
    x_from <- xmin
    x_to <- xmax
  } else {
    x_from <- xmax
    x_to <- xmin
  }

  if(y == 'auto') {
    min_age <- min(tt$y.max[tt$pop %in% c(from, to)])
    y <- (min_age / 2) + nudge_y
  }

  x_lab <- ((xmax + xmin) * 0.5) + nudge_x
  if(labpos == 'below') y_lab <- y - labmar
  if(labpos == 'above') y_lab <- y + labmar

  cat('Pop1:', pop1, '   Pop2:', pop2, '\n')
  cat('xmin:', xmin, '   xmax:', xmax, '   xlab:', x_lab, '\n')
  cat('y:', y, '   y_lab:', y_lab, '     labmar:', labmar, '\n')

  p <- p +
    geom_segment(
      aes(x = x_from, xend = x_to, y = y, yend = y),
      colour = 'grey20', size = arrow_lwd,
      arrow = arrow(length = unit(arrowhead_size, "cm"),
                    angle = 45, type = 'closed')
    ) +
    geom_label(
      aes(x = x_lab, y = y_lab, label = mrate),
      fontface = lab_font, label.size = 0, size = labsize, colour = 'grey20',
      fill = lab_bg, alpha = 0.7)

  return(p)
}

## Draw connection line in demography plot for a focal population;
## line will be drawn between the xmax of child1 and xmin of child2.
getcon <- function(pop, poplist, tt) {
  children <- names(poplist[c(grep(pop, poplist))])

  y_loc <- tt$y.min[tt$pop == pop]
  x_start <- min(tt$x.max[tt$pop %in% children])
  x_end <- max(tt$x.min[tt$pop %in% children])
  con <- data.frame(y_loc = y_loc, x_start = x_start, x_end = x_end)
  return(con)
}
