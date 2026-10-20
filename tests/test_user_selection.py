"""Settings checks use tiny dummy files, never films or media encoders."""
import os
import re
import shutil
from pathlib import Path
import subprocess
import tempfile
import unittest
ROOT = Path(__file__).resolve().parents[1]
TEXT = (ROOT/'Batman-v-Superman-IMAX-Restorer.bat').read_text()
HELPER = ROOT/'docs/scripts/Select-Restoration.ps1'
class SelectionSource(unittest.TestCase):
    def test_selection_precedes_workspace_and_avoids_config_code(self):
        text=(ROOT/'Batman-v-Superman-IMAX-Restorer.bat').read_text()
        self.assertLess(text.index('-ValidateEnvironment'),text.index('call :prepare_workspace'))
        self.assertIn('-STA',text)
        helper=HELPER.read_text()
        self.assertNotIn('Invoke-Expression',helper)
        self.assertIn("$start.EnvironmentVariables['file'] = $Source",helper)
        self.assertIn('exit $process.ExitCode',helper)
        self.assertNotIn('mshta',text.lower())
        for term in ('ValidationMode', 'RESTORER_VALIDATION_MODE', 'Exhaustive', 'Basic', 'Selection validation passed'):
            self.assertNotIn(term, helper)
        self.assertLess(helper.index('Only the unaltered video track'), helper.index('Select-Path $true'))
