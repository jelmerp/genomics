#### SET-UP --------------------------------------------------------------------
if(!'pacman' %in% rownames(installed.packages())) install.packages('pacman')
library(pacman)
packages <- c('plyr', 'reshape2', 'ggplot2', 'lazyeval',
              'dplyr', 'gridExtra', 'RColorBrewer')
p_load(char = packages, install = TRUE)


#### select_files() function --------------------------------------------------
## Args:
# ID.lookup: TRUE if function should grep for string given, FALSE if it should use pops.msmc/pops.legend lookup.
# to.select = individual or population ID or "all", meaning all files

select_files <- function(msmc_mode = 'ind', to.select = 'all', ID.lookup = FALSE,
                         additional.grep = FALSE,
                         method = 'samtools', filedir = NULL, quiet = FALSE) {

   if(is.null(filedir)) filedir <- paste0('output/', method, '/', msmc_mode)
   if(quiet == FALSE) cat('Folder is:', filedir, '. ')

   files <- list.files(filedir, full.names = TRUE)
   files <- files[grepl('final.txt', files)] # include.dirs = FALSE doesnt work in list.files so this is to exclude dirs.
   IDs <- sapply(strsplit(files, '\\.'), '[[', 2)

   if(msmc_mode != 'ind' && to.select != 'all') {
      if(ID.lookup == TRUE) IDs.keep <- IDs[IDs %in% pops.msmc[match(to.select, pops.legend)]]
      if(ID.lookup == FALSE) IDs.keep <- IDs[IDs %in% to.select]
      if(length(IDs.keep) == 0) stop("NO FILES DETECTED!\n")
      files <- files[apply(sapply(IDs.keep, grepl, files), 1, sum) != 0]
   }

   if(msmc_mode == 'ind' && to.select != 'all') {
      files <- files[IDs %in% to.select]
   }

   if(additional.grep != FALSE) {
      if(length(files) == 1) files <- files[grep(additional.grep, files)]
      if(length(files) > 1) files <- files[apply(sapply(additional.grep, grepl, files), 1, sum) != 0]
   }

   if(quiet == FALSE) cat('Selected files:\n')
   if(quiet == FALSE) print(files)

   if(length(files) == 0) stop("NO FILES DETECTED!\n")
   return(files)
}


#### FUNCTIONS: read_msmc_base() and read_msmc() -------------------------------
## read_msmc_base(): Read msmc output and prepare for plotting:
read_msmc_base <- function(filename, ID.add = NULL, setname = NULL, pop = NULL,
                           mutrate = mutrate.yr.a, gen.time = gentime,
                           skip_tail = 4, skip_head = 4) {

  msmc <- read.table(filename, header = TRUE)

  msmc <- arrange(melt(msmc,
                       measure.vars = c("left_time_boundary", "right_time_boundary"),
                       id.vars = c("time_index", "lambda")), time_index)
  msmc$variable <- NULL
  colnames(msmc) <- c('time_index', 'lambda', 'time_scaled')
  msmc <- msmc[, c('time_index', 'time_scaled', 'lambda')]

  msmc$time <- round((msmc$time_scaled / (mutrate * gen.time)) * gen.time)
  msmc$Ne <- (1 / msmc$lambda) / (2 * mutrate * gen.time)

  msmc <- msmc[(1 + skip_head):(nrow(msmc) - skip_tail), ]

  if(is.null(ID.add)) msmc$ID <- unlist(strsplit(filename, '\\.'))[2]
  if(!is.null(ID.add)) msmc$ID <- paste0(unlist(strsplit(filename, '\\.'))[2], ID.add)

  if(!is.null(setname)) msmc$set <- setname else msmc$set <- NA

  if(!is.null(pop)) {
      msmc$pop <- pop
      msmc$pop.col <- as.character(ind.info$pop.col[grep(pop, ind.info$popgroup)[1]])
  }
  if(is.null(pop)) {
      msmc$pop <- NA
      msmc$pop.col <- NA
  }

  return(msmc)
}

