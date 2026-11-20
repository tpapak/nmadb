\name{nmadb}
\alias{nmadb}
\alias{getManifest}
\alias{getNMADB}
\alias{nmadatanames}
\alias{verifiedStudies}
\alias{unverifiedStudies}
\alias{listVerified}
\alias{exportData}
\alias{readByID}
\alias{wide2long}
\alias{runnetmeta}
\alias{getmetaNetw}
\alias{isOutcomeCompatibleWithMeasure}
\alias{verifyData}
\alias{checkRecords}
\alias{response}
\alias{recs}
\alias{havedata}
\alias{filename}
\title{Query NMADB and retrieve verified network datasets}
\description{Access the frozen REDCap catalogue and Excel datasets hosted on GitHub.
Dataset downloads are checked against their original SHA-256 and byte size.
Network analysis and verification operate without a source database connection.}
\usage{
getManifest()
getNMADB(raw = FALSE)
nmadatanames(studies)
verifiedStudies()
unverifiedStudies()
listVerified()
exportData(recid, filename)
readByID(recid)
wide2long(data, type = "binary")
runnetmeta(recid, model = "random", measure = "notset")
getmetaNetw(indata, type, model = "fixed", tau = NA, sm)
isOutcomeCompatibleWithMeasure(outcome, measure)
verifyData(recid)
checkRecords(records)
response()
recs()
havedata()
filename(recid)
}
\arguments{
\item{raw}{Return original variable names and raw string values instead of labelled columns.}
\item{studies, records}{Catalogue rows to list or verify.}
\item{recid}{One record ID, supplied as a string or number. IDs containing hyphens must be strings.}
\item{filename}{Destination workbook path.}
\item{data, indata}{A data frame containing network outcome data.}
\item{type, outcome}{Outcome or input format, such as binary, continuous, rate, survival or iv.}
\item{model}{Use a fixed/common or random effects model.}
\item{measure, sm}{Effect measure, such as OR, RR, RD, MD, SMD, HR or IRR.}
\item{tau}{Reserved compatibility argument. It does not fix heterogeneity.}
}
\details{
Public reads require no API token. \code{getNMADB()} returns labelled columns such
as \code{Record.ID}, \code{First.Author}, and \code{Effect.Measure};
\code{getNMADB(raw=TRUE)} preserves raw variable names and historical values.
Dataset associations are in \code{dataset_sha256} and \code{dataset_url}.

\code{readByID()} returns the legacy list components \code{name}, \code{data},
\code{type}, \code{effect}, and \code{format}. An absent dataset or checksum
mismatch raises an error. Historically incomplete extraction data remain unchanged;
not every workbook contains enough information to run a network analysis.

The \code{netmeta} and \code{meta} packages are needed for network analyses.
The wide-to-long conversion is implemented locally in R and requires no JavaScript
or remotely downloaded source code.

The package includes a versioned catalogue, codebook, dataset manifest and
\code{database-manifest.json}. The database manifest records resource sizes,
SHA-256 hashes, snapshot date, and record counts. Bundled resources are verified
before use. \code{getManifest()} returns this database manifest.

There is no database client, API endpoint, token handling, or database write
operation in this package. Extraction forms and XML snapshot publication are
maintainer workflows outside the package. Dataset URLs are independent of their
hosting provider; every workbook is verified by size and SHA-256.

Offline distributions can bundle workbooks as
\code{inst/extdata/datasets/<sha256>.xlsx}. A bundled workbook is used before
its external URL and undergoes the same verification. The regular CRAN package
keeps the full workbook collection external. An explicit
\code{nmadb.dataset_root} overrides both bundled and remote retrieval.

For an offline checkout, set \code{options(nmadb.path="/path/to/checkout",
nmadb.dataset_root="/path/to/checkout")}.

}
\value{Catalogue functions return data frames or names. \code{readByID} returns
a dataset and its metadata. \code{runnetmeta} and \code{getmetaNetw} return a
\code{netmeta} result. Verification functions return pass/fail information.
\code{exportData} saves a verified workbook and invisibly returns its path.
\code{getManifest} returns snapshot metadata and the resource manifest.}
\examples{
catalog <- getNMADB()
head(nmadatanames(catalog))
raw_catalog <- getNMADB(raw=TRUE)
head(raw_catalog$dataset_sha256)
\dontrun{
network <- readByID("501321")
analysis <- runnetmeta("501321", model="random")
}
}
