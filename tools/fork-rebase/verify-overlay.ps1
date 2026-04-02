param(
  [Parameter(Mandatory = $true)]
  [string]$TargetRepo,

  [string]$SourceRoot = ""
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
    $path = $parts[0].Trim()
    if ([string]::IsNullOrWhiteSpace($path)) {
      throw "Invalid manifest entry: '$Line'"
    }

    return [PSCustomObject]@{
      Source = $path
      Target = $path
      Display = $path
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

$missing = New-Object System.Collections.Generic.List[string]
$different = New-Object System.Collections.Generic.List[string]
$matched = New-Object System.Collections.Generic.List[string]

foreach ($entry in $entries) {
  $mapping = Parse-ManifestEntry -Line $entry

  $srcRelative = $mapping.Source.Replace('/', [IO.Path]::DirectorySeparatorChar)
  $dstRelative = $mapping.Target.Replace('/', [IO.Path]::DirectorySeparatorChar)

  $src = Join-Path $SourceRoot $srcRelative
  $dst = Join-Path $targetOpencodeRoot $dstRelative

  if (-not (Test-Path -LiteralPath $src) -or -not (Test-Path -LiteralPath $dst)) {
    $missing.Add($mapping.Display)
    continue
  }

  $srcHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $src).Hash
  $dstHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $dst).Hash

  if ($srcHash -eq $dstHash) {
    $matched.Add($mapping.Display)
  }
  else {
    $different.Add($mapping.Display)
  }
}

Write-Host "Overlay verification" -ForegroundColor Cyan
Write-Host "- Matched: $($matched.Count)"
Write-Host "- Different: $($different.Count)"
Write-Host "- Missing: $($missing.Count)"

if ($different.Count -gt 0) {
  Write-Host ""
  Write-Host "Different files:" -ForegroundColor Yellow
  foreach ($d in $different) {
    Write-Host "- $d"
  }
}

if ($missing.Count -gt 0) {
  Write-Host ""
  Write-Host "Missing files:" -ForegroundColor Yellow
  foreach ($m in $missing) {
    Write-Host "- $m"
  }
}

if ($different.Count -eq 0 -and $missing.Count -eq 0) {
  Write-Host ""
  Write-Host "PASS: target repo is aligned with overlay manifest." -ForegroundColor Green
  exit 0
}

Write-Host ""
Write-Host "HOLD: target repo is not fully aligned with overlay manifest." -ForegroundColor Red
exit 2
