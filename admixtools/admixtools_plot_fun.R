# calcD <- function(ABBA, BABA) { (ABBA - BABA) / (ABBA + BABA) }

#### PACKAGES ------------------------------------------------------------------
if(!'pacman' %in% rownames(installed.packages())) install.packages('pacman')
library(pacman)
packages <- c('ggpubr', 'cowplot', 'tidyverse', 'forcats', 'here')
p_load(char = packages, install = TRUE)


#### FUNCTIONS TO RETURN DFs FROM ADMIXTOOLS OUTPUT ----------------------------
## D-statistics:
prep_d <- function(atools_file, sort = TRUE,
                   running_mode = 'dmode',
                   include_outgroup = FALSE) {

  output <- read.delim(atools_file, sep = "", header = FALSE, as.is = TRUE)
  output <- output[, -1] # Get rid of "result:" column

  if(running_mode == 'dmode')
    colnames(output) <- c('popA', 'popB', 'popC', 'popD', 'D',
                          'se', 'Z', 'BABA', 'ABBA', 'nSNP')
  if(running_mode == 'fmode')
    colnames(output) <- c('popA', 'popB', 'popC', 'popD', 'f4',
                          'se', 'Z', 'BABA', 'ABBA', 'nSNP')

  if(include_outgroup == FALSE)
    output <- output %>%
      mutate(popcomb = paste0('(', popA, ',', popB, '),', popC),
             popcomb2 = paste0(popA, popB, popC))

  if(include_outgroup == TRUE)
    output <- output %>%
      mutate(popcomb = paste0('(', popA, ',', popB, '),', popC, ' | ', popD),
             popcomb2 = paste0(popA, popB, popC, popD))

  if(sort == TRUE) output <- output %>% arrange(popcomb)

  return(output)
}

## f4-ratio:
prep_f4r <- function(atools_file) {

  output <- read.delim(atools_file, sep = "", header = FALSE)
  output <- output[, -c(1, 6:8, 10)]
  colnames(output) <- c('popA', 'popD', 'popX', 'popC', 'popB', 'alpha', 'se', 'Z')
  output <- output[, c('popA', 'popB', 'popX', 'popC', 'popD', 'alpha', 'se', 'Z')]

  output <- output %>%
    mutate(alpha = round(alpha, 3),
           se = round(se, 5),
           Z1 = round(Z, 2),
           Z2 = round(abs(1 - output$alpha) / output$se, 2),
           Z = ifelse(alpha < 0.5, Z1, Z2),
           sig = ifelse(abs(Z) > 3, 'b_sig', 'a_nonsig'),
           popcomb = paste0('(', popA, ',', popB, '),[', popX, '],', popC))

  return(output)
}

## f3-test:
prep_f3 <- function(atools_file) {
  output <- read.delim(atools_file, sep = "", header = FALSE)
  output <- output[, -1]
  colnames(output) <- c('popA', 'popB', 'popX', 'f3', 'se', 'Z', 'nrSNPs')
  output <- output %>% mutate(f3 = round(f3, 3), se = round(se, 5), Z = round(Z, 2))
  return(output)
}


