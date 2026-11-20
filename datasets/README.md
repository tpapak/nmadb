# NMADB Excel datasets

This snapshot contains 603 Excel datasets extracted from the `dataset` field in
the REDCap export dated 2026-11-20. The workbook bytes are preserved unchanged.
Publication references remain DOI links; this directory contains no PDFs.

`manifest.json` maps each original REDCap `record_id` and `field` to its original
`filename`, byte `size`, SHA-256, repository `path`, and `file_url`. Files are named
`files/<sha256>.xlsx`. Record IDs are strings, including IDs containing hyphens.

Download URLs are pinned to the full Git commit in `file_revision`, rather than a
moving branch. Keep that commit reachable when merging this branch: use a normal
merge, rather than squash or rebase, because the manifest refers to the first
commit containing the workbooks.

## Retrieving a dataset

1. Find the manifest entry matching the requested `record_id` and `field`.
2. Download `file_url`.
3. Compare the downloaded byte size and SHA-256 against the manifest before
   opening the workbook. Reject a mismatch; do not interpret it as a dataset.

File identity is independent of storage location. A university server or Zenodo
release can supply an alternative URL if the downloaded bytes have the same
SHA-256. This snapshot does not change the R package's REDCap download functions.

REDCap remains the interface for data entry and database updates. Future
repeating instruments should extend the association with a stable study ID,
event, instrument and repeat instance. Do not use a URL as the study identifier.

Only the 603 records with dataset attachments have entries here. The complete
REDCap export has 1,670 records; absence from this manifest is not a missing
database record. Full database exports, API credentials, and browser session
files are not included.

## Verifying a checkout

From the repository root:

```sh
python3 datasets/verify.py
```
