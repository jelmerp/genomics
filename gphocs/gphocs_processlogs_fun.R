################################################################################
##### SET-UP #####
################################################################################
library(data.table)
library(TeachingDemos)
library(gdata)
library(plyr)
library(reshape2)
library(tidyverse)
library(RColorBrewer)


################################################################################
##### Wrapper function to cut, prep and merge all log files into a single df and edit #####
################################################################################
getlogs <- function(setID,
                    logdir,
                    burnin = 100000,
                    last_sample = NULL,
                    subsample = 50,
                    cut = TRUE,
                    rename.pops = TRUE,
                    mutrate_sd = 0,
                    gentime_sd = 0) {
  # logdir <- 'analyses/gphocs/output/raw/'; setID = 'berrufmyo_'
  # burnin = 100000; last_sample = NULL; rename.pops = FALSE
  # subsample = 50; cut = TRUE; mutrate_sd = 0; gentime_sd = 0

  ## Collect all logs:
  logfiles <- list.files(logdir, pattern = paste0('.*', setID, '.*\\.log'))
  print(logfiles)

  Log <- lapply(logfiles, cutprep_log,
                rename.pops = rename.pops,
                mutrate_sd = mutrate_sd, gentime_sd = gentime_sd,
                logdir = logdir, setID = setID, burnin = burnin,
                last_sample = last_sample, subsample = subsample, cut = cut)
  Log <- compact(Log) # Remove NULL entries
  if(length(Log) > 1) Log <- do.call(rbind, Log) else Log <- Log[[1]]
  cat('##### getlogs function: Done processing individuals logs.\n')

  ## Edit final merged logfiles:
  Log$setID <- factor(setID)
  Log$cn <- factor('aa')
  Log$migpattern <- paste0(Log$migfrom, '_2_', Log$migto)
  Log$migpattern <- gsub('NA_2_NA', NA, Log$migpattern)

  Log <- Log %>%
    dplyr::select(setID, runID, rep, Sample, var, val, cval, pop,
                  migfrom, migto, migpattern, migtype.run, cn)

  return(Log)
}


################################################################################
##### Step 1: Open one logfile and cut off burn-in and/or last samples #####
################################################################################
cut_log <- function(logfile, logdir,
                   burnin, last_sample, subsample,
                   return_log = TRUE, write_log = TRUE) {

  Log <- read.table(paste0(logdir, '/', logfile), header = TRUE)
  cat('\n\n#### cut_log function:', logfile, "\tnrows:", nrow(Log), '\n')

  ## Remove burn-in:
  if(burnin > 0) Log <- Log[-which(Log$Sample < burnin), ]

  if(nrow(Log) < 1000) {
    cat('\n#### cut_log function: SKIPPING: LESS THAN 1000 ROWS LEFT AFTER REMOVING BURN-IN\n')
  } else {
    ## Remove final samples:
    if(!is.null(last_sample)) if(any(Log$Sample > last_sample))
      Log <- Log[-which(Log$Sample > last_sample), ]

    ## subsample:
    Log <- Log[seq(from = 1, to = nrow(Log), by = subsample), ]
    cat("#### cut_log function: Last sample:", max(Log$Sample), '\n')

    if(write_log == TRUE) {
      if(!dir.exists(paste0(logdir, '/cut/'))) dir.create(paste0(logdir, '/cut/'))
      write.table(Log, paste0(logdir, '/cut/', logfile),
                  sep = '\t', quote = FALSE, row.names = FALSE)
    }
    if(return_log == TRUE) return(Log)
  }
}


################################################################################
##### Step 2: Melt dataframe and prep vars ######
################################################################################
prep_log <- function(oneLog, logfile, runID, setID,
                     mutrate_sd, gentime_sd, rename.pops) {

  colnames(oneLog) <- gsub('\\.\\.', 2, colnames(oneLog))
  colnames(oneLog)[(ncol(oneLog)-2):ncol(oneLog)] <- c('mut_NA', 'dataLd_NA', 'FullLd_NA')

  migcols <- grep('m_', colnames(oneLog))
  for(migcol in migcols) {
    m <- oneLog[, migcol]

    migpattern <- unlist(strsplit(colnames(oneLog)[migcol], split = '_'))[2]
    #cat('#### prep_log function: Migration pattern:', migpattern, '\n')
    migto <- unlist(strsplit(migpattern, split = '2'))[2]
    migto.column <- grep(paste0('theta_', migto, '$'), colnames(oneLog))
    th <- oneLog[, migto.column]

    ## Population migration rate:
    colname.mig2 <- paste0('2Nm_', migpattern)
    oneLog$newcolumn1 <- (m * m.scale) * (th * t.scale) / 4
    colnames(oneLog)[grep('newcolumn1', colnames(oneLog))] <- colname.mig2

    ## Proportion of migrants:
    mutrate.gen_dist <- rnorm(nrow(oneLog), mean = mutrate.gen, sd = mutrate_sd)

    colname.mig3 <- paste0('m.prop_', migpattern)
    oneLog$newcolumn2 <- (m * m.scale) * mutrate.gen_dist * 100
    colnames(oneLog)[grep('newcolumn2', colnames(oneLog))] <- colname.mig3
  }

  runID <- logfile %>%
    gsub(paste0(setID, '_'), '', .) %>%
    strsplit(., split = '_') %>%
    unlist(.) %>%
    .[1]

  mlog <- oneLog %>%
    melt(id = 'Sample') %>%
    separate(variable, sep = '_', into = c('var', 'pop'), extra = 'merge') %>%
    separate(pop, sep = '2', into = c('migfrom', 'migto'), remove = FALSE) %>%
    dplyr::rename(val = value) %>%
    mutate(migfrom = factor(migfrom),
           migto = factor(migto),
           setID = setID,
           runID = runID) %>%
    select(setID, runID, Sample, var, val, pop, migfrom, migto)

  mlog$migfrom[which(is.na(mlog$migto))] <- NA ## set migfrom to NA for non-migration vars
  mlog$pop[which(!is.na(mlog$migto))] <- NA ## set pop to NA for migration var (i.e. when migto is not NA)

  if(rename.pops == TRUE) {
    cat('#### prep_log function: Pops not found:',
        unique(mlog$pop)[!unique(mlog$pop) %in% pop.lookup$popname.long], '\n')
    mlog$pop <- poprename(mlog$pop)
    mlog$migfrom <- poprename(mlog$migfrom)
    mlog$migto <- poprename(mlog$migto)
  }

  mlog$rep <- factor(as.integer(gsub('.*rep([0-9]).*log', '\\1', logfile)))
  mlog$migtype.run <- factor(ifelse(grepl('multmig', runID), 'mult',
                                    ifelse(grepl('noMig', runID, ignore.case = TRUE),
                                           'none', 'single')))
  mlog <- add.cvalue(mlog, mutrate_sd = mutrate_sd, gentime_sd = gentime_sd)

  return(mlog)
}


