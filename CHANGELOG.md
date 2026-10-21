# Changelog

## 1.0.1 — 2026-10-21

- Check the supported source-video fingerprint before restoration starts; stop on
  unsupported sources or source-check failures without re-encoding the source.
- Provide native source/output dialogs, Enter-before-dialog instructions, manual
  path fallback, clear restoration choices, confirmation and cancellation.
- Improve setup, stage progress, completion and error messages.
- Stop on reported tool failures or missing/empty expected outputs; protect
  existing destination files and retain diagnostic logs.
- Keep generated temporary videos in `docs/temp` and run logs separately in
  `docs/logs`. Silently clean known temporary videos after success and before a
  confirmed fresh run; protect unrelated files and active workspaces.
- Explain safe manual removal of interrupted work after closing the program.
  Automatic resume is not implemented.
- Refresh the README while retaining original comparison GIFs, credits and modes.
- Validate the maintenance changes with Windows synthetic regression tests.

Film-specific split points, transformations, encoding settings, assembly order
and bundled processing tool versions remain unchanged.

[Release notes and complete download](https://github.com/teymourb/Batman-v-Superman-IMAX-Restorer/releases/tag/v1.0.1)

[Earlier releases](https://github.com/teymourb/Batman-v-Superman-IMAX-Restorer/releases)
