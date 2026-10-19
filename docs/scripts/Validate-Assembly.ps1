# Windows PowerShell 5.1. No additional runtime or private media is required.
# Compares decoded video frames only: timestamps, HDR metadata and audio are not qualified.
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$FFmpegPath,
    [Parameter(Mandatory=$true)][string]$AssemblyPath,
    [Parameter(Mandatory=$true)][string]$InputListPath,
    [Parameter(Mandatory=$true)][string]$WorkDirectory
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$resultPath = $null

function Require-File([string]$Path) {
    $item = Get-Item -LiteralPath $Path -ErrorAction Stop
    if ($item.PSIsContainer -or $item.Length -le 0) { throw "Missing or empty regular file: $Path" }
    return $item.FullName
}

# .NET Framework ProcessStartInfo has no ArgumentList. Apply the Windows CRT
# quoting algorithm, never cmd.exe / Invoke-Expression / a shell command string.
function Quote-Argument([string]$Value) {
    $quoted = '"'
    $slashes = 0
    foreach ($character in $Value.ToCharArray()) {
        if ($character -eq '\') { $slashes++; continue }
        if ($character -eq '"') {
            $quoted += ('\' * (2 * $slashes + 1)) + '"'
        } else {
            $quoted += ('\' * $slashes) + $character
        }
        $slashes = 0
    }
    return $quoted + ('\' * (2 * $slashes)) + '"'
}

function Write-FrameHashes([string]$Source, [string]$Stem) {
    $hashPath = Join-Path $script:work ($Stem + '.framehash')
    $logPath = Join-Path $script:work ($Stem + '.stderr.log')
    $arguments = @('-hide_banner', '-nostdin', '-loglevel', 'level+info', '-xerror',
        '-max_error_rate', '0', '-err_detect', 'explode', '-hwaccel', 'none',
        '-noautorotate', '-noauto_conversion_filters', '-i', $Source,
        '-map', '0:v:0', '-an', '-sn', '-dn', '-fps_mode', 'passthrough',
        '-vf', 'showinfo', '-c:v', 'rawvideo', '-pix_fmt', '+', '-threads:v', '1',
        '-f', 'framehash', '-hash', 'sha256', '-n', $hashPath)
    $start = New-Object System.Diagnostics.ProcessStartInfo
    $start.FileName = $script:ffmpeg
    $start.Arguments = (($arguments | ForEach-Object { Quote-Argument $_ }) -join ' ')
    $start.UseShellExecute = $false
    $start.CreateNoWindow = $true
    $start.RedirectStandardError = $true
    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $start
    $log = [IO.File]::Open($logPath, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::Read)
    $started = $false
    try {
        if (-not $process.Start()) { throw 'FFmpeg did not start' }
        $started = $true
        $copy = $process.StandardError.BaseStream.CopyToAsync($log)
        $process.WaitForExit()
        $copy.GetAwaiter().GetResult()
        if ($process.ExitCode -ne 0) { throw "Decode failed for $Source; see $logPath" }
    } finally {
        try {
            if ($started -and -not $process.HasExited) { $process.Kill(); $process.WaitForExit() }
        } finally {
            $process.Dispose()
            $log.Dispose()
        }
    }
    # showinfo describes the decoded native format/geometry of EVERY frame,
    # before rawvideo encoding. Stream logs from disk; never hold a film's frame
    # list in RAM. Hash bytes alone cannot distinguish all pixel interpretations.
    $logReader = [IO.File]::OpenText($logPath)
    $formats = [IO.StreamWriter]::new(($hashPath + '.formats'), $false, [Text.Encoding]::ASCII)
    $count = [long]0
    try {
        while ($null -ne ($line = $logReader.ReadLine())) {
            if ($line -match '\[(error|fatal|panic)\]') { throw "Decoder error: see $logPath" }
            if ($line -match '\[Parsed_showinfo_\d+ @[^]]+\].*\bn:\s*(\d+)\s+pts:.*\bfmt:([A-Za-z0-9_]+).*?\bs:(\d+x\d+)') {
                if ([long]$Matches[1] -ne $count) { throw 'Unexpected decoded frame sequence' }
                $formats.WriteLine($Matches[2] + ':' + $Matches[3])
                $count++
            }
        }
        if ($count -eq 0) { throw 'No decoded frame format evidence' }
    } finally { $formats.Dispose(); $logReader.Dispose() }
    return Require-File $hashPath
}

function Open-Hashes([string]$Path) {
    return @{ Reader = [IO.File]::OpenText($Path); Formats = [IO.File]::OpenText($Path + '.formats'); Headers = @{}; Frames = [long]0; Ready = $false }
}
function Next-Frame($State) {
    while ($null -ne ($line = $State.Reader.ReadLine())) {
        if ($line.StartsWith('#')) {
            if ($State.Ready) { throw 'Unexpected header within frame records' }
            if ($line -match '^#(version|hash|media_type 0|codec_id 0|dimensions 0):\s*(.+)$') {
                if ($State.Headers.ContainsKey($Matches[1])) { throw 'Duplicate hash header' }
                $State.Headers[$Matches[1]] = $Matches[2].Trim()
            }
            continue
        }
        if (-not $State.Ready) {
            foreach ($key in @('version', 'hash', 'media_type 0', 'codec_id 0', 'dimensions 0')) {
                if (-not $State.Headers.ContainsKey($key)) { throw "Missing hash header: $key" }
            }
            if ($State.Headers['version'] -ne '2' -or $State.Headers['hash'] -ne 'SHA256' -or
                $State.Headers['media_type 0'] -ne 'video' -or $State.Headers['codec_id 0'] -ne 'rawvideo' -or
                $State.Headers['dimensions 0'] -notmatch '^\d+x\d+$') { throw 'Unsupported hash stream' }
            $State.Ready = $true
        }
        if ($line -notmatch '^\s*0,\s*-?\d+,\s*-?\d+,\s*\d+,\s*([1-9]\d*),\s*([a-fA-F0-9]{64})\s*$') {
            throw 'Unparseable frame record'
        }
        $State.Frames++
        # Deliberately excludes DTS/PTS/duration. Equality proves decoded pixel
        # order and count, not timing, stream metadata or intended film edits.
        $pixels = $Matches[1] + ':' + $Matches[2].ToLowerInvariant()
        $format = $State.Formats.ReadLine()
        if ($null -eq $format) { throw 'Missing decoded frame format evidence' }
        return $pixels + ':' + $format
    }
    if ($null -ne $State.Formats.ReadLine()) { throw 'Extra decoded frame format evidence' }
    if ($State.Frames -eq 0) { throw 'No decoded frames' }
    return $null
}

try {
    $ffmpeg = Require-File $FFmpegPath
    $assembly = Require-File $AssemblyPath
    $list = Require-File $InputListPath
    $inputs = [IO.File]::ReadAllLines($list, [Text.Encoding]::UTF8)
    if ($inputs.Count -eq 0) { throw 'No assembly inputs' }
    $sources = @()
    foreach ($inputPath in $inputs) {
        if ([string]::IsNullOrWhiteSpace($inputPath)) { throw 'Empty assembly input entry' }
        $sources += Require-File $inputPath
    }
    $work = [IO.Path]::GetFullPath($WorkDirectory)
    # Atomic exclusive directory acquisition: Directory.CreateDirectory would
    # silently accept an existing directory and could overwrite old evidence.
    $parent = Split-Path -Parent $work
    if (-not [IO.Directory]::Exists($parent)) { throw 'Validation parent directory missing' }
    $null = New-Item -ItemType Directory -Path $work -ErrorAction Stop
    $resultPath = Join-Path $work 'result.txt'
    $actual = $null
    try {
        $actual = Open-Hashes (Write-FrameHashes $assembly 'assembled')
        $index = 0
        foreach ($source in $sources) {
            $index++
            Write-Host "Checking assembly segment $index of $($sources.Count)..."
            $expected = Open-Hashes (Write-FrameHashes $source ('input-{0:D3}' -f $index))
            try {
                while ($null -ne ($frame = Next-Frame $expected)) {
                    $other = Next-Frame $actual
                    if ($null -eq $other -or $frame -ne $other -or
                        $expected.Headers['dimensions 0'] -ne $actual.Headers['dimensions 0']) {
                        throw "Assembly mismatch at segment $index frame $($expected.Frames)"
                    }
                }
            } finally { $expected.Reader.Dispose(); $expected.Formats.Dispose() }
        }
        if ($null -ne (Next-Frame $actual)) { throw 'Assembly contains extra frames' }
        $message = "PASS: $($actual.Frames) decoded video frames match ordered inputs. Timing, HDR metadata, audio and intended film edits are not verified."
        [IO.File]::WriteAllText($resultPath, $message + [Environment]::NewLine)
        Write-Host $message
    } finally { if ($null -ne $actual) { $actual.Reader.Dispose(); $actual.Formats.Dispose() } }
    exit 0
} catch {
    $message = 'FAIL: ' + $_.Exception.Message
    if ($null -ne $resultPath) { [IO.File]::WriteAllText($resultPath, $message + [Environment]::NewLine) }
    [Console]::Error.WriteLine($message)
    exit 2
}
