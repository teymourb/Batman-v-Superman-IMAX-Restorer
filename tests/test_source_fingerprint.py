"""Mandatory identity gate: tiny synthetic streams only, never private media.
Expected hashes are replaced ONLY in isolated test copies of the helper.
"""
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
HELPER = ROOT / 'docs/scripts/Test-SourceFingerprint.ps1'
FFMPEG = os.environ.get('RESTORER_BUNDLED_FFMPEG')
MKVMERGE = os.environ.get('RESTORER_REAL_MKVMERGE')
BVS = '58371280f7c8debbf2a87fa1bad9e6b97ae6f83d49d981489f724608f9e0781c'
ASTEROID = '203c7f5e1fc79013282c7a3218228818e5ecb60a04fd55ac420ce3de538373cd'

class FingerprintSource(unittest.TestCase):
    def test_fixed_references_no_production_override_and_gate_before_processing(self):
        helper = HELPER.read_text(encoding='utf-8-sig')
        self.assertIn(BVS, helper)
        self.assertIn(ASTEROID, helper)
        parameters = helper.split('param(', 1)[1].split('\n)', 1)[0]
        self.assertNotRegex(parameters.lower(), 'expected|skip|override|bypass')
        launcher = next(ROOT.glob('*Restorer.bat')).read_text()
        self.assertLess(launcher.index('Test-SourceFingerprint.ps1'), launcher.index('::Making sure'))
        self.assertIn('if not "%fingerprint_result%"=="0"', launcher[launcher.index('Test-SourceFingerprint.ps1'):].split('::Making sure')[0])

@unittest.skipUnless(os.name == 'nt' and FFMPEG and MKVMERGE,
                     'requires Windows and verified bundled FFmpeg/MKVToolNix')
