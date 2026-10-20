# Current public/developer boundary — 2026-10-20

The owner requested removal of developer qualification from the public program.
The launcher now asks only for the required source, output folder, restoration
and confirmation. It never invokes frame comparison or asks for a check level.
Frame comparison and its manifests are developer tools under `tools/qualification`;
BvS storage and continuation helpers are also separate developer experiments.
They are excluded from the application payload. There is no public validation
report or skipped-test status. Processing exit/output/input safeguards remain.
Successful completion returns 0; actual MKVToolNix warnings retain their warning
status. Retaining temporary files alone is not a warning. All intermediates are
still retained: no cleanup or automatic resume has been introduced.

Cuts, requested frame counts, transformations, HandBrake settings, Avidemux
section order and tool versions remain unchanged. FFmpeg uses -nostdin and
Avidemux questions remain visible. This does not resolve codec/join uncertainty.
Windows evidence for this revision must be recorded before validated merge;
earlier results below qualify their historical source revisions only.

## Historical implementation/evidence record

The following dated sections describe prior work, including the now withdrawn
public validation-level design. They are retained as development history and
must not be read as the current application workflow or release instructions.

# Development status — 2026-10-19

## Current state and authorization

BvS remains a Windows batch utility. Published v1.0.0 is unchanged; the proposed
maintenance target is v1.0.1, not released. Final-remux, workspace and stage-safety
changes are merged; independent assembly validation merged in PR #6 at
`f3a4dfb1f22c5240a51a0903abb660d30bd4f8d9`. Validated source head is
`888dffd36047d99e69dfcfb1ca99e39e1ac5368e`: both Windows Server 2022 jobs
with MKVToolNix 78.0 and 102.0 PASS, all 30 methods without skips in the
real-tool stage. Job logs were checked before merging:
https://github.com/teymourb/Batman-v-Superman-IMAX-Restorer/actions/runs/39193323312

Both 1.78 and 1.43 unmasked modes retain their original media-command arguments,
cuts, transforms, encoding settings and output names. Startup anchors execution
to the launcher directory, requires docs, refuses any existing docs/temp and
checks exclusive workspace creation. Existing work survives restarts and
simultaneous launches. There is no automatic resume.

Preparation, splitting, HandBrake encoding and Avidemux assembly stop on positive
or negative process failures and reject missing/empty expected outputs. Assembly
checks each fixed load/append input before starting. MKVToolNix warning status 1
stops for review; failures return 2. Stage markers and tool diagnostics go to
processing.log; final-remux diagnostics go to final-remux.log in docs/temp.

When exhaustive checking is selected, before final remux
`tools/qualification/Validate-Assembly.ps1` reads the mode-specific
ordered manifest and uses the bundled FFmpeg to compare decoded frame hashes
of the segments, in order, against the assembly. Missing validator/tool, process
failures, decoder errors, malformed reports and mismatches stop processing and
retain all work. Reports and diagnostics are kept in a new validation directory.
Windows PowerShell runs the check; no additional processing executable is added.
Decoding the segments plus assembly is approximately two film lengths of decode
work, not a wall-clock estimate; 4K HEVC validation can take substantial time.

Frame identity and order do not qualify timestamps, HDR metadata, intended cuts,
framing or synchronization. Automatic cleanup remains disabled pending broader
qualification. All intermediates and logs remain even after final output creation;
completion returns warning 1 for review. Prepared video, raw splits, encoded
splits, assembly and final output can coexist, requiring substantially more disk
space. After review, move the retained workspace somewhere safe before another
run. Explicit exits restore the caller directory.

