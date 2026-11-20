# Compatibility constants contain no embedded credentials.
NMADBURL <- Sys.getenv("NMADB_API_URL", "https://redcap.cebm.gr/api/")
PUBLICTOKEN <- ""

.nmadb_admin_post <- function(fields, file=NULL) {
  token <- Sys.getenv("NMADB_API_TOKEN")
  if (!nzchar(token)) stop("Set NMADB_API_TOKEN locally to enable REDCap writes.")
  if (!requireNamespace("RCurl", quietly=TRUE)) stop("Install RCurl to enable REDCap writes.")
  arguments <- c(list(uri=getOption("nmadb.api_url", Sys.getenv("NMADB_API_URL", NMADBURL)),
                     token=token, returnFormat="json"), fields)
  if (!is.null(file)) arguments$file <- RCurl::fileUpload(file)
  result <- do.call(RCurl::postForm, arguments)
  parsed <- tryCatch(jsonlite::fromJSON(result), error=function(e) stop("REDCap returned a non-JSON response."))
  if (is.list(parsed) && !is.null(parsed$error)) stop(parsed$error)
  parsed
}
