# Development status — 2026-10-18

## Current state and authorization

BvS remains a Windows batch utility. Original main/v1.0.0 was 79ae0c0; final-remux
parity is merged via PR #1 at 79ba4ad. Proposed maintenance target: v1.0.1, not
released. PR #2 introduces the same workspace helper structure as Asteroid City.

Both 1.78 and 1.43 unmasked modes retain assembled video and final-remux.log after
warnings/errors, missing tools or absent/empty output. Warnings return status 1;
errors return 2. No media-command arguments, cuts, transforms, encoder settings or
successful output names changed.

Startup checks the launcher folder/docs, refuses ANY existing docs/temp and checks
creation before processing. A second run cannot acquire an existing workspace.
Success cleanup removes only the known log and uses nonrecursive rmdir; unknown
leftovers survive with a cleanup warning. Explicit exits restore caller cwd.
Existing work survives restarts. There is no automatic resume.

prepare_workspace/cleanup_workspace and generic workspace tests are byte-identical
to Asteroid City. This is the first shared structural refactor; film-specific
processing commands remain explicit in each repository.

The owner approved the next maintenance/refactoring tasks, parallel work and the
branch/PR/Windows-test/validated-merge workflow. Release downloads/tags, major
architecture/dependency changes and private-media access need separate approval.
No release archive, tool binary or private film is committed or uploaded.

## Validation

`python3 -m unittest discover -s tests -v` on macOS: four source checks PASS;
eight Windows methods SKIP as intended. Python/C# are development-only tools.

- Final-remux parity: all six methods passed in both exact-78.0/102.0 Windows jobs.
  https://github.com/teymourb/Batman-v-Superman-IMAX-Restorer/actions/runs/39155612524
- Workspace follow-up: all 12 methods pass with no skips in each real-tool stage,
  using Windows Server 2022 and MKVToolNix 78.0/102.0:
  https://github.com/teymourb/Batman-v-Superman-IMAX-Restorer/actions/runs/39156034272
- Coverage: 32 remux branch/status cases, missing tool/output, both synthetic remux
  modes preserving video packet hashes and PCM bytes; unrelated caller cwd and
  sentinel files, missing docs, temp as file, repeated restarts retaining work,
  simultaneous launch, unknown nested leftovers and success/warning/error exits.
- Original media-command digest is unchanged; diff checks pass. Helpers and generic
  workspace tests match Asteroid City exactly.

Harnesses execute actual startup/remux/helper/exit sections but bypass dialogs,
previous processing and PAUSE. Full-film cuts, encoding, HDR, track metadata,
synchronization and Windows desktop dialogs are NOT qualified. General special-
character source/destination paths, actual ACL/disk-full failure fixtures and
full-stage error handling remain separate work. No private media used.

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

Add stage-level error handling before deleting inputs to preparation, extraction,
encoding and assembly stages. Then simplify repeated input/remux branches while
preserving command baselines. Introduce portable planning/profile code when there
is a demonstrated shared need. Source fingerprint qualification is separate and
synthetic-first; the reported BvS hash is not an implemented acceptance gate.

## Stage-safety branch (not yet Windows-qualified)

Preparation, splitting, HandBrake encoding and Avidemux assembly have immediate
positive/negative exit gates, fixed-path nonempty output checks and processing.log
stage diagnostics. Assembly requires every fixed load/append input first. Media
arguments remain byte-identical to the original command baseline. Final remux
also rejects negative process exit codes.

Avidemux 2.8.1 does not reliably propagate append/save failures, so these checks
are structural guards, not completeness qualification. All intermediate inputs,
assembly and logs remain even after output creation; production completion returns
warning 1 and asks for review. This intentionally increases peak disk usage.
Independent assembly completeness qualification is needed before automatic cleanup
can safely return. No automatic resume and no private-media access.

New native stub tests execute entire production mode control flow while bypassing
only dialogs/PAUSE. They inject positive errors, negative crashes with partial
outputs, missing/empty successful outputs at every pre-remux stage, missing tools
and MKVToolNix preparation warnings. macOS: five static checks pass; eleven Windows
methods skip. Actual Windows evidence remains required before merging this branch.
