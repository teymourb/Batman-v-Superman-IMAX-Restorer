# Third-party components

The restoration script has its own MIT license in LICENSE.txt. That license does
not cover the separate processing applications.

This application retains the processing binaries from the public BvS v1.0.0 archive,
without updating/rebuilding them. Existing Avidemux/MKVToolNix notices are retained.
Missing top-level HandBrake and FFmpeg GPL texts are added under docs/licenses.
The upstream source references and license texts are listed below. Exact source
and build correspondence for every bundled dependency has not been established;
adding a license text does not establish that correspondence.

| Component | Observed version | Upstream/reference | Included notice |
| --- | --- | --- | --- |
| MKVToolNix | 78.0 | https://mkvtoolnix.download/ | Existing doc/COPYING and doc/licenses retained |
| HandBrakeCLI | 1.6.1 (2023012300) | https://github.com/HandBrake/HandBrake/tree/1.6.1 | GPL-2.0 text from that tag added |
| Avidemux CLI | PE product 2.8.1.22260 | https://github.com/mean00/avidemux2 | Existing Licenses/license.txt retained |
| FFmpeg | N-112110-g5acc3c4cff-20230917 | https://github.com/FFmpeg/FFmpeg/tree/5acc3c4cff | GPL-3.0 text added; binary has --enable-gpl and --enable-version3 |

FFmpeg's exact distributor, dependency source set and build recipe have not been
verified. No particular build distributor is claimed here. The embedded FFmpeg commit alone is not the complete corresponding
source for this statically linked binary and all enabled components. HandBrakeCLI
1.6.1's retained executable is byte-identical to the official upstream Windows
x86_64 CLI release (SHA256
`3ba066c1b962f5bfe56edf54e11b74ccd729aa14133583d26cb37c7566e647ca`).
Its upstream signature was downloaded but not cryptographically verified. This
establishes executable correspondence, not complete dependency-source provision.
The official CLI archive also contains notices missing from the old tool folder;
they are retained byte-for-byte under docs/programs/handbrake/doc in the application package. Source submodule pointers in the restorer
repository are not proof of matching binary source. Official artifact:
https://github.com/HandBrake/HandBrake/releases/download/1.6.1/HandBrakeCLI-1.6.1-win-x86_64.zip

A subsequent static comparison with the official Avidemux 2.8.1 Windows
installer matched 416 retained runtime files, including avidemux_cli.exe, DLLs
and plugins, byte-for-byte. The installer and official source tarball both match
the upstream SHA256 sidecar. The other seven retained Avidemux files are an
installation log, generated uninstall/configuration files and the retained
license text; they are not conflicting runtime executables. Complete dependency
source/build correspondence is still being inventoried. No installer was run.
Upstream: https://github.com/mean00/avidemux2/releases/tag/2.8.1

The BvS application includes no film-logo MKV.

References: https://ffmpeg.org/legal.html and the licenses shipped alongside the
tools. The component licenses are separate from the restorer script license.
