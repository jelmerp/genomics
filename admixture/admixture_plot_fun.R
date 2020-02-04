#### LOAD PACKAGES -------------------------------------------------------------
library(pacman)
packages <- c('gridExtra', 'grid', 'RColorBrewer', 'scales',
              'ggpubr', 'cowplot', 'ggforce', 'patchwork',
              'forcats', 'here', 'tidyverse')
p_load(char = packages, install = TRUE)


#### GET K-VALUES FOR WHICH OUTPUT FILES ARE PRESENT ---------------------------
get.Ks <- function(setID,
                   filedir = here('analyses/admixture/output')) {
  cat("## Filedir:", filedir, '\n')

  Q.files <- list.files(filedir, pattern = paste0(setID, '.[0-9+].Q'))
  K <- as.integer(gsub(paste0(setID, '.*\\.([0-9]+)\\.Q$'), '\\1', Q.files))

  cat("## K's found:\n")
  print(K)

  return(K)
}


#### K CROSS-VALIDATION PLOT --------------------------------------------------
k.plot <- function(setID,
                   plot.title = '',
                   filedir = here('analyses/admixture/output/'),
                   fig.save = FALSE,
                   figdir = 'analyses/admixture/figures/') {

  K <- get.Ks(setID, filedir = filedir)
  CV.files <- list.files(filedir, pattern = paste0(setID, '.[0-9+].admixtureOutLog.txt'))

  get.CV <- function(K) {
    K.filename <- list.files(filedir, full.names = TRUE,
                             pattern = paste0(setID, '.', K, '\\.admixtureOutLog.txt'))
    K.file <- readLines(K.filename)
    CV <- gsub('.*: (.*)', '\\1', K.file[grep('CV', K.file)])
    return(CV)
  }
  CV <- sapply(sapply(K, get.CV), '[', 1)
  CV.df <- arrange(data.frame(K, CV), K)
  CV.df$CV <- as.numeric(as.character(CV.df$CV))

  p <- ggplot(CV.df, aes(x = K, y = CV, group = 1)) +
    geom_point() +
    geom_line(color = "grey40") +
    scale_x_continuous(breaks = 1:nrow(CV.df)) +
    labs(x = 'K (number of clusters)',
         y = 'Cross-validation error',
         title = plot.title) +
    theme_bw() +
    theme(
      legend.text = element_text(size = 16),
      legend.spacing.x = unit(0, 'cm'),
      legend.spacing.y = unit(0.1, 'cm'),
      legend.margin = margin(t = 0.1, r = 0.1, b = 0.1, l = 0.1, unit = "cm"),
      legend.title = element_text(size = 16, face = 'bold'),
      legend.background = element_rect(fill = "grey90", colour = "grey30"),
      legend.key = element_rect(fill = "grey90"),
      legend.key.size = unit(1, "cm"),
      legend.text.align = 0,
      axis.text.x = element_text(size = 14),
      axis.text.y = element_text(size = 14),
      axis.ticks.length = unit(.25, "cm"),
      axis.title.x = element_text(size = 16, margin = unit(c(4, 0, 0, 0), 'mm')),
      axis.title.y = element_text(size = 14, margin = unit(c(0, 4, 0, 0), 'mm')),
      panel.grid.major = element_blank(),
      panel.grid.minor = element_blank(),
      plot.title = element_text(hjust = 0.5, size = 20),
      plot.margin = margin(0.3, 0.3, 0.3, 0.3, "cm")
      )

  if(fig.save == TRUE) {
    if(!dir.exists(figdir)) dir.create(figdir, recursive = TRUE)
    figfile <- paste0(figdir, '/', setID, '.CVplot.png')
    cat('## Saving to file:', figfile, '\n')
    ggsave(figfile, p, width = 5, height = 5)
    if(file.open == TRUE) system(paste("xdg-open", figfile))
  }

  return(p)
}


