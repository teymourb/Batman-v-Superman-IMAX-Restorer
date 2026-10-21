"""Real Windows workspace ownership, safe deletion and process-tree supervision."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import time
import unittest

ROOT = Path(__file__).resolve().parents[1]
HELPER = ROOT / 'docs/scripts/Manage-Workspace.ps1'
FILM = 'BvS' if (ROOT / 'Batman-v-Superman-IMAX-Restorer.bat').exists() else 'Asteroid'
MEDIA = 'BvS.mkv' if FILM == 'BvS' else 'AsteroidCity.mkv'


class CleanupContract(unittest.TestCase):
    def test_shared_helper_has_bounded_ownership_and_process_tree(self):
        text = HELPER.read_text()
        self.assertIn('[IO.FileMode]::CreateNew', text)
        self.assertIn('[IO.FileShare]::None', text)
        self.assertIn('AssignProcessToJobObject', text)
        self.assertIn('info.Basic.Flags=0x2000', text)
        self.assertIn('[IO.Directory]::Delete($work, $false)', text)
        self.assertNotIn('Remove-Item -Recurse', text)


@unittest.skipUnless(os.name == 'nt', 'requires Windows job objects and filesystem semantics')
class WindowsCleanup(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name)
        self.install = self.base / 'Restorer with spaces & (brackets)'
        self.scripts = self.install / 'docs/scripts'
        self.scripts.mkdir(parents=True)
        shutil.copy2(HELPER, self.scripts / HELPER.name)
        self.work = self.install / 'docs/temp'
        self.marker = self.install / 'docs/.restorer-workspace.json'
        self.source = self.base / 'source.mkv'
        self.source.write_bytes(b'untouched source')
        self.destination = self.base / 'output'
        self.destination.mkdir()
        self.final = self.destination / 'finished.mkv'
        self.final.write_bytes(b'untouched final output')
        self.env = os.environ.copy()
        self.env.pop('RESTORER_WORKSPACE_TOKEN', None)
        self.env.pop('RESTORER_LOG_DIRECTORY', None)
        self.env.update(file=str(self.source), folder=str(self.destination))

    def command(self, action, launcher=None):
        command = ['powershell.exe', '-NoProfile', '-ExecutionPolicy', 'Bypass',
                   '-File', str(self.scripts / HELPER.name), '-Action', action,
                   '-Film', FILM]
        if launcher:
            command += ['-Launcher', str(launcher)]
        return command

    def run_helper(self, action, launcher=None, env=None):
        result = subprocess.run(self.command(action, launcher), env=env or self.env,
                                cwd=self.base, capture_output=True, text=True, timeout=60)
        self.assertEqual(self.source.read_bytes(), b'untouched source')
        self.assertEqual(self.final.read_bytes(), b'untouched final output')
        return result

    def prepare(self):
        result = self.run_helper('Prepare')
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        return json.loads(self.marker.read_text(encoding='utf-8-sig'))

    def launcher(self, outcome=0, orphan=False, hold=False):
        script = self.install / 'fake.bat'
        lines = ['@echo off',
                 'powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0docs\\scripts\\Manage-Workspace.ps1" -Action CheckOwned -Film ' + FILM,
                 'if errorlevel 1 exit /b 9',
                 '> "docs\\temp\\' + MEDIA + '" echo owned generated media',
                 '> "%RESTORER_LOG_DIRECTORY%\\processing.log" echo diagnostic stays']
        if orphan:
            (self.install / 'orphan.ps1').write_text(
                "[IO.File]::WriteAllText((Join-Path $PSScriptRoot 'child-ready'), 'ready')\n"
                "Start-Sleep -Seconds 4\n"
                "[IO.File]::WriteAllText((Join-Path $PSScriptRoot 'orphan-wrote'), 'unsafe')\n")
            lines += ['start "" /b powershell.exe -NoProfile -File "%~dp0orphan.ps1"',
                      'powershell.exe -NoProfile -Command "$until=[DateTime]::UtcNow.AddSeconds(10); while (-not (Test-Path -LiteralPath (Join-Path $env:RESTORER_TEST_INSTALL ''child-ready''))) { if ([DateTime]::UtcNow -gt $until) { exit 3 }; Start-Sleep -Milliseconds 50 }"',
                      'if errorlevel 1 exit /b 8']
        if hold:
            lines += ['> "%~dp0run-ready" echo ready', 'ping -n 30 127.0.0.1 >nul']
        lines += ['exit /b ' + str(outcome)]
        script.write_bytes(('\r\n'.join(lines) + '\r\n').encode())
        self.env['RESTORER_TEST_INSTALL'] = str(self.install)
        return script

    def test_owned_media_cleanup_preserves_logs_source_and_final(self):
        owner = self.prepare()
        (self.work / MEDIA).write_bytes(b'owned media')
        (self.work / 'extracted-video.bin').write_bytes(b'interrupted source-check scratch')
        log = Path(owner['LogDirectory']) / 'processing.log'
        log.write_bytes(b'keep diagnostic')
        result = self.run_helper('Cleanup')
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertFalse(self.work.exists())
        self.assertFalse(self.marker.exists())
        self.assertEqual(log.read_bytes(), b'keep diagnostic')
        result = self.run_helper('Cleanup')
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_restart_discards_only_previously_owned_media(self):
        old = self.prepare()
        (self.work / MEDIA).write_bytes(b'interrupted expensive media')
        old_log = Path(old['LogDirectory']) / 'processing.log'
        old_log.write_bytes(b'previous failure')
        new = self.prepare()
        self.assertNotEqual(old['Token'], new['Token'])
        self.assertEqual(list(self.work.iterdir()), [])
        self.assertEqual(old_log.read_bytes(), b'previous failure')

    def test_legacy_migration_archives_logs_but_unknown_and_corrupt_owner_stop(self):
        self.work.mkdir()
        known = self.work / MEDIA
        known.write_bytes(b'legacy work')
        (self.work / 'processing.log').write_bytes(b'legacy diagnostic')
        result = self.run_helper('Prepare')
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(list(self.work.iterdir()), [])
        archived = list((self.install / 'docs/logs').glob('legacy-*/processing.log'))
        self.assertEqual(len(archived), 1)
        self.assertEqual(archived[0].read_bytes(), b'legacy diagnostic')
        known.write_bytes(b'owned work')
        unknown = self.work / 'important.txt'
        unknown.write_bytes(b'unknown user data')
        result = self.run_helper('Cleanup')
        self.assertEqual(result.returncode, 2, result.stdout + result.stderr)
        self.assertEqual(known.read_bytes(), b'owned work')
        self.assertEqual(unknown.read_bytes(), b'unknown user data')
        unknown.unlink()
        self.marker.write_text('{broken json')
        result = self.run_helper('Prepare')
        self.assertEqual(result.returncode, 2, result.stdout + result.stderr)
        self.assertEqual(known.read_bytes(), b'owned work')

    def test_source_or_destination_in_work_or_logs_is_refused(self):
        owner = self.prepare()
        inside = self.work / 'source.mkv'
        inside.write_bytes(b'protected')
        for key, value in [('file', str(inside)), ('folder', str(self.work)),
                           ('folder', owner['LogDirectory'])]:
            with self.subTest(key=key, value=value):
                env = self.env.copy(); env[key] = value
                result = self.run_helper('Prepare', env=env)
                self.assertEqual(result.returncode, 2, result.stdout + result.stderr)
                self.assertEqual(inside.read_bytes(), b'protected')

    def test_marker_alone_and_similarly_named_sibling_do_not_block(self):
        self.prepare()
        self.work.rmdir()
        sibling = self.install / 'docs/temp2'
        sibling.mkdir()
        sentinel = sibling / 'source.mkv'
        sentinel.write_bytes(b'sibling source')
        self.env['file'] = str(sentinel)
        result = self.run_helper('Prepare')
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(sentinel.read_bytes(), b'sibling source')
        self.assertTrue(self.work.is_dir())

    def test_locked_generated_file_cleanup_fails_and_retains_bytes(self):
        import ctypes
        from ctypes import wintypes
        self.prepare()
        media = self.work / MEDIA
        media.write_bytes(b'locked generated work')
        create = ctypes.WinDLL('kernel32', use_last_error=True).CreateFileW
        create.argtypes = [wintypes.LPCWSTR, wintypes.DWORD, wintypes.DWORD,
                           wintypes.LPVOID, wintypes.DWORD, wintypes.DWORD, wintypes.HANDLE]
        create.restype = wintypes.HANDLE
        close = ctypes.WinDLL('kernel32', use_last_error=True).CloseHandle
        close.argtypes = [wintypes.HANDLE]
        handle = create(str(media), 0x80000000, 1, None, 3, 0, None)
        self.assertNotEqual(handle, wintypes.HANDLE(-1).value)
        try:
            result = self.run_helper('Cleanup')
            self.assertEqual(result.returncode, 2, result.stdout + result.stderr)
            self.assertEqual(media.read_bytes(), b'locked generated work')
            self.assertTrue(self.marker.exists())
            result = self.run_helper('Supervise', self.launcher())
            self.assertEqual(result.returncode, 2, result.stdout + result.stderr)
            self.assertEqual(media.read_bytes(), b'locked generated work')
            self.assertFalse(any((self.install / 'docs/logs').glob('run-*/processing.log')))
        finally:
            close(handle)
        result = self.run_helper('Cleanup')
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_junction_root_and_unknown_nested_directory_are_not_traversed(self):
        self.prepare()
        outside = self.base / 'external'
        outside.mkdir()
        sentinel = outside / MEDIA
        sentinel.write_bytes(b'external sentinel')
        link = self.work / 'linked'
        result = subprocess.run(['cmd.exe', '/d', '/c', 'mklink', '/J', str(link), str(outside)],
                                capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        try:
            result = self.run_helper('Cleanup')
            self.assertEqual(result.returncode, 2, result.stdout + result.stderr)
            self.assertEqual(sentinel.read_bytes(), b'external sentinel')
        finally:
            os.rmdir(link)
        os.rmdir(self.work)
        result = subprocess.run(['cmd.exe', '/d', '/c', 'mklink', '/J', str(self.work), str(outside)],
                                capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        try:
            result = self.run_helper('Prepare')
            self.assertEqual(result.returncode, 2, result.stdout + result.stderr)
            self.assertEqual(sentinel.read_bytes(), b'external sentinel')
        finally:
            os.rmdir(self.work)

    def test_supervisor_cleans_success_retains_failure_and_rejects_unsupervised_entry(self):
        for outcome in (0, 1, 2):
            with self.subTest(outcome=outcome):
                result = self.run_helper('Supervise', self.launcher(outcome))
                self.assertEqual(result.returncode, outcome, result.stdout + result.stderr)
                self.assertEqual(self.work.exists(), outcome != 0)
                logs = list((self.install / 'docs/logs').glob('run-*/processing.log'))
                self.assertGreaterEqual(len(logs), 1)
        result = self.run_helper('CheckOwned')
        self.assertEqual(result.returncode, 2, result.stdout + result.stderr)

    def test_lingering_child_is_stopped_before_cleanup(self):
        result = self.run_helper('Supervise', self.launcher(orphan=True))
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertTrue((self.install / 'child-ready').exists())
        self.assertFalse(self.work.exists())
        time.sleep(4.5)
        self.assertFalse((self.install / 'orphan-wrote').exists())

    def test_concurrent_cleanup_and_start_cannot_take_live_workspace(self):
        launcher = self.launcher(hold=True)
        proc = subprocess.Popen(self.command('Supervise', launcher), env=self.env,
                                cwd=self.base, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        try:
            deadline = time.monotonic() + 20
            while not (self.install / 'run-ready').exists():
                if proc.poll() is not None or time.monotonic() > deadline:
                    self.fail('Supervisor did not reach ready marker')
                time.sleep(.05)
            media = (self.work / MEDIA).read_bytes()
            for action in ('Cleanup', 'Prepare'):
                result = self.run_helper(action)
                self.assertEqual(result.returncode, 2, result.stdout + result.stderr)
                self.assertEqual((self.work / MEDIA).read_bytes(), media)
        finally:
            if proc.poll() is None:
                proc.kill()
            proc.communicate(timeout=30)
        # Killing the supervisor closes the job and stops its children. Cleanup may
        # briefly refuse while that named job drains; retry only until a fixed deadline.
        deadline = time.monotonic() + 10
        while True:
            result = self.run_helper('Cleanup')
            if result.returncode == 0:
                break
            if time.monotonic() > deadline:
                self.fail(result.stdout + result.stderr)
            time.sleep(.1)
        self.assertFalse(self.work.exists())


if __name__ == '__main__':
    unittest.main(verbosity=2)
