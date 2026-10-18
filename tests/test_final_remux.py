"""Narrow regression tests: static on any OS; extracted final-remux blocks on Windows.

The harness executes the production remux block and terminal handlers, bypassing
only dialogs, earlier processing, and PAUSE. It does not test the whole restorer.
"""
import hashlib
import itertools
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / 'Batman-v-Superman-IMAX-Restorer.bat'
TEXT = SCRIPT.read_text(encoding='utf-8')


def remux_blocks():
    chunks = TEXT.split('\techo Remuxing audio and subtitles\n')[1:]
    assert len(chunks) == 2
    return [c.split('\n) else', 1)[0] for c in chunks]


def media_commands(text):
    commands = []
    for line in text.splitlines():
        line = line.strip()
        if line.startswith('docs\\programs\\'):
            line = line.split(' > "docs\\temp\\final-remux.log"', 1)[0]
            line = line.split(' >> "docs\\temp\\processing.log"', 1)[0]
            commands.append(line)
    return '\n'.join(commands).encode()


class SourceRegression(unittest.TestCase):
    def test_processing_commands_preserved(self):
        # v1.0.0 command baseline; only diagnostic redirection may change.
        self.assertEqual(hashlib.sha256(media_commands(TEXT)).hexdigest(),
                         'e408b65705da5723e44aec4a428f539fa908a061ffbeddf1c6af09ff7310e9d8')

    def test_every_remux_branch_checks_status_before_cleanup(self):
        for block in remux_blocks():
            commands = re.findall(r'mkvmerge -o[^\n]+\n([^\n]+)\n([^\n]+)', block)
            self.assertEqual(len(commands), 4)
            for error, warning in commands:
                self.assertEqual(error.strip(), 'if errorlevel 2 goto remux_failed')
                self.assertEqual(warning.strip(), 'if errorlevel 1 goto remux_warning')
            self.assertIn('if not exist "!final_output!"', block)
            self.assertNotRegex(block, r'(?im)^\s*del\s')

    def test_terminal_handlers_do_not_delete_retained_files(self):
        handlers = TEXT.split('\n:remux_warning\n', 1)[1]
        self.assertNotRegex(handlers, r'(?im)^\s*(del|rmdir)\s')
        self.assertIn('exit /b 1', handlers)
        self.assertIn('exit /b 2', handlers)
        self.assertIn('A new run will preserve this folder', handlers)


