## Dialog readiness — unreleased

Pause for Enter before opening each file/folder dialog, so the preceding
instructions remain readable. Q quits before a dialog opens. Manual path entry,
source verification and restoration behavior are unchanged.

## Console presentation — unreleased

Group setup and results with ASCII headings and spacing. Wrap long displayed
paths without changing their values. Show one shared free-space figure for a
shared drive. Source-check elapsed progress updates in place on an interactive
console; redirected logs remain ordinary lines. Processing recipes are unchanged.

## Mandatory source recognition — unreleased

Check the supported compressed video before restoration starts. BvS recognizes
its confirmed HDR10 base stream with or without the tested added Profile 8.1 RPU;
Asteroid checks its original AVC extraction. Wrong sources and failed checks stop
with diagnostics. No video encoding or decoding is performed by this check.
Only its own temporary extraction is removed. Film-processing recipes are unchanged.

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
