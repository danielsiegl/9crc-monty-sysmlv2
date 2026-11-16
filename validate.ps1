<#
.SYNOPSIS
    Runs the Open-MBEE sysml-toolkit (sysmlv2) locally against this repository.

.DESCRIPTION
    On first run, downloads the latest Windows release of sysml-toolkit and the
    SysML v2 standard library into .bin\. Later runs reuse what is in .bin\.

    With no arguments, validates all .sysml files in the repository as one model
    (same as the CI workflow). Any other arguments are passed straight to sysmlv2.

.EXAMPLE
    .\validate.ps1
    Validates every .sysml file in the repo.

.EXAMPLE
    .\validate.ps1 eval --all
    Evaluates all computable values (library and model files are added automatically).

.EXAMPLE
    .\validate.ps1 -Update
    Re-downloads the latest sysml-toolkit release, then validates.
#>
[CmdletBinding()]
param(
    # Force re-download of the latest sysml-toolkit release.
    [switch]$Update,

    # Arguments passed to sysmlv2 (default: check).
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$SysmlArgs
)

$ErrorActionPreference = 'Stop'

# Keep in sync with SYSML_RELEASE_VERSION in .github/workflows/sysmlv2validation.yml
$SysmlReleaseVersion = '2026-08'

$RepoRoot = $PSScriptRoot
$BinDir   = Join-Path $RepoRoot '.bin'
$ExePath  = Join-Path $BinDir 'sysmlv2.exe'
$LibRoot  = Join-Path $BinDir "SysML-v2-Release-$SysmlReleaseVersion"
$LibDir   = Join-Path $LibRoot 'sysml.library'

New-Item -ItemType Directory -Force $BinDir | Out-Null

# ------------------------------------------------------------
# sysml-toolkit binary
# ------------------------------------------------------------
if ($Update -or -not (Test-Path $ExePath)) {
    Write-Host 'Fetching latest sysml-toolkit release info...'
    $release = Invoke-RestMethod 'https://api.github.com/repos/Open-MBEE/sysml-toolkit/releases/latest'

    $asset = $release.assets |
        Where-Object { $_.name -like 'sysmlv2-*-x86_64-pc-windows-msvc.zip' } |
        Select-Object -First 1
    if (-not $asset) {
        throw "No Windows x86_64 asset in release $($release.tag_name). Assets: $($release.assets.name -join ', ')"
    }

    $tmp = Join-Path ([IO.Path]::GetTempPath()) ("sysml-toolkit-" + [guid]::NewGuid())
    New-Item -ItemType Directory $tmp | Out-Null
    try {
        $zip = Join-Path $tmp $asset.name
        Write-Host "Downloading $($asset.name) ($($release.tag_name))..."
        Invoke-WebRequest $asset.browser_download_url -OutFile $zip

        # Verify checksum against SHA256SUMS if published.
        $sums = $release.assets | Where-Object name -eq 'SHA256SUMS' | Select-Object -First 1
        if ($sums) {
            $sumsText = (Invoke-WebRequest $sums.browser_download_url).Content
            if ($sumsText -is [byte[]]) { $sumsText = [Text.Encoding]::UTF8.GetString($sumsText) }
            $line = ($sumsText -split "`n") | Where-Object { $_ -match [regex]::Escape($asset.name) } | Select-Object -First 1
            if (-not $line) { throw "No checksum for $($asset.name) in SHA256SUMS." }
            $expected = ($line.Trim() -split '\s+')[0]
            $actual   = (Get-FileHash $zip -Algorithm SHA256).Hash
            if ($actual -ne $expected) { throw "Checksum mismatch for $($asset.name): expected $expected, got $actual" }
            Write-Host 'Checksum OK.'
        }

        $extract = Join-Path $tmp 'x'
        Expand-Archive $zip -DestinationPath $extract
        $exe = Get-ChildItem $extract -Recurse -Filter 'sysmlv2.exe' | Select-Object -First 1
        if (-not $exe) { throw "sysmlv2.exe not found in $($asset.name)." }

        Copy-Item $exe.FullName $ExePath -Force
        Set-Content (Join-Path $BinDir 'sysmlv2.version') $release.tag_name
        Write-Host "Installed sysml-toolkit $($release.tag_name) to $ExePath"
    }
    finally {
        Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# ------------------------------------------------------------
# SysML v2 standard library (sparse clone of sysml.library only)
# ------------------------------------------------------------
if (-not (Test-Path $LibDir)) {
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        throw 'git is required to download the SysML v2 standard library.'
    }
    Write-Host "Downloading SysML v2 standard library ($SysmlReleaseVersion)..."
    Remove-Item $LibRoot -Recurse -Force -ErrorAction SilentlyContinue
    git -c advice.detachedHead=false clone --quiet --depth 1 --filter=blob:none --sparse --branch $SysmlReleaseVersion `
        https://github.com/Systems-Modeling/SysML-v2-Release.git $LibRoot
    if ($LASTEXITCODE -ne 0) { throw 'git clone of SysML-v2-Release failed.' }
    git -C $LibRoot sparse-checkout set sysml.library
    if ($LASTEXITCODE -ne 0) { throw 'git sparse-checkout failed.' }
}

# ------------------------------------------------------------
# Run
# ------------------------------------------------------------
$files = @(Get-ChildItem $RepoRoot -Recurse -File -Filter '*.sysml' |
    Where-Object { $_.FullName -notlike "$BinDir*" } |
    Sort-Object FullName |
    ForEach-Object FullName)

if (-not $files) { throw 'No .sysml files found.' }

if (-not $SysmlArgs) { $SysmlArgs = @('check') }

$version = Get-Content (Join-Path $BinDir 'sysmlv2.version') -ErrorAction SilentlyContinue
Write-Host "sysml-toolkit $version | library $SysmlReleaseVersion | $($files.Count) file(s)"

# --version / help don't take model files.
if ($SysmlArgs[0] -in @('--version', '-V', '--help', '-h', 'help')) {
    & $ExePath @SysmlArgs
}
else {
    $cmd  = $SysmlArgs[0]
    $rest = @($SysmlArgs | Select-Object -Skip 1)
    & $ExePath $cmd --lib $LibDir @files @rest
}
exit $LASTEXITCODE
