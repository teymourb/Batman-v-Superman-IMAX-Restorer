# Development status

## Final-remux safety, proposed 1.0.1

Base: `79ae0c0ba8a8bea2e88648cf61ce4b3f14aebce3` (main / v1.0.0).
Both 1.78 and 1.43 unmasked workflows now retain assembled video and
`docs\temp\final-remux.log` after warnings, errors, missing tools or missing/empty
output. MKVToolNix status 1 returns warning status 1; errors return status 2.
Success still follows existing cleanup. No media command arguments changed.

`python3 -m unittest discover -s tests -v` on macOS: three source regressions
passed; three Windows tests skipped. The Windows workflow exercises all eight
mode/source/destination combinations against native executable exit statuses,
missing tool and missing/empty output, plus a synthetic video/audio remux.
It tests both the exact bundled MKVToolNix 78.0 executable and version 102.0.
Windows execution remains pending until the PR workflow runs.

The harness bypasses dialogs, earlier processing and PAUSE. Full-film cuts,
encoding, HDR, track/metadata preservation, synchronization and desktop dialogs
remain unverified. Startup still deletes retained temporary files: do not restart
a failed job before recovering its retained intermediate. Workspace cleanup is a
separate follow-up; this patch deliberately does not change it.

## Bundled-tool audit, 2026-10-18

Public archive inspected:
https://github.com/teymourb/Batman-v-Superman-IMAX-Restorer/releases/download/v1.0.0/Batman-v-Superman-IMAX-Restorer_v1.0.0.7z

- Release archive SHA256: `7f4701624ae87c21225e339b2caa65085ec7380a446b17bb155d04155ae4829a`.
- Bundled `docs/programs/mkvtoolnix/mkvmerge.exe` SHA256:
  `f707365fc6374db58c875d69fe8d3c3f572ab54369b28a863bc9aaad3ebc09ef`.
- Executable bytes match the previously audited official 64-bit MKVToolNix 78.0
  executable. Windows CI downloads the official 78.0 archive and checks both
  its archive hash and executable hash before executing synthetic tests.
- Official archive SHA256:
  `28aeb942e88b9bde8ad93b00020c9ab5289836bffd6df36582a6fd652cc7fdba`.
- No Windows executable was run on macOS. No release artifacts or private film
  files are committed; dependency licensing/repackaging is outside this patch.
