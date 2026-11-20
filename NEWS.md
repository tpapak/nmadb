# nmadb 1.3.0

* Public reads use the bundled 1,670-record catalogue and 603 external Excel
  datasets; no source-database connection or credentials are required.
* `getManifest()` exposes the frozen database manifest. Catalogue, codebook,
  dataset manifest, and workbook bytes are checked against SHA-256 hashes.
* Offline distributions can bundle original workbooks in `inst/extdata/datasets`;
  these are preferred over external URLs and checked against the same hashes.
* Public query, download, conversion and analysis functions are retained.
  Conversion runs in R, without V8 or downloaded JavaScript.
* Fixed and random analysis selection works with current netmeta.
* Verification returns failures correctly, including within `checkRecords()`.
* Breaking change: database administration is outside the package. Removed
  `updateVerifiedStatus()`, `importreq()`, `uploaddatasets()`, `NMADBURL`,
  `PUBLICTOKEN`, and the `updateRecord`/`updateDB` verification arguments.
  RCurl is no longer a dependency, including optional dependencies.
