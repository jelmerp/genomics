#### PACKAGES ------------------------------------------------------------------
suppressPackageStartupMessages(library(tidyverse))
suppressPackageStartupMessages(library(vcfR))
suppressPackageStartupMessages(library(adegenet))
suppressPackageStartupMessages(library(dartR))
suppressPackageStartupMessages(library(viridis))
suppressPackageStartupMessages(library(plotly))
suppressPackageStartupMessages(library(cowplot))
suppressPackageStartupMessages(library(patchwork))

#### FUNCTIONS TO PREP AND RUN MANTEL TEST -------------------------------------
## Prep metadata:
prep_metadata <- function(setID) {
  ## Read and process metadata:
  lookup_raw <- read.delim(infile_lookup, as.is = TRUE) %>%
    select(ID, Sample_ID, species, sp, site)
  pops <- read.csv(infile_pops, as.is = TRUE) %>%
    select(site, site_short, site_lump, sp, pop2)
  sites <- read.delim(infile_sites, as.is = TRUE) %>%
    select(site, sp, lat, lon) %>%
    merge(., pops, by = c('site', 'sp'), all.x = TRUE)

  # Subset to inds in VCF:
  #stopifnot(all(snps_raw@ind.names %in% lookup_raw$ID)) # Check if all VCF inds are in lookup
  #lookup_raw_sel <- lookup_raw %>% filter(ID %in% snps_raw@ind.names)
  lookup_raw_sel <- lookup_raw

  # Include site GPS coords in lookup:
  #stopifnot(all(lookup_raw_sel$site %in% sites$site)) # Check if all sites are in site-lookup
  lookup <- lookup_raw_sel %>%
    merge(., sites, by = c('site', 'sp')) %>%
    mutate(site_short = ifelse(is.na(site_short), site, site_short),
           site_lump = ifelse(is.na(site_lump), site, site_lump),
           pop2 = ifelse(is.na(pop2), sp, pop2))
}

## Read VCF into genlight object:
read_vcf <- function(infile_vcf, lookup, RDS_vcf,
                     overwrite_RDS = FALSE) {

  if(file.exists(RDS_vcf)) {
    message("RDS file RDS_vcf exists...")
    if(overwrite_RDS == FALSE) {
      message("Reading existing RDS file RDS_vcf...")
      snps <- readRDS(RDS_vcf)
      return(snps)
    } else {
      message("Overwriting existing RDS file RDS_vcf...")
    }
  }

  snps <- vcfR2genlight(read.vcfR(infile_vcf))
  if(nchar(snps@ind.names)[1] > 1)
    snps@ind.names <- substr(snps@ind.names, 1, 7) # Long->short IDs

  ## Get lookup with only matching inds & in same order as in "snps" object:
  lookup <- lookup %>%
    filter(ID %in% snps@ind.names) %>%
    arrange(match(ID, snps@ind.names))

  ## Add GPS and population assignments to genlight object:
  snps@other$latlong <- lookup %>% select(lat, lon) # Include lat-long in genlight object
  snps@pop <- lookup %>% pull(site_short) %>% factor() # Include pop-info

  #print(snps@other$latlong)
  #print(snps@pop)

  saveRDS(snps, RDS_vcf)
  return(snps)
}

## Run Mantel test:
mantel_run <- function(snps, lookup, inds_sel, RDS_mantel,
                       testrun = FALSE, overwrite_RDS = FALSE) {

  cat('## mantel_run: testrun:', testrun, '\n')
  cat('## mantel_run: overwrite RDS:', overwrite_RDS, '\n\n')

  if(file.exists(RDS_mantel)) {
    message("\nRDS file RDS_mantel exists...")
    if(overwrite_RDS == FALSE) {
      message("\nReading existing RDS file RDS_mantel...")
      mantel <- readRDS(RDS_mantel)
      return(mantel)
    } else {
      message("\nOverwriting existing RDS file RDS_mantel...")
    }
  }

  ## Subset inds:
  snps <- gl.keep.ind(snps, ind.list = inds_sel)

  ## Do Mantel test at population level (uses FST):
  if(testrun == FALSE) {
    mantel <- gl.ibd(snps)
  }

  if(testrun == TRUE) {
    message("\nDoing testrun with 100 SNPs...")
    mantel <- gl.ibd(snps[, 1:100])
  }

  ## Adding lookup to mantel list:
  mantel$lookup <- filter(lookup, ID %in% inds_sel)

  saveRDS(mantel, RDS_mantel)
}

## Mantel test wrap:
mantel_wrap <- function(subset, snps, lookup, ...) {
  #my_subset = subsets['macsp3']

  (subsetID <- names(subset))
  (my_sps <- subset[[1]])

  RDS_mantel <- paste0(outdir_RDS, setID, '_', subsetID, '_mantel.RDS')

  (inds_sel <- lookup %>%
      filter(ID %in% snps@ind.names, sp %in% my_sps) %>%
      pull(ID))

  mantel <- mantel_run(snps, lookup, inds_sel, RDS_mantel, ...)
}


#### FUNCTIONS TO PLOT MANTEL TEST RESULTS -------------------------------------
# mytheme(): create ggplot theme
mytheme <- function () {
  theme_bw() %+replace%
    theme(axis.title = element_text(size = 16),
          axis.text = element_text(size = 16),
          legend.title = element_text(face = 'bold', size = 13),
          legend.text = element_text(size = 13),
          aspect.ratio = 1,
          plot.title = element_text(size = 14, hjust = 0.5,
                                    margin = margin(0, 0, 1, 0)))
}
theme_set(mytheme())

