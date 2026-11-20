library(nmadb)

raw <- getNMADB(raw=TRUE)
catalog <- getNMADB()
stopifnot(nrow(raw) == 1670L, nrow(catalog) == 1670L,
          ncol(raw) == 410L, !anyDuplicated(names(raw)),
          is.character(raw$record_id), "570-1" %in% catalog$Record.ID,
          sum(nzchar(raw$dataset_sha256)) == 603L,
          all(c("Record.ID", "First.Author", "Year", "Verified", "Format", "Effect.Measure", "Type.of.Outcome") %in% names(catalog)),
          length(listVerified()) == nrow(verifiedStudies()),
          all(verifiedStudies()$Verified == "True"),
          all(unverifiedStudies()$Verified == "False"),
          nrow(recs()) == 1670L, nrow(havedata()) > 0L)

# Long format keeps every populated arm and its original study ID.
wide <- data.frame(id=c("s1","s2"), t1=c("A","A"), r1=c(1,2), n1=c(10,20),
                   t2=c("B",NA), r2=c(3,NA), n2=c(10,NA))
long <- wide2long(wide)
stopifnot(nrow(long) == 3L, identical(names(long), c("id","t","r","n")),
          sum(long$r) == 6, sum(long$id == "s1") == 2L)
stopifnot(isOutcomeCompatibleWithMeasure("binary","OR"),
          !isOutcomeCompatibleWithMeasure("continuous","OR"))

# No database clients, endpoints, tokens, or write operations are exported.
exports <- getNamespaceExports("nmadb")
stopifnot(!any(c("importreq", "uploaddatasets", "updateVerifiedStatus", "NMADBURL", "PUBLICTOKEN") %in% exports))
manifest <- getManifest()
stopifnot(manifest$record_count == 1670L, manifest$dataset_count == 603L,
          all(c("catalog.tsv", "codebook.json", "dataset-manifest.json") %in% manifest$resources$file))

# A modified catalogue with the original byte size must fail its manifest hash.
cache <- tempfile(); dir.create(file.path(cache,"inst","extdata"),recursive=TRUE)
bundled <- system.file("extdata",package="nmadb")
invisible(file.copy(list.files(bundled,full.names=TRUE),file.path(cache,"inst","extdata")))
table <- file.path(cache,"inst","extdata","catalog.tsv")
bytes <- readBin(table,"raw",n=file.info(table)$size)
bytes[1] <- as.raw(bitwXor(as.integer(bytes[1]),1L)); writeBin(bytes,table)
old_path <- getOption("nmadb.path")
options(nmadb.path=cache)
rejected_table <- try(getNMADB(),silent=TRUE)
options(nmadb.path=old_path)
stopifnot(inherits(rejected_table,"try-error"),grepl("SHA-256",as.character(rejected_table)))
unlink(cache,recursive=TRUE)

# Real repository integration checks are enabled by an explicit local checkout.
checkout <- Sys.getenv("NMADB_TEST_CHECKOUT")
if (nzchar(checkout)) {
  options(nmadb.dataset_root=checkout)
  for (id in c("501321","481216","479888","479999","479629")) {
    network <- suppressMessages(readByID(id))
    stopifnot(identical(names(network),c("name","data","type","effect","format")), nrow(network$data)>0)
    if (requireNamespace("netmeta",quietly=TRUE) && requireNamespace("meta",quietly=TRUE)) {
      result <- suppressMessages(runnetmeta(id))
      stopifnot(inherits(result,"netmeta"), result$random, !result$common)
    }
  }
  if (requireNamespace("netmeta",quietly=TRUE) && requireNamespace("meta",quietly=TRUE)) {
    fixed <- suppressMessages(runnetmeta("481216", model="fixed"))
    stopifnot(fixed$common, !fixed$random)
    stopifnot(!verifyData("no-such-record")$passed)
    checked <- suppressMessages(checkRecords(data.frame(Record.ID=c("481216","no-such-record"))))
    stopifnot(checked[[1]]$verified, !checked[[2]]$verified)
  }
  # Original Excel bytes may also be bundled under inst/extdata for offline use.
  offline <- tempfile(); dir.create(file.path(offline,"inst","extdata","datasets"),recursive=TRUE)
  invisible(file.copy(list.files(system.file("extdata",package="nmadb"),full.names=TRUE),
                      file.path(offline,"inst","extdata")))
  manifest <- jsonlite::fromJSON(system.file("extdata","dataset-manifest.json",package="nmadb"))$files
  row <- manifest[manifest$record_id=="481216",]
  bundled_file <- file.path(offline,"inst","extdata","datasets",paste0(row$sha256,".xlsx"))
  stopifnot(file.copy(file.path(checkout,row$path),bundled_file))
  options(nmadb.path=offline,nmadb.dataset_root=NULL)
  bundled <- suppressMessages(readByID("481216"))
  stopifnot(bundled$type=="binary",bundled$effect=="RR",nrow(bundled$data)>0L)
  bytes <- readBin(bundled_file,"raw",n=file.info(bundled_file)$size)
  bytes[1] <- as.raw(bitwXor(as.integer(bytes[1]),1L));writeBin(bytes,bundled_file)
  rejected_bundle <- try(exportData("481216",tempfile()),silent=TRUE)
  stopifnot(inherits(rejected_bundle,"try-error"),grepl("SHA-256",as.character(rejected_bundle)))
  options(nmadb.path=old_path,nmadb.dataset_root=checkout)
  unlink(offline,recursive=TRUE)
  # A downloaded workbook with altered bytes must not replace the destination.
  fake <- tempfile(); dir.create(fake)
  manifest <- jsonlite::fromJSON(system.file("extdata","dataset-manifest.json",package="nmadb"))$files
  row <- manifest[manifest$record_id=="481216",]
  dir.create(file.path(fake,"datasets","files"),recursive=TRUE)
  file.copy(file.path(checkout,row$path),file.path(fake,row$path))
  file <- file.path(fake,row$path)
  bytes <- readBin(file,"raw",n=file.info(file)$size)
  bytes[1] <- as.raw(bitwXor(as.integer(bytes[1]),1L)); writeBin(bytes,file)
  options(nmadb.dataset_root=fake)
  destination <- tempfile(); writeLines("preserve me",destination)
  rejected <- try(exportData("481216",destination),silent=TRUE)
  stopifnot(inherits(rejected,"try-error"),grepl("SHA-256",as.character(rejected)),
            identical(readLines(destination),"preserve me"))
  unlink(c(fake,destination),recursive=TRUE)
}
