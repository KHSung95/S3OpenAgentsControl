param(
  [string]$TargetPath = "",

  [string]$SourceRoot = "",

  [switch]$DryRun,

  [switch]$FailOnMissing
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$manifestPath = Join-Path $PSScriptRoot "overlay-manifest.txt"
if (-not (Test-Path -LiteralPath $manifestPath)) {
  throw "Manifest not found: $manifestPath"
}

if ([string]::IsNullOrWhiteSpace($SourceRoot)) {
  $SourceRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..\overlay\desktop")).Path
}
else {
  $SourceRoot = (Resolve-Path $SourceRoot).Path
}

if ([string]::IsNullOrWhiteSpace($TargetPath)) {
  if (-not [string]::IsNullOrWhiteSpace($env:OPENCODE_HOME)) {
    $TargetPath = $env:OPENCODE_HOME
  }
  elseif (-not [string]::IsNullOrWhiteSpace($env:XDG_CONFIG_HOME)) {
    $TargetPath = Join-Path $env:XDG_CONFIG_HOME "opencode"
  }
  else {
    $TargetPath = Join-Path $HOME ".config\opencode"
  }
}

if (Test-Path -LiteralPath $TargetPath) {
  $targetRoot = (Resolve-Path $TargetPath).Path
}
elseif ($DryRun) {
  $targetRoot = [IO.Path]::GetFullPath($TargetPath)
}
else {
  New-Item -ItemType Directory -Path $TargetPath -Force | Out-Null
  $targetRoot = (Resolve-Path $TargetPath).Path
}

$entries = Get-Content -LiteralPath $manifestPath |
  ForEach-Object { $_.Trim() } |
  Where-Object { $_ -ne "" -and -not $_.StartsWith("#") }

function Parse-ManifestEntry {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Line
  )

  $parts = $Line -split "=>", 2
  if ($parts.Count -eq 1) {
    $source = $parts[0].Trim()
    if ([string]::IsNullOrWhiteSpace($source)) {
      throw "Invalid manifest entry: '$Line'"
    }

    return [PSCustomObject]@{
      Source = $source
      Target = $source
      Display = $source
    }
  }

  $source = $parts[0].Trim()
  $target = $parts[1].Trim()

  if ([string]::IsNullOrWhiteSpace($source) -or [string]::IsNullOrWhiteSpace($target)) {
    throw "Invalid manifest entry: '$Line'"
  }

  return [PSCustomObject]@{
    Source = $source
    Target = $target
    Display = "$source => $target"
  }
}

$missingSources = New-Object System.Collections.Generic.List[string]
$installed = New-Object System.Collections.Generic.List[string]

Write-Host "Installing OpenCode config overlay" -ForegroundColor Cyan
Write-Host "- SourceRoot: $SourceRoot"
Write-Host "- TargetPath: $targetRoot"
Write-Host "- DryRun: $DryRun"

foreach ($entry in $entries) {
  $mapping = Parse-ManifestEntry -Line $entry
  $sourceRelative = $mapping.Source.Replace('/', [IO.Path]::DirectorySeparatorChar)

  $src = Join-Path $SourceRoot $sourceRelative
  $dst = Join-Path $targetRoot $sourceRelative

  if (-not (Test-Path -LiteralPath $src)) {
    $missingSources.Add($mapping.Display)
    Write-Host "MISS  $($mapping.Display)" -ForegroundColor Yellow
    continue
  }

  if ($DryRun) {
    Write-Host "COPY  $($mapping.Source)"
    $installed.Add($mapping.Source)
    continue
  }

  $dstDir = Split-Path -Path $dst -Parent
  if (-not (Test-Path -LiteralPath $dstDir)) {
    New-Item -ItemType Directory -Path $dstDir -Force | Out-Null
  }

  Copy-Item -LiteralPath $src -Destination $dst -Force
  Write-Host "COPY  $($mapping.Source)"
  $installed.Add($mapping.Source)
}

Write-Host ""
Write-Host "Install result" -ForegroundColor Cyan
Write-Host "- Copied: $($installed.Count)"
Write-Host "- Missing source files: $($missingSources.Count)"

if ($missingSources.Count -gt 0) {
  Write-Host ""
  Write-Host "Missing source files:" -ForegroundColor Yellow
  foreach ($m in $missingSources) {
    Write-Host "- $m"
  }

  if ($FailOnMissing) {
    throw "Install failed due to missing source files."
  }
}

Write-Host ""
Write-Host "Done. Your local OpenCode config path is updated." -ForegroundColor Green
