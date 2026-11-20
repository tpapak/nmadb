# nmadb — network meta-analysis database

NMADB provides a frozen catalogue of 1,670 network meta-analysis records and
603 Excel datasets. REDCap is the interface for extraction forms and database
updates. Public reads use the table bundled with this package and workbooks
hosted on GitHub; they require no REDCap login or API token.

## Install

```r
install.packages("remotes")
remotes::install_github("tpapak/nmadb", ref="migration/github-datasets-20261120")
```

Version 1.3.0 requires `digest`, `jsonlite`, and `readxl`. Install `netmeta` and
`meta` to run analyses. The package no longer requires devtools, V8, or JavaScript
loaded from a remote URL at runtime.

## Catalogue and datasets

The existing public function names and main return shapes are retained:

```r
library(nmadb)
catalog <- getNMADB()           # labelled columns, including Record.ID
raw <- getNMADB(raw=TRUE)       # raw REDCap names and string values
nmadatanames(catalog)
listVerified()
verifiedStudies()
unverifiedStudies()
network <- readByID("501321")
# list(name, data, type, effect, format)
exportData("501321", "network.xlsx")
```

`inst/extdata/catalog.tsv` contains all original XML table fields plus
`dataset_sha256` and `dataset_url`. Historical values are preserved, including
values outside the original form's validation rules. `codebook.json` provides
field labels, choices, field types, and original validation annotations.
These describe the source snapshot, not subsequent changes to the live forms.
A frozen table is refreshed by exporting the updated REDCap project and
regenerating the snapshot, rather than querying REDCap on every public read.

`datasets/manifest.json` maps record IDs to original filenames, SHA-256 hashes,
byte sizes, and commit-pinned GitHub download URLs. Every workbook is verified
before it replaces a requested destination file. Missing datasets raise a clear
error. Publication references remain DOI links; PDFs are not hosted.

## Analysis and verification

```r
install.packages(c("netmeta", "meta"))
runnetmeta("481216", model="random", measure="OR")
runnetmeta("481216", model="fixed")
verifyData("481216")
checkRecords(catalog[catalog$Record.ID %in% c("481216", "501321"), ])
```

`wide2long()`, `getmetaNetw()`, and `isOutcomeCompatibleWithMeasure()` remain
available. Conversion runs locally in R. Fixed and random model choices are
passed through to current `netmeta`. Historical incomplete workbooks or
atypical effect measures may fail analysis; preserving a workbook does not
establish its scientific validity.

## REDCap administration

`response()`, `recs()`, `havedata()`, and `filename()` retain their helper roles.
`importreq()`, `uploaddatasets()`, `updateVerifiedStatus()`, and verification with
`updateRecord=TRUE` or `updateDB=TRUE` remain explicit REDCap write operations.
They require optional `RCurl` and a locally configured `NMADB_API_TOKEN`.
Set `NMADB_API_URL` or `options(nmadb.api_url=...)` to the intended endpoint.
No token is included in the package. Cloudflare or server rules may still
prevent writes; GitHub hosting does not bypass those restrictions.

Administrative writes change the live REDCap project, not this frozen snapshot.
The old attachment-upload helpers are retained for compatibility; NMADB's
normal dataset downloads now use GitHub.

## Local verification

```sh
python3 datasets/verify.py
```

For offline package integration tests, set `NMADB_TEST_CHECKOUT` to this checkout
and run `tests/regression.R` with the installed package. This checks representative
binary, continuous, survival, rate, and wide-labelled networks, model selection,
verification results, and rejection of an altered workbook. Ordinary package
checks do not upload anything or require network access.

Database contents are not guaranteed valid and are not intended to substitute
for study selection and validation in a systematic review.
