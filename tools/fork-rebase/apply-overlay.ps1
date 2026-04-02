param(
  [Parameter(Mandatory = $true)]
  [string]$TargetRepo,

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
  $SourceRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\.." )).Path
}
else {
  $SourceRoot = (Resolve-Path $SourceRoot).Path
}

$targetRepoPath = (Resolve-Path $TargetRepo).Path
$targetOpencodeRoot = Join-Path $targetRepoPath ".opencode"
if (-not (Test-Path -LiteralPath $targetOpencodeRoot)) {
  throw "Target repo does not contain .opencode/: $targetRepoPath"
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

if ($entries.Count -eq 0) {
  throw "No entries in manifest: $manifestPath"
}

$missingSources = New-Object System.Collections.Generic.List[string]
$copied = New-Object System.Collections.Generic.List[string]

Write-Host "Applying overlay" -ForegroundColor Cyan
Write-Host "- SourceRoot: $SourceRoot"
Write-Host "- TargetRepo: $targetRepoPath"
Write-Host "- DryRun: $DryRun"

foreach ($entry in $entries) {
  $mapping = Parse-ManifestEntry -Line $entry

  $srcRelative = $mapping.Source.Replace('/', [IO.Path]::DirectorySeparatorChar)
  $dstRelative = $mapping.Target.Replace('/', [IO.Path]::DirectorySeparatorChar)

  $src = Join-Path $SourceRoot $srcRelative
  $dst = Join-Path $targetOpencodeRoot $dstRelative

  if (-not (Test-Path -LiteralPath $src)) {
    $missingSources.Add($mapping.Display)
    Write-Host "MISS  $($mapping.Display)" -ForegroundColor Yellow
    continue
  }

  if ($DryRun) {
    Write-Host "COPY  $($mapping.Display)"
    $copied.Add($mapping.Display)
    continue
  }

  $dstDir = Split-Path -Path $dst -Parent
  if (-not (Test-Path -LiteralPath $dstDir)) {
    New-Item -ItemType Directory -Path $dstDir -Force | Out-Null
  }

  Copy-Item -LiteralPath $src -Destination $dst -Force
  Write-Host "COPY  $($mapping.Display)"
  $copied.Add($mapping.Display)
}

Write-Host ""
Write-Host "Overlay result" -ForegroundColor Cyan
Write-Host "- Copied: $($copied.Count)"
Write-Host "- Missing source files: $($missingSources.Count)"

if ($missingSources.Count -gt 0) {
  Write-Host ""
  Write-Host "Missing source files:" -ForegroundColor Yellow
  foreach ($m in $missingSources) {
    Write-Host "- $m"
  }

  if ($FailOnMissing) {
    throw "Overlay failed due to missing source files."
  }
}

Write-Host ""
Write-Host "Done. Review changes in target repo with git status/diff." -ForegroundColor Green