#### GET Q-DATAFRAME -----------------------------------------------------------
Qdf <- function(setID = setID,
                K = 2,
                sort_by = 'ID',
                inds_df = inds,
                indID.column = 'ID',
                convertToShortIDs = FALSE,
                filedir.Qdf = filedir) {
  cat("## K:", K, '\n')

  Qfile <- list.files(filedir.Qdf, full.names = TRUE,
                      pattern = paste0(setID, ".", K, ".Q"))
  cat("## Qfile:", Qfile, '\n')

  indlist_file <- list.files(filedir.Qdf, full.names = TRUE,
                             pattern = paste0(setID, ".indivs.txt"))
  indlist <- readLines(indlist_file)
  if(convertToShortIDs == TRUE) indlist <- substr(indlist_file, 1, 7)

  if(!all(indlist %in% inds_df[, indID.column])) {
    cat("## NOT ALL INDS IN ADMIXTOOLS ARE FOUND IN LOOKUP - MISSING INDS:\n")
    print(indlist[! indlist %in% inds_df[, indID.column]])
  }

  Q <- read.table(Qfile, as.is = TRUE) %>%
    cbind(indlist) %>%
    merge(inds_df, ., by.x = indID.column, by.y = 'indlist') %>%
    arrange(!!(sym(sort_by)))

  cat("Dimensions of Q df:", dim(Q), '\n')

  Q <- Q[dim(Q)[1]:1,]
  #Q$ID <- factor(Q$ID, levels = Q$ID[1:nrow(Q)])
  Q[, indID.column] <- factor(Q[, indID.column], levels = Q[, indID.column][1:nrow(Q)])
  Q <- gather(Q, key = 'cluster', value = 'proportion', matches("^V[0-9]+"))

  return(Q)
}


#### VERTICAL BARPLOT ----------------------------------------------------------
ggax.v <- function(Q,
                   barcols = NULL,
                   indID.column = 'ID',
                   prop.column = 'proportion',
                   group.column = 'site',
                   ylab = NULL,
                   indlabs = FALSE,
                   indlab.cols = NULL,
                   indlab.column = NULL,
                   indlab.size = 12,
                   grouplab.cols = 'grey10',
                   grouplab.size = 14,
                   grouplab.labeller = NULL,
                   grouplab.bgcol = 'white',
                   grouplab.angle = 0,
                   strip_show = TRUE,
                   mar = c(0.1, 0.1, 0.1, 0.1),
                   plot.title = '',
                   plotwidth = 8,
                   plotheight = 6,
                   return.plot = TRUE,
                   fig.save = FALSE,
                   figfile = NULL) {

  # species.labeller <- function(variable, value) c('gri', '', 'hyb', 'mur', '')
  # grouplab.labeller <- labeller(species = as_labeller(species.labeller))
  ## Multiple labellers:
  #facet_wrap(Species~var, labeller = labeller(Species=as_labeller(facet_labeller_top),
  #                                            var = as_labeller(facet_labeller_bottom)))
  # site.type.labs <- c(parapatric = 'parapatric', sympatric = 'sympatric',
  #                     zparapatric = 'parapatric')
  # grouplab.labeller <- labeller(site.type = site.type.labs)

  ## Prep:
  stackedbar.column <- 'cluster'

  ## Plot:
  p <- ggplot(Q, aes_(x = as.name(indID.column),
                      y = as.name(prop.column),
                      fill = as.name(stackedbar.column))) +
    geom_bar(position = 'stack', stat = 'identity') +
    guides(fill = FALSE) +
    scale_x_discrete(expand = c(0, 0)) +
    scale_y_continuous(expand = c(0, 0)) +
    theme(axis.title.x = element_blank(),
          axis.text.x = element_blank(),
          axis.ticks.x = element_blank(),
          axis.title.y = element_blank(),
          axis.text.y = element_blank(),
          axis.ticks.y = element_blank(),
          axis.line = element_blank(),
          plot.margin = margin(mar[1], mar[2], mar[3], mar[4], 'cm'))

  ## Colors for bars:
  if(!is.null(barcols)) p <- p + scale_fill_manual(values = barcols)

  ## y-label:
  if(!is.null(ylab)) {
    p <- p + theme(axis.title.y = element_text(angle = 90, size = 15))
    p <- p + labs(y = ylab)
  }

  ## Ind-labels - text and color:
  if(indlabs == TRUE) {
    if(!is.null(indlab.column)) {
      my.indlabs <- Q %>% filter(cluster == 'V1') %>% pull(!!(sym(indlab.column)))
      cat('## Number of indlabs:', length(my.indlabs), '\n')
      cat('## Changed indlabs:', my.indlabs, '\n')
      p <- p + scale_x_discrete(expand = c(0, 0), labels = my.indlabs)
    }
    if(!is.null(indlab.cols)) {
      indlab.cols <- as.character(Q[, indlab.cols])
      p <- p + theme(
        axis.text.x = element_text(size = indlab.size, face = 'bold',
                                   angle = 90, hjust = 1,
                                   color = as.character(indlab.cols))
        )
    } else {
      p <- p + theme(
        axis.text.x = element_text(size = indlab.size, face = 'bold',
                                   angle = 90, hjust = 1)
        )
    }
  }

  ## Facet grid:
  if(!is.null(grouplab.labeller)) {
    p <- p + facet_grid(as.formula(paste0("~", paste0(group.column, collapse = "+"))),
                        scales = "free_x", space = "free_x", labeller = grouplab.labeller)
  } else {
    p <- p + facet_grid(as.formula(paste0("~", paste0(group.column, collapse = "+"))),
                        scales = "free_x", space = "free_x")
  }

  ## Top strips - basic text and colours:
  if(strip_show == TRUE) p <- p + theme(
    strip.text = element_text(size = grouplab.size,
                              colour = grouplab.cols,
                              angle = grouplab.angle)
    )
  if(strip_show == FALSE) p <- p + theme(strip.text = element_blank())

  ## Top strips - background colour:
  if(length(grouplab.bgcol) == 1) {
    if(strip_show == TRUE) p <- p + theme(strip.background = element_rect(fill = grouplab.bgcol))
  } else {
    if(strip_show == TRUE) {
    p <- p + theme(strip.background = element_rect(fill = 'gray90'))
      g <- ggplot_gtable(ggplot_build(p))
      strip_both <- which(grepl('strip-', g$layout$name))
      k <- 1
      for (i in strip_both) {
        j <- which(grepl('rect', g$grobs[[i]]$grobs[[1]]$childrenOrder))
        g$grobs[[i]]$grobs[[1]]$children[[j]]$gp$fill <- grouplab.bgcol[k]
        k <- k + 1
      }
      p <- g
    }
  }
  if(strip_show == FALSE) p <- p + theme(strip.background = element_blank())

  ## Print and save plot:
  grid.draw(p)
  if(fig.save == TRUE) {
    if(is.null(figfile)) figfile <- 'tmp.png'
    ggsave(figfile, p, width = plotwidth, height = plotheight)
    system(paste("xdg-open", figfile))
  }
  if(return.plot == TRUE) return(p)
}


