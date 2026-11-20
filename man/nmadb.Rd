\name{nmadb}
\alias{nmadb}
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
\alias{updateVerifiedStatus}
\alias{response}
\alias{recs}
\alias{havedata}
\alias{filename}
\alias{importreq}
\alias{uploaddatasets}
\alias{NMADBURL}
\alias{PUBLICTOKEN}
\title{Query NMADB and retrieve verified network datasets}
\description{Access the frozen REDCap catalogue and Excel datasets hosted on GitHub.
Dataset downloads are checked against their original SHA-256 and byte size.
Legacy network analysis, verification and administrative function names are retained.}
\usage{
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
verifyData(recid, updateRecord = FALSE)
checkRecords(records, updateDB = FALSE)
updateVerifiedStatus(recid, isVerified = 0, err = "")
response()
recs()
havedata()
filename(recid)
importreq(recid)
uploaddatasets()
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
\item{updateRecord, updateDB}{Whether to submit verification results to the configured REDCap project.}
\item{isVerified}{Verification code, zero or one.}
\item{err}{Diagnostic to save for an unsuccessful verification.}
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

REDCap write helpers require the optional \code{RCurl} package and a locally set
\env{NMADB_API_TOKEN}. Configure \env{NMADB_API_URL} or option \code{nmadb.api_url}
for the intended project. They do not edit the frozen public snapshot. The
\code{PUBLICTOKEN} compatibility constant is empty.

For an offline checkout, set \code{options(nmadb.path="/path/to/checkout",
nmadb.dataset_root="/path/to/checkout")}. Administrative workbook uploads use
\code{nmadb.upload_dir}, defaulting to \code{"nmadb"}.
}
\value{Catalogue functions return data frames or names. \code{readByID} returns
a dataset and its metadata. \code{runnetmeta} and \code{getmetaNetw} return a
\code{netmeta} result. Verification functions return pass/fail information.
\code{exportData} saves a verified workbook and invisibly returns its path.
Write helpers return the REDCap API response.}
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
