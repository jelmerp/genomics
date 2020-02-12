#### PROCESS SAMTOOLS FLAGSTAT OUTPUT ------------------------------------------
## Process a single file:
read.flagstats <- function(ID, rawbam = TRUE, bamdir = 'qc/bam/') {
  if(rawbam == TRUE) infile_flagstats <- paste0(bamdir, '/', ID, '.rawbam.samtools-flagstat.txt')
  if(rawbam == FALSE) infile_flagstats <- paste0(bamdir, '/', ID, '.samtools-flagstat.txt')
  flagstats <- readLines(infile_flagstats)

  bam.flag.total <- as.integer(unlist(strsplit(flagstats[grep('in total', flagstats)], split = ' '))[1])
  bam.flag.mapped <- as.integer(unlist(strsplit(flagstats[grep('mapped.*%', flagstats)], split = ' '))[1])
  bam.flag.paired <- as.integer(unlist(strsplit(flagstats[grep('paired in sequencing', flagstats)], split = ' '))[1])
  bam.flag.proppaired <- as.integer(unlist(strsplit(flagstats[grep('properly paired', flagstats)], split = ' '))[1])

  return(c(ID, bam.flag.total, bam.flag.mapped, bam.flag.paired, bam.flag.proppaired))
}

## Wrapper to process multiple files:
read.flagstats.all <- function(IDs = IDs.long, rawbam = TRUE) {
  flagstats <- data.frame(
    do.call(rbind, lapply(IDs, read.flagstats, rawbam = rawbam)), stringsAsFactors = FALSE
  )
  colnames(flagstats) <- c('ID', 'bam.flag.total', 'bam.flag.mapped',
                           'bam.flag.paired', 'bam.flag.proppaired')
  integer_cols <- c('bam.flag.total', 'bam.flag.mapped', 'bam.flag.paired', 'bam.flag.proppaired')
  flagstats[, integer_cols] <- lapply(flagstats[, integer_cols], as.integer)
  return(flagstats)
}

#### PROCESS FASTQ STATS -------------------------------------------------------
## Process a single file:
read.fastqstats <- function(ID, read) {
  infile_fastqstats <- paste0(dir_fastqstats, '/', ID, '.', read, '.fastqstats.txt')
  fastqstats <- read.delim(infile_fastqstats, header = FALSE, as.is = TRUE) %>%
    filter(V1 %in% c('reads', 'len mean', '%dup', 'qual mean')) %>%
    pull(V2)
  return(c(ID, read, fastqstats))
}

## Wrapper to process multiple files:
read.fastqstats.all <- function(IDs = IDs.long, read = 'R1') {
  fastqstats <- data.frame(
    do.call(rbind, lapply(IDs, read.fastqstats, read = read)), stringsAsFactors = FALSE
    )

  colnames(fastqstats) <- c('ID', 'read', 'fastq.reads', 'fastq.meanlen',
                            'fastq.pct.dup', 'fastq.qual')

  fastqstats$fastq.reads <- as.integer(fastqstats$fastq.reads)
  fastqstats$fastq.meanlen <- round(as.numeric(fastqstats$fastq.meanlen), 2)
  fastqstats$fastq.pct.dup <- round(as.numeric(fastqstats$fastq.pct.dup), 2)
  fastqstats$fastq.qual <- round(as.numeric(fastqstats$fastq.qual), 4)

  fastqstats <- fastqstats %>%
    select(ID, read, fastq.reads, fastq.qual, fastq.pct.dup, fastq.meanlen)

  return(fastqstats)
}

#### PROCESS EA-UTILS BAM STATS ------------------------------------------------
## Process a single file:
read.bamstats <- function(ID,
                          my.colnames.initial = bamstats.colnames.initial,
                          rawbam = TRUE) {
  if(rawbam == FALSE) infile_bamstats <- paste0(dir_bamstats, '/', ID, '.ea-utils-samstats.txt')
  if(rawbam == TRUE) infile_bamstats <- paste0(dir_bamstats, '/', ID, '.rawbam.ea-utils-samstats.txt')

  bamstats <- read.delim(infile_bamstats, header = FALSE, as.is = TRUE, nrows = 42)
  bamstats <- bamstats[1:which(bamstats$V1 == '%N'), ]

  bamstats.df <- setNames(data.frame(matrix(ncol = nrow(bamstats), nrow = 1)), bamstats$V1)
  bamstats.df[1, ] <- bamstats$V2

  if(ncol(bamstats.df) < 42) {
    complete.df <- setNames(data.frame(matrix(ncol = 42, nrow = 0)), my.colnames.initial)

    if(any(colnames(bamstats.df) == 'distant mate'))
      colnames(bamstats.df)[which(colnames(bamstats.df) == 'distant mate')] <- 'distant mates'

    bamstats.df <- merge(complete.df, bamstats.df, by = colnames(bamstats.df), all.y = TRUE) %>%
      select(my.colnames.initial)
  }

  bamstats.df$ID <- ID
  bamstats.df <- bamstats.df %>% select(ID, my.colnames.initial)

  return(bamstats.df)
}

## Wrapper to process multiple files:
read.bamstats.all <- function(IDs, my.colnames.final = bamstats.colnames.final) {
  bamstats <- as.data.frame(do.call(rbind, lapply(IDs, read.bamstats)))
  colnames(bamstats) <- c('ID', my.colnames.final)

  bamstats$reads <- as.integer(bamstats$reads)
  bamstats$pct.ambiguous <- as.numeric(bamstats$pct.ambiguous)
  bamstats$mapq.mean <- as.numeric(bamstats$mapq.mean)

  return(bamstats)
}


## Create a boxplot comparing stats across species:
ggbox <- function(my.df, my.y, my.x = 'species.short',
                  ytitle = '', xtitle = NULL, ptitle = NULL, xlabs = NULL,
                  saveplot = TRUE, figdir = 'qc/plots/') {

  p <- ggplot(data = my.df) +
    geom_boxplot(aes_string(x = my.x, y = my.y),
                 outlier.color = NA) +
    geom_jitter(aes_string(x = my.x, y = my.y),
                width = 0.05, colour = 'grey30', size = 1.5) +
    labs(y = ytitle) +
    theme(
      axis.text.x = element_text(size = 16),
      axis.text.y = element_text(size = 16),
      axis.title.x = element_text(size = 18),
      axis.title.y = element_text(size = 18),
      plot.margin = unit(c(0.5, 0.5, 0.5, 0.5), "cm"),
      plot.title = element_text(hjust = 0.5, size = 24)
    )

  if(!is.null(xlabs)) p <- p + scale_x_discrete(labels = xlabs)
  if(!is.null(xtitle)) p <- p + labs(y = ytitle, x = xtitle)
  if(!is.null(ptitle)) p <- p + ggtitle(ptitle)

  if(saveplot == TRUE) {
    figfile <- paste0(figdir, '/', my.y, '.png')
    ggsave(figfile, p, width = 6, height = 6)
    system(paste('xdg-open', figfile))
  }
  return(p)
}
