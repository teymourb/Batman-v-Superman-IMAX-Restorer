# Owner-operated BvS 1.78 storage qualification

This is a separate test procedure, not a production cleanup feature. It needs an
attended Windows run. It preserves the source film, every expensive HandBrake
encode, the assembled video and diagnostic logs. It permanently removes only
specifically named reproducible working copies at two checkpoints. The ordinary
launcher remains unchanged and still retains its working videos.

Do not use this procedure for BvS 1.43 or Asteroid City. Select **option 1** only.
The test launcher refuses other options before media processing starts.

## Prepare the test copy

1. Use the existing, updated test installation at
   `H:\Restorer\Testing\Batman-v-Superman-IMAX-Restorer_v1.0.0`.
   The actual program folder is the one containing the original `.bat` launcher
   and `docs`. If these are inside another folder, use that inner folder.
2. Put the supplied **BvS-Storage-Qualification.bat** beside the original launcher.
   Do not replace or rename the original launcher.
3. Put the supplied **Storage-Qualification-Checkpoint.ps1** inside
   `docs\scripts`, alongside `Validate-Assembly.ps1` and the assembly manifests.
4. If `docs\temp` already exists, stop and report it. Do not delete or rename
   recovery work simply to make the test start.
5. Close other programs that could consume substantial disk space. Keep the PC
   powered, awake and connected to power during processing.

The provided source-only package must be assembled and checked before these
instructions are used. It does not include the original bundled processing tools.

## Run once, then attend two checkpoints

Double-click **BvS-Storage-Qualification.bat**, select the original source film,
choose a new output folder on H:, and select **1: IMAX 1.78**. Never select an
existing finished output as the destination to overwrite.

A preflight check verifies the source path and a conservative storage budget
before the first media-processing command. If it refuses to start, preserve its
message and stop rather than trying to force the run.

The first long stage creates the sections and runs HandBrake on five IMAX
sections. It does not encode the entire film. Let it finish. Do not launch another
copy of the program.

**Before assembly**, the first checkpoint records working-file sizes and free
space, then asks permission to permanently remove only `docs\temp\BvS.mkv`.
This is the generated video-only working copy, not the original source film.
All ten source sections and all five cropped encodes remain.

**After independent assembly validation succeeds**, the second checkpoint asks
permission to permanently remove only these generated scope sections:

```text
docs\temp\BvS_2s.mkv
docs\temp\BvS_4s.mkv
docs\temp\BvS_6s.mkv
docs\temp\BvS_8s.mkv
docs\temp\BvS_10s.mkv
```

They have already been compared against the assembled video. The final remux
needs only that assembly and the original film for audio, subtitles and metadata.
The original IMAX sections, cropped encodes, validated assembly and logs remain.

Follow the checkpoint helper's explicit confirmation instructions. Do not manually
delete files or empty the Recycle Bin. An ordinary Explorer deletion may retain
files in that bin and fail to release space. The helper uses a fixed allowlist,
not a wildcard or a whole-folder deletion.

If any stage fails, declines permission, or reports insufficient space, **stop**.
Do not rerun the launcher: automatic resume is not implemented. Preserve all
remaining files and provide the small text logs for investigation. Retained
encodes may allow recovery without repeating HandBrake, but that requires a
reviewed recovery procedure.

## Storage estimate and evidence

For a 76.5 GB source, five cropped encodes are expected to total approximately
10 GB. Estimated peak additional usage is around 185 GB, plus container overhead
and diagnostic reports. This is an estimate, not a guaranteed maximum. The
reported 262 GB free should provide useful margin under these assumptions;
checkpoint measurements establish the actual figures. Do not run other large
downloads or processing jobs on H: during qualification.

Return the checkpoint reports, `processing.log`, `final-remux.log`, assembly
validation text reports and the completed manual qualification form. Keep films,
intermediate videos and any film frames private. Screenshots should show only
status messages or file sizes unless separate permission is given.

These results qualify this test variant's 1.78 path with its two controlled
removals. They do not establish the production keep-everything launcher's peak
storage, qualify other modes, or authorize a public release.

## Maintainer build

Use Python 3 in a source checkout; the owner does not need Python for the run:

```text
python3 tools/build_storage_qualification.py --output /new/path/BvS-Storage-Qualification.bat
```

The destination must not exist. The builder verifies the exact reviewed
production launcher SHA256, checks insertion anchors, verifies every original
media-command line remains unchanged, and emits CRLF. The helper's interface is
`-Phase Preflight`, `-Phase BeforeAssembly` or `-Phase BeforeRemux`; it receives source/destination
variables through the inherited process environment, not expanded command-line
arguments. Its installation root comes from its own script location.
