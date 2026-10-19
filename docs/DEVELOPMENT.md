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

Before final remux, `docs/scripts/Validate-Assembly.ps1` reads the mode-specific
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
