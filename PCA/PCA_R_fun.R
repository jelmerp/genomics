################################################################################
##### PROCESS PCA DATAFRAME #####
################################################################################
pca.process <- function(pca.res,
                        lookup,
                        PCAtype = 'snpgdsPCA',
                        subset.ID = 'all',
                        write_files = FALSE,
                        pca.ID = 'tmp',
                        my_outdir_pca = 'tmp') {

  ## Reorganize df:
  if(PCAtype == 'glPCA') {
    pca <- data.frame(ID = rownames(pca.res$scores),
                      PC1 = pca.res$scores[, 'PC1'], PC2 = pca.res$scores[, 'PC2'],
                      PC3 = pca.res$scores[, 'PC3'], PC4 = pca.res$scores[, 'PC4'],
                      stringsAsFactors = FALSE, row.names = NULL)
    eigenvals <- pca.res$eig # Eigenfactor df
  }

  if(PCAtype == 'snpgdsPCA') {
    pca <- data.frame(ID = pca.res$sample.id,
                      PC1 = pca.res$eigenvect[, 1], PC2 = pca.res$eigenvect[, 2],
                      PC3 = pca.res$eigenvect[, 3], PC4 = pca.res$eigenvect[, 4],
                      stringsAsFactors = FALSE)
    eigenvals <- pca.res$eigenval # Eigenfactor df
  }

  ## Merge with metadata df:
  pca <- merge(pca, lookup, by = 'ID')

  ## Write to file:
  if(write_files == TRUE) {
    if(!dir.exists(my_outdir_pca)) dir.create(my_outdir_pca, recursive = TRUE)
    outfile_pca <- paste0(my_outdir_pca, '/', pca.ID, '.txt')
    outfile_eigenvals <- paste0(my_outdir_pca, '/', pca.ID, '_eigenvals.txt')

    cat('##### Writing pca dfs to file:', outfile_pca, '\n')
    write.table(pca, outfile_pca, sep = '\t', quote = FALSE, row.names = FALSE)
    writeLines(as.character(eigenvals), outfile_eigenvals)
  }

  #print(head(pca))
  cat("##### Number of rows in pca df:", nrow(pca))
  return(pca)
}


