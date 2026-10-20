# Windows PowerShell 5.1. Mandatory known-source check; no override or cached pass.
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][ValidateSet('BvS','Asteroid')][string]$Film,
    [Parameter(Mandatory=$true)][string]$Source,
    [Parameter(Mandatory=$true)][string]$WorkDirectory,
    [string]$InstallationRoot
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($InstallationRoot)) { $InstallationRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..')) }
# Presentation only: update one bounded line in an interactive console.
# Redirected output remains ordinary newline-delimited text for logs and tests.
$script:progressActive = $false
function Complete-SourceProgress {
    if ($script:progressActive) { Write-Host ''; $script:progressActive = $false }
}
function Write-SourceProgress([string]$Text) {
    if ([Console]::IsOutputRedirected) { Write-Host $Text; return }
    try { $width = [Math]::Min(120, [Console]::WindowWidth - 1) }
    catch { Write-Host $Text; return }
    if ($width -lt 20) { Write-Host $Text; return }
    $line = if ($Text.Length -gt $width) { $Text.Substring(0,$width - 3) + '...' } else { $Text }
    Write-Host -NoNewline ("`r" + $line.PadRight($width))
    $script:progressActive = $true
}
function Get-Sha256([string]$Path) {
    $stream = [IO.File]::OpenRead($Path); $sha = [Security.Cryptography.SHA256]::Create()
    try { return ([BitConverter]::ToString($sha.ComputeHash($stream))).Replace('-','').ToLowerInvariant() }
    finally { $sha.Dispose(); $stream.Dispose() }
}
function Quote-Argument([string]$Value) {
    $quoted = '"'; $slashes = 0
    foreach ($character in $Value.ToCharArray()) {
        if ($character -eq '\') { $slashes++; continue }
        if ($character -eq '"') { $quoted += ('\' * (2 * $slashes + 1)) + '"' }
        else { $quoted += ('\' * $slashes) + $character }
        $slashes = 0
    }
    return $quoted + ('\' * (2 * $slashes)) + '"'
}
function Check-Cancellation {
    if (-not [Console]::IsInputRedirected) {
        try { while ([Console]::KeyAvailable) {
            if ([Console]::ReadKey($true).Key -eq [ConsoleKey]::Q) {
                throw [OperationCanceledException]::new('Source check cancelled. Restoration has not started.')
            }
        } } catch [InvalidOperationException] { }
    }
}
function Invoke-CheckedTool([string]$Tool, [string[]]$Arguments, [string]$Stage, [bool]$AllowRawTimestampWarning = $false) {
    $stdout = Join-Path $script:diagnostics ($Stage + '.stdout.log')
    $stderr = Join-Path $script:diagnostics ($Stage + '.stderr.log')
    $start = New-Object Diagnostics.ProcessStartInfo
    $start.FileName = $Tool
    $start.Arguments = (($Arguments | ForEach-Object { Quote-Argument $_ }) -join ' ')
    $start.UseShellExecute = $false; $start.CreateNoWindow = $true
    $start.RedirectStandardOutput = $true; $start.RedirectStandardError = $true
    $process = New-Object Diagnostics.Process
    $process.StartInfo = $start
    $out = [IO.File]::Open($stdout, 'CreateNew', 'Write', 'Read')
    $err = [IO.File]::Open($stderr, 'CreateNew', 'Write', 'Read')
    $started = $false; $outCopy = $null; $errCopy = $null
    try {
        if (-not $process.Start()) { throw "Cannot start $Stage" }
        $started = $true
        $outCopy = $process.StandardOutput.BaseStream.CopyToAsync($out)
        $errCopy = $process.StandardError.BaseStream.CopyToAsync($err)
        $timer = [Diagnostics.Stopwatch]::StartNew(); $next = 10
        while (-not $process.WaitForExit(250)) {
            Check-Cancellation
            if ($timer.Elapsed.TotalSeconds -ge $next) {
                Write-SourceProgress ("Checking source: {0}; elapsed {1} seconds. No encoding. Press Q to cancel." -f $Stage, [int]$timer.Elapsed.TotalSeconds)
                $next += 10
            }
        }
        $process.WaitForExit()
        $null = $outCopy.GetAwaiter().GetResult()
        $null = $errCopy.GetAwaiter().GetResult()
        if ($process.ExitCode -ne 0) { throw "$Stage failed or reported warnings (exit $($process.ExitCode)). See $script:diagnostics" }
    } finally {
        Complete-SourceProgress
        try { if ($started -and -not $process.HasExited) { $process.Kill(); $process.WaitForExit() } }
        finally {
            try { if ($outCopy) { $null = $outCopy.GetAwaiter().GetResult() }; if ($errCopy) { $null = $errCopy.GetAwaiter().GetResult() } }
            finally { $process.Dispose(); $out.Dispose(); $err.Dispose() }
        }
    }
    # Raw elementary HEVC has no container timestamps. Permit only this exact
    # known hash-muxer warning; all other diagnostics stop the check.
    $diagnosticText = [IO.File]::ReadAllText($stderr).Trim()
    $knownTimestampWarning = '\A\[hash @ [0-9a-fA-F]+\] Timestamps are unset in a packet for stream 0\. This is deprecated and will stop working in the future\. Fix your code to set the timestamps properly\.?\z'
    if ($diagnosticText.Length -ne 0 -and -not ($AllowRawTimestampWarning -and $diagnosticText -match $knownTimestampWarning)) { throw "$Stage reported diagnostics. See $stderr" }
    return $stdout
}
$expected = if ($Film -eq 'BvS') { '58371280f7c8debbf2a87fa1bad9e6b97ae6f83d49d981489f724608f9e0781c' } else { '203c7f5e1fc79013282c7a3218228818e5ecb60a04fd55ac420ce3de538373cd' }
$record = [ordered]@{ schema_version=1; film=$Film; status='NOT_COMPLETED'; started_utc=[DateTime]::UtcNow.ToString('o'); recipe=$(if ($Film -eq 'BvS') {'mkvextract-default-hevc;ffmpeg-copy-filter_units-remove_types=35|62;sha256-v1'} else {'mkvextract-default-avc;sha256-v1'}); expected_sha256=$expected; actual_sha256=$null; source=$Source; tools=[ordered]@{} }
$sourceHandle = $null; $scratch = $null; $recordPath = $null; $exitCode = 2
try {
    $work = Get-Item -LiteralPath $WorkDirectory
    if (-not $work.PSIsContainer -or ($work.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'Working directory must be an existing ordinary directory.' }
    $recordPath = Join-Path $work.FullName 'source-fingerprint.json'
    if (Test-Path -LiteralPath $recordPath) { throw 'An earlier source-check record exists. Preserve this workspace before starting again.' }
    $script:diagnostics = Join-Path $work.FullName ('source-check-' + [Guid]::NewGuid().ToString('N'))
    $null = [IO.Directory]::CreateDirectory($script:diagnostics)
    $scratch = Join-Path $script:diagnostics 'extracted-video.bin'
    $inputFile = Get-Item -LiteralPath $Source
    if ($inputFile.PSIsContainer -or $inputFile.Length -le 0 -or ($inputFile.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'Source must be a nonempty ordinary file.' }
    $Source = $inputFile.FullName
    $record.source = $Source
    # Hold against writes/deletion while tools identify/extract/hash the source.
    $sourceHandle = [IO.File]::Open($Source, 'Open', 'Read', 'Read')
    $inputFile.Refresh()
    $record.source_bytes = $sourceHandle.Length
    $record.source_last_write_utc = $inputFile.LastWriteTimeUtc.ToString('o')
    $rootItem = Get-Item -LiteralPath $InstallationRoot
    if (-not $rootItem.PSIsContainer -or ($rootItem.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'Installation root must be an ordinary directory.' }
    $root = $rootItem.FullName
    $merge = Join-Path $root 'docs\programs\mkvtoolnix\mkvmerge.exe'
    $extract = Join-Path $root 'docs\programs\mkvtoolnix\mkvextract.exe'
    $ffmpeg = Join-Path $root 'docs\programs\ffmpeg\ffmpeg.exe'
    $tools = @($merge,$extract); if ($Film -eq 'BvS') { $tools += $ffmpeg }
    foreach ($tool in $tools) { if (-not [IO.File]::Exists($tool)) { throw "Required bundled tool is missing: $tool" } }
    Write-Host ''
    Write-Host '----------------------------------------------------------------'
    Write-Host 'SOURCE VIDEO CHECK'
    Write-Host '----------------------------------------------------------------'
    Write-Host 'Checking that the video matches the supported source. The original is unchanged.'
    Write-Host 'This reads the video without encoding it. A temporary extracted track is removed after this check.'
    Write-Host ("Press Q to cancel. Diagnostic records are retained in: {0}" -f $work.FullName)
    foreach ($tool in $tools) {
        $name = [IO.Path]::GetFileNameWithoutExtension($tool)
        $versionArg = if ($name -eq 'ffmpeg') { '-version' } else { '--version' }
        $versionLog = Invoke-CheckedTool $tool @($versionArg) ($name + '-version')
        $record.tools[$name] = @{ version=([IO.File]::ReadAllLines($versionLog) | Select-Object -First 1); sha256=(Get-Sha256 $tool) }
    }
    $identification = Invoke-CheckedTool $merge @('-J',$Source) 'identify'
    $info = [IO.File]::ReadAllText($identification) | ConvertFrom-Json
    $videos = @($info.tracks | Where-Object { $_.type -eq 'video' })
    if ($videos.Count -ne 1) { throw 'Exactly one video track is required.' }
    $video = $videos[0]
    $codec = if ($Film -eq 'BvS') { 'V_MPEGH/ISO/HEVC' } else { 'V_MPEG4/ISO/AVC' }
    if ($video.properties.codec_id -ne $codec) { throw "Unsupported video codec. Expected $codec" }
    $record.track_id = $video.id; $record.codec_id = $codec
    $drive = New-Object IO.DriveInfo ([IO.Path]::GetPathRoot($work.FullName))
    if ($drive.AvailableFreeSpace -lt ($inputFile.Length + 1GB)) { throw 'Not enough working-drive space for temporary video extraction plus a 1 GiB reserve. Free space and retry with a new workspace.' }
    $null = Invoke-CheckedTool $extract @($Source,'tracks',("{0}:{1}" -f $video.id,$scratch)) 'extract'
    if (-not [IO.File]::Exists($scratch) -or (Get-Item -LiteralPath $scratch).Length -le 0) { throw 'Video extraction produced no data.' }
    if ($Film -eq 'BvS') {
        $hashLog = Invoke-CheckedTool $ffmpeg @('-nostdin','-hide_banner','-loglevel','warning','-f','hevc','-i',$scratch,'-map','0:v:0','-c:v','copy','-bsf:v','filter_units=remove_types=35|62','-f','hash','-hash','sha256','-') 'fingerprint' $true
        $result = [IO.File]::ReadAllText($hashLog).Trim()
        if ($result -notmatch '\ASHA256=([a-fA-F0-9]{64})\z') { throw 'Fingerprint tool produced an invalid result.' }
        $actual = $Matches[1].ToLowerInvariant()
    } else {
        $stream = [IO.File]::OpenRead($scratch); $sha = [Security.Cryptography.SHA256]::Create()
        try {
            $buffer = New-Object byte[] (4MB); $timer = [Diagnostics.Stopwatch]::StartNew(); $next=10
            while (($count=$stream.Read($buffer,0,$buffer.Length)) -gt 0) {
                $null = $sha.TransformBlock($buffer,0,$count,$buffer,0); Check-Cancellation
                if ($timer.Elapsed.TotalSeconds -ge $next) { Write-SourceProgress ("Hashing source video; elapsed {0} seconds. No encoding. Press Q to cancel." -f [int]$timer.Elapsed.TotalSeconds); $next+=10 }
            }
            $null = $sha.TransformFinalBlock($buffer,0,0)
            $actual = ([BitConverter]::ToString($sha.Hash)).Replace('-','').ToLowerInvariant()
        } finally { Complete-SourceProgress; $stream.Dispose(); $sha.Dispose() }
    }
    $record.actual_sha256 = $actual
    if ($actual -ne $expected) { $record.status='MISMATCH'; throw 'The video does not match the supported source. Restoration has not started. Choose the required unaltered disc video; audio and subtitle differences are allowed.' }
    $record.status='MATCH'; $exitCode=0
} catch [OperationCanceledException] {
    $record.status='CANCELLED'; $record.error=$_.Exception.Message; Complete-SourceProgress; Write-Host ''; Write-Host '================================================================'; Write-Host ('[STOP] ' + $_.Exception.Message); Write-Host '================================================================'; $exitCode=3
} catch {
    if ($record.status -ne 'MISMATCH') { $record.status='FAILED' }
    $record.error=$_.Exception.Message
    Complete-SourceProgress
    Write-Host ''
    Write-Host '================================================================'
    Write-Host ('[STOP] Source check stopped: ' + $_.Exception.Message)
    Write-Host '================================================================'
    Write-Host 'Restoration has not started. Keep the diagnostics for troubleshooting.'
} finally {
    if ($sourceHandle) { $sourceHandle.Dispose() }
    if ($scratch -and [IO.File]::Exists($scratch)) {
        try { [IO.File]::Delete($scratch) } catch { $record.cleanup_error=$_.Exception.Message; $record.status='FAILED'; $exitCode=2; Write-Host '[STOP] Temporary source extraction could not be removed. Keep the workspace for review.' }
    }
    if ($recordPath -and -not [IO.File]::Exists($recordPath)) {
        $record.completed_utc=[DateTime]::UtcNow.ToString('o')
        try { $json=$record | ConvertTo-Json -Depth 8; $stream=[IO.File]::Open($recordPath,'CreateNew','Write','Read'); try { $writer=New-Object IO.StreamWriter($stream,[Text.UTF8Encoding]::new($false)); $writer.Write($json); $writer.Flush() } finally { $stream.Dispose() } }
        catch { Write-Host ('[STOP] Cannot save source-check record: '+$_.Exception.Message); $exitCode=2 }
    }
}
Complete-SourceProgress
if ($exitCode -eq 0) {
    Write-Host ''
    Write-Host '================================================================'
    Write-Host '[OK] Source video matches.'
    Write-Host '================================================================'
}
exit $exitCode