# read_msmc(): Read a single or multiple MSMC output files:
read_msmc <- function(filename, ID.add = NULL, setname = NULL, pop = NULL,
                      mutrate = mutrate.yr.a, gen.time = gentime,
                      skip_tail = 4, skip_head = 4) {

  if(length(filename) == 1) {
    msmc <- read_msmc_base(filename, mutrate = mutrate, gen.time = gen.time, setname = setname,
                           ID.add = ID.add, pop = pop, skip_tail = skip_tail, skip_head = skip_head)
  }

  if(length(filename) > 1) {
    msmc <- do.call(rbind, lapply(filename, read_msmc_base, mutrate = mutrate, gen.time = gen.time,
                                  ID.add = ID.add, setname = setname, pop = pop,
                                  skip_tail = skip_tail, skip_head = skip_head))
  }

  return(msmc)
}


#### plot_msmc() function ------------------------------------------------------
plot_msmc <- function(msmc_output, col.by = 'ID', my.cols = NULL,
                      linetype.by = 'fixed', lwd = 1.2,
                      ylim = NULL, xlim = NULL, log.x = TRUE, log.y = FALSE,
                      my.xticks = NULL, my.xtext = NULL, my.yticks = NULL, my.ytext = NULL,
                      plot.legend = TRUE, legend.position = 'top',
                      legend.labels = NULL, plot.title = NULL, save.plot = TRUE,
                      filetype = 'png', filename = NULL, file.open = TRUE) {

  msmc_output$fixed <- NA # for mapping on a variable with no variation

  ## Linetypes [Improve: do same for colour as for linetype]
  linetypes <- c('solid', 'longdash', 'twodash', 'dashed', 'dotted', 'dotdash')
  linetype.by.column <- grep(linetype.by, colnames(msmc_output))
  msmc_output$Linetype <- linetypes[match(msmc_output[, linetype.by.column],
                                          sort(unique(msmc_output[, linetype.by.column])))]
  if(all(is.na(msmc_output$Linetype))) msmc_output$Linetype <- 'solid'

  if(log.y == FALSE) msmc_output$Ne <- msmc_output$Ne / 1000

  ## Initiate plot:
  p <- ggplot()

  ## Plot lines:
  if(col.by == 'ID')
    p <- p + geom_line(data = msmc_output, size = lwd,
                       aes(x = time, y = Ne, linetype = Linetype, colour = ID))
  if(col.by == 'set')
    p <- p + geom_line(data = msmc_output, size = lwd,
                       aes(x = time, y = Ne, alpha = ID, linetype = Linetype, colour = set))
  if(col.by == 'pop')
    p <- p + geom_line(data = msmc_output, size = lwd,
                       aes(x = time, y = Ne, alpha = ID, linetype = Linetype, colour = pop.col))

  ## Colour scheme:
  if(col.by != 'pop')
    if(is.null(legend.labels)) legend.labels <- sort(unique(msmc_output$ID))
    if(is.null(my.cols)) my.cols <- c("#999999", "#E69F00", "#56B4E9", "#009E73", "#F0E442",
                                      "#0072B2", "#D55E00", "#CC79A7", 'red', 'black')
    p <- p + scale_colour_manual(values = my.cols, labels = legend.labels)

  if(col.by == 'pop') {
    col.order <- order(match(unique(msmc_output$pop), poporder))

    if(length(unique(msmc_output$pop.col)) > 1)
      p <- p + scale_colour_identity(guide = 'legend',
                                     breaks = unique(msmc_output$pop.col)[col.order],
                                     labels = unique(msmc_output$set)[col.order])

    if(length(unique(msmc_output$pop.col)) == 1)
      p <- p + scale_colour_identity(guide = 'none',
                                     breaks = unique(msmc_output$pop.col)[col.order],
                                     labels = unique(msmc_output$set)[col.order])
   }

  ## Linetypes:
  linetype.order <- order(unique(msmc_output[, linetype.by.column]))

  if(length(unique(msmc_output$Linetype)) > 1)
    p <- p + scale_linetype_identity(guide = 'none',
                                     breaks = unique(msmc_output$Linetype)[linetype.order],
                                     labels = unique(msmc_output$set)[linetype.order])
  if(length(unique(msmc_output$Linetype)) == 1)
    p <- p + scale_linetype_identity(guide = 'none',
                                     breaks = unique(msmc_output$Linetype)[linetype.order],
                                     labels = unique(msmc_output$set)[linetype.order])

  p <- p + scale_alpha_manual(values = rep(1, 100), guide = FALSE)

  ## Theme:
  p <- p + theme_bw()
  p <- p + theme(plot.margin = unit(c(0.5, 1, 1, 0.5), "lines")) # top, right, ..
  p <- p + theme(axis.text.y = element_text(size = 20, color = 'grey20'))
  p <- p + theme(axis.text.x = element_text(size = 20, color = 'grey20'))
  p <- p + theme(axis.title.x = element_text(size = 20, vjust = -1))
  p <- p + theme(axis.title.y = element_text(size = 20)) #, vjust = 0.3))
  #p <- p + theme(panel.grid.major = element_blank(), panel.grid.minor=element_blank())

  if(plot.legend == TRUE) {
    p <- p + theme(legend.text = element_text(size = 19))
    p <- p + theme(legend.title = element_blank())
    p <- p + theme(legend.margin = unit(0, 'line'))
    p <- p + theme(legend.key.height = unit(0.8, "cm"))
    p <- p + theme(legend.key.width = unit(1, "cm"))
    p <- p + theme(legend.position = legend.position)
  }
  if(plot.legend == FALSE) p <- p + theme(legend.position = 'none')
  if(!is.null(plot.title)) {
     p <- p + labs(title = plot.title)
     p <- p + theme(plot.title = element_text(size = 18, face = 'bold'))
  }
  p <- p + labs(x = 'Time (years ago)', y = expression(N[e] ~ ~ (x10^3)))

  ## Log x-scale:
  if(log.x == TRUE) {

    ## X and Y ticks and labels:
    if(is.null(my.xticks))
      my.xticks <- c(seq(from = 1e+03, to = 9e+03, by = 1e+03),
                     seq(from = 1e+04, to = 9e+04, by = 1e+04),
                     seq(from = 1e+05, to = 9e+05, by = 1e+05),
                     seq(from = 1e+06, to = 9e+06, by = 1e+06),
                     seq(from = 1e+07, to = 9e+07, by = 1e+07))

    if(is.null(my.xtext))
      my.xtext <- c(bquote('10'^3), rep('', 8), bquote('10'^4), rep('', 8), bquote('10'^5),
                    rep('', 8), bquote('10'^6), rep('', 8), bquote('10'^7), rep('', 8))

    if(is.null(xlim)) {
      p <- p + scale_x_log10(breaks = my.xticks, labels = my.xtext)
    } else {
      p <- p + scale_x_log10(breaks = my.xticks, labels = my.xtext, limits = xlim)
    }
  }

  ## Log y-scale:
  if(log.y == TRUE) {

    if(is.null(my.yticks))
      my.yticks <- c(seq(from = 1e+02, to = 9e+02, by = 1e+02),
                     seq(from = 1e+03, to = 9e+03, by = 1e+03),
                     seq(from = 1e+04, to = 9e+04, by = 1e+04),
                     seq(from = 1e+05, to = 9e+05, by = 1e+05),
                     seq(from = 1e+06, to = 9e+06, by = 1e+06),
                     seq(from = 1e+07, to = 9e+07, by = 1e+07),
                     seq(from = 1e+08, to = 9e+08, by = 1e+08),
                     seq(from = 1e+09, to = 9e+09, by = 1e+09))

    if(is.null(my.ytext))
      my.ytext <- c(rep('', 9), 1, rep('', 3), 5, rep('', 4), 10, rep('', 8), 100,
                    rep('', 8), 1000, rep('', 8), 10000, rep('', 8), 100000,
                    rep('', 8), 1000000, rep('', 8))

    if(is.null(ylim)) {
      p <- p + scale_y_log10(breaks = my.yticks, labels = my.ytext)
    } else {
      p <- p + scale_y_log10(breaks = my.yticks, labels = my.ytext, limits = ylim)
    }

  }

  ## Save plot:
  if(save.plot == TRUE) {
    if(is.null(filename) & is.null(plot.title)) plot.title <- msmc_output$ID[1]
    if(is.null(filename)) filename <- plot.title
    filename.full <- paste0('figures/', filename, '.', filetype)
    ggsave(plot = p, filename.full, width = 10, height = 6)
    if(file.open == TRUE) system(paste('xdg-open', filename.full))
   }

  print(p)
  return(p)
}
