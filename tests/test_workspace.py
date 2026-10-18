"""Exercise the launcher's real workspace helpers on Windows, without dialogs/media."""
import os
from pathlib import Path
import re
import subprocess
import tempfile
import time
import unittest

from test_final_remux import TEXT

STARTUP = TEXT.split('::Making sure', 1)[0]
SUCCESS = TEXT.split('::Remove only the known log;', 1)[1].split(
    ':: Workspace helpers:', 1)[0]
HELPERS = TEXT.split(':: Workspace helpers:', 1)[1].split('\n:remux_warning', 1)[0]
HANDLERS = ':remux_warning' + TEXT.split('\n:remux_warning', 1)[1]


class WorkspaceSource(unittest.TestCase):
    def test_startup_and_cleanup_are_connected_to_tested_helpers(self):
        self.assertIn('call :prepare_workspace\nif errorlevel 1 exit /b 2', STARTUP)
        self.assertIn('call :cleanup_workspace\nif errorlevel 1 goto cleanup_incomplete', SUCCESS)
        self.assertNotRegex(TEXT, r'(?im)^\s*del\s+\*')
        self.assertNotRegex(TEXT, r'(?im)^\s*rmdir\s+/(s|q)')
        self.assertIn('if exist "docs\\temp" (', HELPERS)
        self.assertIn('mkdir "docs\\temp"\nif errorlevel 1 (', HELPERS)
        self.assertIn('rmdir "docs\\temp" 2>nul', HELPERS)


