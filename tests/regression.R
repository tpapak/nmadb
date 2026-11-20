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

# Public package reads and tests never require, or make, administrative writes.
old <- Sys.getenv("NMADB_API_TOKEN", unset=NA_character_)
Sys.unsetenv("NMADB_API_TOKEN")
failed <- try(updateVerifiedStatus("570-1"), silent=TRUE)
stopifnot(inherits(failed,"try-error"), grepl("NMADB_API_TOKEN",as.character(failed)))
if (!is.na(old)) Sys.setenv(NMADB_API_TOKEN=old)

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
