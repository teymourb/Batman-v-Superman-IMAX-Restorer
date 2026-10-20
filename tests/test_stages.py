"""Actual batch mode control flow with native synthetic tools; no film data."""
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import unittest
from test_final_remux import ROOT, TEXT

START = TEXT.index('if %version%==1 (')
PIPELINE = TEXT[START:]

class StageSource(unittest.TestCase):
    def test_assembly_manifests_match_actual_append_order(self):
        for mode in ('1.78','1.43'):
            command=next(x for x in TEXT.splitlines() if 'avidemux_cli --load' in x and '--save "docs\\temp\\BvS_'+mode+'.mkv"' in x)
            expected=re.findall(r'--(?:load|append) "([^"]+)"',command)
            self.assertEqual((ROOT/'tools/qualification'/('assembly-inputs-'+mode+'.txt')).read_text().splitlines(),expected)
        for token in ('validate_assembly', 'RESTORER_VALIDATION_MODE', 'assembly-check.txt', 'Validate-Assembly.ps1'):
            self.assertNotIn(token, TEXT)
        self.assertIn('Restoration complete.', TEXT)

    def test_noninteractive_ffmpeg_and_visible_assembly(self):
        for line in TEXT.splitlines():
            if line.lstrip().startswith('docs\\programs\\ffmpeg\\ffmpeg '):
                self.assertEqual(line.count(' -nostdin'), 1)
            if line.lstrip().startswith('docs\\programs\\avidemux\\avidemux_cli '):
                self.assertNotIn('processing.log', line)
                self.assertNotIn('2>&1', line)

    def test_stage_gates_and_retention(self):
        commands = re.findall(r'(?m)^\s*docs\\programs\\(?:[^\n]+processing.log[^\n]*|avidemux\\avidemux_cli[^\n]*)\n([^\n]+)\n([^\n]+)', TEXT)
        self.assertEqual(len(commands), 36)
        for first, second in commands:
            self.assertIn('goto stage_', first)
            self.assertTrue('goto stage_warning' in second or 'if not errorlevel 0' in second)
        self.assertNotRegex(PIPELINE, r'(?im)^\s*del "docs\\temp\\BvS')
        self.assertNotIn(':cleanup_workspace', TEXT)