@unittest.skipUnless(os.name=='nt','requires native Windows PowerShell 5.1')
class SelectionWindows(unittest.TestCase):
    def setUp(self):
        self.tmp=tempfile.TemporaryDirectory(prefix='selection & (test) ')
        self.addCleanup(self.tmp.cleanup)
        self.root=Path(self.tmp.name)
        self.source=self.root/'source.mkv'; self.source.write_bytes(b'synthetic-not-video')
        self.dest=self.root/'output'; self.dest.mkdir()
    def run_selection(self,source=None,destination=None,mode='1',extra=(),env=None):
        return subprocess.run(['powershell.exe','-NoProfile','-STA','-ExecutionPolicy','Bypass','-File',str(HELPER),'-Film','BvS','-ValidateOnly','-Source',str(source or self.source),'-Destination',str(destination or self.dest),'-Mode',mode,*extra],capture_output=True,text=True,encoding='utf-8',timeout=30,env=env)
    def test_spaces_ampersands_parentheses_unicode_and_quotes(self):
        self.source.rename(self.root/'caf\u00e9 (video) & source.mkv'); self.source=self.root/'caf\u00e9 (video) & source.mkv'
        result=self.run_selection(source='"'+str(self.source)+'"')
        self.assertEqual(result.returncode,0,result.stdout+result.stderr)
        self.assertEqual(list(self.dest.iterdir()),[])
    def test_invalid_inputs_never_create_processing_workspace(self):
        for changes in ({'source':self.root/'missing.mkv'},{'source':self.dest},{'destination':self.root/'missing'},{'mode':'3'}):
            result=self.run_selection(**changes)
            self.assertEqual(result.returncode,2,result.stdout+result.stderr)
        for name in ('bang!.mkv','percent%.mkv','caret^.mkv'):
            p=self.root/name; p.write_bytes(b'test')
            self.assertEqual(self.run_selection(source=p).returncode,2)
        self.assertEqual(list(self.dest.iterdir()),[])
    def test_existing_output_is_preserved(self):
        output=self.dest/'Batman v Superman Dawn of Justice Ultimate Edition IMAX 1.78.mkv'; output.write_bytes(b'keep')
        self.assertEqual(self.run_selection().returncode,2)
        self.assertEqual(output.read_bytes(),b'keep')
    def test_source_is_output_rejected(self):
        output=self.dest/'Batman v Superman Dawn of Justice Ultimate Edition IMAX 1.78.mkv'; output.write_bytes(b'keep')
        self.assertEqual(self.run_selection(source=output).returncode,2)
    def test_manual_quit_no_workspace_or_child(self):
        result=subprocess.run(['powershell.exe','-NoProfile','-STA','-ExecutionPolicy','Bypass','-File',str(HELPER),'-Film','BvS','-Manual'],input='q\n',capture_output=True,text=True,encoding='utf-8',timeout=30)
        self.assertEqual(result.returncode,3,result.stdout+result.stderr)
    def test_helper_launches_child_with_unicode_environment_and_returns_status(self):
        self.source.rename(self.root/'caf\u00e9 (video) & source.mkv'); self.source=self.root/'caf\u00e9 (video) & source.mkv'
        child=self.root/'child (launcher) & test.bat'
        child.write_text('@echo off\nsetlocal DisableDelayedExpansion\npowershell.exe -NoProfile -Command "[IO.File]::WriteAllText($env:SELECTION_TRACE, $env:file + [Environment]::NewLine + $env:folder + [Environment]::NewLine + $env:version + [Environment]::NewLine + $env:dialog)"\nexit /b 7\n')
        trace=self.root/'trace.txt'; env=os.environ.copy(); env['SELECTION_TRACE']=str(trace)
        result=subprocess.run(['powershell.exe','-NoProfile','-STA','-ExecutionPolicy','Bypass','-File',str(HELPER),'-Film','BvS','-Manual','-Launcher',str(child)],input=f'{self.source}\n{self.dest}\n1\nwrong-answer\ny\n',capture_output=True,text=True,encoding='utf-8',timeout=30,env=env)
        self.assertEqual(result.returncode,7,result.stdout+result.stderr)
        recorded = trace.read_text(encoding='utf-8').splitlines()
        # PowerShell's GetFullPath may expand the runner's 8.3 TEMP directory.
        self.assertTrue(Path(recorded[0]).samefile(self.source))
        self.assertTrue(Path(recorded[1]).samefile(self.dest))
        self.assertEqual(Path(recorded[0]).name, self.source.name)
        self.assertEqual(Path(recorded[1]).name, self.dest.name)
        self.assertEqual(recorded[2:], ['1', 'y'])
        self.assertIn('A file path is not a confirmation',result.stdout)
    def test_confirmation_retry_and_cancel_before_launch(self):
        child=self.root/'child.bat'; child.write_text('@echo off\npowershell.exe -NoProfile -Command "[IO.File]::WriteAllText($env:SELECTION_TRACE,\'started\')"\nexit /b 0\n')
        trace=self.root/'trace.txt';env=os.environ.copy();env['SELECTION_TRACE']=str(trace)
        cmd=['powershell.exe','-NoProfile','-STA','-ExecutionPolicy','Bypass','-File',str(HELPER),'-Film','BvS','-Manual','-Launcher',str(child)]
        prefix=f'{self.source}\n{self.dest}\n1\n'
        for ending in ('q\n','\n','n\n'):
            result=subprocess.run(cmd,input=prefix+ending,env=env,capture_output=True,text=True,encoding='utf-8',timeout=30)
            self.assertEqual(result.returncode,3,result.stdout+result.stderr)
            self.assertFalse(trace.exists())
        result=subprocess.run(cmd,input=prefix+'invalid\ny\n',env=env,capture_output=True,text=True,encoding='utf-8',timeout=30)
        self.assertEqual(result.returncode,0,result.stdout+result.stderr)
        self.assertEqual(trace.read_text(),'started')
        self.assertNotIn('Exhaustive',result.stdout)
        self.assertIn('A file path is not a confirmation',result.stdout)

    def test_dialog_readiness_enter_quit_and_retry(self):
        # Exercise the real readiness function without opening native UI in CI.
        prefix = HELPER.read_text().split('\ntry {\n    if ($ValidateEnvironment)', 1)[0]
        harness = self.root / 'readiness.ps1'
        for is_source in ('$true', '$false'):
            harness.write_text(prefix + "\ntry { Wait-ForDialog " + is_source + "; Write-Host 'DIALOG_READY'; exit 0 } catch [OperationCanceledException] { Write-Host $_.Exception.Message; exit 3 }\n")
            for answer, status in (('\n', 0), ('q\n', 3), ('not-ready\n\n', 0)):
                result = subprocess.run(['powershell.exe', '-NoProfile', '-File', str(harness)],
                                        input=answer, capture_output=True, text=True, timeout=30)
                self.assertEqual(result.returncode, status, result.stdout + result.stderr)
                self.assertEqual('DIALOG_READY' in result.stdout, status == 0)
                self.assertEqual(list(self.dest.iterdir()), [])

    def test_selected_entry_valid_settings_are_silent(self):
        env=os.environ.copy()
        env.update(file=str(self.source),folder=str(self.dest),version='1',dialog='y',dialog2='y',RESTORER_SELECTION_READY='1')
        cmd=['powershell.exe','-NoProfile','-STA','-ExecutionPolicy','Bypass','-File',str(HELPER),'-Film','BvS','-ValidateEnvironment']
        result=subprocess.run(cmd,env=env,capture_output=True,text=True,encoding='utf-8',timeout=30)
        self.assertEqual(result.returncode,0,result.stdout+result.stderr)
        self.assertEqual(result.stdout,'')

    def test_selected_entry_without_valid_settings_stops(self):
        env=os.environ.copy()
        for key in ('file','folder','version','dialog','dialog2','RESTORER_SELECTION_READY'): env.pop(key,None)
        result=subprocess.run(['powershell.exe','-NoProfile','-STA','-ExecutionPolicy','Bypass','-File',str(HELPER),'-Film','BvS','-ValidateEnvironment'],env=env,capture_output=True,text=True,encoding='utf-8',timeout=30)
        self.assertEqual(result.returncode,2,result.stdout+result.stderr)

