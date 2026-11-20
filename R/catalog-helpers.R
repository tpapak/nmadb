# Legacy raw catalogue helpers now use the bundled snapshot.
response <- function() {
  output <- character()
  connection <- textConnection("output", "w", local=TRUE)
  utils::write.csv(getNMADB(raw=TRUE), connection, row.names=FALSE, na="")
  close(connection)
  paste(output, collapse="\n")
}
recs <- function() getNMADB(raw=TRUE)
havedata <- function() {
  records <- recs()
  records[records$data_available == "1", , drop=FALSE]
}
filename <- function(recid) {
  if (length(recid) != 1L || is.na(recid) || !grepl("^[A-Za-z0-9_-]+$", as.character(recid))) stop("Invalid record ID.")
  file.path("nmadb", paste0(recid, ".xlsx"))
}
