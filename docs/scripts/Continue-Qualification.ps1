# Separate owner-run packaging experiment. Never invoked by the production launcher.
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$InstallationRoot,
    [Parameter(Mandatory=$true)][string]$Destination
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0
$expectedToolHash = 'f707365fc6374db58c875d69fe8d3c3f572ab54369b28a863bc9aaad3ebc09ef'
$held = @()
$run = $null
function Safe-Item([string]$Path, [bool]$File) {
    if ($Path -match '[\x00-\x1f"]' -or -not [IO.Path]::IsPathRooted($Path)) { throw 'Use an absolute path without quotes or control characters.' }
    $item = Get-Item -LiteralPath $Path -Force
    if ($File) { if ($item -isnot [IO.FileInfo] -or $item.Length -le 0) { throw "Expected a nonempty regular file: $Path" } }
    elseif ($item -isnot [IO.DirectoryInfo]) { throw "Expected an existing directory: $Path" }
    $ancestor = $item
    while ($null -ne $ancestor) {
        if (($ancestor.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { throw "Linked paths are unsupported: $Path" }
        if ($ancestor -is [IO.FileInfo]) { $ancestor = $ancestor.Directory } else { $ancestor = $ancestor.Parent }
    }
    if ($item.FullName.StartsWith('\\')) { throw 'Use a local drive, not a network share.' }
    return $item
}
function New-Text([string]$Path, [string]$Text) {
    $stream = [IO.File]::Open($Path,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read)
    try { $bytes = [Text.UTF8Encoding]::new($false).GetBytes($Text); $stream.Write($bytes,0,$bytes.Length) } finally { $stream.Dispose() }
}
function Free-Bytes { return $drive.AvailableFreeSpace }
function Snapshot($Item) { return @{Path=$Item.FullName; Length=$Item.Length; Ticks=$Item.LastWriteTimeUtc.Ticks} }
function Check-Snapshot($Before) {
    $now = Safe-Item $Before.Path $true
    if ($now.Length -ne $Before.Length -or $now.LastWriteTimeUtc.Ticks -ne $Before.Ticks) { throw "Input metadata changed: $($Before.Path)" }
}
try {
    $root = Safe-Item $InstallationRoot $false
    $destinationItem = Safe-Item $Destination $false
    $temp = Safe-Item (Join-Path $root.FullName 'docs\temp') $false
    if ($destinationItem.FullName -eq $temp.FullName -or $destinationItem.FullName.StartsWith($temp.FullName + '\',[StringComparison]::OrdinalIgnoreCase)) { throw 'Destination must be outside the retained workspace.' }
    $stateItem = Safe-Item (Join-Path $temp.FullName 'storage-qualification.json') $true
    $stateSnapshot = Snapshot $stateItem
    $state = Get-Content -LiteralPath $stateItem.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($state.Phase -cne 'BeforeAssembly' -or [long]$state.VideoBytes -le 0) { throw 'Expected the completed BeforeAssembly storage checkpoint.' }
    $source = Safe-Item ([string]$state.Source) $true
    if ($source.Length -ne [long]$state.Length -or $source.LastWriteTimeUtc.Ticks -ne [long]$state.Ticks) { throw 'Original source metadata differs from the storage record.' }
    if ([long]$state.VideoBytes -gt $source.Length) { throw 'Prepared-video size exceeds the original source; invalid storage record.' }
    if ($source.FullName.StartsWith($temp.FullName + '\',[StringComparison]::OrdinalIgnoreCase)) { throw 'Original source must be outside docs/temp.' }
    $assembly = Safe-Item (Join-Path $temp.FullName 'BvS_1.78.mkv') $true
    $tool = Safe-Item (Join-Path $root.FullName 'docs\programs\mkvtoolnix\mkvmerge.exe') $true
    if ((Get-FileHash -LiteralPath $tool.FullName -Algorithm SHA256).Hash -ine $expectedToolHash) { throw 'Bundled mkvmerge does not match the audited MKVToolNix 78 executable.' }
    $sourceSnapshot = Snapshot $source
    $assemblySnapshot = Snapshot $assembly
    $toolSnapshot = Snapshot $tool
    $drive = [IO.DriveInfo]::new([IO.Path]::GetPathRoot($destinationItem.FullName))
    if ($drive.DriveFormat -notin @('NTFS','ReFS','exFAT')) { throw 'Destination requires NTFS, ReFS or exFAT for large output files.' }
    [long]$outputBudget = $assembly.Length + [Math]::Max(0L, $source.Length - [long]$state.VideoBytes) + 2GB
    [long]$required = $outputBudget + 20GB
    if ((Free-Bytes) -lt $required) { throw "Insufficient free space: require $required bytes including 20 GiB reserve." }
    # Advisory process check; read locks below also exclude concurrent writers.
    $active = @(Get-CimInstance Win32_Process | Where-Object {
        $_.Name -match '^(ffmpeg|HandBrakeCLI|avidemux_cli|mkvmerge)\.exe$' -and
        $_.CommandLine -and $_.CommandLine.IndexOf($temp.FullName,[StringComparison]::OrdinalIgnoreCase) -ge 0
    })
    if ($active.Count -gt 0) { throw 'A media process still refers to this workspace. Stop the earlier run first.' }
    Write-Host 'PACKAGE AN UNQUALIFIED TEST OUTPUT: no encoding; no temporary files deleted.'
    Write-Host 'Exhaustive assembly validation was interrupted. Codec/join warnings remain unresolved.'
    Write-Host 'This operation does not establish source identity, picture integrity, timing, HDR or playback compatibility.'
    Write-Host "Source: $($source.FullName)"
    Write-Host "Assembly: $($assembly.FullName)"
    Write-Host ('Output budget {0:N2} GiB; destination free {1:N2} GiB; reserve 20 GiB.' -f ($outputBudget/1GB),((Free-Bytes)/1GB))
    if ((Read-Host 'Type PACKAGE to acknowledge incomplete validation and package, or anything else to cancel') -cne 'PACKAGE') { exit 3 }
    # Reserve this workspace without modifying its state bytes. Only one helper may package it.
    $held += [IO.File]::Open($stateSnapshot.Path,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::None)
    Check-Snapshot $stateSnapshot
    foreach ($snapshot in @($sourceSnapshot,$assemblySnapshot,$toolSnapshot)) {
        $held += [IO.File]::Open($snapshot.Path,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::Read)
        Check-Snapshot $snapshot
    }
    if ((Get-FileHash -LiteralPath $tool.FullName -Algorithm SHA256).Hash -ine $expectedToolHash) { throw 'Tool changed before launch.' }
    if ((Free-Bytes) -lt $required) { throw 'Available space changed before launch.' }
    $run = Join-Path $destinationItem.FullName ('BvS-unqualified-' + [Guid]::NewGuid().ToString('N'))
    $null = New-Item -ItemType Directory -Path $run -ErrorAction Stop
    $output = Join-Path $run 'Batman v Superman IMAX 1.78 UNQUALIFIED.mkv'
    $arguments = @('-o',$output,'-A','--no-audio','-S','--no-subtitles','-B','--no-buttons','--no-chapters','-M','--no-attachments','--no-global-tags',$assembly.FullName,'-D','--no-video',$source.FullName)
    $response = Join-Path $run 'mkvmerge-arguments.json'
    New-Text $response (ConvertTo-Json -InputObject $arguments)
    New-Text (Join-Path $run 'input-record.json') (ConvertTo-Json -Depth 5 -InputObject @{
        Status='UNQUALIFIED'; Validation='Interrupted; not passed'; Source=$sourceSnapshot; Assembly=$assemblySnapshot;
        Tool=$toolSnapshot; ToolSHA256=$expectedToolHash; OutputBudgetBytes=$outputBudget; ReserveBytes=20GB;
        StartedUtc=[DateTime]::UtcNow.ToString('o'); SourceIdentity='Not hashed or verified'; StorageRecord=$stateSnapshot
    })
    New-Text (Join-Path $run 'result.txt') 'UNQUALIFIED: packaging started; no completed result. Assembly validation was interrupted.'
    if (Test-Path -LiteralPath $output) { throw 'Output already exists; refusing overwrite.' }
    $start = [Diagnostics.ProcessStartInfo]::new()
    $start.FileName = $tool.FullName
    $start.Arguments = '"@' + $response + '"'
    $start.WorkingDirectory = $root.FullName
    $start.UseShellExecute = $false
    $start.CreateNoWindow = $true
    $start.RedirectStandardInput = $true
    $start.RedirectStandardOutput = $true
    $start.RedirectStandardError = $true
    $process = [Diagnostics.Process]::new(); $process.StartInfo = $start
    $outStream = $null; $errStream = $null
    try {
        $outStream = [IO.File]::Open((Join-Path $run 'mkvmerge.stdout.log'),[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read)
        $errStream = [IO.File]::Open((Join-Path $run 'mkvmerge.stderr.log'),[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read)
        if (-not $process.Start()) { throw 'mkvmerge could not start.' }
        $process.StandardInput.Close()
        $stdout = $process.StandardOutput.BaseStream.CopyToAsync($outStream)
        $stderr = $process.StandardError.BaseStream.CopyToAsync($errStream)
        Write-Host "Packaging started. Logs and output may grow in: $run"
        $watch = [Diagnostics.Stopwatch]::StartNew()
        while (-not $process.WaitForExit(10000)) {
            Write-Host ('Packaging still running; elapsed {0:N0} seconds. No encoding.' -f $watch.Elapsed.TotalSeconds)
        }
        $null = $stdout.GetAwaiter().GetResult(); $null = $stderr.GetAwaiter().GetResult()
        $status = $process.ExitCode
    } finally {
        # Only the process started above is owned by this helper. Do not terminate unrelated tasks.
        try {
            if (-not $process.HasExited) {
                $process.Kill()
                $null = $process.WaitForExit(10000)
            }
        } catch { }
        if ($null -ne $outStream) { $outStream.Dispose() }
        if ($null -ne $errStream) { $errStream.Dispose() }
        $process.Dispose()
    }
    $nonempty = [IO.File]::Exists($output) -and (Get-Item -LiteralPath $output).Length -gt 0
    $result = "UNQUALIFIED: assembly validation interrupted; not passed.`r`nmkvmerge exit code: $status`r`nNonempty output: $nonempty`r`nOutput: $output`r`nNo inputs, original logs or storage state were changed. Retain all files."
    New-Text (Join-Path $run 'completed-result.txt') $result
    Write-Host $result
    if ($status -eq 0 -and $nonempty) { exit 0 }
    if ($status -eq 1 -and $nonempty) { Write-Warning 'Packaging returned warnings. Review logs; output remains unqualified.'; exit 1 }
    exit 2
} catch {
    $message = 'Packaging stopped: ' + $_.Exception.Message
    [Console]::Error.WriteLine($message)
    if ($null -ne $run -and [IO.Directory]::Exists($run)) {
        try { New-Text (Join-Path $run 'failure.txt') ('UNQUALIFIED; no validation pass.' + [Environment]::NewLine + $message) } catch { }
    }
    exit 2
} finally {
    foreach ($stream in $held) { $stream.Dispose() }
}
