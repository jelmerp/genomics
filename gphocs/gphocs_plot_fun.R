library(data.table)
library(png)
library(grid)
library(RColorBrewer)
library(ggpubr)
library(cowplot)
library(TeachingDemos)
library(plyr)
library(reshape2)
library(tidyverse)

################################################################################
##### VIOLIN PLOT #####
################################################################################
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
                  y.min = 0,
                  y.max = 'max.hpd',
                  ylims.dft = FALSE,
                  ymax.expand = 0.05,
                  yticks.by = 10,
                  rotate.x.ann = FALSE,
                  rm.violins = TRUE,
                  statsum = TRUE,
                  meandot.size = 2,
                  hpdline.width = 1,
                  legpos = 'none',
                  legfillname = NULL,
                  legcolname = NULL,
                  legend.nrow = 1,
                  rm.leg.col = TRUE,
                  rm.leg.fill = FALSE,
                  rm.leg.shape = FALSE,
                  plot.title = NULL,
                  xlab = '',
                  ylab = '',
                  saveplot = FALSE,
                  filename = NULL,
                  filetype = 'png',
                  plot.width = 7,
                  plot.height = 7,
                  plotdir = NULL,
                  file.open = TRUE) {

  if(nrow(data) == 0) stop("Error: no rows in data")

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
  if(shade == TRUE) {
    nrvars <- length(unique(data[, xvar]))
    rect_left <- c(seq(from = 0.5, to = nrvars, by = 2))
    rectangles <- data.frame(x.min = rect_left, x.max = rect_left + 1)
    if(length(shadecol) == 1) shadecol <- rep(shadecol, nrow(rectangles))
    p <- p + geom_rect(data = rectangles,
                       aes(xmin = x.min, xmax = x.max, ymin = -Inf, ymax = Inf),
                       fill = shadecol, colour = shadecol, alpha = 0.5)
  }

  if(rm.violins == FALSE)
    p <- p + geom_violin(data = data,
                         aes(x = xvar, y = yvar, fill = fillvar, colour = colvar))
  if(rm.violins == TRUE)
    p <- p + geom_blank(data = data,
                        aes(x = xvar, y = yvar, fill = fillvar, colour = colvar))

  ## Fill colours:
  if(length(fillcols) == 1) if(fillcols == 'pop.cols') {
      levels.sorted <- levels(data[, fillvar])[sort(match(unique(data[, fillvar]),
                                                          levels(data[, fillvar])))]
      fillcols <- popcols$col[match(levels.sorted, popcols$pop_short)]
  }
  if(length(fillcols) == 1) if(fillcols != 'pop.cols')
    fillcols <- rep(fillcols, length(unique(data[, fillvar])))
  if(is.null(fillcols))
    fillcols <- brewer.pal(n = length(unique(data[, colvar])), name = 'Set1')

  p <- p + scale_fill_manual(values = fillcols, name = legfillname)

  ## Line colours:
  if(length(linecols) == 1) if(linecols == 'pop.cols') {
    cat('Getting popcols...\n')
    levels.sorted <- levels(data[, colvar])[sort(match(unique(data[, colvar]),
                                                       levels(data[, colvar])))]
    cat('Sorted levels:', levels.sorted, '\n')
    linecols <- popcols$col[match(levels.sorted, popcols$pop_short)]
    cat('Line colours:', linecols, '\n')
  }
  if(length(linecols) == 1) if(linecols != 'pop.cols')
    linecols <- rep(linecols, length(unique(data[, colvar])))
  if(is.null(linecols))
    linecols <- brewer.pal(n = length(unique(data[, colvar])), name = 'Set1')

  if(is.null(col.labs)) col.labs <- levels(data$colvar)
  p <- p + scale_colour_manual(values = linecols, labels = col.labs, name = legcolname)

  ## Compute and show data summaries:
  if(statsum == TRUE) {
    (p <- p + stat_summary(data = data,
                          aes(x = xvar,
                              y = yvar,
                              fill = fillvar,
                              color = colvar,
                              width = 0.4),
                          fun.ymin = hpd.min,
                          fun.ymax = hpd.max,
                          geom = "errorbar",
                          size = hpdline.width,
                          position = position_dodge(width = 0.9)))
    p <- p + stat_summary(data = data,
                          aes(x = xvar,
                              y = yvar,
                              fill = fillvar,
                              color = colvar,
                              shape = shapevar),
                          fun.y = mean,
                          geom = "point",
                          size = meandot.size,
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
  my.ybreaks <- seq(y.min, y.max, by = yticks.by)
  p <- p + scale_y_continuous(expand = c(0, 0), breaks = my.ybreaks)

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
    legend.title = element_text(size = 17, face = 'bold'),
    legend.text = element_text(size = 17),
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
    if(is.null(plotdir)) plotdir <- paste0('analyses/gphocs/plots')
    if(!dir.exists(plotdir)) dir.create(plotdir, recursive = TRUE)
    plotfile <- paste0(plotdir, '/', filename, '.', filetype)
    cat('Saving plot:', plotfile, '\n')
    ggsave(filename = plotfile, plot = p,
           width = plot.width, height = plot.height)
    if(file.open == TRUE) system(paste("xdg-open", plotfile))

    if(filetype != 'pdf') {
      plotfile.pdf <- paste0(plotdir, '/', filename, '.pdf')
      ggsave(filename = plotfile.pdf, plot = p,
             width = plot.width, height = plot.height)
    }
  }
  return(p)

}


################################################################################
##### DEMOGRAPHY PLOT #####
################################################################################
dplot <- function(tt, m = NULL, x.min = NULL, y.max = NULL, x.even = FALSE,
                  col.scale = TRUE, yticks.by = 25, x.extra = 5, rm.y.ann = FALSE,
                  xlab = expression(N[e] ~ "(1 tick mark = 25k)"),
                  ylab = 'time (ka ago)',
                  ann.pops = TRUE, legend.plot = FALSE, legend.labs = NULL,
                  popnames.size = 7, popnames.col = 'black',
                  popnames.adj.vert = 0.05, popnames.adj.horz = 0,
                  plot.title = '', plotdir = NULL,
                  saveplot = FALSE, filetype = 'eps',
                  plot.width = 6, plot.height = 6,
                  file.open = TRUE, filename = NULL) {

  ## Base plot:
  p <- ggplot()
  if(x.even == TRUE | col.scale == FALSE) {
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
                 axis.title.y = element_text(size = 22, margin = margin(r = 10)),
                 plot.title = element_text(face = 'bold', size = 22, hjust = 0.5),
                 plot.margin = unit(c(1, 1.2, 0.2, 0.5), "cm"),
                 legend.text = element_text(size = 18, margin = margin(b = 8)),
                 legend.title = element_blank(), # top, right, ..
                 legend.background = element_rect(fill = "grey90", colour = "grey30"),
                 legend.key = element_rect(fill = "grey90"))
  # https://stackoverflow.com/questions/11366964/is-there-a-way-to-change-the-spacing-between-legend-items-in-ggplot2

  ## X-axis annotation:
  if(is.null(xlab))
    p <- p + theme(axis.title.x = element_blank())
  if(!is.null(xlab))
    p <- p + theme(axis.title.x = element_text(size = 22, margin = margin(t = 10)))

  ## Axes breaks:
  my.xbreaks <- seq(from = 0, to = 5000, by = 25)
  my.ybreaks <- seq(from = 0, to = 5000, by = yticks.by)
  p <- p + scale_x_continuous(expand = c(0, 1), breaks = my.xbreaks)
  p <- p + scale_y_continuous(expand = c(0, 0), breaks = my.ybreaks)

  ## Population names:
  if(ann.pops == TRUE) {
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

    if(filetype != 'pdf') {
      plotfile.pdf <- paste0(plotdir, '/', filename, '.pdf')
      ggsave(filename = plotfile.pdf, plot = p, width = plot.width, height = plot.height)
    }
  }

  return(p)
}



################################################################################
##### GET INTERMED COLOUR #####
################################################################################
get.midpoint <- function(col1, col2) {
  col <- rgb(red = (col2rgb(col1)[1] + col2rgb(col2)[1]) / 2,
             green = (col2rgb(col1)[2] + col2rgb(col2)[2]) / 2,
             blue = (col2rgb(col1)[3] + col2rgb(col2)[3]) / 2,
             maxColorValue = 255)
  return(col)
}


################################################################################
##### GET HPD #####
################################################################################
library(TeachingDemos) # has emp.hpd function
hpd.min <- function(x) emp.hpd(x)[1]
hpd.max <- function(x) emp.hpd(x)[2]


################################################################################
##### GET CONVERTED VARNAME (e.g. theta --> Ne) #####
################################################################################
cvar <- function(variable) {
  if(variable == 'theta') return(expression(N[e] ~ "(in 1000s)"))
  if(variable == 'tau') return("divergence time (ka ago)")
}


################################################################################
##### SUMMARIZE MIGRATION #####
################################################################################
m.prep <- function(Log) {
  m <- dplyr::filter(Log, var == 'm') %>%
    group_by(migfrom, migto, var) %>%
    dplyr::summarise(value = mean(cval, na.rm = TRUE))
  return(m)
}


################################################################################
##### GET PARENT POP #####
################################################################################
getparent <- function(kidpop) parentpops[match(kidpop, kidpops)]
