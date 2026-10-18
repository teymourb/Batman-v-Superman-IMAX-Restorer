# Changelog

## Unreleased — proposed 1.0.1

- Stop failed preparation/splitting/encoding/assembly immediately, record stage
  diagnostics and reject missing/empty expected outputs before dependent work.
- Catch negative native-process crash statuses as well as positive failures.
- Preserve all intermediate files and logs even when final remux succeeds:
  Avidemux does not reliably propagate append/save errors. Output creation now
  returns warning status 1 pending manual completeness review. More free disk
  space is required; automatic cleanup needs independent assembly qualification.

- Anchor execution to the launcher folder and refuse an existing temporary
  workspace instead of deleting retained work on restart.
- Remove wildcard cleanup; preserve unexpected temporary files/subdirectories
  and restore the caller directory on success, warnings and errors.

- Retain the assembled video and final-remux diagnostic log when MKVToolNix
  reports warnings or errors, or the destination output is missing or empty.
- Report final-remux warning/error status instead of continuing to success cleanup.
- Add focused Windows regressions and synthetic remux checks for both modes.
- Preserve existing cuts, transforms, encoding settings and remux arguments.

No new downloadable release has been published. Read docs/DEVELOPMENT.md for
validation coverage and known limitations.
