# DFO DIL DFI DOL interpretation
#  -   -   0   0     P4 -> P12
#  0   -   -   -     P4 -> P2
#  -   0   +   +     P4 -> P1

# DFO: P1/P3 & P1/P4
# DIL: P2/P3 & P2/P4
# DFI: P1/P3 & P2/P3
# DOL: P1/P4 & P2/P4

# One assumption that may be violated in real data sets is the expectation of uniform substitution
# rates across the tree. If a particular taxon has a much overall higher substitution rate than the
# others, then all distances involving that taxon would be relatively higher due to an increased number
# of substitutions rather than an introgression involving its sister taxon. This rate increase can be due
# to biological causes or simply a result of disproportionate error in one sequence or genome.
# There are two straightforward solutions to these lineage-specific effects.
# The first would be to change the expected  DD -statistic values away from a 1:1 ratio when there is
# a prior expectation that substitution rates are not equal between sister taxa in a subgroup.
# The second would be to exclude the terminal-branch-substitution site patterns (AAABA, AABAA,ABAAA, and
# BAAAA) from all calculations and instead to use them to calculate linage-specific error rates
# (as was done in the original  DD -statistic analysis; Green et al. 2010).  As long as corresponding
# pairs of counts are excluded from both sides of the equation, the expectation of equality of the left
# and right terms for each  DFOILDFOIL  statistic is not violated. We also note that four-taxon patterns
# containing a single derived allele (BAAA and ABAA) could also be used in the four-taxon D-statistic
# without violating any assumptions of this test (as is done in the 4sp method; Garrigan et al. 2012).


################################################################################
##### READ INPUT AND OUTPUT #####
################################################################################
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


################################################################################
##### PLOT #####
################################################################################
plot.dfoil <- function(dfoil.df, fileID.suffix, save.plot = TRUE) {

  dfoil.df.plot <- dfoil.df %>%
    select(DFO, DIL, DFI, DOL) %>%
    melt(measure.vars = c('DFO', 'DIL', 'DFI', 'DOL'))

  p <- ggplot(dfoil.df.plot, aes(variable, value))
  p <- p + geom_col()
  p <- p + scale_fill_discrete(name = 'statistic')
  #p <- p + scale_y_continuous(limits = c(-0.09, 0.15))
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

  print(p)

  if(save.plot == TRUE) {
    plotfile <- paste0('analyses/dfoil/figures/', fileID.suffix, '.png')
    ggsave(plotfile, plot = p, width = 5, height = 6)
    system(paste("xdg-open", plotfile))
  }
}


