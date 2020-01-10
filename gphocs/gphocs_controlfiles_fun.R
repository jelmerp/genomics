## Create replicate controlfiles:
prep.reps <- function(masterfilename,
                      dir.source = 'controlfiles/master/',
                      dir.target = 'controlfiles/',
                      nreps = 3, rm.master = FALSE) {

  if(!dir.exists(dir.target)) dir.create(dir.target)

  master <- readLines(paste0(dir.source, masterfilename))
  if(rm.master == TRUE) file.remove(masterfilename)

  if(!grepl(format(Sys.Date(), '%y%m%d'), masterfilename)) {
    masterfilename <- gsub('_master.ctrl',
                           paste0('_date', format(Sys.Date(), '%y%m%d'), '_master.ctrl'),
                           masterfilename)
  }

  logfilename <- gsub('_master.ctrl', '.log', masterfilename)

  master[grep('trace-file', master)] <- gsub('output/.*.log',
                                             paste0('output/', logfilename),
                                             master[grep('trace-file', master)])

  for(i in 1:nreps) {
    rep <- sub('_date', paste0('_rep', i, '_date'), master)
    rep <- sub('dummyseed', round(runif(1, 1, 1e+8)), rep)
    repfilename <- sub('_date', paste0('_rep', i, '_date'), masterfilename)
    repfilename <- sub('_master', '', repfilename)
    write(rep, paste0(dir.target, '/', repfilename))
    cat('File created:', repfilename, '\n')
  }

}


## Prepare master for each migration band pattern:
prep.migbands <- function(radiation.id, template.id, migpatterns,
                          dir.source = 'controlfiles/master/',
                          dir.target = 'controlfiles/master/') {
  migfrom.template <- strsplit(template.id, split = '2')[[1]][1]
  migto.template <- strsplit(template.id, split = '2')[[1]][2]
  migto.template <- gsub('_.*', '', migto.template)

  masterfilename <- paste0(dir.source, '/', template.id, '_', radiation.id, '_master.ctrl')
  if(!file.exists(masterfilename)) cat("MASTERFILENAME DOES NOT EXIST", masterfilename, '\n')

  templatefilename <- paste0(dir.target, template.id, '_', radiation.id, '_master.ctrl')

  file.copy(masterfilename, templatefilename)

  template <- readLines(templatefilename)

  aap <- sapply(migpatterns, prep.ctrl, template, templatefilename = templatefilename, template.id = template.id,
                migfrom.template = migfrom.template, migto.template = migto.template, radiation.id = radiation.id)
}


prep.ctrl <- function(migpattern.focal, template, templatefilename, template.id,
                      migfrom.template, migto.template, radiation.id) {

  focalfile <- template
  focalfilename <- sub(paste0(migfrom.template, '2', migto.template), migpattern.focal, templatefilename)

  if(migpattern.focal != 'noMig') {
    migfrom.focal <- strsplit(migpattern.focal, split = '2')[[1]][1]
    migto.focal <- strsplit(migpattern.focal, split = '2')[[1]][2]
    focalfile[grep('source', focalfile)] <- sub(migfrom.template, migfrom.focal, focalfile[grep('source', template)])
    focalfile[grep('target', focalfile)] <- sub(migto.template, migto.focal, focalfile[grep('target', template)])
    focalfile[grep('outputToReplace', focalfile)] <- sub('outputToReplace', paste0(radiation.id, '_', migpattern.focal), focalfile[grep('outputToReplace', template)])
  }

  if(migpattern.focal == 'noMig') {
    focalfile <- focalfile[-grep('MIG-BANDS-START|BAND-START|source|target|BAND-END|MIG-BANDS-END', focalfile)]
  }

  write(focalfile, focalfilename)
  cat("File created:", focalfilename, '\n')
}

