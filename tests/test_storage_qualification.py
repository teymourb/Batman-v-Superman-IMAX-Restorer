"""Owner-only storage launcher; Windows tests use tiny stubs, never film data."""
import importlib.util
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import unittest
from test_final_remux import ROOT, TEXT, media_commands

SPEC = importlib.util.spec_from_file_location('storage_builder', ROOT/'tools/build_storage_qualification.py')
BUILDER = importlib.util.module_from_spec(SPEC)
# Imported lazily: builder is also checked by the source test.


def variant():
    if not hasattr(BUILDER, 'build'):
        SPEC.loader.exec_module(BUILDER)
    return BUILDER.build((ROOT/'Batman-v-Superman-IMAX-Restorer.bat').read_bytes()).decode().replace('\r\n','\n')


class StorageSource(unittest.TestCase):
    def test_media_commands_and_checkpoint_order(self):
        text = variant()
        self.assertEqual(media_commands(text), media_commands(TEXT))
        first = text.index('-Phase BeforeAssembly')
        self.assertLess(text.index('call :require_stage_output "docs\\temp\\BvS_9i_Cropped.mkv"'), first)
        self.assertLess(first, text.index('docs\\programs\\avidemux\\avidemux_cli --load'))
        second = text.index('-Phase BeforeRemux')
        self.assertLess(text.index('call :validate_assembly "1.78"'), second)
        self.assertLess(second, text.index('docs\\programs\\mkvtoolnix\\mkvmerge -o "!folder!'))
        self.assertIn('-Phase Preflight', text)

    def test_windows_checkout_line_endings_are_equivalent(self):
        variant()
        source=(ROOT/'Batman-v-Superman-IMAX-Restorer.bat').read_bytes().replace(b'\r\n',b'\n')
        self.assertEqual(BUILDER.build(source),BUILDER.build(source.replace(b'\n',b'\r\n')))

    def test_changed_baseline_is_rejected(self):
        variant()
        with self.assertRaises(ValueError):
            BUILDER.build((ROOT/'Batman-v-Superman-IMAX-Restorer.bat').read_bytes().replace(b'-b 50800', b'-b 50801'))