@unittest.skipUnless(os.name == 'nt', 'requires actual Windows cmd.exe')
class WindowsWorkspace(unittest.TestCase):
    def make_case(self, root, docs=True):
        install = root / 'Program with spaces & !mark'
        caller = root / 'unrelated caller'
        install.mkdir()
        caller.mkdir()
        if docs:
            (install / 'docs').mkdir()
        foreign = caller / 'docs' / 'temp'
        foreign.mkdir(parents=True)
        (foreign / 'never-delete.txt').write_bytes(b'caller sentinel')
        (caller / 'never-delete.txt').write_bytes(b'caller root sentinel')
        # Simulate a stage without executing a dialog or video tool.
        stage = '''echo PROCESSING_STARTED
echo STAGE_CWD="%CD%"
echo STAGE_OUTCOME=%TEST_OUTCOME%
> "docs\\temp\\final-remux.log" echo synthetic diagnostic
if "%TEST_OUTCOME%"=="hold" (
    > ".test-owned-marker" echo owned
    set /p "release_hold=Continue: "
    del /q ".test-owned-marker"
)
if "%TEST_OUTCOME%"=="leftovers" (
    mkdir "docs\\temp\\unexpected"
    > "docs\\temp\\unexpected\\sentinel.txt" echo preserve me
)
if "%TEST_OUTCOME%"=="warning" (
    > "docs\\temp\\stage-output.txt" echo recoverable work
    goto remux_warning
)
if "%TEST_OUTCOME%"=="error" (
    > "docs\\temp\\stage-output.txt" echo recoverable work
    goto remux_failed
)
'''
        # Reattach the comment text removed by split; production code is intact.
        harness = STARTUP + stage + 'rem Remove only the known log;' + SUCCESS
        harness += 'rem Workspace helpers:' + HELPERS + '\n' + HANDLERS
        harness = re.sub(r'(?im)^\s*PAUSE\s*$', 'rem PAUSE omitted by harness', harness)
        (install / 'run.bat').write_bytes(harness.replace('\n', '\r\n').encode())
        (caller / 'wrapper.bat').write_text('''@echo off
call "%WORKSPACE_TEST_SCRIPT%"
set "restorer_result=%errorlevel%"
echo CALLER_AFTER=%CD%
exit /b %restorer_result%
''')
        return install, caller

    def run_case(self, install, caller, outcome='success'):
        env = os.environ.copy()
        env.update(WORKSPACE_TEST_SCRIPT=str(install / 'run.bat'), TEST_OUTCOME=outcome)
        result = subprocess.run(['cmd.exe', '/d', '/v:off', '/c', 'wrapper.bat'],
                                cwd=caller, env=env, input='\n', capture_output=True,
                                text=True, timeout=30)
        self.assertIn('CALLER_AFTER=' + str(caller), result.stdout)
        self.assertEqual((caller / 'never-delete.txt').read_bytes(), b'caller root sentinel')
        self.assertEqual((caller / 'docs/temp/never-delete.txt').read_bytes(), b'caller sentinel')
        self.assertEqual(sorted(p.name for p in (caller / 'docs/temp').iterdir()), ['never-delete.txt'])
        if 'PROCESSING_STARTED' in result.stdout:
            self.assertIn('STAGE_CWD="' + str(install) + '"', result.stdout)
            self.assertIn('STAGE_OUTCOME=' + outcome, result.stdout)
        return result

    def test_fresh_success_from_unrelated_directory(self):
        with tempfile.TemporaryDirectory() as folder:
            install, caller = self.make_case(Path(folder))
            result = self.run_case(install, caller)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertIn('PROCESSING_STARTED', result.stdout)
            self.assertFalse((install / 'docs/temp').exists())

    def test_existing_recovery_work_survives_repeated_launches(self):
        with tempfile.TemporaryDirectory() as folder:
            install, caller = self.make_case(Path(folder))
            temp = install / 'docs/temp'
            (temp / 'nested').mkdir(parents=True)
            (temp / 'nested/unknown.bin').write_bytes(b'unrecognized work')
            (temp / 'assembled.mkv').write_bytes(b'recoverable video sentinel')
            (temp / 'final-remux.log').write_bytes(b'failure diagnostic')
            before = {p.relative_to(temp): p.read_bytes() for p in temp.rglob('*') if p.is_file()}
            for _ in range(2):
                result = self.run_case(install, caller)
                self.assertEqual(result.returncode, 2, result.stdout + result.stderr)
                self.assertNotIn('PROCESSING_STARTED', result.stdout)
                after = {p.relative_to(temp): p.read_bytes() for p in temp.rglob('*') if p.is_file()}
                self.assertEqual(after, before)

    def test_missing_docs_and_file_at_temp_path(self):
        for missing_docs in (True, False):
            with self.subTest(missing_docs=missing_docs):
                with tempfile.TemporaryDirectory() as folder:
                    install, caller = self.make_case(Path(folder), docs=not missing_docs)
                    temp = install / 'docs/temp'
                    if not missing_docs:
                        temp.write_bytes(b'not a directory')
                    result = self.run_case(install, caller)
                    self.assertEqual(result.returncode, 2, result.stdout + result.stderr)
                    self.assertNotIn('PROCESSING_STARTED', result.stdout)
                    if not missing_docs:
                        self.assertEqual(temp.read_bytes(), b'not a directory')
                    else:
                        self.assertFalse((install / 'docs').exists())

    def test_warning_error_and_unknown_leftovers_are_retained(self):
        for outcome, code in (('warning', 1), ('error', 2), ('leftovers', 1)):
            with self.subTest(outcome=outcome):
                with tempfile.TemporaryDirectory() as folder:
                    install, caller = self.make_case(Path(folder))
                    result = self.run_case(install, caller, outcome)
                    self.assertEqual(result.returncode, code, result.stdout + result.stderr)
                    temp = install / 'docs/temp'
                    self.assertTrue(temp.is_dir())
                    if outcome == 'leftovers':
                        self.assertEqual((temp / 'unexpected/sentinel.txt').read_text().strip(), 'preserve me')
                    else:
                        self.assertTrue((temp / 'stage-output.txt').exists())
                        self.assertIn('synthetic diagnostic', (temp / 'final-remux.log').read_text())

    def test_second_launch_cannot_take_first_runs_workspace(self):
        with tempfile.TemporaryDirectory() as folder:
            install, caller = self.make_case(Path(folder))
            env = os.environ.copy()
            env.update(WORKSPACE_TEST_SCRIPT=str(install / 'run.bat'), TEST_OUTCOME='hold')
            proc = subprocess.Popen(['cmd.exe', '/d', '/v:off', '/c', 'wrapper.bat'],
                                    cwd=caller, env=env, stdin=subprocess.PIPE,
                                    stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
            try:
                # Bounded marker wait: a startup regression must not hang CI.
                marker = install / '.test-owned-marker'
                deadline = time.monotonic() + 10
                while not marker.exists() and proc.poll() is None and time.monotonic() < deadline:
                    time.sleep(0.05)
                self.assertTrue(marker.exists(), 'first run did not acquire workspace within 10 seconds')
                second = self.run_case(install, caller)
                self.assertEqual(second.returncode, 2, second.stdout + second.stderr)
                self.assertNotIn('PROCESSING_STARTED', second.stdout)
                out, err = proc.communicate('\n', timeout=30)
                self.assertEqual(proc.returncode, 0, out + err)
                self.assertFalse((install / 'docs/temp').exists())
            finally:
                if proc.poll() is None:
                    proc.kill()
                    proc.communicate()


if __name__ == '__main__':
    unittest.main(verbosity=2)
