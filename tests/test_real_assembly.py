"""Actual historical Avidemux/FFmpeg on tiny generated videos, never film data."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
FFMPEG = os.environ.get('RESTORER_BUNDLED_FFMPEG')
AVIDEMUX = os.environ.get('RESTORER_REAL_AVIDEMUX')


@unittest.skipUnless(os.name == 'nt' and FFMPEG and AVIDEMUX,
                     'requires Windows and checksum-verified historical tools')
class RealAssembly(unittest.TestCase):
    def command(self, args, **kwargs):
        return subprocess.run([str(x) for x in args], capture_output=True,
                              text=True, timeout=90, **kwargs)

    def make_clips(self, root, codec, pixel_format, open_gop=False):
        clips = []
        for number, color in enumerate(('red', 'green', 'blue')):
            clip = root / ('clip %d.mkv' % number)
            fixture = ('testsrc2=s=128x72:r=24:d=1.5' if open_gop else
                       'color=c=%s:s=128x72:r=24:d=0.5' % color)
            args = [FFMPEG, '-nostdin', '-v', 'error', '-f', 'lavfi', '-i',
                    fixture, '-an',
                    '-c:v', codec, '-pix_fmt', pixel_format, '-g', '12', '-bf', '2']
            if codec == 'libx265':
                args += ['-x265-params', 'pools=1:frame-threads=1:scenecut=0:keyint=12:min-keyint=12:open-gop=%d' % open_gop]
            else:
                args += ['-x264-params', 'open-gop=%d' % open_gop]
            result = self.command(args + ['-y', clip])
            self.assertEqual(result.returncode, 0, result.stderr)
            clips.append(clip)
        return clips

    def assemble(self, clips, output):
        args = [AVIDEMUX, '--load', clips[0]]
        for clip in clips[1:]:
            args += ['--append', clip]
        args += ['--video-codec', 'copy', '--audio-codec', 'copy',
                 '--output-format', 'mkv', '--save', output]
        result = self.command(args)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertTrue(output.is_file(), result.stdout + result.stderr)
        return result

    def validate(self, root, expected, assembly, label):
        inputs = root / (label + '.txt')
        inputs.write_text(''.join(str(p) + '\n' for p in expected), encoding='utf-8')
        work = root / label
        result = self.command([
            'powershell.exe', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File',
            ROOT / 'docs/scripts/Validate-Assembly.ps1', '-FFmpegPath', FFMPEG,
            '-AssemblyPath', assembly, '-InputListPath', inputs,
            '-WorkDirectory', work])
        return result, work

    def test_real_h264_and_hevc10_assembly_and_wrong_sequences(self):
        for codec, pixel_format in [('libx264', 'yuv420p'), ('libx265', 'yuv420p10le')]:
            with self.subTest(codec=codec), tempfile.TemporaryDirectory() as td:
                root = Path(td) / 'Real assembly & !mark'
                root.mkdir()
                clips = self.make_clips(root, codec, pixel_format)
                before = {p: p.read_bytes() for p in clips}
                output = root / 'assembled.mkv'
                self.assemble(clips, output)
                result, _ = self.validate(root, clips, output, 'correct')
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                # Same frame count can conceal wrong order or substituted clips.
                for label, wrong in [('reordered', [clips[1], clips[0], clips[2]]),
                                     ('repeated', [clips[0], clips[0], clips[2]]),
                                     ('omitted', [clips[0], clips[2]])]:
                    bad = root / (label + '.mkv')
                    self.assemble(wrong, bad)
                    result, _ = self.validate(root, clips, bad, label)
                    self.assertEqual(result.returncode, 2, result.stdout + result.stderr)
                for path, data in before.items():
                    self.assertEqual(path.read_bytes(), data)

    def test_silent_append_failure_is_not_accepted(self):
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            clips = self.make_clips(root, 'libx264', 'yuv420p')
            output = root / 'partial.mkv'
            # Avidemux may return zero and save the preceding clip despite this.
            result = self.command([AVIDEMUX, '--load', clips[0], '--append',
                                   root / 'missing.mkv', '--video-codec', 'copy',
                                   '--audio-codec', 'copy', '--output-format', 'mkv',
                                   '--save', output])
            print('Historical Avidemux failed-append status:', result.returncode,
                  'output exists:', output.exists())
            result, _ = self.validate(root, clips, output, 'failed-append')
            self.assertEqual(result.returncode, 2, result.stdout + result.stderr)

    def test_open_gop_and_bframes(self):
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            clips = self.make_clips(root, 'libx265', 'yuv420p10le', open_gop=True)
            output = root / 'open-gop.mkv'
            self.assemble(clips, output)
            result, _ = self.validate(root, clips, output, 'open-gop')
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_copy_split_pattern_accepts_closed_gop_and_rejects_broken_open_gop(self):
        # Same seek/copy pattern as the launchers. The deliberately open-GOP
        # fixture loses reference pictures; independently establish that damage
        # before expecting the gate to reject it. Do not relax decoder checks.
        for open_gop in (False, True):
            with self.subTest(open_gop=open_gop), tempfile.TemporaryDirectory() as td:
                root = Path(td)
                source = root / 'source.mkv'
                result = self.command([FFMPEG, '-nostdin', '-v', 'error', '-f', 'lavfi',
                    '-i', 'testsrc2=s=128x72:r=24:d=3', '-an', '-c:v', 'libx265',
                    '-pix_fmt', 'yuv420p10le', '-x265-params',
                    'pools=1:frame-threads=1:keyint=12:min-keyint=12:scenecut=0:open-gop=%d' % open_gop,
                    '-y', source])
                self.assertEqual(result.returncode, 0, result.stderr)
                pieces = []
                for index, seek in enumerate(('00:00:00.500', '00:00:01.500')):
                    piece = root / ('split-%d.mkv' % index)
                    result = self.command([FFMPEG, '-threads', '0', '-ss', seek,
                        '-noaccurate_seek', '-i', source, '-vframes', '12', '-c:v',
                        'copy', '-map', 'v:0', '-map_chapters', '-1', '-map_metadata',
                        '-1', '-y', piece])
                    self.assertEqual(result.returncode, 0, result.stderr)
                    pieces.append(piece)
                output = root / 'split-assembly.mkv'
                self.assemble(pieces, output)
                # Separate decoder-to-null invocation: no framehash parser/muxer.
                decode = self.command([FFMPEG, '-nostdin', '-v', 'error', '-xerror',
                    '-err_detect', 'explode', '-i', output, '-map', '0:v:0', '-an',
                    '-f', 'null', '-'])
                if open_gop:
                    self.assertIn('Could not find ref with POC', decode.stderr)
                else:
                    self.assertEqual(decode.returncode, 0, decode.stderr)
                    self.assertEqual(decode.stderr.strip(), '')
                result, work = self.validate(root, pieces, output, 'later-gop')
                diagnostics = []
                if result.returncode:
                    for log in work.glob('*.stderr.log'):
                        errors = [line for line in log.read_text(errors='replace').splitlines()
                                  if any(level in line for level in ('[error]', '[fatal]', '[panic]'))]
                        diagnostics += [log.name] + errors[:12]
                self.assertEqual(result.returncode, 2 if open_gop else 0,
                                 result.stdout + result.stderr + '\n'.join(diagnostics))
