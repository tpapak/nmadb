verifyData <- function(recid) {
  passed <- tryCatch({
    result <- runnetmeta(recid)
    if (is.null(result) || !inherits(result, "netmeta")) stop("Network analysis did not return a netmeta result.")
    TRUE
  }, error=function(e) FALSE)
  list(recid=recid, passed=passed)
}
checkRecords <- function(records) {
  ids <- if ("Record.ID" %in% names(records)) records$Record.ID else records$record_id
  lapply(ids, function(id) {
    result <- verifyData(id)
    list(rec=id, verified=result$passed)
  })
}