The bundled Avidemux 2.8.1 does not reliably propagate append/save errors. Primary
sources: [automation callbacks](https://raw.githubusercontent.com/mean00/avidemux2/2.8.1/avidemux/common/ADM_toolkit/automation.cpp)
ignore append/save return values; [CLI UI_RunApp](https://raw.githubusercontent.com/mean00/avidemux2/2.8.1/avidemux/cli/ADM_userInterfaces/ADM_dialog/DIA_none.cpp)
returns zero after automation. A zero exit and nonempty file cannot establish
that assembly succeeded.

The owner approved maintenance, refactoring, useful parallel work and the
source-only branch/PR/Windows-test/validated-merge workflow. Release downloads,
tags, major architecture/dependency changes and private-media access require
separate approval. No release archive, processing binary, logo or private film
is uploaded under source-only authorization.

## Validation and limits

Local `python3 -m unittest discover -s tests -v` on macOS: seven checks PASS;
23 Windows methods SKIP as intended (30 total). Python/C# are development-only.
The original media-command digest remains unchanged. Current assembly evidence
is the PR #6 run above; older runs below describe the prior baseline.

Earlier stage-safety source head `0af524d` passed all sixteen methods with no skips
in each real-tool stage on Windows Server 2022, MKVToolNix 78.0/102.0:
https://github.com/teymourb/Batman-v-Superman-IMAX-Restorer/actions/runs/39157671781

Coverage retained from that baseline includes whole-mode synthetic tool failures,
negative crashes with partial outputs, zero-status missing/empty outputs, immediate
stop and byte-identical retention, missing tools, preparation warnings, manual/
dialog source branches and 40 final-remux mode/source/destination/status cases.
Synthetic real-tool remux tests compare video packet hashes and raw PCM sample
bytes. Workspace tests cover unrelated caller folders, sentinels, special-character
installation paths, recovery work, concurrent starts and unknown leftovers.

New checks verify manifests against Avidemux load/append order and stop before
final remux when the validator is missing or fails. Validator fixtures cover
correct sequences, omitted/repeated/reordered/extra segments, corrupt or truncated
media, missing/empty/directory inputs, unavailable tools, protected existing
evidence, 10-bit pixel fidelity, decoder errors and malformed hash reports.

Actual historical Avidemux/FFmpeg tests use tiny generated H.264 and 10-bit HEVC
clips. They exercise valid assemblies, wrong sequences, silent append failure,
open-GOP/B-frame assembly and the launchers' seek/copy split pattern. An expanded
synthetic copy-split fixture exposed missing HEVC reference pictures with open
GOPs. The current test requires a closed-GOP case to pass and a separate decoder-
to-null invocation to establish the open-GOP damage before requiring validator
rejection. Earlier passing simple fixtures did not cover this condition. This is
a synthetic compatibility finding, not evidence that either actual film is
affected; no real film was inspected. Decoder checks must not be relaxed to make
a damaged fixture pass.

Whole-mode control-flow tests substitute tools and bypass dialogs/PAUSE. Actual
tool tests remain small synthetic fixtures, not full-film qualification. Intended
cuts/framing, quality, HDR/metadata, synchronization, actual source-edition
compatibility, desktop dialogs, general special-character media paths and real
ACL/disk-full conditions remain unqualified. No private media is used.

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

The automated assembly checkpoint is complete. Start with one real-film Windows
qualification run and measure decoding time/storage before expanding to other
modes. Keep automatic deletion disabled meanwhile.
Real-film tests become necessary when the remaining question is actual source/
restoration behavior; private-media access requires task-specific consent.

Resolve release-package provenance, source/license documentation and any asset
redistribution questions before preparing a current candidate and requesting
release approval. Then simplify repeated input/remux branches while preserving
command baselines. Introduce portable planning/profile code when demonstrated
shared needs support it. Source-fingerprint qualification remains separate; the
reported BvS hash is not an implemented acceptance gate.

## Unreleased interaction revision

Selection now uses Windows PowerShell 5.1 STA WinForms dialogs and explicit manual
fallback. Cancel/quit returns 3 without creating docs/temp; invalid selection
returns 2. Setup validates a nonempty MKV, existing destination, mode, existing
output and preserved workspace before confirmation. This is a file/path check,
not proof of the required source fingerprint or adequate disk capacity.
The confirmed child launcher receives Unicode environment values without a
codepage-dependent configuration file or generated command script. Selected
entry revalidates environment before workspace creation. Spaces, Unicode,
ampersands and parentheses are supported; !, %, caret, embedded quotes and control
characters are rejected with an actionable message because inherited batch
processing is not safe for those paths. No processing command arguments changed.
Visible stage names accompany detailed redirected logs. Full dialogue appearance
and desktop cancellation still require hands-on Windows qualification.

The storage-builder's baseline is now an explicitly historical fixture in
`tests/fixtures/storage-qualification-baseline.bat`, checksum pinned to the
reviewed owner-run kit. Rebuilding it reproduces the existing qualification run;
it does not silently incorporate this revised interaction flow. Do not update an
owner's running installation. A future storage launcher requires its own review.
Existing output is checked again immediately before final remux, preserving a
file created while encoding was running. This is not an atomic filesystem lock
against an unrelated process creating the same path at the exact tool launch.

## Owner-operated interrupted-qualification packaging

`tools/qualification/Continue-Qualification.ps1` is a separate packaging experiment for
an existing BvS 1.78 storage-qualification workspace at `BeforeAssembly` after
assembly validation was interrupted. The production launcher never invokes it.
It does not relax the production validation gate or establish any validation pass.

Owner invocation in Windows PowerShell 5.1 (use the actual extracted installation
and an existing destination outside docs/temp):

```powershell
& 'C:\path\to\Continue-Qualification.ps1' -InstallationRoot 'H:\Restorer\Testing\Batman-v-Superman-IMAX-Restorer_v1.0.0' -Destination 'H:\Restorer\Testing\BvS-output'
```

Stop the original launcher/validator first. The helper reads the existing storage
JSON, requires unchanged source size/modification time and the fixed nonempty
`docs/temp/BvS_1.78.mkv`, and pins the audited bundled MKVToolNix 78 executable.
Metadata continuity is not source fingerprint verification. It rejects linked
paths, unsupported destination filesystems and insufficient capacity. Its budget
is assembly bytes + max(source bytes - recorded prepared-video bytes, 0) + 2 GiB
mux allowance + 20 GiB reserve. Existing intermediates already occupy space and
are never removed; a same-drive destination therefore uses the single remaining
free-space pool, without adding fictitious space from deletions.

Read the warning and type `PACKAGE` only to request an explicitly UNQUALIFIED
output. Any other response cancels with exit 3 before creating an output directory.
The tool reserves a new GUID-named child destination, retains partial outputs and
records input metadata, tool SHA256, arguments, stdout/stderr and completed status
there. Logs stream to disk while packaging runs; elapsed-time messages appear
every ten seconds. Cancellation attempts to terminate only its own mkvmerge child
and leaves the start-only result and partial output unqualified. Use Ctrl+C for
normal cancellation; forcibly closing the host or terminating it in Task Manager
cannot guarantee child cleanup. Check for a surviving mkvmerge before retrying,
and never blindly restart the production launcher. It reuses the
production 1.78 final-remux selection arguments through a
UTF-8 JSON response file; there is no encoding. Read-only source/state/assembly/tool
handles exclude concurrent writers during packaging; the state handle also
excludes concurrent continuation launches without writing to the state file. The active-media-process
check is advisory and cannot establish that every unrelated process is idle.
Do not modify files while it runs. Existing source files, intermediates, logs and
storage state are preserved.

Exit 0 means mkvmerge returned 0 and produced a nonempty file; 1 means warning
status with a nonempty file; 2 means failure. Neither 0 nor 1 qualifies assembly,
source identity, codec joins, timestamps, HDR, synchronization or playback. The
new file is labelled UNQUALIFIED and must not be presented as a release-qualified
restoration. A start-only result without completed-result.txt means interrupted
packaging. This operation is not a general resume feature or normal user workflow.

## Maintenance RC interaction and validation policy (2026-10-20)

Setup now requires an explicit choice between basic checks and exhaustive decoded
frame comparison. Basic retains process-status, expected-output and input checks;
it does not establish assembly frame identity, codec compatibility, timestamps,
HDR, audio synchronization or playback. Its assembly-check.txt explicitly says
NOT RUN. Exhaustive records RUNNING, then PASS only after validator exit 0; a
failure or controlled cancellation records NOT PASSED and stops final remux.
Neither mode enables automatic cleanup. Both retain all intermediates and logs.

All production FFmpeg split invocations add only -nostdin, disabling accidental
keyboard commands. Cut positions, frame counts, stream-copy flags, HandBrake
settings, Avidemux load/append order and tool versions remain unchanged.
Avidemux runs attached to the console so codec questions and answers are visible.
No warning is automatically accepted. Its detailed stdout/stderr now appear only
in that console, not processing.log; the log retains the assembly stage marker
and subsequent validation status. Declining a question does not guarantee the
historical tool reports failure; basic checks cannot qualify a partial assembly.

Exhaustive validation prints the active file and ten-second elapsed heartbeats.
Press Q to cancel its decoding, parsing or comparison; it stops processing,
terminates only its own decoder child if active and preserves evidence. The
optional CancellationFile parameter requests the same cancellation for automation
and tests; it cannot bypass validation or establish a pass. Ctrl+C and forced
host termination cannot guarantee a completed status record; never infer PASS
from a RUNNING record. Actual interactive Windows keyboard behavior still needs
bounded desktop qualification; native cancellation-file tests cover the shared
stop/child-cleanup path using synthetic data.
