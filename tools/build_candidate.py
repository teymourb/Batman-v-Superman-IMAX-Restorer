#!/usr/bin/env python3
"""Build a local review-only BvS ZIP from the audited v1.0.0 archive.

No download, bundled executable execution, installation or publication occurs.
Run only from a clean main checkout after Windows qualification. Requires bsdtar.
"""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import tempfile
import zipfile

ROOT = Path(__file__).resolve().parents[1]
BASELINE_SHA256 = '7f4701624ae87c21225e339b2caa65085ec7380a446b17bb155d04155ae4829a'
BASELINE_ROOT = 'Batman-v-Superman-IMAX-Restorer_v1.0.0'
PACKAGE_ROOT = 'Batman-v-Superman-IMAX-Restorer_v1.0.1'
BAT = 'Batman-v-Superman-IMAX-Restorer.bat'
OMIT = {
    'docs/programs/avidemux/Uninstall Avidemux VC++ 64bits.exe',
    'docs/programs/avidemux/Uninstall Avidemux VC++ 64bits.ini',
    'docs/programs/mkvtoolnix/uninst.exe',
}
OVERLAYS = {
    'docs/programs/handbrake/doc/LICENSE': 'docs/licenses/HandBrake-1.6.1/LICENSE',
    'docs/programs/handbrake/doc/README.markdown': 'docs/licenses/HandBrake-1.6.1/README.markdown',
    'docs/programs/handbrake/doc/THANKS.markdown': 'docs/licenses/HandBrake-1.6.1/THANKS.markdown',
    'docs/programs/handbrake/doc/AUTHORS.markdown': 'docs/licenses/HandBrake-1.6.1/AUTHORS.markdown',
    'docs/programs/handbrake/doc/COPYING': 'docs/licenses/HandBrake-1.6.1/COPYING',
    'docs/programs/handbrake/doc/NEWS.markdown': 'docs/licenses/HandBrake-1.6.1/NEWS.markdown',

    BAT: BAT,
    'README.md': 'README.md',
    'CHANGELOG.md': 'CHANGELOG.md',
    'THIRD-PARTY-NOTICES.md': 'docs/THIRD-PARTY-NOTICES.md',
    'docs/licenses/HandBrake-GPL-2.0.txt': 'docs/licenses/HandBrake-GPL-2.0.txt',
    'docs/licenses/FFmpeg-GPL-3.0.txt': 'docs/licenses/FFmpeg-GPL-3.0.txt',
    'docs/scripts/Select-Restoration.ps1': 'docs/scripts/Select-Restoration.ps1',
    'docs/scripts/Test-SourceFingerprint.ps1': 'docs/scripts/Test-SourceFingerprint.ps1',
    'docs/SOURCE-FINGERPRINT.md': 'docs/SOURCE-FINGERPRINT.md',
}


def sha(path):
    result = hashlib.sha256()
    with path.open('rb') as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b''):
            result.update(block)
    return result.hexdigest()


def inventory(root):
    return {p.relative_to(root).as_posix(): {'bytes': p.stat().st_size, 'sha256': sha(p)}
            for p in sorted(root.rglob('*')) if p.is_file()}


