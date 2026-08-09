param(
  [string]$SourceAsset = 'web/vr/assets/new/falling_leaves.glb',
  [string]$OutputAsset = 'web/vr/assets/sanctuary_v3/tree/falling_leaves_animated_quest.glb'
)

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$sourcePath = (Resolve-Path (Join-Path $repoRoot $SourceAsset)).Path
$outputPath = [System.IO.Path]::GetFullPath((Join-Path $repoRoot $OutputAsset))
$outputDirectory = Split-Path -Parent $outputPath
$stageDirectory = Join-Path $repoRoot '.dart_tool/vr_sanctuary_v3_petals'
$metalRoughStage = Join-Path $stageDirectory 'falling_leaves_metalrough.glb'
$resizeStage = Join-Path $stageDirectory 'falling_leaves_512.glb'
$webpStage = Join-Path $stageDirectory 'falling_leaves_webp.glb'

New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null
New-Item -ItemType Directory -Force -Path $stageDirectory | Out-Null
$env:npm_config_cache = Join-Path $repoRoot '.npm-cache'
$cli = '@gltf-transform/cli@4.4.1'

try {
  & npx.cmd --yes $cli metalrough $sourcePath $metalRoughStage
  if ($LASTEXITCODE -ne 0) { throw 'Falling-leaf metal/rough conversion failed' }

  & npx.cmd --yes $cli resize $metalRoughStage $resizeStage --width 512 --height 512
  if ($LASTEXITCODE -ne 0) { throw 'Falling-leaf texture resize failed' }

  & npx.cmd --yes $cli webp $resizeStage $webpStage --quality 82
  if ($LASTEXITCODE -ne 0) { throw 'Falling-leaf WebP conversion failed' }

  # Generic mesh quantization changes the bounds of this skinned asset, so the
  # authored skeleton and transforms are intentionally kept unquantized.
  Copy-Item -LiteralPath $webpStage -Destination $outputPath -Force
  Write-Host "Animated falling-leaf GLB written to $outputPath"
} finally {
  if (Test-Path $stageDirectory) {
    Remove-Item -LiteralPath $stageDirectory -Recurse -Force
  }
}