################################################################################
##### PLOT PCA #####
################################################################################
pcplot <- function(pca.df,
                   eigenvals = NULL,
                   pca.ID = NULL,
                   pcX = 1,
                   pcY = 2,
                   col.by = NULL,
                   col.by.name = NULL,
                   col.by.labs = NULL,
                   cols = NULL,
                   draw_boxes = FALSE,
                   boxlabsize = 10,
                   shape.by = NULL,
                   shape.by.name = NULL,
                   shape.by.labs = NULL,
                   shapes = NULL,
                   dotsize = 3,
                   strokesize = 2.5,
                   legpos = 'right',
                   legstacking = 'vertical',
                   axis_title_size = 18,
                   xmin_buffer = 0.05, xmax_buffer = 0.05,
                   ymin_buffer = 0.05, ymax_buffer = 0.05,
                   plot.title = NULL,
                   plot.save = FALSE,
                   my_outdir_figs = 'tmp') {

  if(!dir.exists(my_outdir_figs)) dir.create(my_outdir_figs, recursive = TRUE)
  if(is.null(pca.ID)) pca.ID <- 'PCA'

  xcolumn <- paste0('PC', pcX)
  ycolumn <- paste0('PC', pcY)

  if(!is.null(eigenvals)) {
    var.x <- round(eigenvals[pcX] / sum(eigenvals, na.rm = TRUE) * 100, 1)
    var.y <- round(eigenvals[pcY] / sum(eigenvals, na.rm = TRUE) * 100, 1)
    lab.x <- paste0('PC', pcX, ' (', var.x, '%)')
    lab.y <- paste0('PC', pcY, ' (', var.y, '%)')
  } else {
    lab.x <- xcolumn
    lab.y <- ycolumn
  }

  ## Limits:
  xmin_val <- min(pca[, xcolumn])
  xmax_val <- max(pca[, xcolumn])
  xrange <- xmax_val - xmin_val
  xmin <- xmin_val - (xmin_buffer * xrange)
  xmax <- xmax_val + (xmax_buffer * xrange)

  ymin_val <- min(pca[, ycolumn])
  ymax_val <- max(pca[, ycolumn])
  yrange <- ymax_val - ymin_val
  ymin <- ymin_val - (ymin_buffer * yrange)
  ymax <- ymax_val + (ymax_buffer * yrange)

  ## By shape and colour:
  if(!is.null(shape.by) & !is.null(col.by)) {
    p <- ggplot(
      data = pca.df,
      aes_string(x = xcolumn, y = ycolumn, color = col.by, shape = shape.by)
    ) +
    geom_point(size = dotsize, stroke = strokesize)

    if(!is.null(shapes)) {
      p <- p + scale_shape_manual(
        values = shapes, name = shape.by.name, labels = shape.by.labs
        )
    } else {
      p <- p + scale_shape_discrete(
        name = shape.by.name, labels = shape.by.labs
        )
    }

    if(!is.null(cols)) {
      p <- p + scale_color_manual(
        values = cols, name = col.by.name, labels = col.by.labs
        )
    } else {
      p <- p + scale_color_discrete(
        name = col.by.name
        )
    }
  }

  ## By colour only:
  if(is.null(shape.by) & !is.null(col.by)) {
    p <- ggplot(
      data = pca.df,
      aes_string(x = xcolumn, y = ycolumn, color = col.by)
    ) +
      geom_point(size = dotsize, stroke = strokesize)

    if(!is.null(col.by.name))
      p <- p + scale_color_manual(
        values = cols, name = col.by.name, labels = col.by.labs
        )
  }

  ## By shape only:
  if(!is.null(shape.by) & is.null(col.by)) {
    p <- ggplot(
      data = pca.df,
      aes_string(x = xcolumn, y = ycolumn, shape = shape.by)
    ) +
      geom_point(size = dotsize, stroke = strokesize)

    if(!is.null(shapes)) {
      p <- p + scale_shape_manual(
        values = shapes, name = shape.by.name, labels = shape.by.labs)
    } else {
      p <- p + scale_shape_discrete(
        name = shape.by.name, labels = shape.by.labs)
    }
  }

  if(draw_boxes == TRUE) {
    p <- p + geom_mark_ellipse(
      aes_string(label = col.by),
      show.legend = FALSE,
      label.fontsize = boxlabsize,
      con.type = 'straight',
      tol = 0.001,
      label.buffer = unit(0, 'mm')
    ) +
      guides(color = FALSE)
  }

  ## Plot formatting:
  p <- p +
    xlim(xmin, xmax) +
    ylim(ymin, ymax) +
    labs(x = lab.x, y = lab.y) +
    theme_bw() +
    theme(legend.position = legpos,
          legend.text = element_text(size = 14),
          legend.spacing.x = unit(0, 'cm'),
          legend.spacing.y = unit(0.1, 'cm'),
          legend.margin = margin(t = 0.1, r = 0.1, b = 0.1, l = 0.1, unit = "cm"),
          legend.title = element_text(size = 14, face = 'bold'),
          #legend.background = element_rect(fill = "grey90", colour = "grey30"),
          legend.key = element_rect(fill = "white"),
          legend.key.size = unit(1, "cm"), #unit(1.3, "cm"),
          legend.text.align = 0,
          legend.box = legstacking,
          axis.text.x = element_blank(),
          axis.text.y = element_blank(),
          axis.ticks.length = unit(.25, "cm"),
          axis.title.x = element_text(size = axis_title_size,
                                      margin = unit(c(4, 0, 0, 0), 'mm')),
          axis.title.y = element_text(size = axis_title_size,
                                      margin = unit(c(0, 4, 0, 0), 'mm')),
          panel.grid.major = element_blank(),
          panel.grid.minor = element_blank(),
          plot.title = element_text(hjust = 0.5, size = 24),
          plot.margin = margin(0.3, 0.3, 0.3, 0.3, "cm")) +
    guides(fill = guide_legend(override.aes = list(shape = 21)))

  if(!is.null(plot.title)) p <- p + ggtitle(plot.title)

  if(plot.save == TRUE) {
    figfile <- paste0(my_outdir_figs, '/', pca.ID, '.png')
    cat('##### Saving plot to file:', figfile, '\n')
    ggsave(figfile, width = 8, height = 6)
    system(paste('xdg-open', figfile))
  }

  return(p)
}

