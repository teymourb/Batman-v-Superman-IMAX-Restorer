"""Owner-only packaging continuation: synthetic inputs, native Windows processes.

The isolated test copy changes only tool identity (a compiled stub or CI tool),
available capacity, and owner input. Production has no such override switches.
"""
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
HELPER = ROOT / 'docs/scripts/Continue-Qualification.ps1'
PIN = 'f707365fc6374db58c875d69fe8d3c3f572ab54369b28a863bc9aaad3ebc09ef'
STUB = r'''
using System;
using System.IO;
using System.Text;
using System.Web.Script.Serialization;
class Stub {
 static int Main(string[] args) {
  var j = new JavaScriptSerializer();
  File.WriteAllText(Environment.GetEnvironmentVariable("STUB_CALL"), j.Serialize(args), Encoding.UTF8);
  if(args.Length != 1 || !args[0].StartsWith("@")) return 9;
  var a = j.Deserialize<string[]>(File.ReadAllText(args[0].Substring(1), Encoding.UTF8));
  File.WriteAllText(Environment.GetEnvironmentVariable("STUB_ARGS"), j.Serialize(a), Encoding.UTF8);
  Console.WriteLine("synthetic mkvmerge diagnostic");
  int code = Int32.Parse(Environment.GetEnvironmentVariable("STUB_EXIT"));
  int n = Array.IndexOf(a,"-o") + 1;
  if(code <= 1 && Environment.GetEnvironmentVariable("STUB_MISSING") != "1")
   File.WriteAllText(a[n], Environment.GetEnvironmentVariable("STUB_EMPTY") == "1" ? "" : "synthetic packaged video");
  return code;
 }
}'''


