verifyData <- function(recid, updateRecord=FALSE) {
  error <- ""
  passed <- tryCatch({
    result <- runnetmeta(recid)
    if (is.null(result) || !inherits(result, "netmeta")) stop("Network analysis did not return a netmeta result.")
    TRUE
  }, error=function(e) { error <<- conditionMessage(e); FALSE })
  if (updateRecord) updateVerifiedStatus(recid, as.integer(passed), error)
  list(recid=recid, passed=passed)
}
updateVerifiedStatus <- function(recid, isVerified=0, err="") {
  .nmadb_admin_post(list(content="record", action="import", format="json",
    data=jsonlite::toJSON(data.frame(record_id=as.character(recid), verified=isVerified,
                                    error=if (isVerified == 1) "" else err), dataframe="rows")))
}
checkRecords <- function(records, updateDB=FALSE) {
  ids <- if ("Record.ID" %in% names(records)) records$Record.ID else records$record_id
  lapply(ids, function(id) {
    result <- verifyData(id, updateRecord=updateDB)
    list(rec=id, verified=result$passed)
  })
}
