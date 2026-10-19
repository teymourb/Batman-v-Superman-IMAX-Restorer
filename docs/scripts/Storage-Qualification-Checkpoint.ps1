# Owner-run storage qualification only. Production launcher never invokes this.
[CmdletBinding()]
param([Parameter(Mandatory=$true)][ValidateSet('Preflight','BeforeAssembly','BeforeRemux')][string]$Phase)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
$temp = Join-Path $root 'docs\temp'
$statePath = Join-Path $temp 'storage-qualification.json'
$log = Join-Path $temp 'storage-qualification.log'
$reserve = 20GB
$names = @('BvS_1i_Cropped.mkv','BvS_2s.mkv','BvS_3i_Cropped.mkv','BvS_4s.mkv','BvS_5i_Cropped.mkv','BvS_6s.mkv','BvS_7i_Cropped.mkv','BvS_8s.mkv','BvS_9i_Cropped.mkv','BvS_10s.mkv')
function Safe-Path([string]$path, [bool]$file) {
    $item = Get-Item -LiteralPath $path -Force
    if ($file -and (($item -isnot [IO.FileInfo]) -or $item.Length -le 0)) { throw "Not a nonempty regular file: $path" }
    $ancestor = $item
    while ($null -ne $ancestor) {
        if (($ancestor.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { throw "Linked paths are unsupported: $path" }
        if ($ancestor -is [IO.FileInfo]) { $ancestor = $ancestor.Directory } else { $ancestor = $ancestor.Parent }
    }
    return $item
}
function Free-Bytes {
    $drive = [IO.DriveInfo]::new([IO.Path]::GetPathRoot($root))
    return $drive.AvailableFreeSpace
}
function Record([string]$message) {
    $line = '{0:o} {1}' -f [DateTime]::UtcNow, $message
    Add-Content -LiteralPath $log -Value $line -Encoding UTF8
    Write-Host $message
}
try {
    $null = Safe-Path $temp $false
    if ((Get-Item -LiteralPath $temp) -isnot [IO.DirectoryInfo]) { throw 'Workspace is not a directory.' }
    if ($Phase -eq 'Preflight') {
        if (Test-Path -LiteralPath $statePath) { throw 'Qualification state already exists; preserve it.' }
        if (Test-Path -LiteralPath $log) { throw 'Qualification log already exists; preserve it.' }
        $sourcePath = $env:file
        if ([string]::IsNullOrWhiteSpace($sourcePath)) { throw 'Source path is unavailable.' }
        if ($sourcePath.StartsWith('"') -and $sourcePath.EndsWith('"')) { $sourcePath = $sourcePath.Substring(1,$sourcePath.Length-2) }
        $source = Safe-Path ([IO.Path]::GetFullPath($sourcePath)) $true
        if ($source.FullName.StartsWith($temp + '\',[StringComparison]::OrdinalIgnoreCase)) { throw 'Original source must be outside docs/temp.' }
        # Two source-sized working sets, capped encode budget, plus headroom.
        $need = 2L * $source.Length + 14GB + $reserve
        if ((Free-Bytes) -lt $need) { throw 'Insufficient free space for conservative preparation budget.' }
        $state = @{Source=$source.FullName; Length=$source.Length; Ticks=$source.LastWriteTimeUtc.Ticks; Phase='Preflight'; VideoBytes=0}
        $stream = [IO.File]::Open($statePath,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read)
        try { $bytes=[Text.Encoding]::UTF8.GetBytes(($state | ConvertTo-Json)); $stream.Write($bytes,0,$bytes.Length) } finally { $stream.Dispose() }
        Record "Preflight source bytes=$($source.Length); free bytes=$(Free-Bytes). No source bytes hashed or modified."
        exit 0
    }
    $null = Safe-Path $statePath $true
    $null = Safe-Path $log $true
    $state = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
    $source = Safe-Path $state.Source $true
    if ($source.Length -ne $state.Length -or $source.LastWriteTimeUtc.Ticks -ne $state.Ticks) { throw 'Original source metadata changed; stop for review.' }
    $assembled = Join-Path $temp 'BvS_1.78.mkv'
    if ($Phase -eq 'BeforeAssembly') {
        if ($state.Phase -ne 'Preflight') { throw 'Unexpected checkpoint order.' }
        $inputs = @($names | ForEach-Object { Safe-Path (Join-Path $temp $_) $true })
        $encoded = @($inputs | Where-Object {$_.Name -like '*_Cropped.mkv'})
        $encodedBytes = ($encoded | Measure-Object Length -Sum).Sum
        if ($encodedBytes -gt 14GB) { throw 'Encoded sections exceed planned budget; retain everything for review.' }
        $remove = @(Safe-Path (Join-Path $temp 'BvS.mkv') $true)
        $state.VideoBytes = $remove[0].Length
        $required = ($inputs | Measure-Object Length -Sum).Sum + $reserve
    } else {
        if ($state.Phase -ne 'BeforeAssembly') { throw 'Unexpected checkpoint order.' }
        $assembly = Safe-Path $assembled $true
        $null = Safe-Path (Join-Path $temp 'assembly-validation-1.78\result.txt') $true
        $report = Get-Content -LiteralPath (Join-Path $temp 'assembly-validation-1.78\result.txt') -Raw
        if ($report -notmatch '^PASS: [1-9][0-9]* decoded video frames match ordered inputs\.') { throw 'Independent assembly PASS evidence is missing.' }
        $remove = @(@('BvS_2s.mkv','BvS_4s.mkv','BvS_6s.mkv','BvS_8s.mkv','BvS_10s.mkv') | ForEach-Object { Safe-Path (Join-Path $temp $_) $true })
        # Measured video-only copy excludes source audio/subtitles; allow extra mux overhead.
        if ($state.VideoBytes -le 0) { throw 'Prepared-video size record is missing.' }
        $otherStreams = [Math]::Max(0L, [long]$source.Length - [long]$state.VideoBytes) + 2GB
        $required = $assembly.Length + $otherStreams + $reserve
    }
    $reclaimed = ($remove | Measure-Object Length -Sum).Sum
    Record "$Phase free bytes=$(Free-Bytes); removable bytes=$reclaimed; required next-stage budget=$required."
    foreach ($item in $remove) { Record "Proposed generated-file removal: $($item.Name), bytes=$($item.Length)" }
    if ((Free-Bytes) + $reclaimed -lt $required) { throw 'Not enough room even after proposed removal; nothing removed.' }
    Write-Host 'Only the generated files listed above will be permanently removed, without using Recycle Bin.'
    Write-Host 'Original film, HandBrake encodes, assembly and diagnostics are retained. No automatic resume.'
    if ((Read-Host 'Type REMOVE to permit this checkpoint, or anything else to stop') -cne 'REMOVE') { throw 'Owner declined removal; all files retained.' }
    foreach ($item in $remove) {
        $current = Safe-Path $item.FullName $true
        if ($current.FullName -eq $source.FullName -or $current.Length -ne $item.Length -or $current.LastWriteTimeUtc.Ticks -ne $item.LastWriteTimeUtc.Ticks) { throw 'Removal target changed; stop.' }
        [IO.File]::Delete($current.FullName)
        if (Test-Path -LiteralPath $current.FullName) { throw "Removal failed: $($current.Name)" }
        Record "Removed generated file: $($current.Name)"
    }
    if ((Free-Bytes) -lt $required) { throw 'Free-space budget changed; stop before next stage.' }
    $state.Phase = $Phase
    $state | ConvertTo-Json | Set-Content -LiteralPath $statePath -Encoding UTF8
    Record "$Phase completed; free bytes=$(Free-Bytes)."
    exit 0
} catch {
    [Console]::Error.WriteLine('Storage qualification stopped: ' + $_.Exception.Message)
    exit 2
}