@unittest.skipUnless(os.name == 'nt', 'requires actual Windows cmd.exe')
class WindowsStages(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.build = tempfile.TemporaryDirectory()
        cls.stub = Path(cls.build.name) / 'stage.exe'
        compiler = Path(os.environ['WINDIR']) / 'Microsoft.NET/Framework64/v4.0.30319/csc.exe'
        subprocess.run([str(compiler), '/nologo', '/out:' + str(cls.stub), str(ROOT/'tests/StageStub.cs')], check=True, capture_output=True)

    @classmethod
    def tearDownClass(cls):
        cls.build.cleanup()

    def run_mode(self, mode, fail=0, code=0, action='normal', omit=None, dialog='y', validator_code=0, missing_validator=False, assembly_question=False):
        with tempfile.TemporaryDirectory(prefix='stage with spaces ') as folder:
            root=Path(folder); (root/'docs/temp').mkdir(parents=True)
            for tool in ('mkvtoolnix/mkvmerge', 'ffmpeg/ffmpeg', 'handbrake/HandBrakeCLI', 'avidemux/avidemux_cli'):
                target=root/'docs/programs'/Path(tool+'.exe');target.parent.mkdir(parents=True,exist_ok=True)
                if tool != omit: shutil.copyfile(self.stub,target)
            scripts=root/'docs/scripts';scripts.mkdir()
            if not missing_validator:
                # Exercise production invocation/status gate without decoding stub bytes.
                (scripts/'Validate-Assembly.ps1').write_text('exit '+str(validator_code)+'\n')
            source=root/'synthetic source.mkv';source.write_bytes(b'original sentinel')
            env=os.environ.copy();env['RESTORER_VALIDATION_MODE']='exhaustive';env['STAGE_QUESTION']='yes' if assembly_question else '';env.update(version=str(mode),dialog=dialog,dialog2='y',file=str(source) if dialog=='y' else '"'+str(source)+'"',folder=str(root),STAGE_TRACE=str(root/'trace'),STAGE_FAIL_AT=str(fail),STAGE_CODE=str(code),STAGE_ACTION=action)
            harness='@echo off\nsetlocal EnableDelayedExpansion\npushd "%~dp0"\n'+PIPELINE
            harness=re.sub(r'(?im)^\s*PAUSE\s*$', 'rem noninteractive harness',harness)
            (root/'run.bat').write_bytes(harness.replace('\n','\r\n').encode())
            result=subprocess.run(['cmd.exe','/d','/c','run.bat'],cwd=root,env=env,capture_output=True,text=True,timeout=30,input='y\n' if assembly_question else None)
            trace=(root/'trace').read_text().splitlines() if (root/'trace').exists() else []
            files={p.name:p.read_bytes() for p in (root/'docs/temp').iterdir() if p.is_file()}
            self.assertEqual(source.read_bytes(),b'original sentinel')
            return result,trace,files

    def test_every_stage_stops_cascades_and_retains_work(self):
        for mode in (1,2):
            success,trace,files=self.run_mode(mode)
            self.assertEqual(success.returncode,0,success.stdout+success.stderr)
            self.assertIn('processing.log',files)
            self.assertIn('BvS.mkv',files)
            self.assertEqual(len(trace),18)
            # Every pre-remux command, including assembly, with partial output.
            for index in range(1,len(trace)):
                for code,action in ((2,'normal'),(-1073741819,'normal'),(0,'empty'),(0,'missing')):
                    with self.subTest(mode=mode,index=index,code=code,action=action):
                        result,seen,kept=self.run_mode(mode,index,code,action)
                        self.assertEqual(result.returncode,2,result.stdout+result.stderr)
                        self.assertEqual(len(seen),index)
                        self.assertIn('processing.log',kept)
                        if index>1: self.assertIn('BvS.mkv',kept)
                        for previous in seen[:-1]:
                            args=previous.split('|')
                            output=args[args.index('-o')+1] if '-o' in args else args[args.index('--save')+1] if '--save' in args else args[-1]
                            self.assertEqual(kept[Path(output).name],b'synthetic stage bytes')
            for tool in ('mkvtoolnix/mkvmerge','ffmpeg/ffmpeg','handbrake/HandBrakeCLI','avidemux/avidemux_cli'):
                with self.subTest(mode=mode,missingtool=tool):
                    result,_,kept=self.run_mode(mode,omit=tool)
                    self.assertEqual(result.returncode,2,result.stdout+result.stderr)
                    self.assertIn('processing.log',kept)

    def test_assembly_question_is_visible_and_requires_explicit_answer(self):
        result, trace, files = self.run_mode(1, assembly_question=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn('SYNTHETIC CODEC QUESTION', result.stderr)
        self.assertIn('SYNTHETIC ANSWER: y', result.stdout)
        self.assertNotIn(b'SYNTHETIC CODEC QUESTION', files['processing.log'])

    def test_manual_source_branch(self):
        for mode in (1,2):
            for code in (0,1,2):
                with self.subTest(mode=mode,code=code):
                    result,trace,files=self.run_mode(mode,1,code,dialog='n')
                    self.assertEqual(result.returncode,0 if code==0 else 1 if code==1 else 2,result.stdout+result.stderr)
                    self.assertEqual(len(trace),18 if code==0 else 1)
                    self.assertIn('BvS.mkv',files)

    def test_preparation_warning_retains_output(self):
        result,trace,files=self.run_mode(1,1,1)
        self.assertEqual(result.returncode,1,result.stdout+result.stderr)
        self.assertEqual(len(trace),1)
        self.assertIn('BvS.mkv',files)

    def test_public_pipeline_does_not_require_developer_validator(self):
        for mode in (1, 2):
            result, trace, files = self.run_mode(mode, validator_code=2, missing_validator=True)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertEqual(len(trace), 18)
            self.assertNotIn('assembly-check.txt', files)