@unittest.skipUnless(os.name == 'nt', 'requires actual Windows PowerShell 5.1')
class ContinuationWindows(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.build = tempfile.TemporaryDirectory(prefix='continuation stub ')
        src = Path(cls.build.name) / 'Stub.cs'
        src.write_text(STUB)
        cls.stub = src.with_suffix('.exe')
        compiler = Path(os.environ['WINDIR']) / 'Microsoft.NET/Framework64/v4.0.30319/csc.exe'
        subprocess.run([str(compiler), '/nologo', '/r:System.Web.Extensions.dll',
                        '/out:' + str(cls.stub), str(src)], check=True, capture_output=True)

    @classmethod
    def tearDownClass(cls):
        cls.build.cleanup()

    def setup_case(self, directory, consent='PACKAGE', capacity=500 * 1024**3,
                   real_tool=None, assembly=None, original=None):
        root = directory / 'installation ü & [copy]'
        temp = root / 'docs/temp'
        temp.mkdir(parents=True)
        destination = directory / 'destination 日本 & [keep]'
        destination.mkdir()
        (destination / 'existing-output.mkv').write_bytes(b'keep previous output')
        source = directory / 'original é & [movie].mkv'
        assembled = temp / 'BvS_1.78.mkv'
        if original:
            shutil.copyfile(original, source)
            shutil.copyfile(assembly, assembled)
        else:
            source.write_bytes(b'original source sentinel')
            assembled.write_bytes(b'already encoded assembly sentinel')
        (temp / 'BvS_1i_Cropped.mkv').write_bytes(b'keep completed encode')
        evidence = temp / 'assembly-validation-1.78'
        evidence.mkdir()
        (evidence / 'assembled.stderr.log').write_bytes(b'incomplete validation evidence')
        (temp / 'processing.log').write_bytes(b'historical processing evidence')
        # Python timestamps can round .NET ticks. Ask actual Windows .NET for
        # exact metadata, as the production checkpoint does.
        metadata = subprocess.check_output([
            'powershell.exe', '-NoProfile', '-Command',
            '[Console]::OutputEncoding=[Text.UTF8Encoding]::new($false); $i=Get-Item -LiteralPath $env:CONT_SOURCE; '
            '@{Source=$i.FullName;Length=$i.Length;Ticks=$i.LastWriteTimeUtc.Ticks;'
            'Phase="BeforeAssembly";VideoBytes=1}|ConvertTo-Json -Compress'],
            env={**os.environ, 'CONT_SOURCE': str(source)}, text=True, encoding='utf-8')
        (temp / 'storage-qualification.json').write_text(metadata, encoding='utf-8')
        tools = root / 'docs/programs/mkvtoolnix'
        tools.mkdir(parents=True)
        if real_tool:
            for item in Path(real_tool).parent.iterdir():
                if item.is_file():
                    shutil.copy2(item, tools / item.name)
        else:
            shutil.copyfile(self.stub, tools / 'mkvmerge.exe')
        script = HELPER.read_text(encoding='utf-8-sig')
        self.assertEqual(script.lower().count(PIN), 1)
        tool_hash = hashlib.sha256((tools / 'mkvmerge.exe').read_bytes()).hexdigest()
        script = script.replace(PIN, tool_hash)
        self.assertEqual(script.count('return $drive.AvailableFreeSpace'), 1)
        script = script.replace('return $drive.AvailableFreeSpace', 'return [long]' + str(capacity))
        script = script.replace("$ErrorActionPreference = 'Stop'",
                                "function Read-Host { param($Prompt) '" + consent + "' }\n$ErrorActionPreference = 'Stop'")
        helper = directory / 'Continue-Test.ps1'
        helper.write_text(script, encoding='utf-8-sig')
        return root, destination, source, helper

    def invoke(self, directory, setup, code=0, empty=False, missing=False):
        root, destination, source, helper = setup
        before = {p.relative_to(root): p.read_bytes() for p in root.rglob('*') if p.is_file()}
        source_before = source.read_bytes()
        env = dict(os.environ, STUB_ARGS=str(directory/'args.json'),
                   STUB_CALL=str(directory/'call.json'), STUB_EXIT=str(code),
                   STUB_EMPTY='1' if empty else '0', STUB_MISSING='1' if missing else '0')
        result = subprocess.run(['powershell.exe', '-NoProfile', '-ExecutionPolicy', 'Bypass',
                                 '-File', str(helper), '-InstallationRoot', str(root),
                                 '-Destination', str(destination)], env=env, capture_output=True,
                                text=True, timeout=90)
        self.assertEqual(source.read_bytes(), source_before)
        self.assertEqual({p.relative_to(root):p.read_bytes() for p in root.rglob('*') if p.is_file()}, before)
        self.assertEqual((destination/'existing-output.mkv').read_bytes(), b'keep previous output')
        return result, list(destination.glob('BvS-unqualified-*'))

    def test_confirmation_and_decline_do_not_touch_inputs(self):
        for consent in ('NO', '', 'package', 'PACKAGE'):
            with self.subTest(consent=consent), tempfile.TemporaryDirectory() as d:
                directory = Path(d).resolve()
                setup = self.setup_case(directory, consent=consent)
                result, outputs = self.invoke(directory, setup)
                self.assertEqual(result.returncode, 0 if consent == 'PACKAGE' else 3,
                                 result.stdout + result.stderr)
                self.assertEqual(len(outputs), 1 if consent == 'PACKAGE' else 0)
                self.assertEqual((directory/'args.json').exists(), consent == 'PACKAGE')

    def test_response_arguments_preserve_mapping_and_unicode_paths(self):
        with tempfile.TemporaryDirectory() as d:
            directory = Path(d).resolve()
            setup = self.setup_case(directory)
            result, outputs = self.invoke(directory, setup)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertEqual(len(outputs), 1)
            args = json.loads((directory/'args.json').read_text(encoding='utf-8-sig'))
            root, _, source, _ = setup
            self.assertEqual(args, ['-o', str(outputs[0]/'Batman v Superman IMAX 1.78 UNQUALIFIED.mkv'),
                '-A', '--no-audio', '-S', '--no-subtitles', '-B', '--no-buttons',
                '--no-chapters', '-M', '--no-attachments', '--no-global-tags',
                str(root/'docs/temp/BvS_1.78.mkv'), '-D', '--no-video', str(source)])
            evidence = '\n'.join(p.read_text(encoding='utf-8-sig', errors='replace')
                                 for p in outputs[0].rglob('*') if p.is_file() and p.suffix != '.mkv')
            self.assertIn('UNQUALIFIED', evidence)
            self.assertNotIn('qualification-status=PASS', evidence)

    def test_invalid_state_source_changes_missing_assembly_and_space_refuse_tool(self):
        for defect in ('bad-json', 'wrong-phase', 'source-length', 'source-ticks',
                       'missing-assembly', 'empty-assembly', 'space', 'tool-hash'):
            with self.subTest(defect=defect), tempfile.TemporaryDirectory() as d:
                directory = Path(d).resolve()
                setup = self.setup_case(directory, capacity=1 if defect=='space' else 500*1024**3)
                root, _, source, helper = setup
                statepath = root/'docs/temp/storage-qualification.json'
                state = json.loads(statepath.read_text())
                if defect == 'bad-json': statepath.write_text('{broken')
                elif defect in ('wrong-phase', 'source-length', 'source-ticks'):
                    field, value = {'wrong-phase':('Phase','Preflight'), 'source-length':('Length',0),
                                    'source-ticks':('Ticks',0)}[defect]
                    state[field] = value
                    statepath.write_text(json.dumps(state))
                elif defect == 'missing-assembly': (root/'docs/temp/BvS_1.78.mkv').unlink()
                elif defect == 'empty-assembly': (root/'docs/temp/BvS_1.78.mkv').write_bytes(b'')
                elif defect == 'tool-hash': (root/'docs/programs/mkvtoolnix/mkvmerge.exe').write_bytes(b'wrong tool')
                result, _ = self.invoke(directory, setup)
                self.assertEqual(result.returncode, 2, result.stdout + result.stderr)
                self.assertFalse((directory/'args.json').exists())

    def test_status_and_nonempty_guards_keep_unqualified_evidence(self):
        for code, empty, missing in ((1,False,False), (2,False,False),
                                     (0,True,False), (0,False,True)):
            with self.subTest(code=code, empty=empty, missing=missing), tempfile.TemporaryDirectory() as d:
                directory = Path(d).resolve()
                setup = self.setup_case(directory)
                result, outputs = self.invoke(directory, setup, code=code, empty=empty, missing=missing)
                self.assertEqual(result.returncode, 1 if code == 1 else 2, result.stdout + result.stderr)
                self.assertEqual(len(outputs),1)
                evidence = '\n'.join(p.read_text(encoding='utf-8-sig', errors='replace')
                                     for p in outputs[0].rglob('*') if p.is_file() and p.suffix != '.mkv')
                self.assertIn('UNQUALIFIED', evidence)
                self.assertNotIn('qualification-status=PASS', evidence)

    def test_second_attempt_preserves_first_output_and_evidence(self):
        with tempfile.TemporaryDirectory() as d:
            directory = Path(d).resolve()
            setup = self.setup_case(directory)
            first, outputs = self.invoke(directory, setup)
            self.assertEqual(first.returncode, 0, first.stdout + first.stderr)
            first_run = outputs[0]
            before = {p.relative_to(first_run):p.read_bytes()
                      for p in first_run.rglob('*') if p.is_file()}
            second, outputs = self.invoke(directory, setup)
            self.assertEqual(second.returncode, 0, second.stdout + second.stderr)
            self.assertEqual(len(outputs), 2)
            self.assertEqual({p.relative_to(first_run):p.read_bytes()
                              for p in first_run.rglob('*') if p.is_file()}, before)

    def test_competing_state_reader_blocks_launch_without_changing_inputs(self):
        # A shared read lock permits initial state inspection but must prevent
        # obtaining the exclusive launch lock. This catches a regression back
        # to compatible FileShare.Read launch locks without timing races.
        with tempfile.TemporaryDirectory() as d:
            directory = Path(d).resolve()
            setup = self.setup_case(directory)
            state = setup[0]/'docs/temp/storage-qualification.json'
            command = (
                '$s=[IO.File]::Open($env:LOCK_STATE,[IO.FileMode]::Open,'
                '[IO.FileAccess]::Read,[IO.FileShare]::Read); '
                'try {[Console]::WriteLine("LOCKED");[Console]::ReadLine()|Out-Null}'
                'finally {$s.Dispose()}')
            holder = subprocess.Popen(['powershell.exe','-NoProfile','-Command',command],
                env={**os.environ,'LOCK_STATE':str(state)}, stdin=subprocess.PIPE,
                stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
            try:
                self.assertEqual(holder.stdout.readline().strip(),'LOCKED')
                result, outputs = self.invoke(directory, setup)
                self.assertEqual(result.returncode,2,result.stdout+result.stderr)
                self.assertEqual(outputs,[])
                self.assertFalse((directory/'args.json').exists())
            finally:
                holder.communicate(input='\n',timeout=15)
            self.assertEqual(holder.returncode,0)

    @unittest.skipUnless(os.environ.get('RESTORER_REAL_MKVMERGE'), 'real CI fixture tools required')
    def test_real_remux_preserves_video_audio_subtitle_and_chapter(self):
        tool = Path(os.environ['RESTORER_REAL_MKVMERGE']).resolve()
        ffmpeg, ffprobe = shutil.which('ffmpeg'), shutil.which('ffprobe')
        self.assertTrue(ffmpeg and ffprobe)
        with tempfile.TemporaryDirectory() as d:
            directory = Path(d).resolve()
            original = directory/'fixture-original.mkv'
            assembly = directory/'fixture-assembly.mkv'
            subtitle = directory/'subtitle.srt'
            subtitle.write_text('1\n00:00:00,000 --> 00:00:00,900\nSynthetic subtitle\n')
            chapter = directory/'chapters.txt'
            chapter.write_text('CHAPTER01=00:00:00.000\nCHAPTER01NAME=Synthetic chapter\n')
            av = directory/'av.mkv'
            subprocess.run([ffmpeg,'-v','error','-f','lavfi','-i','color=c=blue:s=64x64:r=24',
                            '-f','lavfi','-i','sine=frequency=440:sample_rate=48000','-t','1',
                            '-c:v','libx264','-pix_fmt','yuv420p','-c:a','pcm_s16le',str(av)],check=True)
            subprocess.run([str(tool),'-o',str(original),'--chapters',str(chapter),str(av),str(subtitle)],check=True,capture_output=True)
            subprocess.run([str(tool),'-o',str(assembly),'-A','-S','--no-chapters',str(original)],check=True,capture_output=True)
            setup = self.setup_case(directory, real_tool=tool, assembly=assembly, original=original)
            result, outputs = self.invoke(directory, setup)
            self.assertEqual(result.returncode,0,result.stdout+result.stderr)
            output = outputs[0]/'Batman v Superman IMAX 1.78 UNQUALIFIED.mkv'
            def packets(path, stream):
                return subprocess.check_output([ffprobe,'-v','error','-select_streams',stream,
                    '-show_packets','-show_data_hash','sha256','-show_entries','packet=data_hash',
                    '-of','csv=p=0',str(path)])
            for stream in ('v:0','s:0'):
                self.assertTrue(packets(original,stream).strip())
                self.assertEqual(packets(original,stream),packets(output,stream))
            def pcm(path):
                return subprocess.check_output([ffmpeg,'-v','error','-i',str(path),'-map','0:a:0',
                    '-c:a','copy','-f','s16le','pipe:1'])
            self.assertEqual(len(pcm(original)),96000)
            self.assertEqual(pcm(original),pcm(output))
            chapters = json.loads(subprocess.check_output([ffprobe,'-v','error','-show_chapters','-of','json',str(output)]))['chapters']
            self.assertEqual(len(chapters),1)
            self.assertEqual(chapters[0]['tags']['title'],'Synthetic chapter')
