# Source-video fingerprint gate — implementation record, 2026-10-20

This runtime gate is being implemented and must pass reviewed synthetic Windows
checks before candidate qualification. No agent inspected a private film. The
reference values below come from owner-operated Windows commands/screenshots.

## Version 1 recipes and acceptance values

The runtime helper is `docs/scripts/Test-SourceFingerprint.ps1`. It uses the
installation's MKVToolNix identification/extraction tools and, for BvS, its FFmpeg.
Identification must report exactly one video track of the expected codec; its
reported ID is extracted. Track ID 0 is not assumed. Container audio, subtitles,
chapters and track order are outside the hashed extracted video representation.

| Film | Recipe | Accepted SHA256 |
| --- | --- | --- |
| Batman v Superman 2021 remaster | Normal MKVToolNix HEVC extraction, then bundled FFmpeg raw HEVC input, video stream copy, `filter_units=remove_types=35\|62`, hash muxer SHA256 | `58371280f7c8debbf2a87fa1bad9e6b97ae6f83d49d981489f724608f9e0781c` |
| Asteroid City Blu-ray | Normal MKVToolNix AVC extraction, SHA256 of extracted file bytes | `203c7f5e1fc79013282c7a3218228818e5ecb60a04fd55ac420ce3de538373cd` |

BvS's historical unnormalized extraction SHA256 is
`74412d94f23772439af5b6fe3b94b3daa1ad667e0f3c35a2b8b2fe4581445227`.
Fresh owner MKVToolNix 78 extraction reproduced it. Owner HDR10 reference and
RPU-added Profile 8.1 extraction produced the same normalized value above with
the same bundled FFmpeg recipe. Only AUD (35) and RPU (62) NAL units are removed
for hashing; this is not blanket Dolby Vision profile support. Restoration media
commands are not changed by normalization, and source matching does not promise
Dolby Vision output preservation.

Owner Asteroid evidence reports MKVToolNix 78 track 0 AVC extraction. Extraction
byte counts and independent film provenance were not independently verified by
agents. This is the explicit owner-provided compatibility reference, not proof
of every technical property of the disc or all remux applications.

Audited historical bundled FFmpeg executable SHA256:
`d28eec987cf8a2f25f3ce303ff612c35bf7ca541c3a5090de718caf525fb9a62`,
embedded version `N-112110-g5acc3c4cff-20230917`. MKVToolNix baseline is 78.0.
The separately audited mkvmerge SHA256 is
`f707365fc6374db58c875d69fe8d3c3f572ab54369b28a863bc9aaad3ebc09ef`;
it must not be described as the mkvextract executable hash.

## Runtime and evidence limits

The helper runs before preparation/encoding, retains a fingerprint result and
diagnostics in the new workspace, and owns a unique scratch extraction folder.
Only its own scratch material may be cleaned; pre-existing work is preserved.
The full extracted video temporarily requires substantial additional free space.
A mismatch or failed identification/extraction/hash must stop restoration. No
production override or user-selected expected hash is provided.

The normalized result is a hash of compressed packet bytes, not decoded frames.
It excludes source timing and container metadata and intentionally excludes BvS
AUD/RPU bytes. It cannot establish correct cuts, seamless joins, HDR metadata,
audio synchronization or output quality. Equal display content can still hash
differently when its compressed representation changes. Extractor/FFmpeg changes
require recipe compatibility tests before adopting them as production tools.

Required synthetic coverage includes a matching control, changed-video mismatch,
metadata/audio/remux/track-order variants, wrong or multiple video tracks, failed
native processes, malformed output and preserved predecessor files. Historical
passing workflows do not qualify this new implementation. Actual Windows results
and exact source/run identities must be added before validated merge or RC claims.