#### PLOTTING FUNCTIONS --------------------------------------------------------
## Plot D-statistics:
plot_d <- function(d,
                   autosort = TRUE,
                   marg_sig = FALSE,
                   breaks_by = 0.05,
                   draw_rect = FALSE,
                   rect_coord = NULL,
                   hline = NULL, hline2 = NULL,
                   ylab = "D\nD<0: p1p3 admixture\nD>0: p2p3 admixture",
                   pointsize = 1,
                   axis.title.x.size = 16,
                   axis.text.x.size = 16,
                   axis.text.y.size = 14,
                   figsave = FALSE,
                   figdims = c(5, 5), # figdims: c(width, height)
                   figfile = NULL) {

  if(autosort == TRUE) {
  d <- d %>%
    arrange(desc(popcomb)) %>%
    mutate(popcomb = fct_inorder(factor(popcomb)))
  }

  if(marg_sig == TRUE) {
    d$sig <- cut(abs(d$Z), breaks = c(0, 2, 3, Inf), labels = c('black', 'orange', 'red'))
    d$siglab <- gsub('black', '|Z|<2', d$sig)
    d$siglab <- gsub('orange', '3>|Z|>2', d$siglab)
    d$siglab <- gsub('red', '|Z|>3', d$siglab)
    } else {
    d$sig <- cut(abs(d$Z), breaks = c(0, 3, Inf), labels = c('black', 'red'))
    d$siglab <- gsub('black', '|Z|<3', d$sig)
    d$siglab <- gsub('red', '|Z|>3', d$siglab)
    }

  col.labs.all <- c('|Z|<2', '3>|Z|>2', '|Z|>3', '|Z|<3')
  col.labs <- col.labs.all[col.labs.all %in% d$siglab]
  d$siglab <- factor(d$siglab, levels = col.labs)

  cols.all <- c('grey01', 'orange', 'red', 'black')
  mycols <- cols.all[cols.all %in% d$sig]
  d$sig <- factor(d$sig, levels = mycols)

  d_breaks = seq(from = -1, to = 1, by = breaks_by)

  p <- ggplot(d, aes(x = popcomb, y = -D))
  if(draw_rect == TRUE) {
    p <- p + geom_rect(xmin = rect_coord[1], xmax = rect_coord[2],
                       ymin = rect_coord[3], ymax = rect_coord[4],
                       fill = 'grey70')
  }
  p <- p + geom_hline(yintercept = 0, colour = 'grey40', size = 1.5, linetype = 'dotdash') +
    geom_pointrange(aes(ymax = -d$D + d$se, ymin = -d$D - d$se, colour = sig),
                    size = pointsize) +
    labs(y = ylab) +
    scale_y_continuous(breaks = d_breaks) +
    scale_colour_identity(guide = 'legend', labels = col.labs, name = '') +
    coord_flip() +
    theme_bw() +
    theme(panel.border = element_rect(colour = 'grey20', size = 1),
        axis.text.x = element_text(size = axis.text.x.size),
        axis.text.y = element_text(size = axis.text.y.size),
        axis.title.x = element_text(size = axis.title.x.size, colour = 'grey30'),
        axis.title.y = element_blank(),
        #panel.grid.major.x = element_line(size = 0.5, colour = 'grey70'),
        panel.grid.minor.x = element_blank(),
        panel.grid.major.y = element_line(size = 0.2, colour = 'grey70'),
        panel.grid.minor.y = element_blank(),
        plot.title = element_text(size = 18, hjust = 2),
        legend.position = 'top',
        legend.text = element_text(size = 16),
        plot.margin = margin(0.2, 0.2, 0.2, 0.2, "cm"))

  if(!is.null(hline)) p <- p + geom_vline(aes(xintercept = hline), size = 1)
  if(!is.null(hline2)) p <- p + geom_vline(aes(xintercept = hline2), size = 1)

  if(figsave == TRUE) {
    ggsave(figfile, p, width = figdims[1], height = figdims[2])
    system(paste('xdg-open', figfile))
  }
  return(p)
}

## Plot f4-ratio test:
plot_f4r <- function(f_df,
                     ylims = c(0, 1.05),
                     alpha_breaks = c(0, 0.2, 0.4, 0.6, 0.8, 1),
                     figsave = FALSE, figfile = NULL) {

  p <- ggplot(f_df, aes(x = popcomb, y = alpha)) +
    geom_pointrange(aes(ymax = f_df$alpha + f_df$se,
                        ymin = f_df$alpha - f_df$se, colour = sig)) +
    geom_hline(yintercept = 0, colour = 'grey40') +
    geom_hline(yintercept = 1, colour = 'grey40') +
    scale_colour_manual(values = c('black', 'red'),
                        labels = c('|Z| < 3', '|Z| > 3'),
                        name = '') +
    coord_flip() +
    labs(y = expression(paste(alpha, " (prop. P2 ancestry in Px)"))) +
    scale_y_continuous(limits = ylims, breaks = alpha_breaks) +
    theme_bw() +
    theme(panel.border = element_rect(colour = 'grey20', size = 1),
          axis.text.x = element_text(size = 18),
          axis.text.y = element_text(size = 15),
          axis.title.x = element_text(size = 17),
          axis.title.y = element_blank(),
          panel.grid.major.y = element_blank(),
          panel.grid.minor.y = element_blank(),
          plot.title = element_text(size = 18, hjust = 2),
          legend.position = 'top',
          legend.text = element_text(size = 16),
          plot.margin = margin(0.5, 0.5, 0.5, 0.5, "cm"))

  if(figsave == TRUE) {
    ggsave(figfile, p, width = 9, height = 7)
    system(paste('xdg-open', figfile))
  }
  return(p)
}
