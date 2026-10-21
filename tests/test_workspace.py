"""Batch ownership wiring; cleanup/lease behavior is tested in test_workspace_cleanup.

This harness invokes the actual BAT ownership check without selection or media.
An unsupervised caller must never claim an existing or fresh workspace.
"""
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import unittest
from test_final_remux import ROOT, TEXT

HELPERS = TEXT.split(':: Workspace helpers:', 1)[1].split('\n:remux_warning', 1)[0]

class WorkspaceSource(unittest.TestCase):
    def test_batch_requires_supervisor_and_never_deletes_files(self):
        self.assertIn('call :prepare_workspace\nif errorlevel 1 exit /b 2', TEXT)
        self.assertIn('Manage-Workspace.ps1', HELPERS)
        self.assertIn('CheckOwned', HELPERS)
        self.assertNotRegex(TEXT, r'(?im)^\s*(del|rmdir)\s')
        self.assertNotRegex(HELPERS, r'(?im)^\s*mkdir\s')
        self.assertIn('RESTORER_LOG_DIRECTORY', TEXT)

@unittest.skipUnless(os.name == 'nt', 'requires actual Windows cmd.exe and PowerShell')
class WindowsWorkspace(unittest.TestCase):
    def test_unsupervised_worker_preserves_caller_and_existing_work(self):
        for old_work in (False, True):
            with self.subTest(old_work=old_work), tempfile.TemporaryDirectory() as folder:
                root=Path(folder)
                install=root/'Program & (owned)'; caller=root/'unrelated caller'
                scripts=install/'docs/scripts';scripts.mkdir(parents=True);caller.mkdir()
                shutil.copyfile(ROOT/'docs/scripts/Manage-Workspace.ps1',scripts/'Manage-Workspace.ps1')
                foreign=caller/'docs/temp';foreign.mkdir(parents=True)
                (foreign/'keep.txt').write_bytes(b'caller sentinel')
                temp=install/'docs/temp'
                if old_work:
                    temp.mkdir();(temp/'BvS.mkv').write_bytes(b'existing synthetic work')
                harness='@echo off\nsetlocal DisableDelayedExpansion\ncall :prepare_workspace\nif errorlevel 1 exit /b 2\necho PROCESSING_STARTED\npopd\nexit /b 0\n'+HELPERS
                harness=re.sub(r'(?im)^\s*PAUSE\s*$','rem unattended fixture',harness)
                (install/'run.bat').write_bytes(harness.replace('\n','\r\n').encode())
                (caller/'wrapper.bat').write_bytes(b'@echo off\r\ncall "%WORKSPACE_TEST_SCRIPT%"\r\nexit /b %errorlevel%\r\n')
                env=os.environ.copy()
                env['WORKSPACE_TEST_SCRIPT']=str(install/'run.bat')
                for name in ('RESTORER_WORKSPACE_TOKEN','RESTORER_LOG_DIRECTORY'):env.pop(name,None)
                result=subprocess.run(['cmd.exe','/d','/v:off','/c','wrapper.bat'],cwd=caller,env=env,capture_output=True,text=True,input='\n',timeout=30)
                self.assertEqual(result.returncode,2,result.stdout+result.stderr)
                self.assertNotIn('PROCESSING_STARTED',result.stdout)
                self.assertEqual((foreign/'keep.txt').read_bytes(),b'caller sentinel')
                if old_work:self.assertEqual((temp/'BvS.mkv').read_bytes(),b'existing synthetic work')
                else:self.assertFalse(temp.exists())

if __name__ == '__main__':unittest.main(verbosity=2)
