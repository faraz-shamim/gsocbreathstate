param(
  [switch]$RefreshVendor,
  [switch]$SkipInventory
)

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$assetTools = Join-Path $repoRoot '.asset-tools'
$npmCache = Join-Path $repoRoot '.npm-cache'
$threeVersion = '0.164.1'
$threeExtract = Join-Path $assetTools "three-$threeVersion-extract\package"
$threeTarget = Join-Path $repoRoot "web\vr\vendor\three\$threeVersion"

New-Item -ItemType Directory -Force -Path $assetTools | Out-Null
New-Item -ItemType Directory -Force -Path $npmCache | Out-Null
$env:npm_config_cache = $npmCache

if ($RefreshVendor -or -not (Test-Path (Join-Path $threeExtract 'build\three.module.js'))) {
  $archive = npm.cmd pack "three@$threeVersion" --pack-destination $assetTools --silent
  $extractContainer = Join-Path $assetTools "three-$threeVersion-extract"
  if (-not (Test-Path $extractContainer)) {
    New-Item -ItemType Directory -Path $extractContainer | Out-Null
  }
  tar.exe -xf (Join-Path $assetTools $archive.Trim()) -C $extractContainer
}

python (Join-Path $PSScriptRoot 'vendor_three_modules.py') `
  --source-package $threeExtract `
  --target $threeTarget

python (Join-Path $PSScriptRoot 'extract_grass_variants.py') `
  (Join-Path $repoRoot 'web\vr\assets\new\Animated+Grass.glb') `
  (Join-Path $repoRoot 'web\vr\assets\sanctuary_v3\environment\animated_grass_variants.glb')

$pipeline = Join-Path $PSScriptRoot 'vr_sanctuary_v3_pipeline.py'
if (-not $SkipInventory) {
  python $pipeline --write-inventory
}
python $pipeline --audit --validate --strict --check-inventory

Write-Host 'Sanctuary V3 asset build contract passed.'
