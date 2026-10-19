# Development status — 2026-10-18

## Current state and authorization

BvS remains a Windows batch utility. Published v1.0.0 is unchanged; the proposed
maintenance target is v1.0.1, not released. Stage-safety PR #4 merged at `3378431a`; validated source head is `0af524d`.
Final-remux safeguards and workspace lifecycle improvements preceded this work.
Both 1.78 and 1.43 unmasked modes retain the original media-command arguments,
cuts, transforms, encoding settings and output names.

Startup anchors execution to the launcher directory, requires docs, refuses any
existing docs/temp and checks exclusive workspace creation. Existing work survives
restarts and simultaneous launches. There is no automatic resume.

Preparation, splitting, HandBrake encoding and Avidemux assembly stop on positive
or negative process failures and reject missing/empty expected outputs. Assembly
also checks each fixed load/append input before starting. MKVToolNix warning status
1 stops for review; failures return 2. Stage markers and tool diagnostics go to
processing.log; final-remux diagnostics go to final-remux.log in docs/temp.

Structural stage gates are supplemented by independent decoded-frame assembly
validation before final remux. `docs/scripts/Validate-Assembly.ps1` reads the
mode-specific ordered manifest, decodes each input and the assembly with the
bundled FFmpeg, and compares frame hashes in order. Missing validator, signed
process failures, decode failures and mismatches stop the pipeline and retain
all work. Its new work directory contains the reports and diagnostics. This
requires decoding the film twice in total (segments plus assembly) and can be
slow on 4K HEVC. It adds no processing executable; Windows PowerShell is required.

This does not validate timestamps, HDR metadata, intended cuts/framing or
synchronization. Cleanup remains disabled until qualification. The
bundled Avidemux 2.8.1 does not reliably propagate append/save errors to its exit
status. All intermediates, assembly and logs therefore remain even after a final
output is created. Completion returns warning 1 and requests manual review. This
requires substantially more disk space: prepared video, raw splits, encoded
splits, assembly and final output can coexist. After review, move the retained
workspace somewhere safe before another run. Explicit exits restore caller cwd.

Primary Avidemux 2.8.1 sources: [automation callbacks](https://raw.githubusercontent.com/mean00/avidemux2/2.8.1/avidemux/common/ADM_toolkit/automation.cpp)
ignore append/save return values; [CLI UI_RunApp](https://raw.githubusercontent.com/mean00/avidemux2/2.8.1/avidemux/cli/ADM_userInterfaces/ADM_dialog/DIA_none.cpp)
returns zero after automation. A zero exit plus a nonempty file cannot establish
that all segments were appended successfully.

Workspace and output-check helpers use the same structure as Asteroid City;
film-specific commands remain explicit. The owner approved maintenance,
refactoring, useful parallel work and the source-only branch/PR/Windows-test/
validated-merge workflow. Release downloads/tags, major architecture/dependency
changes and private-media access require separate approval. No release archive,
processing binary, logo or private film is uploaded under this authorization.

## Validation

`python3 -m unittest discover -s tests -v` on macOS: five static checks PASS;
eleven Windows methods SKIP as intended. Python/C# are development-only tools.
The original media-command digest and diff checks pass.

Windows stage-safety run for source head `0af524d`: **PASS**. All sixteen test
methods passed with no skips in each real-tool stage, using Windows Server 2022
and MKVToolNix 78.0/102.0:
https://github.com/teymourb/Batman-v-Superman-IMAX-Restorer/actions/runs/39157671781

Coverage includes whole production mode control flow with native synthetic tools:
every pre-remux stage receives positive errors, negative crashes with partial
outputs, or missing/empty outputs despite status zero. Tests check immediate stop
and byte-identical retention of earlier work. Missing tools, preparation warnings
and both manual/dialog source branches are exercised. The final-remux matrix has
40 mode/source/destination/status cases, including negative process crashes.

Existing synthetic real-tool remux tests compare video packet hashes and raw PCM
sample bytes in both modes. Workspace tests cover unrelated caller directories,
sentinel files, special-character installation paths, existing recovery work,
concurrent launches and unknown leftovers. Earlier workspace Windows evidence:
https://github.com/teymourb/Batman-v-Superman-IMAX-Restorer/actions/runs/39156034272

Whole-mode tests replace tools with synthetic stubs and bypass dialogs/PAUSE;
they do not qualify real Avidemux/HandBrake film processing. Full-film completeness,
cuts, encoding quality, HDR, metadata, synchronization, Windows desktop dialogs,
general special-character source/destination paths and actual ACL/disk-full
fixtures remain unqualified. No private media is used.

## Bundled-tool audit

Public v1.0.0 archive:
https://github.com/teymourb/Batman-v-Superman-IMAX-Restorer/releases/download/v1.0.0/Batman-v-Superman-IMAX-Restorer_v1.0.0.7z

- Archive SHA256: 7f4701624ae87c21225e339b2caa65085ec7380a446b17bb155d04155ae4829a.
- Bundled mkvmerge.exe SHA256:
  f707365fc6374db58c875d69fe8d3c3f572ab54369b28a863bc9aaad3ebc09ef.
- Bytes match official 64-bit 78.0. CI checks archive and executable hashes.
- Official archive SHA256:
  28aeb942e88b9bde8ad93b00020c9ab5289836bffd6df36582a6fd652cc7fdba.
- No Windows executable was run locally. Other dependency provenance/licensing
  and a full release-package audit remain release-preparation work.

## Next

Qualify the independent assembly check on actual Windows synthetic media and
representative real restorations before considering automatic deletion. Current
branch changes have local static checks only until Windows CI results are recorded.
Review retained outputs manually when real-film qualification becomes necessary;
private media needs task-specific consent. Resolve release-package provenance,
source/license documentation and any asset redistribution questions before
preparing a current candidate and requesting release approval.

Then simplify repeated input/remux branches while preserving command baselines.
Introduce portable planning/profile code when a demonstrated shared need supports
it. Source-fingerprint qualification remains separate and synthetic-first; the
reported BvS hash is not an implemented acceptance gate.

## Assembly validation branch

The mode manifests are checked against actual Avidemux load/append argument order.
Whole-mode synthetic tools isolate validator status handling: a missing validator,
positive failure and negative failure must prevent final remux and preserve work.
The original media-command digest remains unchanged. No private media is used.
