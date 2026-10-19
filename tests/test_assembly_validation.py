"""Synthetic, real-FFmpeg qualification of the decoded-frame assembly gate."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
VALIDATOR = ROOT / 'docs' / 'scripts' / 'Validate-Assembly.ps1'
FFMPEG = os.environ.get('RESTORER_ASSEMBLY_FFMPEG') or shutil.which('ffmpeg')


class ValidatorSourceTests(unittest.TestCase):
    def test_validator_has_no_shell_or_automatic_cleanup(self):
        text = VALIDATOR.read_text()
        self.assertIn('$start.UseShellExecute = $false', text)
        self.assertIn("'-fps_mode', 'passthrough'", text)
        self.assertIn("'-pix_fmt', '+'", text)
        self.assertIn("'-xerror'", text)
        self.assertNotIn('Remove-Item', text)
        self.assertIn('ReadLine()', text)
        self.assertIn('CopyToAsync', text)
        self.assertIn('$null = $copy.GetAwaiter().GetResult()', text)


@unittest.skipUnless(os.name == 'nt' and FFMPEG, 'Requires Windows PowerShell and synthetic FFmpeg tool')
class AssemblyValidationTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='assembly & ! [test] ')
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.first = self.root / 'first & ! [clip].mkv'
        self.second = self.root / 'second clip.mkv'
        self.good = self.root / 'assembled.mkv'
        self.ffmpeg = Path(FFMPEG).resolve()
        for path, color in [(self.first, 'red'), (self.second, 'blue')]:
            self.run_ffmpeg('-f', 'lavfi', '-i', f'color={color}:s=64x48:r=5:d=1',
                            '-c:v', 'ffv1', str(path))
        self.concat([self.first, self.second], self.good)

    def run_ffmpeg(self, *args):
        subprocess.run([str(self.ffmpeg), '-hide_banner', '-loglevel', 'error', '-nostdin',
                        *args], check=True, capture_output=True, timeout=60)

    def concat(self, paths, output):
        listing = self.root / 'concat.txt'
        listing.write_text(''.join("file '" + p.as_posix().replace("'", "'\\''") + "'\n" for p in paths), encoding='utf-8')
        self.run_ffmpeg('-f', 'concat', '-safe', '0', '-i', str(listing), '-c', 'copy', str(output))

    def validate(self, inputs=None, assembly=None, work=None, tool=None):
        manifest = self.root / 'inputs.txt'
        manifest.write_text('\n'.join(str(p) for p in (inputs or [self.first, self.second])) + '\n', encoding='utf-8-sig')
        result = subprocess.run(['powershell.exe', '-NoProfile', '-ExecutionPolicy', 'Bypass',
            '-File', str(VALIDATOR), '-FFmpegPath', str(tool or self.ffmpeg),
            '-AssemblyPath', str(assembly or self.good), '-InputListPath', str(manifest),
            '-WorkDirectory', str(work or self.root / 'evidence')],
            cwd=self.root, capture_output=True, text=True, timeout=120)
        return result

    def test_exact_assembly_and_special_character_paths_pass(self):
        result = self.validate()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn('10 decoded video frames', (self.root / 'evidence/result.txt').read_text())
        self.assertTrue(self.first.exists())
        self.assertTrue(self.second.exists())

    def test_missing_repeated_reordered_and_extra_segments_fail(self):
        variants = [[self.first], [self.first, self.first], [self.second, self.first],
                    [self.first, self.second, self.second]]
        for index, paths in enumerate(variants):
            with self.subTest(paths=paths):
                output = self.root / f'wrong-{index}.mkv'
                self.concat(paths, output)
                result = self.validate(assembly=output, work=self.root / f'evidence-{index}')
                self.assertEqual(result.returncode, 2, result.stdout + result.stderr)
                self.assertTrue(self.first.exists())

    def test_truncated_or_corrupt_decode_fails(self):
        damaged = self.root / 'corrupt.mkv'
        data = self.good.read_bytes()
        damaged.write_bytes(data[:len(data)//2])
        result = self.validate(assembly=damaged)
        self.assertEqual(result.returncode, 2, result.stdout + result.stderr)

    def test_missing_empty_and_directory_inputs_fail(self):
        empty = self.root / 'empty.mkv'
        empty.touch()
        for index, path in enumerate([self.root / 'missing.mkv', empty, self.root]):
            with self.subTest(path=path):
                result = self.validate(inputs=[path], work=self.root / f'evidence-{index}')
                self.assertEqual(result.returncode, 2, result.stdout + result.stderr)

    def test_missing_tool_and_existing_evidence_fail_without_overwrite(self):
        result = self.validate(tool=self.root / 'missing.exe')
        self.assertEqual(result.returncode, 2)
        evidence = self.root / 'evidence'
        evidence.mkdir()
        sentinel = evidence / 'result.txt'
        sentinel.write_bytes(b'prior evidence')
        result = self.validate()
        self.assertEqual(result.returncode, 2, result.stdout + result.stderr)
        self.assertEqual(sentinel.read_bytes(), b'prior evidence')

    def test_ten_bit_frames_are_not_downconverted(self):
        first10 = self.root / '10bit.mkv'
        self.run_ffmpeg('-f', 'lavfi', '-i', 'testsrc2=s=64x48:r=5:d=1',
                        '-pix_fmt', 'yuv420p10le', '-c:v', 'ffv1', str(first10))
        result = self.validate(inputs=[first10], assembly=first10)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        hashes = (self.root / 'evidence/assembled.framehash').read_text()
        # 64*48 YUV420 pixels at two bytes/component = 9216 bytes/frame.
        self.assertIn('9216,', hashes)




@unittest.skipUnless(os.name == 'nt', 'Requires Windows PowerShell and native fault-injection executable')
class AssemblyValidatorFaultTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.build = tempfile.TemporaryDirectory(prefix='assembly-decoder-stub-')
        cls.stub = Path(cls.build.name) / 'decoder.exe'
        source = Path(cls.build.name) / 'Decoder.cs'
        source.write_text(r'''
using System;
using System.IO;
class Decoder {
    static int Main(string[] args) {
        string mode = Environment.GetEnvironmentVariable("ASSEMBLY_DECODER_FAULT");
        string output = args[args.Length - 1];
        string text = "#version: 2\n#hash: SHA256\n#media_type 0: video\n#codec_id 0: rawvideo\n#dimensions 0: 64x48\n0, 0, 0, 1, 4608, " + new string('a', 64) + "\n";
        if (mode == "missing") return 0;
        if (mode == "directory") { Directory.CreateDirectory(output); return 0; }
        if (mode == "empty") text = "";
        if (mode == "headeronly") text = text.Substring(0, text.LastIndexOf("0, 0,"));
        if (mode == "malformed") text = text.Replace(new string('a', 64), "not-a-hash");
        if (mode == "unsupported") text = text.Replace("#hash: SHA256", "#hash: MD5");
        if (mode == "stream") text = text.Replace("0, 0, 0, 1,", "1, 0, 0, 1,");
        File.WriteAllText(output, text);
        string format = mode == "pixel" && output.EndsWith("assembled.framehash") ? "yuv420p10le" : "yuv420p";
        Console.Error.WriteLine("[Parsed_showinfo_0 @ stub] [info] n: 0 pts: 0 fmt:" + format + " s:64x48");
        if (mode == "stderr") Console.Error.WriteLine("[error] synthetic decoder error");
        return mode == "exit" ? 9 : 0;
    }
}
''')
        compiler = Path(os.environ['WINDIR']) / 'Microsoft.NET/Framework64/v4.0.30319/csc.exe'
        subprocess.run([str(compiler), '/nologo', '/target:exe', '/out:' + str(cls.stub), str(source)],
                       check=True, capture_output=True, text=True)

    @classmethod
    def tearDownClass(cls):
        cls.build.cleanup()

    def test_decoder_errors_and_unparseable_hashes_fail_closed(self):
        for mode in ['missing', 'directory', 'empty', 'headeronly', 'malformed',
                     'unsupported', 'stream', 'stderr', 'exit', 'pixel', 'valid']:
            with self.subTest(mode=mode), tempfile.TemporaryDirectory() as td:
                root = Path(td)
                segment = root / 'segment.mkv'
                segment.write_bytes(b'preserved synthetic input')
                listing = root / 'inputs.txt'
                listing.write_text(str(segment) + '\n', encoding='utf-8')
                env = os.environ.copy()
                env['ASSEMBLY_DECODER_FAULT'] = mode
                result = subprocess.run(['powershell.exe', '-NoProfile', '-ExecutionPolicy', 'Bypass',
                    '-File', str(VALIDATOR), '-FFmpegPath', str(self.stub), '-AssemblyPath', str(segment),
                    '-InputListPath', str(listing), '-WorkDirectory', str(root / 'evidence')],
                    capture_output=True, text=True, timeout=30, env=env)
                self.assertEqual(result.returncode, 0 if mode == 'valid' else 2, result.stdout + result.stderr)
                self.assertEqual(segment.read_bytes(), b'preserved synthetic input')


if __name__ == '__main__':
    unittest.main()
