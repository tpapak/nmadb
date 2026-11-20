wide2long <- function(data, type="binary") {
  variables <- switch(type, binary=c("t", "r", "n"), continuous=c("t", "y", "sd", "n"),
                      rate=c("t", "r", "n", "time"), survival=c("t", "r", "n", "time"),
                      iv=c("t"),
                      stop("Unsupported outcome type: ", type))
  # Some historical workbooks are already long despite their catalogue flag.
  if (all(variables %in% names(data))) return(data)
  arms <- grep("^t[0-9]+$", names(data), value=TRUE)
  if (!length(arms)) stop("Wide data require treatment columns t1, t2, ...")
  suffixes <- sub("^t", "", arms)
  suffixes <- suffixes[order(as.integer(suffixes))]
  if (!"id" %in% names(data)) {
    if ("StudyID" %in% names(data)) data$id <- data$StudyID else data$id <- seq_len(nrow(data))
  }
  arm_columns <- unlist(lapply(suffixes, function(suffix) paste0(variables, suffix)))
  extra_columns <- setdiff(names(data), c("id", arm_columns))
  output <- lapply(suffixes, function(suffix) {
    columns <- paste0(variables, suffix)
    if (!all(columns %in% names(data))) stop("Missing wide-data columns: ", paste(setdiff(columns, names(data)), collapse=", "))
    arm <- data.frame(id=data$id, data[extra_columns], data[columns], check.names=FALSE)
    names(arm) <- c("id", extra_columns, variables)
    arm[!is.na(arm$t) & nzchar(trimws(as.character(arm$t))), , drop=FALSE]
  })
  result <- do.call(rbind, output)
  rownames(result) <- NULL
  result
}