# dist2df(): transform an object of class 'dist' to a dataframe:
dist2df <- function(dist, varname = 'distance') {
  as.data.frame(as.matrix(dist)) %>%
    rownames_to_column() %>%
    rename(site1 = rowname) %>%
    pivot_longer(cols = -site1, names_to = 'site2') %>%
    filter(site1 != site2) %>%
    rename(!!varname := value)
}

## Create tidy df:
mantel2df <- function(mantel, lookup) {
  Dgeo_df <- dist2df(mantel$Dgeo, varname = 'geo_dist')
  Dgen_df <- dist2df(mantel$Dgen, varname = 'gen_dist')
  dist_df <- merge(Dgeo_df, Dgen_df, by = c('site1', 'site2')) %>%
    mutate(sp1 = lookup$sp[match(site1, lookup$site)],
           sp2 = lookup$sp[match(site2, lookup$site)],
           comparison = ifelse(sp1 == sp2, 'intraspecific', 'interspecific'))
}

## Create IBD plot:
ibd_plot <- function(dist_df,
                     pointsize = 4,
                     addline = 'by_comp',
                     plotplotly = TRUE,
                     plot_title = NULL,
                     show_plot = TRUE,
                     save_plot = TRUE,
                     outfile_plot = NULL) {
  #lm(Dgen ~ Dgeo)

  ## Plot as regular ggplot:
  p <- ggplot(data = dist_df) +
    geom_point(aes(x = geo_dist, y = gen_dist, color = comparison),
               size = pointsize) +
    scale_color_manual(values = my_cols) +
    labs(x = "Geographic distance", y = 'Genetic distance')

  if(addline == 'overall') {
    p <- p + geom_smooth(aes(x = geo_dist, y = gen_dist),
                         method = 'lm', se = FALSE,
                         color = 'grey20', size = 0.5, linetype = 'dashed')
  }
  if(addline == 'by_comp') {
    p <- p + geom_smooth(aes(x = geo_dist, y = gen_dist, color = comparison),
                         method = 'lm', se = FALSE,
                         size = 0.5, linetype = 'dashed')
  }

  if(!is.null(plot_title)) p <- p + ggtitle(plot_title)

  if(save_plot == TRUE) {
    ggsave(outfile_plot, width = 6, height = 4)
    system(paste('xdg-open', outfile_plot))
  }

  ## Create Plotly plot:
  if(plotplotly == TRUE) {
    pl <- p + aes(text = paste0(site1, '(', sp1, ') - ', site2, '(', sp2, ')'))
    pl <- ggplotly(pl)
    if(show_plot == TRUE) print(pl)
  }
  if(plotplotly == FALSE) if(show_plot == TRUE) print(p)

  return(p)
}

## Wrapper:
ibd_plot_wrap <- function(setID, subsetID,
                          input_dir, output_dir, ...) {
  # subsetID = 'macsp3'

  ## Files:
  if(!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)
  plotbase <- paste0(output_dir, setID, '_', subsetID)
  outfile_plot <- paste0(plotbase, '.png')
  mantel_RDS <- paste0(input_dir, setID, '_', subsetID, '_mantel.RDS')
  stopifnot(file.exists(mantel_RDS))

  ## Get mantel RDS:
  mantel <- readRDS(mantel_RDS)
  cat("## Statistic:", mantel$mantel$method, '\n')
  cat("## Value:", mantel$mantel$statistic, '\n')
  cat("## Significance:", mantel$mantel$signif, '\n')

  ## Plot:
  lookup <- mantel$lookup %>%
    select(species, site_short) %>%
    rename(site = site_short)

  dist_df <- mantel2df(mantel, lookup)

  ibd_plot(dist_df, outfile_plot = outfile_plot, ...)
}


#### TESTING -------------------------------------------------------------------
## Filter a VCF:
# snps <- new('genlight', as.matrix(snps)[keep.rows, ])

# ordering <- levels(snps@pop)
# latlon <- RgoogleMaps::geosphere_mercator(snps@other$latlong)
# latlon <- apply(latlon, 2, function(a) tapply(a, pop(snps), mean, na.rm = T))
# Dgeo <- as.dist(as.matrix(log(dist(latlon)))[ordering, ordering])
# Dgen <- gl.dist.pop(snps[, 1:1000], method = "euclidean")
# Dgen <- as.dist(as.matrix(Dgen)[ordering, ordering])
#
# ## Mantel test at individual level:
# snps_sel_ind <- snps_sel
# snps_sel_ind@pop <- factor(snps_sel_ind@ind.names)
# aap <- gl.ibd(snps_sel_ind[, 1:100])
#
# ## "Manual" Mantel:
# #gl.ibd
# snps_sel_ind <- snps_sel
# snps_sel_ind@pop <- factor(snps_sel_ind@ind.names)
# ordering <- levels(snps_sel_ind@pop)
# latlon <- RgoogleMaps::geosphere_mercator(snps_sel@other$latlong) +
#   round(rnorm(length(inds_sel), mean = 5, sd = 10)) # Add random noise to avoid same GPS
# #latlon <- snps_sel@other$latlong
# Dgeo <- log(dist(latlon))
# str(Dgeo)
# Dgeo <- as.dist(as.matrix(Dgeo)[ordering, ordering])
# Dgen <- gl.dist.pop(snps_sel_ind, method = "euclidean")
# Dgen <- as.dist(as.matrix(Dgen)[ordering, ordering])
