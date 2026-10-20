# Windows PowerShell 5.1. Collect settings before any processing workspace exists.
[CmdletBinding()]
param(
    [ValidateSet('BvS','Asteroid')][string]$Film = 'BvS',
    [string]$Launcher,
    [string]$Source,
    [string]$Destination,
    [string]$Mode,
    [switch]$Manual,
    [switch]$ValidateOnly,
    [switch]$ValidateEnvironment
)
$ErrorActionPreference = 'Stop'
# Redirected automation uses UTF-8; leave the owner's interactive console unchanged.
if ([Console]::IsInputRedirected) { [Console]::InputEncoding = New-Object Text.UTF8Encoding($false) }
if ([Console]::IsOutputRedirected) { [Console]::OutputEncoding = New-Object Text.UTF8Encoding($false) }
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
function Read-Answer([string]$Prompt) {
    $answer = Read-Host $Prompt
    if ([string]::IsNullOrWhiteSpace($answer) -or $answer.Trim() -eq 'q') { throw [OperationCanceledException]::new('Cancelled. No processing started.') }
    return $answer.Trim()
}
function Get-PathValue([string]$Value) {
    $value = $Value.Trim()
    if ($value.StartsWith('"') -and $value.EndsWith('"') -and $value.Length -ge 2) { $value = $value.Substring(1,$value.Length-2) }
    if ([string]::IsNullOrWhiteSpace($value)) { throw 'A path is required.' }
    # The inherited batch processing body uses delayed expansion and percent expansion.
    if ($value -match '[!%^<>|"\x00-\x1f]') { throw 'This batch version cannot safely use paths containing ! % ^ < > | or quotes/control characters. Move or rename that file/folder, then select a supported path.' }
    if (-not [IO.Path]::IsPathRooted($value)) { throw 'Enter a full absolute path, including its drive.' }
    return [IO.Path]::GetFullPath($value)
}
function Show-AvailableSpace([string]$Label, [string]$Path) {
    try {
        $driveRoot = [IO.Path]::GetPathRoot($Path)
        if ($driveRoot.StartsWith('\\')) { throw 'Network share space is not available through DriveInfo.' }
        $drive = New-Object IO.DriveInfo($driveRoot)
        $freeGiB = $drive.AvailableFreeSpace / 1GB
        Write-Host ('Available space ({0}): {1:N1} GiB on {2}' -f $Label, $freeGiB, $driveRoot)
    } catch {
        Write-Host ('Available space ({0}): unavailable; check this location in File Explorer.' -f $Label)
    }
}
function Check-Selection {
    $script:Source = Get-PathValue $Source
    $script:Destination = Get-PathValue $Destination
    $null = Get-PathValue $root
    if (-not [IO.File]::Exists($Source)) { throw 'The source file does not exist. Select an existing MKV file.' }
    if ([IO.Path]::GetExtension($Source) -ine '.mkv' -or (Get-Item -LiteralPath $Source).Length -eq 0) { throw 'The source must be a nonempty MKV file.' }
    if (-not [IO.Directory]::Exists($Destination)) { throw 'The output folder does not exist. Create or select an existing folder.' }
    if ($Mode -notin @('1','2')) { throw 'Choose mode 1 or 2.' }
    $name = if ($Film -eq 'BvS') {
        if ($Mode -eq '1') { 'Batman v Superman Dawn of Justice Ultimate Edition IMAX 1.78.mkv' } else { 'Batman v Superman Dawn of Justice Ultimate Edition IMAX 1.43 (unmasked).mkv' }
    } else {
        if ($Mode -eq '1') { 'Asteroid City Theatrical Scope Restoration (unmasked).mkv' } else { 'Asteroid City Theatrical Scope Restoration (masked).mkv' }
    }
    $script:ExpectedOutput = Join-Path $Destination $name
    if ([string]::Equals($Source,$ExpectedOutput,[StringComparison]::OrdinalIgnoreCase)) { throw 'The source and output paths must be different.' }
    if (Test-Path -LiteralPath $ExpectedOutput) { throw "The output already exists: $ExpectedOutput. Choose another folder; existing files will not be overwritten." }
    $workspace = Join-Path $root 'docs\temp'
    if (Test-Path -LiteralPath $workspace) { throw "Existing work found at $workspace. Preserve it and review the logs before moving it aside. Nothing was deleted." }
}
function Select-Path([bool]$IsSource) {
    if (-not $Manual) {
        $dialog = $null
        try {
            Add-Type -AssemblyName System.Windows.Forms
            if ($IsSource) {
                $dialog = New-Object System.Windows.Forms.OpenFileDialog
                $dialog.Title = 'Step 1: select the original source MKV'
                $dialog.Filter = 'Matroska video (*.mkv)|*.mkv'
                $dialog.CheckFileExists = $true
            } else {
                $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
                $dialog.Description = 'Step 2: select an existing output folder'
            }
            if ($dialog.ShowDialog() -eq [Windows.Forms.DialogResult]::OK) {
                if ($IsSource) { return $dialog.FileName } else { return $dialog.SelectedPath }
            }
            Write-Host 'Selection cancelled. No processing has started.'
        } catch { Write-Host ('The selection dialog is unavailable: ' + $_.Exception.Message) }
        finally { if ($null -ne $dialog) { $dialog.Dispose() } }
        while ($true) {
            $choice = Read-Answer 'Type m to enter the path manually, or q to quit'
            if ($choice -eq 'm') { break }
            Write-Host 'Enter m or q.'
        }
    }
    if ($IsSource) { return Read-Answer 'Paste the full source MKV path (quotes accepted), or q to quit' }
    return Read-Answer 'Paste the full output folder path (quotes accepted), or q to quit'
}
try {
    if ($ValidateEnvironment) {
        $Source = $env:file; $Destination = $env:folder; $Mode = $env:version
        if ($env:RESTORER_SELECTION_READY -ne '1' -or $env:dialog -ne 'y' -or $env:dialog2 -ne 'y') { throw 'Selection is missing. Start the launcher normally.' }
    } elseif (-not $ValidateOnly) {
        if ($Film -eq 'BvS') {
            Write-Host '=== Batman v Superman: Dawn of Justice Ultimate Edition IMAX Restorer ==='
            Write-Host 'Restore your preferred constant-width IMAX presentation with HDR10.'
            Write-Host 'Required source: an MKV rip of the 4K Ultra HD Blu-ray (2021 Remaster).'
        } else {
            Write-Host '=== Asteroid City Theatrical Scope Restorer ==='
            Write-Host 'Restore your preferred constant-height Scope theatrical presentation.'
            Write-Host 'Required source: an MKV rip of the Asteroid City Blu-ray disc.'
        }
        Write-Host 'Only the unaltered video track from this specific disc is supported.'
        if ($Film -eq 'BvS') { Write-Host 'Source matching ignores added Dolby Vision RPU metadata; this restorer targets HDR10 output.' }
        Write-Host 'No other version will work. You may keep whichever audio and subtitle tracks you wish in your rip.'
        Write-Host 'Your original MKV is not modified. The restoration is saved as a separate file.'
        Write-Host 'No processing has started. At a text prompt, enter q or leave it blank to quit.'
        Write-Host 'Step 1 of 3: select your source MKV in the file dialog.'
        while ($true) {
            try {
                $Source = Get-PathValue (Select-Path $true)
                if (-not [IO.File]::Exists($Source) -or [IO.Path]::GetExtension($Source) -ine '.mkv' -or (Get-Item -LiteralPath $Source).Length -eq 0) { throw 'Select an existing nonempty MKV file.' }
                break
            } catch [OperationCanceledException] { throw } catch { Write-Host ('Source: ' + $_.Exception.Message) }
        }
        Write-Host 'Step 2 of 3: select the folder where the restored MKV will be saved.'
        while ($true) {
            try {
                $Destination = Get-PathValue (Select-Path $false)
                if (-not [IO.Directory]::Exists($Destination)) { throw 'Select an existing output folder.' }
                break
            } catch [OperationCanceledException] { throw } catch { Write-Host ('Destination: ' + $_.Exception.Message) }
        }
        if ($Film -eq 'BvS') {
            Write-Host 'Step 3 of 3: choose your constant-width IMAX restoration.'
            Write-Host '1: IMAX 1.78:1 - IMAX scenes vertically centre-cropped and upscaled to fill 16:9.'
            Write-Host '   Scope scenes remain unchanged. Best suited for 16:9 screens.'
            Write-Host '2: IMAX 1.43:1 (unmasked) - Scope scenes downscaled and windowboxed in a 16:9 container.'
            Write-Host '   IMAX scenes remain unchanged. Preserves the full height of the IMAX image.'
        } else {
            Write-Host 'Step 3 of 3: choose your constant-height Scope theatrical restoration.'
            Write-Host '1: Scope Theatrical (unmasked) - Black and White scenes downscaled and windowboxed.'
            Write-Host '   Keeps the 16:9 container; Blu-ray compliant.'
            Write-Host '2: Scope Theatrical (masked) - Black and White scenes downscaled and pillarboxed.'
            Write-Host '   Uses a 2.39:1 container with the top and bottom black bars removed.'
        }
        while ($true) {
            $Mode = Read-Answer 'Choose 1 or 2'
            if ($Mode -in @('1','2')) { break }
            Write-Host 'Enter 1 or 2; your source and destination selections are retained.'
        }
    }
    Check-Selection
    if ($ValidateOnly -or $ValidateEnvironment) { exit 0 }
    Write-Host 'Review your restoration before starting:'
    Write-Host "Source: $Source"
    Write-Host "Output: $ExpectedOutput"
    $modeName = if ($Film -eq 'BvS') {
        if ($Mode -eq '1') { 'IMAX 1.78:1 (constant-width; IMAX scenes vertically centre-cropped)' } else { 'IMAX 1.43:1 (constant-width; unmasked 16:9 container)' }
    } else {
        if ($Mode -eq '1') { 'Scope Theatrical (constant-height; unmasked 16:9 container)' } else { 'Scope Theatrical (constant-height; masked 2.39:1 container)' }
    }
    Write-Host "Restoration: $modeName"
    Write-Host "Working files: $(Join-Path $root 'docs\temp')"
    $sourceBytes = (Get-Item -LiteralPath $Source).Length
    Write-Host ('Source size: {0:N2} GiB ({1} bytes).' -f ($sourceBytes / 1GB), $sourceBytes)
    Show-AvailableSpace 'working drive' $root
    Show-AvailableSpace 'destination drive' $Destination
    if ([string]::Equals([IO.Path]::GetPathRoot($root), [IO.Path]::GetPathRoot($Destination), [StringComparison]::OrdinalIgnoreCase)) {
        Write-Host 'Working files and final output share the same free-space pool; do not add the two figures.'
    } else {
        Write-Host 'Working files and final output use separate drive locations.'
    }
    Write-Host 'Before restoration, the source check temporarily extracts the video track and then removes that extraction.'
    Write-Host 'Allow free space approximately equal to the source MKV size plus 1 GiB for that check.'
    Write-Host 'Allow room for several large temporary video files as well as the final MKV.'

    Write-Host 'Temporary videos and logs are kept in the working folder after processing.'
    Write-Host 'Processing can take several hours. Keep this window open and your PC awake.'
    while ($true) {
        $answer = Read-Answer 'Start processing? Enter y to start, or n/q to quit'
        if ($answer -eq 'n') { throw [OperationCanceledException]::new('Cancelled. No processing started.') }
        if ($answer -eq 'y') { break }
        Write-Host 'Enter y, n or q. A file path is not a confirmation.'
    }
    $Launcher = Get-PathValue $Launcher
    if (-not [IO.File]::Exists($Launcher)) { throw 'The launcher is missing.' }
    $start = New-Object Diagnostics.ProcessStartInfo
    $start.FileName = $env:ComSpec
    $start.Arguments = '/d /v:off /c ""' + $Launcher + '" --selected"'
    $start.UseShellExecute = $false
    $start.WorkingDirectory = $root
    $start.EnvironmentVariables['file'] = $Source
    $start.EnvironmentVariables['folder'] = $Destination
    $start.EnvironmentVariables['version'] = $Mode
    $start.EnvironmentVariables['dialog'] = 'y'
    $start.EnvironmentVariables['dialog2'] = 'y'
    $start.EnvironmentVariables['RESTORER_SELECTION_READY'] = '1'
    $process = [Diagnostics.Process]::Start($start)
    $process.WaitForExit()
    exit $process.ExitCode
} catch [OperationCanceledException] { Write-Host $_.Exception.Message; exit 3 }
catch { Write-Host ('Cannot start: ' + $_.Exception.Message); Write-Host 'No media tool was started by setup.'; exit 2 }