##### HORIZONTAL BARPLOT -------------------------------------------------------
ggax <- function(Q,
                 barcols = NULL,
                 labcols = NULL,
                 indlab.column = NULL,
                 indlab.size = 20,
                 indlab.firstOnly = TRUE,
                 indID.column = 'ID.short',
                 prop.column = 'proportion',
                 plot.title = '',
                 plotwidth = 6,
                 plotheight = 8,
                 figfile,
                 fig.save = FALSE,
                 return.plot = TRUE) {

  if(!is.null(labcols)) labcols <- as.character(Q[, labcols])

  p <- ggplot(Q, aes_(x = as.name(indID.column), y = as.name(prop.column))) +
    geom_bar(stat = 'identity', aes(fill = cluster)) +
    coord_flip() +
    guides(fill = FALSE) +
    labs(title = plot.title) +
    theme(plot.title = element_text(size = 20, hjust = 0.5),
          axis.title.x = element_blank(),
          axis.text.x = element_blank(),
          axis.ticks.x = element_blank(),
          axis.title.y = element_blank(),
          axis.ticks.y = element_blank(),
          axis.line = element_blank()) +
    scale_x_discrete(expand = c(0,0)) +
    scale_y_continuous(expand = c(0,0))

  ## Text and color for (ind-)labels:
  if(!is.null(indlab.column)) {
    my.indlabs <- Q %>% filter(cluster == 'V1') %>% pull(!!(sym(indlab.column)))
    cat('Number of indlabs:', length(my.indlabs), '\n')

    if(indlab.firstOnly == TRUE) {
      indlabs.org <- my.indlabs
      my.indlabs <- rep("", length(indlabs.org))
      last.indices <- length(indlabs.org) - match(unique(indlabs.org), rev(indlabs.org)) + 1
      my.indlabs[last.indices] <- indlabs.org[last.indices]
    }

    cat('Changed indlabs:', my.indlabs, '\n')
    p <- p + scale_x_discrete(expand = c(0, 0), labels = my.indlabs)
  }

  if(is.null(labcols)) {
    p <- p + theme(axis.text.y = element_text(size = indlab.size))
  } else {
    p <- p + theme(axis.text.y = element_text(size = indlab.size,
                                              color = as.character(labcols)))
  }

  ## colors for bars:
  if(!is.null(barcols)) p <- p + scale_fill_manual(values = barcols)

  ## Save plot:
  print(p)

  if(fig.save == TRUE) {
    ggsave(figfile, p, width = plotwidth, height = plotheight)
    system(paste("xdg-open", figfile))
  }
  if(return.plot == TRUE) return(p)
}


#### GET INTERMEDIATE COLOUR ---------------------------------------------------
get.midpoint <- function(col1, col2) {
  col <- rgb(red = (col2rgb(col1)[1] + col2rgb(col2)[1]) / 2,
             green = (col2rgb(col1)[2] + col2rgb(col2)[2]) / 2,
             blue = (col2rgb(col1)[3] + col2rgb(col2)[3]) / 2,
             maxColorValue = 255)
  return(col)
}
