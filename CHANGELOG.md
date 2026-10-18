# Changelog

## Unreleased — proposed 1.0.1

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
