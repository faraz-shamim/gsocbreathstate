$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$optimizer = Join-Path $PSScriptRoot 'optimize_vr_glb.ps1'
$outputRoot = Join-Path $repoRoot 'web\vr\assets\sanctuary_v3\atmosphere'

Push-Location $repoRoot
try {
  & $optimizer `
    -InputAsset 'web\vr\assets\new\moon.glb' `
    -OutputAsset 'web\vr\assets\sanctuary_v3\atmosphere\moon_quest.glb' `
    -TextureCodec webp `
    -TextureSize 1024 `
    -SimplifyRatio 0.75 `
    -SimplifyError 0.001

  & $optimizer `
    -InputAsset 'web\vr\assets\new\aurora.glb' `
    -OutputAsset 'web\vr\assets\sanctuary_v3\atmosphere\aurora_quest.glb' `
    -TextureCodec webp `
    -TextureSize 512 `
    -SimplifyRatio 0.05 `
    -SimplifyError 0.025

  New-Item -ItemType Directory -Force -Path $outputRoot | Out-Null
  Copy-Item `
    -LiteralPath 'web\vr\assets\scene_v2\moon_albedo.webp' `
    -Destination (Join-Path $outputRoot 'moon_albedo.webp') `
    -Force
  Copy-Item `
    -LiteralPath 'web\vr\assets\scene_v2\moon_normal.webp' `
    -Destination (Join-Path $outputRoot 'moon_normal.webp') `
    -Force
} finally {
  Pop-Location
}

Write-Host "Sanctuary V3 atmosphere assets built in $outputRoot"
