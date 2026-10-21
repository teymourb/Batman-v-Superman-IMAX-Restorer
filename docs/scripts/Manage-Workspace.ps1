# Windows PowerShell 5.1. Fixed-workspace lifecycle; never traverses/deletes unknown work.
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][ValidateSet('Supervise','Prepare','Cleanup','CheckOwned')][string]$Action,
    [Parameter(Mandatory=$true)][ValidateSet('BvS','Asteroid')][string]$Film,
    [string]$Launcher,
    [string]$InstallationRoot
)
$ErrorActionPreference = 'Stop'
if (-not $InstallationRoot) { $InstallationRoot = Join-Path $PSScriptRoot '..\..' }
$root = [IO.Path]::GetFullPath($InstallationRoot)
if ($root -ne [IO.Path]::GetPathRoot($root)) { $root = $root.TrimEnd('\') }
$docs = Join-Path $root 'docs'
$work = Join-Path $docs 'temp'
$logs = Join-Path $docs 'logs'
$marker = Join-Path $docs '.restorer-workspace.json'
$leasePath = Join-Path $docs '.restorer-workspace.lock'
$allowed = if ($Film -eq 'BvS') { @('BvS.mkv','BvS_1.43.mkv','BvS_1.78.mkv','BvS_10s.mkv','BvS_10s_Windowboxed.mkv','BvS_1i.mkv','BvS_1i_Cropped.mkv','BvS_2s.mkv','BvS_2s_Windowboxed.mkv','BvS_3i.mkv','BvS_3i_Cropped.mkv','BvS_4s.mkv','BvS_4s_Windowboxed.mkv','BvS_5i.mkv','BvS_5i_Cropped.mkv','BvS_6s.mkv','BvS_6s_Windowboxed.mkv','BvS_7i.mkv','BvS_7i_Cropped.mkv','BvS_8s.mkv','BvS_8s_Windowboxed.mkv','BvS_9i.mkv','BvS_9i_Cropped.mkv') } else { @('AsteroidCity.mkv','AsteroidCity_10a.mkv','AsteroidCity_10a_Pillarboxed.mkv','AsteroidCity_10a_Windowboxed.mkv','AsteroidCity_11s.mkv','AsteroidCity_11s_Cropped.mkv','AsteroidCity_12a.mkv','AsteroidCity_12a_Pillarboxed.mkv','AsteroidCity_12a_Windowboxed.mkv','AsteroidCity_13s.mkv','AsteroidCity_13s_Cropped.mkv','AsteroidCity_2a.mkv','AsteroidCity_2a_Pillarboxed.mkv','AsteroidCity_2a_Windowboxed.mkv','AsteroidCity_3s.mkv','AsteroidCity_3s_Cropped.mkv','AsteroidCity_4a.mkv','AsteroidCity_4a_Pillarboxed.mkv','AsteroidCity_4a_Windowboxed.mkv','AsteroidCity_5s.mkv','AsteroidCity_5s_Cropped.mkv','AsteroidCity_6a.mkv','AsteroidCity_6a_Pillarboxed.mkv','AsteroidCity_6a_Windowboxed.mkv','AsteroidCity_7s.mkv','AsteroidCity_7s_Cropped.mkv','AsteroidCity_8a.mkv','AsteroidCity_8a_Pillarboxed.mkv','AsteroidCity_8a_Windowboxed.mkv','AsteroidCity_9s.mkv','AsteroidCity_9s_Cropped.mkv','AsteroidCity_Logo1_Cropped.mkv','AsteroidCity_Logo2.mkv','AsteroidCity_Logo2_Cropped.mkv','AsteroidCity_Logo2_Letterboxed.mkv','AsteroidCity_S.mkv','AsteroidCity_b.mkv','AsteroidCity_b_Cropped.mkv','AsteroidCity_b_Letterboxed.mkv') }

$allowed += 'extracted-video.bin'

function Assert-NoLinks([string]$Path) {
    $current = [IO.Path]::GetFullPath($Path)
    while ($current) {
        $item = Get-Item -LiteralPath $current -Force -ErrorAction SilentlyContinue
        if ($item -and ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
            throw "Linked/reparse paths are not safe for workspace cleanup: $current"
        }
        $parent = [IO.Directory]::GetParent($current)
        if (-not $parent) { break }
        $current = $parent.FullName
    }
}
function Test-Within([string]$Path, [string]$Parent) {
    $value = [IO.Path]::GetFullPath($Path).TrimEnd('\')
    $boundary = [IO.Path]::GetFullPath($Parent).TrimEnd('\')
    return $value.Equals($boundary, [StringComparison]::OrdinalIgnoreCase) -or
        $value.StartsWith($boundary + '\', [StringComparison]::OrdinalIgnoreCase)
}
function Assert-Boundaries {
    Assert-NoLinks $root
    foreach ($path in @($work,$logs,$marker,$leasePath)) { Assert-NoLinks $path }
    if (-not [IO.Directory]::Exists($docs)) { throw 'The docs directory is missing.' }
    foreach ($path in @($env:file,$env:folder)) {
        if (-not [string]::IsNullOrWhiteSpace($path)) {
            Assert-NoLinks $path
            if ((Test-Within $path $work) -or (Test-Within $path $logs)) {
                throw 'The source and output folder must be outside docs\temp and docs\logs.'
            }
        }
    }
}
function Read-Owner {
    Assert-Boundaries
    if (-not [IO.File]::Exists($marker)) { throw 'Unrecognized temporary work: preserve or move docs\temp manually; nothing was deleted.' }
    $owner = Get-Content -LiteralPath $marker -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($owner.Schema -ne 1 -or $owner.Film -ne $Film -or $owner.Root -cne $root -or
        -not $owner.Token -or -not (Test-Within $owner.LogDirectory $logs)) {
        throw 'Workspace ownership record is invalid. Nothing was deleted.'
    }
    Assert-NoLinks $owner.LogDirectory
    return $owner
}
function Assert-NoLegacyWorkers {
    # Old launchers had no job/lease. Refuse migration while a process still uses
    # this installation; inaccessible relevant executables also fail closed.
    $names = @('ffmpeg.exe','HandBrakeCLI.exe','avidemux_cli.exe','mkvmerge.exe','mkvextract.exe','cmd.exe','powershell.exe')
    $processes = @(Get-CimInstance Win32_Process -ErrorAction Stop)
    $ancestors = @{}; $ancestorId = [uint32]$PID
    while ($ancestorId -and -not $ancestors.ContainsKey($ancestorId)) {
        $ancestors[$ancestorId] = $true
        $ancestor = $processes | Where-Object { $_.ProcessId -eq $ancestorId } | Select-Object -First 1
        if (-not $ancestor) { break }
        $ancestorId = [uint32]$ancestor.ParentProcessId
    }
    foreach ($process in $processes) {
        if ($ancestors.ContainsKey([uint32]$process.ProcessId) -or $names -notcontains $process.Name) { continue }
        if (-not $process.ExecutablePath) {
            if ($process.Name -notin @('cmd.exe','powershell.exe')) { throw 'A media process cannot be inspected. Close earlier restorations before retrying.' }
            continue
        }
        if ((Test-Within $process.ExecutablePath $root) -or
            ($process.CommandLine -and $process.CommandLine.IndexOf($root,[StringComparison]::OrdinalIgnoreCase) -ge 0)) {
            throw 'An earlier process still references this installation. Close it before discarding temporary media.'
        }
    }
}
function Remove-OwnedMedia {
    Assert-Boundaries
    if (-not (Test-Path -LiteralPath $work)) {
        if (Test-Path -LiteralPath $marker) { $null = Read-Owner; Remove-Item -LiteralPath $marker }
        return
    }
    $legacy = -not (Test-Path -LiteralPath $marker)
    if ($legacy) { Assert-NoLegacyWorkers } else { $null = Read-Owner }
    if (-not [IO.Directory]::Exists($work)) { throw 'The workspace is not a directory. Nothing was deleted.' }
    # Inspect every entry before modifying anything. Legacy diagnostics have an
    # exact allowlist and are archived; no recursive deletion is ever used.
    $entries = @(Get-ChildItem -LiteralPath $work -Force)
    $diagnostics = @()
    $legacyFiles = @('processing.log','final-remux.log','source-fingerprint.json')
    $stages = @('mkvmerge-version','mkvextract-version','ffmpeg-version','identify','extract','fingerprint')
    $diagnosticNames = @('extracted-video.bin')
    foreach ($stage in $stages) { $diagnosticNames += ($stage + '.stdout.log'); $diagnosticNames += ($stage + '.stderr.log') }
    foreach ($entry in $entries) {
        if ($entry.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "Linked temporary entry retained: $($entry.FullName)" }
        if ($legacy -and $entry.PSIsContainer -and $entry.Name -match '^source-check-[a-fA-F0-9]{32}$') {
            foreach ($child in @(Get-ChildItem -LiteralPath $entry.FullName -Force)) {
                if ($child.PSIsContainer -or ($child.Attributes -band [IO.FileAttributes]::ReparsePoint) -or $diagnosticNames -notcontains $child.Name) {
                    throw "Unrecognized previous diagnostic retained: $($child.FullName)"
                }
            }
            $diagnostics += $entry
        } elseif ($legacy -and -not $entry.PSIsContainer -and $legacyFiles -contains $entry.Name) {
            $diagnostics += $entry
        } elseif ($entry.PSIsContainer -or $allowed -notcontains $entry.Name) {
            throw "Unrecognized working file retained: $($entry.FullName). Move it aside before retrying."
        }
    }
    if ($diagnostics.Count) {
        $archive = Join-Path $logs ('legacy-' + [Guid]::NewGuid().ToString('N'))
        [IO.Directory]::CreateDirectory($archive) | Out-Null
        foreach ($entry in $diagnostics) {
            Assert-NoLinks $entry.FullName
            # Fingerprint extraction is generated media, not a log; discard that
            # one exact scratch file rather than archiving gigabytes as a log.
            if ($entry.PSIsContainer) {
                $scratch = Join-Path $entry.FullName 'extracted-video.bin'
                if ([IO.File]::Exists($scratch)) { Remove-Item -LiteralPath $scratch }
            }
            Move-Item -LiteralPath $entry.FullName -Destination (Join-Path $archive $entry.Name)
        }
    }
    foreach ($entry in $entries) {
        if ($diagnostics -contains $entry) { continue }
        Assert-NoLinks $entry.FullName
        if ($entry.Attributes -band [IO.FileAttributes]::ReadOnly) { throw "Read-only work retained: $($entry.FullName)" }
        Remove-Item -LiteralPath $entry.FullName -ErrorAction Stop
    }
    # Nonrecursive final removal protects unknown files created after inspection.
    [IO.Directory]::Delete($work, $false)
    if (Test-Path -LiteralPath $marker) { Remove-Item -LiteralPath $marker }
}
function New-Workspace([string]$Token, [string]$LogDirectory) {
    Assert-Boundaries
    if (Test-Path -LiteralPath $work) { Remove-OwnedMedia }
    elseif (Test-Path -LiteralPath $marker) { $null = Read-Owner; Remove-Item -LiteralPath $marker }
    [IO.Directory]::CreateDirectory($LogDirectory) | Out-Null
    [IO.Directory]::CreateDirectory($work) | Out-Null
    $owner = [ordered]@{Schema=1; Film=$Film; Root=$root; Token=$Token; LogDirectory=$LogDirectory}
    # CreateNew refuses a conflicting marker rather than replacing unrelated data.
    $bytes = [Text.UTF8Encoding]::new($false).GetBytes(($owner | ConvertTo-Json))
    $stream = [IO.File]::Open($marker, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
    try { $stream.Write($bytes,0,$bytes.Length) } finally { $stream.Dispose() }
}

# A named Job Object outlives its supervisor while terminated children are draining.
# Refusing an existing job closes the crash/restart window before stale-work deletion.
function Initialize-Native {
    if ('RestorerWorkspaceJob' -as [type]) { return }
    Add-Type -TypeDefinition @'
using System;
using System.ComponentModel;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;
public sealed class RestorerWorkspaceJob : IDisposable {
    IntPtr job;
    [StructLayout(LayoutKind.Sequential)] struct IO_COUNTERS { public ulong a,b,c,d,e,f; }
    [StructLayout(LayoutKind.Sequential)] struct BASIC_LIMIT {
        public long a,b; public uint Flags; public UIntPtr Min,Max; public uint Active;
        public UIntPtr Affinity; public uint Priority,Scheduling;
    }
    [StructLayout(LayoutKind.Sequential)] struct EXTENDED_LIMIT {
        public BASIC_LIMIT Basic; public IO_COUNTERS Io;
        public UIntPtr ProcessMemory,JobMemory,PeakProcess,PeakJob;
    }
    [StructLayout(LayoutKind.Sequential)] struct ACCOUNTING {
        public long a,b,c,d; public uint PageFaults,Total,Active,Terminated;
    }
    [StructLayout(LayoutKind.Sequential, CharSet=CharSet.Unicode)] struct STARTUP {
        public int cb; public string reserved,desktop,title;
        public uint x,y,w,h,xc,yc,fill,flags; public short show,reserved2;
        public IntPtr reservedPtr,input,output,error;
    }
    [StructLayout(LayoutKind.Sequential)] struct PROCESS {
        public IntPtr process,thread; public uint pid,tid;
    }
    [DllImport("kernel32.dll", CharSet=CharSet.Unicode, SetLastError=true)] static extern IntPtr CreateJobObject(IntPtr a,string n);
    [DllImport("kernel32.dll",SetLastError=true)] static extern bool SetInformationJobObject(IntPtr j,int c,ref EXTENDED_LIMIT i,int s);
    [DllImport("kernel32.dll",SetLastError=true)] static extern bool QueryInformationJobObject(IntPtr j,int c,out ACCOUNTING i,int s,IntPtr r);
    [DllImport("kernel32.dll",CharSet=CharSet.Unicode,SetLastError=true)] static extern bool CreateProcess(string app,StringBuilder cmd,IntPtr pa,IntPtr ta,bool inherit,uint flags,IntPtr env,string cwd,ref STARTUP si,out PROCESS pi);
    [DllImport("kernel32.dll",SetLastError=true)] static extern bool AssignProcessToJobObject(IntPtr j,IntPtr p);
    [DllImport("kernel32.dll",SetLastError=true)] static extern uint ResumeThread(IntPtr t);
    [DllImport("kernel32.dll")] static extern uint WaitForSingleObject(IntPtr p,uint ms);
    [DllImport("kernel32.dll",SetLastError=true)] static extern bool GetExitCodeProcess(IntPtr p,out uint code);
    [DllImport("kernel32.dll",SetLastError=true)] static extern bool TerminateProcess(IntPtr p,uint code);
    [DllImport("kernel32.dll",SetLastError=true)] static extern bool TerminateJobObject(IntPtr j,uint code);
    [DllImport("kernel32.dll")] static extern bool CloseHandle(IntPtr h);
    [DllImport("kernel32.dll")] static extern IntPtr GetStdHandle(int n);
    [DllImport("kernel32.dll",SetLastError=true)] static extern bool SetHandleInformation(IntPtr h,uint mask,uint flags);
    public RestorerWorkspaceJob(string name) {
        job=CreateJobObject(IntPtr.Zero,name); int error=Marshal.GetLastWin32Error();
        if(job==IntPtr.Zero) throw new Win32Exception(error);
        if(error==183) { CloseHandle(job); job=IntPtr.Zero; throw new InvalidOperationException("A previous restoration still has active processes. Wait for it to stop before retrying."); }
        var info=new EXTENDED_LIMIT(); info.Basic.Flags=0x2000;
        if(!SetInformationJobObject(job,9,ref info,Marshal.SizeOf(info))) { error=Marshal.GetLastWin32Error(); CloseHandle(job); job=IntPtr.Zero; throw new Win32Exception(error); }
    }
    public int Run(string launcher,string cwd) {
        var si=new STARTUP(); si.cb=Marshal.SizeOf(si); PROCESS pi;
        si.flags=0x100; si.input=GetStdHandle(-10); si.output=GetStdHandle(-11); si.error=GetStdHandle(-12);
        foreach(var h in new[]{si.input,si.output,si.error}) {
            if(h!=IntPtr.Zero && h!=new IntPtr(-1) && !SetHandleInformation(h,1,1)) throw new Win32Exception();
        }
        string shell=Environment.GetEnvironmentVariable("ComSpec");
        var cmd=new StringBuilder("\""+shell+"\" /d /v:off /s /c \"\""+launcher+"\" --selected\"");
        if(!CreateProcess(shell,cmd,IntPtr.Zero,IntPtr.Zero,true,4,IntPtr.Zero,cwd,ref si,out pi)) throw new Win32Exception();
        try {
            if(!AssignProcessToJobObject(job,pi.process)) { int e=Marshal.GetLastWin32Error(); TerminateProcess(pi.process,2); WaitForSingleObject(pi.process,30000); throw new Win32Exception(e); }
            if(ResumeThread(pi.thread)==0xffffffff) { TerminateProcess(pi.process,2); throw new Win32Exception(); }
            WaitForSingleObject(pi.process,0xffffffff); uint code;
            if(!GetExitCodeProcess(pi.process,out code)) throw new Win32Exception();
            Stop(); return unchecked((int)code);
        } finally { CloseHandle(pi.thread); CloseHandle(pi.process); }
    }
    public void Stop() {
        if(job==IntPtr.Zero) return;
        if(!TerminateJobObject(job,2)) throw new Win32Exception();
        for(int i=0;i<300;i++) {
            ACCOUNTING a;
            if(!QueryInformationJobObject(job,1,out a,Marshal.SizeOf(typeof(ACCOUNTING)),IntPtr.Zero)) throw new Win32Exception();
            if(a.Active==0) return; Thread.Sleep(100);
        }
        throw new InvalidOperationException("Worker processes have not stopped; temporary work was retained.");
    }
    public void Dispose() { if(job!=IntPtr.Zero) { CloseHandle(job); job=IntPtr.Zero; } }
}
'@
}

$lease = $null; $job = $null
try {
    Assert-Boundaries
    if ($Action -eq 'CheckOwned') {
        $owner = Read-Owner
        if (-not $env:RESTORER_WORKSPACE_TOKEN -or $owner.Token -cne $env:RESTORER_WORKSPACE_TOKEN -or
            $owner.LogDirectory -cne $env:RESTORER_LOG_DIRECTORY -or -not [IO.Directory]::Exists($work)) {
            throw 'This processing entry requires the supervised setup workflow.'
        }
        # The supervisor must actually hold the exclusive lease.
        $probe = $null
        try { $probe = [IO.File]::Open($leasePath,[IO.FileMode]::Open,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None) }
        catch [IO.IOException] {
            if (($_.Exception.HResult -band 65535) -in @(32,33)) { exit 0 }
            throw
        }
        finally { if ($probe) { $probe.Dispose() } }
        throw 'No active workspace supervisor owns this run.'
    }
    try { $lease = [IO.File]::Open($leasePath,[IO.FileMode]::OpenOrCreate,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None) }
    catch { throw 'Another restoration or cleanup is active. Wait for it to finish; nothing was deleted.' }
    Initialize-Native
    $hash = [Security.Cryptography.SHA256]::Create()
    try { $identity = [BitConverter]::ToString($hash.ComputeHash([Text.Encoding]::UTF8.GetBytes($root.ToUpperInvariant()))).Replace('-','') }
    finally { $hash.Dispose() }
    $job = New-Object RestorerWorkspaceJob ('Local\FilmRestorer-' + $identity)
    if ($Action -eq 'Cleanup') { Remove-OwnedMedia; exit 0 }
    $token = [Guid]::NewGuid().ToString('N')
    $logDirectory = Join-Path $logs ('run-' + $token)
    New-Workspace $token $logDirectory
    if ($Action -eq 'Prepare') { exit 0 }
    if (-not $Launcher -or -not [IO.File]::Exists($Launcher)) { throw 'The restoration launcher is missing.' }
    Assert-NoLinks $Launcher
    $env:RESTORER_WORKSPACE_TOKEN = $token
    $env:RESTORER_LOG_DIRECTORY = $logDirectory
    $result = $job.Run([IO.Path]::GetFullPath($Launcher), $root)
    if ($result -eq 0) {
        try { Remove-OwnedMedia }
        catch { Write-Host ('[STOP] Output was created, but temporary cleanup did not finish: ' + $_.Exception.Message); exit 2 }
    }
    exit $result
} catch {
    Write-Host ('[STOP] ' + $_.Exception.Message)
    exit 2
} finally {
    if ($job) { $job.Dispose() }
    if ($lease) { $lease.Dispose() }
}
