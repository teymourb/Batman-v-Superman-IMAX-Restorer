# Development status

## Final-remux safety, proposed 1.0.1

Base: `79ae0c0ba8a8bea2e88648cf61ce4b3f14aebce3` (main / v1.0.0).
Both 1.78 and 1.43 unmasked workflows now retain assembled video and
`docs\temp\final-remux.log` after warnings, errors, missing tools or missing/empty
output. MKVToolNix status 1 returns warning status 1; errors return status 2.
No media command arguments changed.

`python3 -m unittest discover -s tests -v` on macOS: three source regressions
passed; three Windows tests skipped. The Windows workflow exercises all eight
mode/source/destination combinations against native executable exit statuses,
missing tool and missing/empty output, plus a synthetic video/audio remux.
It tests both the exact bundled MKVToolNix 78.0 executable and version 102.0.
Final-remux parity was merged in PR #1 at `79ba4ad` after both Windows jobs
passed: https://github.com/teymourb/Batman-v-Superman-IMAX-Restorer/actions/runs/39155612524.

The harness bypasses dialogs, earlier processing and PAUSE. Full-film cuts,
encoding, HDR, track/metadata preservation, synchronization and desktop dialogs
remain unverified. Earlier stages retain legacy error handling.

## Workspace safety follow-up

Base: `79ba4ad87ec653f2540b8a8373da1f999c870c88` (merged final-remux parity).
Launch now anchors execution to the script folder with checked `pushd`, requires
`docs`, refuses any existing `docs/temp` and verifies workspace creation. Success
removes only the known final-remux log and attempts nonrecursive directory
removal; unexpected files/subdirectories remain. Success, warnings and errors
restore the caller directory. Helpers and synthetic workspace tests share the
Asteroid City structure, with film-specific processing kept unchanged.

Local validation: four source regressions passed; eight Windows tests skipped on
macOS. Windows CI is pending for this follow-up. New Windows cases launch from
an unrelated directory, use installation paths containing spaces, `&` and `!`,
check cwd during processing and after exit, preserve existing recovery work across
repeated launches, reject missing docs/file-at-temp, preserve unknown leftovers,
and refuse concurrent acquisition of an active workspace. No runtime tool version
or restoration media command changed. A retained workspace needs manual review
and relocation before a fresh run; this is not resume support.

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
