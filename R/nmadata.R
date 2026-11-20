# Public reads use the frozen table and hash-verified GitHub datasets.
.nmadb_file <- function(name) {
  directory <- getOption("nmadb.path")
  result <- if (is.null(directory)) system.file("extdata", name, package="nmadb") else file.path(directory, "inst", "extdata", name)
  if (!nzchar(result) || !file.exists(result)) stop("Missing NMADB snapshot file: ", name)
  result
}

getNMADB <- function(raw=FALSE) {
  catalog <- utils::read.delim(.nmadb_file("catalog.tsv"), colClasses="character",
                              check.names=FALSE, na.strings=NULL, quote="\"", comment.char="")
  if (raw) return(catalog)
  codebook <- jsonlite::fromJSON(.nmadb_file("codebook.json"), simplifyVector=FALSE)
  labels <- stats::setNames(names(catalog), names(catalog))
  for (field in codebook) {
    name <- field$name
    if (!name %in% names(catalog)) next
    labels[name] <- field$label
    choices <- unlist(field$choices, use.names=TRUE)
    if (length(choices)) {
      matched <- match(catalog[[name]], names(choices))
      found <- !is.na(matched)
      catalog[[name]][found] <- unname(choices[matched[found]])
    }
  }
  names(catalog) <- make.names(unname(labels), unique=TRUE)
  # IDs remain strings, including legacy values containing hyphens.
  for (name in setdiff(names(catalog), "Record.ID")) catalog[[name]] <- utils::type.convert(catalog[[name]], as.is=TRUE)
  catalog
}

listdata <- function() getNMADB()

nmadatanames <- function(studies) paste(studies$Record.ID, studies$First.Author, studies$Year, sep="_")
verifiedStudies <- function() {
  catalog <- getNMADB()
  catalog[!is.na(catalog$Verified) & catalog$Verified %in% c(TRUE, "True", "TRUE", "1"), , drop=FALSE]
}
listVerified <- function() nmadatanames(verifiedStudies())
unverifiedStudies <- function() {
  catalog <- getNMADB()
  catalog[!is.na(catalog$Verified) & catalog$Verified %in% c(FALSE, "False", "FALSE", "0"), , drop=FALSE]
}

exportData <- function(recid, filename) {
  if (length(recid) != 1L || is.na(recid)) stop("Supply one record ID.")
  manifest <- jsonlite::fromJSON(.nmadb_file("dataset-manifest.json"))$files
  row <- manifest[manifest$record_id == as.character(recid) & manifest$field == "dataset", , drop=FALSE]
  if (nrow(row) != 1L) stop("No dataset is available for record ", recid)
  temporary <- tempfile(fileext=".xlsx")
  on.exit(unlink(temporary), add=TRUE)
  repository <- getOption("nmadb.dataset_root")
  if (!is.null(repository)) {
    if (!file.copy(file.path(repository, row$path), temporary)) stop("Unable to read dataset from local checkout.")
  } else {
    status <- utils::download.file(row$file_url, temporary, mode="wb", quiet=TRUE)
    if (status != 0L) stop("Dataset download failed.")
  }
  if (file.info(temporary)$size != row$size || digest::digest(file=temporary, algo="sha256") != row$sha256)
    stop("Dataset failed size or SHA-256 verification; destination was not modified.")
  if (!file.copy(temporary, filename, overwrite=TRUE)) stop("Unable to save dataset to ", filename)
  invisible(filename)
}

readByID = function(recid) {
  catalog = getNMADB()
  fl = tempfile(fileext=".xlsx")
  exportData(recid,fl)
  on.exit(unlink(fl), add=TRUE)
  dts = as.data.frame(readxl::read_xlsx(fl))
  if (!"id" %in% names(dts) && "StudyID" %in% names(dts)) dts$id <- dts$StudyID
  file.remove(fl)
  dtsformat = 
    catalog[catalog$Record.ID %in% recid,]$Format 
  dtstype = 
    catalog[catalog$Record.ID %in% recid,]$Type.of.Outcome
  effecttype = 
    tolower(as.character(catalog[catalog$Record.ID %in% recid,]$Effect.Measure))
  dtseffect = switch( effecttype
                    , "odds ratio"={"OR"}
                    , "risk ratio"={"RR"}
                    , "hazard ratio"={"HR"}
                    , "rate ratio"={"IRR"}
                    , "risk difference"={"RD"}
                    , "mean difference"={"MD"}
                    , "standardized mean difference"={"SMD"}
                    , "other"={"other"}
                    )
  out = dts
  return (list( name   = recid
              , data   = out
              , type   = tolower(dtstype)
              , effect = dtseffect
              , format = dtsformat))
}