@unittest.skipUnless(os.name == 'nt', 'requires Windows PowerShell 5.1 and cmd.exe')
class WindowsSelection(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.build = tempfile.TemporaryDirectory(prefix='selection-native-')
        cls.stub = Path(cls.build.name) / 'processing.exe'
        compiler = Path(os.environ['WINDIR']) / 'Microsoft.NET/Framework64/v4.0.30319/csc.exe'
        subprocess.run([str(compiler), '/nologo', '/target:exe', '/out:' + str(cls.stub),
                        str(ROOT / 'tests/StageStub.cs')], check=True, capture_output=True)

    @classmethod
    def tearDownClass(cls):
        cls.build.cleanup()

    def make_case(self, root):
        install = root / 'Program & (test) [unicode é]'
        scripts = install / 'docs/scripts'
        scripts.mkdir(parents=True)
        shutil.copyfile(HELPER, scripts / HELPER.name)
        launcher = install / 'Batman-v-Superman-IMAX-Restorer.bat'
        # Synthetic pipeline transport fixture substitutes only the separately tested identity gate.
        (scripts / "Test-SourceFingerprint.ps1").write_text("exit 0\n")
        # Only remove attended terminal pauses; all setup and processing code stays real.
        launcher.write_bytes(re.sub(r'(?im)^\s*PAUSE\s*$', 'rem unattended terminal pause', TEXT).replace('\n', '\r\n').encode())
        for tool in ('mkvtoolnix/mkvmerge', 'ffmpeg/ffmpeg', 'handbrake/HandBrakeCLI', 'avidemux/avidemux_cli'):
            target = install / 'docs/programs' / (tool + '.exe')
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(self.stub, target)
        source = root / 'Source & (test) [é].mkv'
        source.write_bytes(b'synthetic original')
        destination = root / 'Output & (test) [é]'
        destination.mkdir()
        return install, launcher, source, destination

    def invoke(self, install, launcher, source, destination, mode='1', answers=None, validate=False):
        env = os.environ.copy()
        env.update(STAGE_TRACE=str(install / 'called.txt'), STAGE_CODE='0', STAGE_FAIL_AT='0', STAGE_ACTION='normal')
        cmd = ['powershell.exe', '-NoProfile', '-STA', '-ExecutionPolicy', 'Bypass', '-File',
               str(install / 'docs/scripts/Select-Restoration.ps1'), '-Film', 'BvS']
        if validate:
            cmd += ['-ValidateOnly', '-Source', str(source), '-Destination', str(destination), '-Mode', mode]
        else:
            cmd += ['-Manual', '-Launcher', str(launcher)]
        return subprocess.run(cmd, cwd=install.parent, env=env, input=answers, text=True,encoding='utf-8',
                              capture_output=True, timeout=60)

    def test_real_setup_child_transport_both_modes_and_quoted_paths(self):
        for mode in ('1', '2'):
            with self.subTest(mode=mode), tempfile.TemporaryDirectory() as td:
                install, launcher, source, destination = self.make_case(Path(td))
                answers = '"' + str(source) + '"\n"' + str(destination) + '"\n' + mode + '\ny\n'
                result = self.invoke(install, launcher, source, destination, mode, answers)
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assertIn('Restoration complete.', result.stdout)
                name = 'Batman v Superman Dawn of Justice Ultimate Edition IMAX ' + ('1.78.mkv' if mode == '1' else '1.43 (unmasked).mkv')
                self.assertTrue((destination / name).is_file(), result.stdout + result.stderr)
                self.assertIn(name, result.stdout.split('Restoration complete.', 1)[1])
                self.assertEqual(source.read_bytes(), b'synthetic original')
                self.assertFalse((install / 'docs/temp/assembly-check.txt').exists())
                self.assertIn('Source size:', result.stdout)
                self.assertIn('Available space (working files and final output):', result.stdout)
                self.assertIn('share this available space', result.stdout)
                self.assertTrue((install / 'docs/temp/processing.log').exists())

    def test_quit_and_invalid_confirmation_do_not_create_workspace(self):
        for answers in ('q\n', '', None):
            with tempfile.TemporaryDirectory() as td:
                install, launcher, source, destination = self.make_case(Path(td))
                if answers is None:
                    answers = str(source) + '\n' + str(destination) + '\n1\n' + str(source) + '\nn\n'
                result = self.invoke(install, launcher, source, destination, answers=answers)
                self.assertEqual(result.returncode, 3, result.stdout + result.stderr)
                self.assertFalse((install / 'docs/temp').exists())
                self.assertFalse((install / 'called.txt').exists())

    def test_existing_output_and_invalid_selection_preserve_sentinels(self):
        with tempfile.TemporaryDirectory() as td:
            install, launcher, source, destination = self.make_case(Path(td))
            output = destination / 'Batman v Superman Dawn of Justice Ultimate Edition IMAX 1.78.mkv'
            output.write_bytes(b'previous output')
            for selected_source, mode in ((source, '1'), (source, 'garbage'), (source.with_name('missing.mkv'), '2')):
                result = self.invoke(install, launcher, selected_source, destination, mode=mode, validate=True)
                self.assertEqual(result.returncode, 2, result.stdout + result.stderr)
                self.assertEqual(output.read_bytes(), b'previous output')
                self.assertFalse((install / 'docs/temp').exists())
                self.assertFalse((install / 'called.txt').exists())

    def test_fingerprint_failure_stops_before_any_processing(self):
        for status in (2, -1, -1073741819):
            with self.subTest(status=status), tempfile.TemporaryDirectory() as td:
                install, launcher, source, destination = self.make_case(Path(td))
                (install / 'docs/scripts/Test-SourceFingerprint.ps1').write_text(
                    "Write-Host 'Synthetic fingerprint mismatch: restoration not started.'\nexit %s\n" % status)
                answers = str(source) + '\n' + str(destination) + '\n1\ny\n'
                result = self.invoke(install, launcher, source, destination, answers=answers)
                self.assertEqual(result.returncode, 2, result.stdout + result.stderr)
                self.assertIn('Synthetic fingerprint mismatch', result.stdout)
                self.assertFalse((install / 'called.txt').exists(), 'processing tool ran after rejected source')
                self.assertEqual(list(destination.iterdir()), [])
                self.assertEqual(source.read_bytes(), b'synthetic original')