@unittest.skipUnless(os.name == 'nt', 'requires actual Windows cmd.exe')
class WindowsRemux(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.build_dir = tempfile.TemporaryDirectory(prefix='remux-stub-')
        cls.stub = Path(cls.build_dir.name) / 'mkvmerge.exe'
        compiler = (Path(os.environ['WINDIR']) / 'Microsoft.NET' / 'Framework64'
                    / 'v4.0.30319' / 'csc.exe')
        subprocess.run([str(compiler), '/nologo', '/target:exe',
                        '/out:' + str(cls.stub), str(ROOT / 'tests' / 'MkvmergeStub.cs')],
                       check=True, capture_output=True, text=True)

    @classmethod
    def tearDownClass(cls):
        cls.build_dir.cleanup()

    def run_block(self, root, mode, dialog, dialog2, stub_code=0, missing=False,
                  empty=False, no_output=False, real_tool=None, source=None, assembled=None):
        temp = root / 'docs' / 'temp'
        tools = root / 'docs' / 'programs' / 'mkvtoolnix'
        temp.mkdir(parents=True)
        tools.mkdir(parents=True)
        output_dir = root / 'output with spaces'
        output_dir.mkdir()
        source_path = root / 'source with spaces.mkv'
        intermediate = temp / ('BvS_1.78.mkv' if mode == 1 else 'BvS_1.43.mkv')
        if source:
            shutil.copyfile(source, source_path)
            shutil.copyfile(assembled, intermediate)
        else:
            source_path.write_bytes(b'original synthetic sentinel')
            intermediate.write_bytes(b'assembled synthetic sentinel')
        before = source_path.read_bytes()
        if not missing:
            if real_tool:
                # Preserve sibling DLL discovery for the real portable tool.
                for item in Path(real_tool).parent.iterdir():
                    if item.is_file():
                        shutil.copy2(item, tools / item.name)
            else:
                shutil.copyfile(self.stub, tools / 'mkvmerge.exe')
        env = os.environ.copy()
        env.update(dialog=dialog, dialog2=dialog2,
                   file=str(source_path) if dialog == 'y' else '"' + str(source_path) + '"',
                   folder=str(output_dir) + ('\\' if dialog2 == 'n' else ''),
                   STUB_EXIT=str(stub_code), STUB_EMPTY='1' if empty else '0',
                   STUB_NO_OUTPUT='1' if no_output else '0',
                   STUB_ARGS=str(root / 'args.txt'))
        handlers = ':remux_warning\n' + TEXT.split('\n:remux_warning\n', 1)[1]
        harness = ('@echo off\nsetlocal\npushd "%~dp0"\nsetlocal enabledelayedexpansion\n'
                   + remux_blocks()[mode - 1] + '\necho Done!\npopd\nexit /b 0\n'
                   + handlers)
        # PAUSE is intentionally excluded from this noninteractive harness.
        harness = re.sub(r'(?im)^\s*PAUSE\s*$', 'rem PAUSE omitted by test harness', harness)
        (root / 'run.bat').write_bytes(harness.replace('\n', '\r\n').encode())
        result = subprocess.run(['cmd.exe', '/d', '/c', 'run.bat'], cwd=root,
                                env=env, capture_output=True, text=True, timeout=30)
        self.assertEqual(source_path.read_bytes(), before)
        return result, intermediate, root / 'args.txt', output_dir

    def test_branch_and_exit_status_matrix(self):
        for mode, dialog, dialog2, code in itertools.product((1, 2), ('y', 'n'), ('y', 'n'), (0, 1, 2, 9, -1073741819)):
            with self.subTest(mode=mode, source=dialog, destination=dialog2, code=code):
                with tempfile.TemporaryDirectory(prefix='restorer with spaces ') as folder:
                    root = Path(folder)
                    result, intermediate, args_path, output_dir = self.run_block(
                        root, mode, dialog, dialog2, code)
                    self.assertEqual(result.returncode, 0 if code == 0 else 1 if code == 1 else 2, result.stdout + result.stderr)
                    self.assertEqual(intermediate.exists(), True)
                    self.assertEqual('Done!' in result.stdout, code == 0)
                    args = args_path.read_text().splitlines()
                    self.assertIn('docs\\temp\\' + intermediate.name, args)
                    self.assertIn(str(root / 'source with spaces.mkv'), args)
                    output = Path(args[args.index('-o') + 1])
                    self.assertEqual(output.parent.resolve(), output_dir.resolve())
                    expected = '1.78' if mode == 1 else '1.43 (unmasked)'
                    self.assertEqual(output.name, 'Batman v Superman Dawn of Justice Ultimate Edition IMAX ' + expected + '.mkv')
                    self.assertIn('stub diagnostic', (root / 'docs/temp/final-remux.log').read_text())
                    if code:
                        self.assertIn('A new run will preserve', result.stdout)

    def test_missing_executable_and_empty_output_retain_intermediate(self):
        for missing, empty, no_output in ((True, False, False), (False, True, False),
                                          (False, False, True)):
            with self.subTest(missing=missing, empty=empty, no_output=no_output):
                with tempfile.TemporaryDirectory() as folder:
                    result, intermediate, _, _ = self.run_block(
                        Path(folder), 1, 'y', 'n', missing=missing, empty=empty,
                        no_output=no_output)
                    self.assertEqual(result.returncode, 2, result.stdout + result.stderr)
                    self.assertTrue(intermediate.exists())
                    self.assertNotIn('Done!', result.stdout)

    @unittest.skipUnless(os.environ.get('RESTORER_REAL_MKVMERGE'),
                         'set RESTORER_REAL_MKVMERGE for real synthetic-media test')
    def test_real_synthetic_remux(self):
        tool = Path(os.environ['RESTORER_REAL_MKVMERGE']).resolve()
        ffmpeg = shutil.which('ffmpeg')
        self.assertIsNotNone(ffmpeg, 'FFmpeg is required for synthetic fixture generation')
        with tempfile.TemporaryDirectory() as folder:
            fixtures = Path(folder)
            source = fixtures / 'source.mkv'
            video = fixtures / 'video.mkv'
            subprocess.run([ffmpeg, '-v', 'error', '-f', 'lavfi', '-i',
                            'color=c=blue:s=64x64:r=24', '-f', 'lavfi', '-i',
                            'sine=frequency=440:sample_rate=48000', '-t', '1',
                            '-c:v', 'libx264', '-pix_fmt', 'yuv420p', '-c:a', 'pcm_s16le',
                            str(source)], check=True)
            subprocess.run([str(tool), '-o', str(video), '-A', str(source)], check=True)
            for mode in (1, 2):
                with tempfile.TemporaryDirectory(prefix='synthetic remux ') as run_dir:
                    result, intermediate, _, output_dir = self.run_block(
                        Path(run_dir), mode, 'y', 'n', real_tool=tool,
                        source=source, assembled=video)
                    self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                    self.assertTrue(intermediate.exists())
                    output = next(output_dir.glob('*.mkv'))
                    # H.264 packet payloads should remain identical. PCM audio may
                    # be re-packetized by mkvmerge: compare its concatenated sample
                    # bytes, rather than requiring identical packet boundaries.
                    def video_packets(path):
                        return subprocess.check_output([
                            'ffprobe', '-v', 'error', '-select_streams', 'v:0',
                            '-show_packets', '-show_data_hash', 'sha256',
                            '-show_entries', 'packet=data_hash', '-of', 'csv=p=0', str(path)])
                    with self.subTest(mode=mode, stream='video'):
                        expected = video_packets(source)
                        self.assertTrue(expected.strip())
                        self.assertEqual(video_packets(output), expected)
                    def pcm_samples(path):
                        return subprocess.check_output([
                            ffmpeg, '-v', 'error', '-i', str(path), '-map', '0:a:0',
                            '-c:a', 'copy', '-f', 's16le', 'pipe:1'])
                    with self.subTest(mode=mode, stream='PCM audio'):
                        expected = pcm_samples(source)
                        self.assertEqual(len(expected), 48000 * 2)  # 1 s, mono, 16-bit
                        self.assertEqual(pcm_samples(output), expected)



if __name__ == '__main__':
    unittest.main(verbosity=2)
