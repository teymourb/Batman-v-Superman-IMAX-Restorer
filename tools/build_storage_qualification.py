"""Build a separate, owner-operated BvS 1.78 qualification launcher.

The production launcher is immutable input. No media processing is performed.
"""
import argparse
import hashlib
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
BASELINE = ROOT / "Batman-v-Superman-IMAX-Restorer.bat"
BASELINE_SHA256 = "9a6bf745e16278daa513d35cb2735cc1550a3b2fd6e8cc89dfb65cec513a4727"
OUTPUT_NAME = "BvS-Storage-Qualification.bat"


def media_commands(text):
    return re.findall(r"(?m)^\s*docs\\programs\\[^\r\n]+", text)


def build(source):
    if hashlib.sha256(source.replace(b"\r\n", b"\n")).hexdigest() != BASELINE_SHA256:
        raise ValueError("Production launcher differs from the reviewed baseline; review builder anchors first.")
    original = source.decode("utf-8").replace("\r\n", "\n")
    text = original

    def insert_before(anchor, addition):
        nonlocal text
        if text.count(anchor) != 1:
            raise ValueError("Expected exactly one insertion anchor: " + repr(anchor))
        text = text.replace(anchor, addition + anchor, 1)

    insert_before(
        "::Making sure batch file drive location has enough space\n",
        'echo TEST ONLY: BvS 1.78 storage qualification with two attended checkpoints.\n'
        'if not exist "docs\\scripts\\Storage-Qualification-Checkpoint.ps1" (\n'
        '    echo Required storage qualification helper is missing.\n'
        '    popd\n'
        '    exit /b 2\n'
        ')\n\n',
    )
    insert_before(
        "echo Tool diagnostics are written to docs\\temp\\processing.log during processing.\n",
        'if not "%version%"=="1" (\n'
        '    echo This test launcher supports option 1, BvS 1.78, only.\n'
        '    echo No media processing has started. Existing workspace is retained.\n'
        '    popd\n'
        '    exit /b 2\n'
        ')\n\n',
    )

    def checkpoint(phase):
        return (
            '\tset "stage_name=storage qualification checkpoint: ' + phase + '"\n'
            '\techo Stage: !stage_name!>> "docs\\temp\\processing.log"\n'
            '\tpowershell.exe -NoProfile -ExecutionPolicy Bypass -File '
            '"docs\\scripts\\Storage-Qualification-Checkpoint.ps1" -Phase ' + phase + '\n'
            '\tif errorlevel 1 goto stage_failed\n'
            '\tif not errorlevel 0 goto stage_failed\n\n'
        )

    mode_start = (
        '\techo You have selected: IMAX 1.78:1 ^(Cropped^)\n'
        '\techo If this is correct press Enter\n'
        '\techo If this was the wrong choice please restart this program\n'
        '\tPAUSE\n'
    )
    if text.count(mode_start) != 1:
        raise ValueError("Expected exactly one mode-1 confirmation anchor")
    text = text.replace(mode_start, mode_start + "\n" + checkpoint("Preflight"), 1)
    insert_before(
        '\t::Concatenating all 10 files\n\techo Exporting...\n'
        '\tset "stage_name=avidemux_cli: BvS_1.78.mkv"\n',
        checkpoint("BeforeAssembly"),
    )
    anchor = '\tcall :validate_assembly "1.78" "docs\\temp\\BvS_1.78.mkv"\n\tif errorlevel 1 goto stage_failed\n'
    if text.count(anchor) != 1:
        raise ValueError("Expected exactly one successful-validation anchor")
    text = text.replace(anchor, anchor + "\n" + checkpoint("BeforeRemux"), 1)
    if media_commands(text) != media_commands(original):
        raise ValueError("Media commands changed")
    return text.replace("\n", "\r\n").encode("utf-8")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, required=True,
                        help="New output file; existing files are never overwritten")
    args = parser.parse_args()
    generated = build(BASELINE.read_bytes())
    if args.output.resolve() == BASELINE.resolve():
        parser.error("Output must be separate from the production launcher")
    with args.output.open("xb") as stream:
        stream.write(generated)
    print(str(args.output))
    print("SHA256: " + hashlib.sha256(generated).hexdigest())


if __name__ == "__main__":
    main()
