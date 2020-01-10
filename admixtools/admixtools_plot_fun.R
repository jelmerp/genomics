## According to qpDstat:
# Positive D: gene flow between 1 and 3
# Negative D: gene flow between 2 and 3

## Formula:
# Positive D =  more ABBA = gene flow between 2 and 3
# calcD <- function(ABBA, BABA) { (ABBA - BABA) / (ABBA + BABA) }
# calcD(154728, 111720)
# calcD(124562, 316312)

################################################################################
##### RETURN DFs #####
################################################################################
return.dfmode <- function(file.id,
                          running.mode = 'dmode',
                          include.outgroup = FALSE) {

  outputfile <- paste0('analyses/admixtools/output/', file.id, '.', running.mode, '.out')
  output <- read.delim(outputfile, sep = "", header = FALSE, as.is = TRUE)
  output <- output[, -1] # Get rid of "result:" column

  if(running.mode == 'dmode')
    colnames(output) <- c('popA', 'popB', 'popC', 'popD', 'D',
                          'se', 'Z', 'BABA', 'ABBA', 'nrSNPS')
  if(running.mode == 'fmode')
    colnames(output) <- c('popA', 'popB', 'popC', 'popD', 'f4',
                          'se', 'Z', 'BABA', 'ABBA', 'nrSNPS')

  if(include.outgroup == FALSE)
    output <- output %>%
      mutate(popcomb = paste0('(', popA, ',', popB, '),', popC))

  if(include.outgroup == TRUE)
    output <- output %>%
      mutate(popcomb = paste0('(', popA, ',', popB, '),', popC, ',', popD))

  output <- output %>% arrange(popcomb)

  return(output)
}

return.f4ratio <- function(file.id) {
  outputfile <- paste0('analyses/admixtools/output/', file.id, '.f4ratio.out')

  output <- read.delim(outputfile, sep = "", header = FALSE)
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

return.f3 <- function(file.id) {
  outputfile <- paste0('analyses/admixtools/output/', file.id, '.f3.out')
  output <- read.delim(outputfile, sep = "", header = FALSE)
  output <- output[, -1]
  colnames(output) <- c('popA', 'popB', 'popX', 'f3', 'se', 'Z', 'nrSNPs')
  output <- output %>% mutate(f3 = round(f3, 3), se = round(se, 5), Z = round(Z, 2))
  return(output)
}


################################################################################
##### PLOT #####
################################################################################
plot.dstats <- function(d.df,
                        marg.sig = FALSE,
                        d.breaks = seq(from = -1, to = 1, by = 0.05),
                        ylab = "D\nnegative D = p1p3 admixture\npositive D = p2p3 admixture",
                        fig.save = FALSE,
                        figfile = NULL) {

  if(marg.sig == TRUE) {
    d.df$sig <- cut(abs(d.df$Z), breaks = c(0, 2, 3, Inf),
                    labels = c('black', 'orange', 'red'))
    d.df$siglab <- gsub('black', '|Z|<2', d.df$sig)
    d.df$siglab <- gsub('orange', '3>|Z|>2', d.df$siglab)
    d.df$siglab <- gsub('red', '|Z|>3', d.df$siglab)
    } else {
    d.df$sig <- cut(abs(d.df$Z), breaks = c(0, 3, Inf),
                    labels = c('black', 'red'))
    d.df$siglab <- gsub('black', '|Z|<3', d.df$sig)
    d.df$siglab <- gsub('red', '|Z|>3', d.df$siglab)
    }

  col.labs.all <- c('|Z|<2', '3>|Z|>2', '|Z|>3', '|Z|<3')
  col.labs <- col.labs.all[col.labs.all %in% d.df$siglab]

  p <- ggplot(d.df, aes(x = popcomb, y = -D)) +
    geom_pointrange(aes(ymax = -d.df$D + d.df$se,
                        ymin = -d.df$D - d.df$se,
                        colour = sig)) +
    geom_hline(yintercept = 0, colour = 'grey40') +
    labs(y = ylab) +
    scale_y_continuous(breaks = d.breaks) +
    scale_colour_identity(guide = 'legend', labels = col.labs, name = '') +
    coord_flip() +
    theme_bw() +
    theme(panel.border = element_rect(colour = 'grey20', size = 1),
          axis.text.x = element_text(size = 14),
          axis.text.y = element_text(size = 14),
          axis.title.x = element_text(size = 14),
          axis.title.y = element_blank(),
          panel.grid.major.y = element_blank(),
          panel.grid.minor.y = element_blank(),
          plot.title = element_text(size = 18, hjust = 2),
          legend.position = 'top',
          legend.text = element_text(size = 16),
          plot.margin = margin(0.3, 0.3, 0.3, 0.3, "cm"))

  if(fig.save == TRUE) {
    ggsave(figfile, p, width = 6, height = 10)
    system(paste('xdg-open', figfile))
  }

  print(p)
  return(p)
}

plot.f4r <- function(f.df, ylims = c(0, 1.05), alpha.breaks = c(0, 0.2, 0.4, 0.6, 0.8, 1),
                     figfile = NULL, fig.save = FALSE) {

  p <- ggplot(f.df, aes(x = popcomb, y = alpha)) +
    geom_pointrange(aes(ymax = f.df$alpha + f.df$se, ymin = f.df$alpha - f.df$se, colour = sig)) +
    geom_hline(yintercept = 0, colour = 'grey40') +
    geom_hline(yintercept = 1, colour = 'grey40') +
    scale_colour_manual(values = c('black', 'red'), labels = c('|Z| < 3', '|Z| > 3'), name = '') +
    coord_flip() +
    labs(y = expression(paste(alpha, " (prop. P2 ancestry in Px)"))) +
    scale_y_continuous(limits = ylims, breaks = alpha.breaks) +
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

  if(fig.save == TRUE) {
    ggsave(figfile, p, width = 9, height = 7)
    system(paste('xdg-open', figfile))
  }

  print(p)
  return(p)
}