class FingerprintWindows(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix='fingerprint & (é) ')
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.install = self.root / 'install'
        self.scripts = self.install / 'docs/scripts'
        self.scripts.mkdir(parents=True)
        programs = self.install / 'docs/programs'
        shutil.copytree(Path(MKVMERGE).parent, programs / 'mkvtoolnix')
        shutil.copytree(Path(FFMPEG).parent, programs / 'ffmpeg')
        self.helper = self.scripts / HELPER.name
        self.helper.write_bytes(HELPER.read_bytes())
        self.extract = programs / 'mkvtoolnix/mkvextract.exe'

    def command(self, args):
        result = subprocess.run([str(a) for a in args], capture_output=True, text=True, timeout=60)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        return result

    def clip(self, codec='libx264', color='red', name='source'):
        source = self.root / (name + '.mkv')
        args = [FFMPEG, '-nostdin', '-v', 'error', '-f', 'lavfi', '-i',
                'color=c=%s:s=64x64:r=24:d=0.5' % color, '-an', '-c:v', codec]
        if codec == 'libx265':
            args += ['-x265-params', 'pools=1:frame-threads=1:aud=1', '-pix_fmt', 'yuv420p10le']
        self.command(args + ['-y', source])
        return source

    def extracted(self, source, name='raw', track=0):
        target = self.root / (name + '.bin')
        self.command([self.extract, source, 'tracks', str(track) + ':' + str(target)])
        return target

    def normalized(self, raw):
        result = self.command([FFMPEG, '-nostdin', '-v', 'error', '-f', 'hevc', '-i', raw,
                               '-map', '0:v:0', '-c:v', 'copy', '-bsf:v', 'filter_units=remove_types=35|62',
                               '-f', 'hash', '-hash', 'sha256', '-'])
        return re.search(r'SHA256=([0-9a-f]{64})', result.stdout).group(1)

    def reference(self, film, expected):
        # Test-copy substitution, deliberately unavailable to installed public code.
        text = HELPER.read_text(encoding='utf-8-sig').replace(BVS if film == 'BvS' else ASTEROID, expected)
        self.helper.write_text(text, encoding='utf-8-sig')

    def gate(self, source, film='Asteroid', label='work'):
        work = self.root / label
        work.mkdir()
        before = source.read_bytes() if source.is_file() else None
        result = subprocess.run(['powershell.exe', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File',
                                 str(self.helper), '-Film', film, '-Source', str(source),
                                 '-WorkDirectory', str(work)], capture_output=True, text=True, timeout=60)
        if before is not None:
            self.assertEqual(source.read_bytes(), before, 'source was modified')
        record = json.loads((work / 'source-fingerprint.json').read_text(encoding='utf-8'))
        self.assertEqual(record['status'] == 'MATCH', result.returncode == 0, record)
        self.assertFalse(list(work.glob('source-check-*/extracted-video.bin')), 'owned scratch extraction leaked')
        return result, work

    def test_avc_exact_match_and_changed_picture_rejected(self):
        source = self.clip()
        expected = hashlib.sha256(self.extracted(source).read_bytes()).hexdigest()
        self.reference('Asteroid', expected)
        result, work = self.gate(source)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertTrue((work / 'source-fingerprint.json').is_file())
        changed = self.clip(color='blue', name='changed')
        result, _ = self.gate(changed, label='changed-work')
        self.assertEqual(result.returncode, 2, result.stdout + result.stderr)

    def test_avc_remux_audio_and_track_reorder_keep_identity(self):
        source = self.clip()
        self.reference('Asteroid', hashlib.sha256(self.extracted(source).read_bytes()).hexdigest())
        audio = self.root / 'audio.wav'
        self.command([FFMPEG, '-nostdin', '-v', 'error', '-f', 'lavfi', '-i',
                      'sine=frequency=1000:duration=0.5', '-y', audio])
        remux = self.root / 'remux.mkv'
        self.command([MKVMERGE, '-o', remux, '--track-order', '0:0,1:0', audio, source])
        identity = json.loads(self.command([MKVMERGE, '-J', remux]).stdout)
        video = [t for t in identity['tracks'] if t['type'] == 'video']
        self.assertNotEqual(video[0]['id'], 0, 'fixture must actually reorder the video ID')
        result, _ = self.gate(remux)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_hevc_rpu_and_aud_normalization_accepts_same_base(self):
        source = self.clip(codec='libx265')
        raw = self.extracted(source)
        self.reference('BvS', self.normalized(raw))
        result, _ = self.gate(source, 'BvS')
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        # A synthetic type-62 NAL proves filtering, not valid Dolby Vision playback.
        injected = self.root / 'injected.hevc'
        injected.write_bytes(raw.read_bytes() + b'\x00\x00\x00\x01\x7c\x01\x80')
        self.assertEqual(self.normalized(injected), self.normalized(raw))
        no_aud = self.root / 'without-aud.hevc'
        self.command([FFMPEG, '-nostdin', '-v', 'error', '-f', 'hevc', '-i', raw, '-c:v', 'copy',
                      '-bsf:v', 'filter_units=remove_types=35', '-f', 'hevc', no_aud])
        self.assertNotEqual(no_aud.read_bytes(), raw.read_bytes(), 'fixture must actually contain AUD')
        self.assertEqual(self.normalized(no_aud), self.normalized(raw))
        remux = self.root / 'injected.mkv'
        self.command([MKVMERGE, '-o', remux, injected])
        result, _ = self.gate(remux, 'BvS', 'injected-work')
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        changed = self.clip(codec='libx265', color='blue', name='different')
        result, _ = self.gate(changed, 'BvS', 'different-work')
        self.assertEqual(result.returncode, 2, result.stdout + result.stderr)

    def test_bad_source_wrong_codec_and_missing_extractor_fail_closed(self):
        source = self.clip()
        self.reference('Asteroid', hashlib.sha256(self.extracted(source).read_bytes()).hexdigest())
        bad = self.root / 'bad.mkv'; bad.write_bytes(b'not an MKV')
        result, _ = self.gate(bad)
        self.assertEqual(result.returncode, 2, result.stdout + result.stderr)
        result, _ = self.gate(source, 'BvS', 'wrong-codec')
        self.assertEqual(result.returncode, 2, result.stdout + result.stderr)
        self.extract.unlink()
        result, _ = self.gate(source, label='missing-extractor')
        self.assertEqual(result.returncode, 2, result.stdout + result.stderr)

    def test_existing_record_and_multiple_video_tracks_preserved_and_rejected(self):
        source = self.clip()
        expected = hashlib.sha256(self.extracted(source).read_bytes()).hexdigest()
        self.reference('Asteroid', expected)
        work = self.root / 'existing'; work.mkdir()
        record = work / 'source-fingerprint.json'; record.write_bytes(b'previous evidence')
        result = subprocess.run(['powershell.exe', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File',
                                 str(self.helper), '-Film', 'Asteroid', '-Source', str(source),
                                 '-WorkDirectory', str(work)], capture_output=True, text=True, timeout=60)
        self.assertEqual(result.returncode, 2, result.stdout + result.stderr)
        self.assertEqual(record.read_bytes(), b'previous evidence')
        multiple = self.root / 'multiple.mkv'
        second = self.clip(color='blue', name='second-video')
        self.command([MKVMERGE, '-o', multiple, source, second])
        result, _ = self.gate(multiple)
        self.assertEqual(result.returncode, 2, result.stdout + result.stderr)

    def test_hash_tool_nonzero_malformed_and_stderr_never_pass(self):
        source = self.clip(codec='libx265')
        expected = self.normalized(self.extracted(source))
        self.reference('BvS', expected)
        code = self.root / 'HashFailure.cs'
        code.write_text('''using System;
class HashFailure {
 static int Main(string[] args) {
  if (Array.IndexOf(args, "-version") >= 0) { Console.WriteLine("synthetic ffmpeg version"); return 0; }
  string action = Environment.GetEnvironmentVariable("FINGERPRINT_TEST_ACTION");
  if (action == "empty") return 0;
  if (action == "error") return 2;
  if (action == "warning") return 1;
  if (action == "crash") return unchecked((int)0xC0000005);
  if (action == "diagnostic") Console.Error.WriteLine("synthetic processing error");
  if (action == "known-warning") Console.Error.WriteLine("[hash @ 0000abcd] Timestamps are unset in a packet for stream 0. This is deprecated and will stop working in the future. Fix your code to set the timestamps properly");
  Console.WriteLine(action == "malformed" ? "not a valid fingerprint" : "SHA256=" + Environment.GetEnvironmentVariable("FINGERPRINT_TEST_HASH"));
  return 0;
 }
}''')
        compiler = Path(os.environ['WINDIR']) / 'Microsoft.NET/Framework64/v4.0.30319/csc.exe'
        target = self.install / 'docs/programs/ffmpeg/ffmpeg.exe'
        target.unlink()
        self.command([compiler, '/nologo', '/out:' + str(target), code])
        previous = os.environ.get('FINGERPRINT_TEST_ACTION')
        os.environ['FINGERPRINT_TEST_HASH'] = expected
        try:
            for action in ('error', 'warning', 'crash', 'empty', 'malformed', 'diagnostic'):
                os.environ['FINGERPRINT_TEST_ACTION'] = action
                result, work = self.gate(source, 'BvS', action)
                self.assertEqual(result.returncode, 2, action + result.stdout + result.stderr)
                record = json.loads((work / 'source-fingerprint.json').read_text())
                self.assertEqual(record['status'], 'FAILED')
                self.assertFalse(list(work.rglob('extracted-video.bin')), 'test extraction not cleaned')
            os.environ['FINGERPRINT_TEST_ACTION'] = 'known-warning'
            result, _ = self.gate(source, 'BvS', 'known-warning')
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        finally:
            os.environ.pop('FINGERPRINT_TEST_HASH', None)
            if previous is None: os.environ.pop('FINGERPRINT_TEST_ACTION', None)
            else: os.environ['FINGERPRINT_TEST_ACTION'] = previous

    def test_external_helper_uses_explicit_installation_tools(self):
        source = self.clip()
        self.reference('Asteroid', hashlib.sha256(self.extracted(source).read_bytes()).hexdigest())
        external = self.root / 'owner toolkit'; external.mkdir()
        copied = external / HELPER.name; copied.write_bytes(self.helper.read_bytes())
        work = self.root / 'external-work'; work.mkdir()
        result = subprocess.run(['powershell.exe', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File',
                                 str(copied), '-Film', 'Asteroid', '-Source', str(source),
                                 '-WorkDirectory', str(work), '-InstallationRoot', str(self.install)],
                                capture_output=True, text=True, timeout=60)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
