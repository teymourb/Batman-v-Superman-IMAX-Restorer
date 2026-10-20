# Changelog

## Unreleased — proposed 1.0.1

- Rewrite setup, processing and completion messages using the original source
  requirements and restoration descriptions; remove developer qualification
  choices and frame-comparison reports from the released workflow.
- Keep frame comparison, fixtures and qualification helpers in developer tools,
  separate from the application and its public package.
- Disable accidental FFmpeg keyboard input and show Avidemux questions and
  diagnostics directly in the console. Warnings are not automatically accepted.
- Stop failed preparation/splitting/encoding/assembly, record stage diagnostics
  and reject missing/empty outputs before dependent work. Catch native crashes.
- Preserve intermediates and logs after completion or failure. Retention alone
  does not turn successful completion into a warning; actual tool warnings and
  errors remain separate. Allow additional disk space for retained files.

- Anchor execution to the launcher folder and refuse an existing temporary
  workspace instead of deleting retained work on restart.
- Remove wildcard cleanup; preserve unexpected temporary files/subdirectories
  and restore the caller directory on success, warnings and errors.

- Retain the assembled video and final-remux diagnostic log when MKVToolNix
  reports warnings or errors, or the destination output is missing or empty.
- Report final-remux warning/error status instead of continuing to success cleanup.
- Add focused Windows regressions and synthetic remux checks for both modes.
- Preserve existing cuts, transforms, encoding settings and remux arguments.

No new downloadable release has been published. Read README.md for usage and known limitations.