################################################################################
##### Step 3: Wrapper function to first apply cut_log(), then prep_log() #####
################################################################################
cutprep_log <- function(logfile, logdir, setID, runID,
                        burnin, last_sample, subsample, cut = TRUE,
                        mutrate_sd, gentime_sd, rename.pops,
                        return_log = TRUE, write_log = TRUE) {

  if(cut == TRUE) {
    Log <- cut_log(logfile = logfile, logdir = logdir, burnin = burnin,
                  last_sample = last_sample, subsample = subsample,
                  return_log = return_log, write_log = write_log)
  }

  if(cut == FALSE) {
    cat('\n\n#### cutprep_log function: not cutting log, just reading it in.')
    cat('#### cutprep_log function: ', logfile, "\tnrows:", nrow(Log))
    Log <- read.table(paste0(logdir, '/cut/', logfile), header = TRUE)
  }

  if(!is.null(Log)) {
    ## Remove underscores: ## TEMPORARY ##
    colnames(Log) <- gsub('anc_m', 'anc.m', colnames(Log))
    colnames(Log) <- gsub('mur_', 'mur.', colnames(Log))
    colnames(Log) <- gsub('gri_', 'gri.', colnames(Log))
    #cat('#### cutprep_log function: Column names of Log:\n', colnames(Log), '\n')

    Log <- prep_log(oneLog = Log,
                    logfile = logfile,
                    setID = setID,
                    rename.pops = rename.pops,
                    mutrate_sd = mutrate_sd,
                    gentime_sd = gentime_sd)
    return(Log)
  }
}


################################################################################
##### Add converted demographic values #####
################################################################################
add.cvalue <- function(Log, gentime_sd, mutrate_sd) {

  cat('#### add.cvalue function: Adding converted values...\n')
  Log$cval <- NA

  ## Total migration rate:
  smr <<- Log %>%
    dplyr::filter(var == 'tau') %>%
    dplyr::group_by(pop) %>%
    dplyr::summarise(tau = mean(val))

  focalpops <- as.character(unique(Log$migto))
  focalpops <- focalpops[!is.na(focalpops)]
  #cat('#### add.cvalue function: Focal pops for migration rate:', focalpops, '\n')

  if(length(focalpops) > 1)
    newmig <- do.call(rbind, lapply(focalpops, getlifespan, Log = Log, smr = smr))
  if(length(focalpops) == 1)
    newmig <- getlifespan(focalpops, Log = Log, smr = smr)

  if(length(focalpops) >= 1)
    Log$cval[newmig$frows] <- (Log$val[newmig$frows] * m.scale) * (newmig$lifespan * t.scale)

  ## Tau & theta:
  gentime_dist <- rlnorm(nrow(Log), meanlog = log(gentime), sdlog = gentime_sd)
  mutrate.gen_dist <- rnorm(nrow(Log), mean = mutrate.gen, sd = mutrate_sd)

  my_theta  <- Log$val[Log$var == 'theta'] * t.scale
  my_mutrate.gen <- mutrate.gen_dist[Log$var == 'theta']
  Log$cval[Log$var == 'theta'] <- my_theta / (4 * my_mutrate.gen)

  my_tau <- Log$val[Log$var == 'tau'] * t.scale
  my_mutrate.yr <- mutrate.gen_dist[Log$var == 'tau'] / gentime_dist[Log$var == 'tau']
  Log$cval[Log$var == 'tau'] <- my_tau / my_mutrate.yr

  return(Log)
}




################################################################################
##### Get lifespan for a pop in a specific run #####
################################################################################
getlifespan <- function(focalpop, Log, smr) {

  if(is.null(focalpop)) focalpop <- unlist(strsplit(migRun, split = '2'))[2]
  #cat('##### Getlifespan: focal pop:', focalpop, '\n')

  tau.parent <- smr$tau[smr$pop == getparent(focalpop)]

  if(focalpop %in% currentpops) {
    lifespan <- tau.parent
  } else {
    lifespan <- tau.parent - smr$tau[smr$pop == focalpop]
  }

  frows <- which(Log$var == 'm' & Log$migto == focalpop)

  lifespan.df <- data.frame(frows, lifespan)
  return(lifespan.df)
}


################################################################################
##### Get parent pop #####
################################################################################
getparent <- function(kidpop) {
  parentpops[match(kidpop, kidpops)]
}


################################################################################
##### Convert population name #####
################################################################################
poprename <- function(pop) {
  pop.lookup$popname.short[match(pop, pop.lookup$popname.long)]
}