def preflight(tar, baseline):
    """Reject escapes, duplicates, links and special entries BEFORE extraction."""
    names = subprocess.check_output([tar, '-tf', str(baseline)], text=True).splitlines()
    details = subprocess.check_output([tar, '-tvf', str(baseline)], text=True).splitlines()
    if not names or len(names) != len(details):
        raise RuntimeError('archive listing cannot be verified')
    seen = set()
    for name, detail in zip(names, details):
        clean = name.rstrip('/')
        parts = clean.split('/')
        if (not clean or '\\' in name or name.startswith('/') or
                any(ord(c) < 32 or ord(c) == 127 for c in name) or
                any(p in ('', '.', '..') or ':' in p for p in parts) or
                parts[0] != BASELINE_ROOT):
            raise RuntimeError('unsafe archive path: ' + repr(name))
        folded = clean.casefold()
        if folded in seen:
            raise RuntimeError('duplicate/case-colliding archive path: ' + repr(name))
        seen.add(folded)
        if not detail or detail[0] not in '-d' or ' -> ' in detail or ' link to ' in detail:
            raise RuntimeError('archive contains a link or unsupported entry: ' + repr(name))
    return len(names)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('baseline', type=Path)
    parser.add_argument('output', type=Path, help='new directory outside the repository')
    args = parser.parse_args()
    baseline, output = args.baseline.resolve(), args.output.resolve()
    if output == ROOT or ROOT in output.parents:
        parser.error('output must be outside the repository')
    if output.exists():
        parser.error('output already exists; use a new directory')
    if sha(baseline) != BASELINE_SHA256:
        parser.error('historical archive checksum mismatch')
    if subprocess.check_output(['git', 'status', '--porcelain', '--untracked-files=all'], cwd=ROOT):
        parser.error('commit the source changes before packaging')
    branch = subprocess.check_output(['git', 'branch', '--show-current'], cwd=ROOT, text=True).strip()
    if branch != 'main':
        parser.error('build only from the validated main branch')
    commit = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip()
    tar = shutil.which('bsdtar')
    if not tar:
        parser.error('bsdtar is required; no tool will be installed automatically')
    for source in OVERLAYS.values():
        if not (ROOT / source).is_file():
            parser.error('required reviewed overlay is missing: ' + source)
    entries = preflight(tar, baseline)
    with tempfile.TemporaryDirectory(prefix='bvs-candidate-') as folder:
        scratch = Path(folder)
        subprocess.run([tar, '-xf', str(baseline), '-C', str(scratch),
                        '--no-same-owner', '--no-same-permissions'], check=True)
        root = scratch / BASELINE_ROOT
        if any(p.is_symlink() for p in scratch.rglob('*')):
            raise RuntimeError('archive extracted a symlink')
        before = inventory(root)
        if len(before) != 621 or sum(v['bytes'] for v in before.values()) != 452870184:
            raise RuntimeError('extracted baseline differs from the audited inventory')
        original = subprocess.check_output(['git', 'show', 'v1.0.0:' + BAT], cwd=ROOT)
        if (root / BAT).read_bytes().replace(b'\r\n', b'\n') != original.replace(b'\r\n', b'\n'):
            raise RuntimeError('historical batch differs from tagged source')
        for rel in OMIT:
            (root / rel).unlink()
        for dest, source in OVERLAYS.items():
            data = (ROOT / source).read_bytes()
            if dest.endswith('.bat'):
                data = data.replace(b'\r\n', b'\n').replace(b'\n', b'\r\n')
            target = root / dest
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(data)
        after = inventory(root)
        changed = sorted(p for p in before.keys() & after.keys() if before[p] != after[p])
        added = sorted(after.keys() - before.keys())
        removed = sorted(before.keys() - after.keys())
        if (not set(changed) <= OVERLAYS.keys() or set(removed) != OMIT or
                set(added) != OVERLAYS.keys() - before.keys()):
            raise RuntimeError('unexpected package delta')
        for rel in before.keys() - OMIT - OVERLAYS.keys():
            if before[rel] != after[rel]:
                raise RuntimeError('retained payload changed: ' + rel)
        # Explicitly verify every retained tool, not just its four main EXEs.
        for rel in before:
            if rel.startswith('docs/programs/') and rel not in OMIT and before[rel] != after[rel]:
                raise RuntimeError('bundled tool changed: ' + rel)
        output.mkdir(parents=True)
        archive = output / (PACKAGE_ROOT + '-candidate.zip')
        with zipfile.ZipFile(archive, 'w', compression=zipfile.ZIP_DEFLATED, compresslevel=9) as z:
            for rel in sorted(after):
                info = zipfile.ZipInfo(PACKAGE_ROOT + '/' + rel, date_time=(2026, 10, 20, 0, 0, 0))
                info.compress_type = zipfile.ZIP_DEFLATED
                info.create_system = 3
                info.external_attr = 0o100644 << 16
                z.writestr(info, (root / rel).read_bytes(), compress_type=zipfile.ZIP_DEFLATED, compresslevel=9)
        with zipfile.ZipFile(archive) as z:
            if z.testzip() is not None:
                raise RuntimeError('ZIP CRC verification failed')
            for entry in z.infolist():
                rel = entry.filename[len(PACKAGE_ROOT) + 1:]
                if hashlib.sha256(z.read(entry)).hexdigest() != after[rel]['sha256']:
                    raise RuntimeError('ZIP payload verification failed')
        manifest = {
            'status': 'review-only; not approved for publication',
            'source_commit': commit,
            'baseline_archive_sha256': BASELINE_SHA256,
            'baseline_archive_entries': entries,
            'candidate_archive_sha256': sha(archive),
            'candidate_archive_bytes': archive.stat().st_size,
            'changed': changed, 'added': added, 'removed': removed,
            'original_files': before, 'candidate_files': after,
            'limits': ['No full-film or Windows desktop UI qualification is implied by packaging',
                       'Dependency source/build correspondence remains a separate publication gate',
                       'ZIP integrity does not establish restoration correctness'],
        }
        manifest_path = output / 'PACKAGE-MANIFEST.json'
        manifest_path.write_text(json.dumps(manifest, indent=2, sort_keys=True) + '\n')
        (output / 'SHA256SUMS.txt').write_text(''.join(sha(p) + '  ' + p.name + '\n' for p in (archive, manifest_path)))
        print(json.dumps({k: manifest[k] for k in ('source_commit', 'candidate_archive_sha256',
                         'candidate_archive_bytes', 'changed', 'added', 'removed')}, indent=2))
        print('Candidate:', archive)


if __name__ == '__main__':
    main()