@unittest.skipUnless(os.name == 'nt', 'requires native Windows PowerShell 5.1 and cmd.exe')
class StorageWindows(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.builddir = tempfile.TemporaryDirectory()
        cls.stub = Path(cls.builddir.name)/'stage.exe'
        compiler = Path(os.environ['WINDIR'])/'Microsoft.NET/Framework64/v4.0.30319/csc.exe'
        subprocess.run([str(compiler), '/nologo', '/out:'+str(cls.stub), str(ROOT/'tests/StageStub.cs')],check=True,capture_output=True)

    @classmethod
    def tearDownClass(cls):
        cls.builddir.cleanup()

    def setup_case(self, root, consent='REMOVE', validator=0, fail=0, space=500*1024**3, mode=1, missing_helper=False):
        temp = root/'docs/temp'; temp.mkdir(parents=True)
        scripts=root/'docs/scripts'; scripts.mkdir()
        for name in ('mkvtoolnix/mkvmerge','ffmpeg/ffmpeg','handbrake/HandBrakeCLI','avidemux/avidemux_cli'):
            dest=root/'docs/programs'/(name+'.exe'); dest.parent.mkdir(parents=True,exist_ok=True); shutil.copyfile(self.stub,dest)
        helper=(ROOT/'docs/scripts/Storage-Qualification-Checkpoint.ps1').read_text()
        # Model disk capacity and owner response only; execute actual guards/deletion on real files.
        self.assertEqual(helper.count('return $drive.AvailableFreeSpace'),1)
        helper=helper.replace('return $drive.AvailableFreeSpace','return [long]'+str(space))
        helper=helper.replace("$ErrorActionPreference = 'Stop'", "function Read-Host { param($Prompt) '"+consent+"' }\n$ErrorActionPreference = 'Stop'")
        if consent == 'SECOND_NO':
            helper=helper.replace("function Read-Host { param($Prompt) 'SECOND_NO' }", "function Read-Host { param($Prompt) if ($Phase -eq 'BeforeRemux') { 'NO' } else { 'REMOVE' } }")
        if not missing_helper:
            (scripts/'Storage-Qualification-Checkpoint.ps1').write_text(helper)
        (scripts/'Validate-Assembly.ps1').write_text("New-Item -ItemType Directory -Path 'docs/temp/assembly-validation-1.78' | Out-Null\nSet-Content 'docs/temp/assembly-validation-1.78/result.txt' '"+('PASS: 1 decoded video frames match ordered inputs.' if validator==0 else 'FAIL: synthetic validator')+"'\nexit "+str(validator))
        source=root/'source.mkv'; source.write_bytes(b'original source sentinel')
        env=os.environ.copy(); env.update(version=str(mode),dialog='y',dialog2='y',file=str(source),folder=str(root),STAGE_TRACE=str(root/'trace'),STAGE_FAIL_AT=str(fail),STAGE_CODE='2',STAGE_ACTION='normal')
        start = 'if not exist \"docs\\scripts\\Storage-Qualification-Checkpoint.ps1\" (' if missing_helper else 'if not \"%version%\"==\"1\" ('
        pipe=variant()[variant().index(start):]
        # Bypass only existing interactive PAUSE; owner confirmation is mocked above.
        harness='@echo off\nsetlocal EnableDelayedExpansion\npushd "%~dp0"\n'+re.sub(r'(?im)^\s*PAUSE\s*$', 'rem pause bypassed in synthetic test',pipe)
        (root/'run.bat').write_bytes(harness.replace('\n','\r\n').encode())
        return env,source

    def run_case(self, **kwargs):
        with tempfile.TemporaryDirectory(prefix='storage & [test] ') as directory:
            root=Path(directory); env,source=self.setup_case(root,**kwargs)
            result=subprocess.run(['cmd.exe','/d','/c','run.bat'],cwd=root,env=env,capture_output=True,text=True,timeout=90)
            self.assertEqual(source.read_bytes(),b'original source sentinel')
            names={p.name for p in (root/'docs/temp').iterdir()}
            trace=(root/'trace').read_text().splitlines() if (root/'trace').exists() else []
            log=(root/'docs/temp/storage-qualification.log').read_text(encoding='utf-8-sig') if (root/'docs/temp/storage-qualification.log').exists() else ''
            return result,names,trace,log

    def test_success_releases_only_redundant_copies(self):
        result,names,trace,log=self.run_case()
        self.assertEqual(result.returncode,1,result.stdout+result.stderr)
        self.assertEqual(len(trace),18)
        self.assertNotIn('BvS.mkv',names)
        for n in (2,4,6,8,10): self.assertNotIn('BvS_'+str(n)+'s.mkv',names)
        for n in (1,3,5,7,9):
            self.assertIn('BvS_'+str(n)+'i.mkv',names)
            self.assertIn('BvS_'+str(n)+'i_Cropped.mkv',names)
        self.assertIn('BvS_1.78.mkv',names)
        self.assertIn('final-remux.log',names)
        self.assertEqual(log.count('Removed generated file:'),6)

    def test_declining_first_checkpoint_retains_all_work(self):
        result,names,trace,log=self.run_case(consent='NO')
        self.assertEqual(result.returncode,2,result.stdout+result.stderr)
        self.assertEqual(len(trace),16)
        self.assertIn('BvS.mkv',names)
        self.assertNotIn('Removed generated file:',log)

    def test_declining_second_checkpoint_preserves_scope_segments(self):
        result,names,trace,log=self.run_case(consent='SECOND_NO')
        self.assertEqual(result.returncode,2,result.stdout+result.stderr)
        self.assertEqual(len(trace),17)
        for n in (2,4,6,8,10): self.assertIn('BvS_'+str(n)+'s.mkv',names)
        self.assertIn('BvS_1.78.mkv',names)
        self.assertEqual(log.count('Removed generated file:'),1)

    def test_unsupported_mode_and_missing_helper_refuse_processing(self):
        for kwargs in ({'mode':2}, {'missing_helper':True}):
            result,names,trace,log=self.run_case(**kwargs)
            self.assertEqual(result.returncode,2,result.stdout+result.stderr)
            self.assertEqual(trace,[])
            self.assertNotIn('Removed generated file:',log)

    def test_encoder_failure_never_reaches_cleanup(self):
        result,names,trace,log=self.run_case(fail=16)
        self.assertEqual(result.returncode,2)
        self.assertIn('BvS.mkv',names)
        self.assertNotIn('Removed generated file:',log)

    def test_validator_failure_preserves_assembly_inputs(self):
        result,names,trace,log=self.run_case(validator=2)
        self.assertEqual(result.returncode,2,result.stdout+result.stderr)
        self.assertEqual(len(trace),17)
        for n in (2,4,6,8,10): self.assertIn('BvS_'+str(n)+'s.mkv',names)
        self.assertIn('BvS_1.78.mkv',names)
        self.assertEqual(log.count('Removed generated file:'),1)

    def test_insufficient_space_stops_before_processing(self):
        result,names,trace,log=self.run_case(space=1024)
        self.assertEqual(result.returncode,2,result.stdout+result.stderr)
        self.assertEqual(trace,[])
        self.assertNotIn('BvS.mkv',names)

    def test_helper_rejects_directory_and_link_targets(self):
        with tempfile.TemporaryDirectory(prefix='storage guards ') as directory:
            root=Path(directory); env,_=self.setup_case(root)
            helper=root/'docs/scripts/Storage-Qualification-Checkpoint.ps1'
            def run(phase):
                return subprocess.run(['powershell.exe','-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',str(helper),'-Phase',phase],env=env,cwd=root,capture_output=True,text=True,timeout=30)
            self.assertEqual(run('Preflight').returncode,0)
            for name in ('BvS_1i_Cropped.mkv','BvS_2s.mkv','BvS_3i_Cropped.mkv','BvS_4s.mkv','BvS_5i_Cropped.mkv','BvS_6s.mkv','BvS_7i_Cropped.mkv','BvS_8s.mkv','BvS_9i_Cropped.mkv','BvS_10s.mkv'):
                (root/'docs/temp'/name).write_bytes(b'synthetic')
            target=root/'docs/temp/BvS.mkv'; target.mkdir()
            self.assertEqual(run('BeforeAssembly').returncode,2)
            self.assertTrue(target.is_dir())
            target.rmdir()
            elsewhere=root/'elsewhere'; elsewhere.mkdir(); (elsewhere/'sentinel').write_bytes(b'keep')
            subprocess.run(['cmd.exe','/d','/c','mklink','/J',str(target),str(elsewhere)],check=True,capture_output=True)
            self.assertEqual(run('BeforeAssembly').returncode,2)
            self.assertEqual((elsewhere/'sentinel').read_bytes(),b'keep')
