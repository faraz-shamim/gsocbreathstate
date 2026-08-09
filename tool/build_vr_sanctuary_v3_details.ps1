param(
  [switch]$SkipExisting
)

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$optimizer = Join-Path $PSScriptRoot 'optimize_vr_glb.ps1'
$sourceRoot = Join-Path $repoRoot 'web\vr\assets\new'
$outputRoot = Join-Path $repoRoot 'web\vr\assets\sanctuary_v3\details'

$assets = @(
  @{ Name = 'rock1'; Ratio = 0.28; Texture = 512; Error = 0.002 },
  @{ Name = 'rock2'; Ratio = 0.28; Texture = 512; Error = 0.002 },
  @{ Name = 'rock3'; Ratio = 0.08; Texture = 512; Error = 0.02 },
  @{ Name = 'rock_pack'; Ratio = 1.0; Texture = 512; Error = 0.002 },
  @{ Name = 'lavender'; Ratio = 1.0; Texture = 256; Error = 0.002 },
  @{ Name = 'chamomile'; Ratio = 0.08; Texture = 256; Error = 0.02 },
  @{ Name = 'glowing_plants'; OutputName = 'glowing_plants_parts'; PreserveParts = $true; Ratio = 1.0; Texture = 512; Error = 0.002 },
  @{ Name = 'bush1'; Ratio = 0.12; Texture = 256; Error = 0.02 },
  @{ Name = 'bush2'; Ratio = 1.0; Texture = 512; Error = 0.002 },
  @{ Name = 'bush3'; Ratio = 0.01; Texture = 256; Error = 0.08 },
  @{ Name = 'bush4'; Ratio = 1.0; Texture = 256; Error = 0.002 },
  @{ Name = 'bush5'; Ratio = 0.35; Texture = 512; Error = 0.002 }
)

Push-Location $repoRoot
try {
  foreach ($asset in $assets) {
    $inputPath = Join-Path $sourceRoot "$($asset.Name).glb"
    $outputName = if ($asset.OutputName) { $asset.OutputName } else { $asset.Name }
    $outputPath = "web\vr\assets\sanctuary_v3\details\$($outputName)_quest.glb"
    if ($SkipExisting -and (Test-Path $outputPath)) {
      Write-Host "Keeping existing $outputPath"
      continue
    }
    & $optimizer `
      -InputAsset $inputPath `
      -OutputAsset $outputPath `
      -TextureCodec webp `
      -TextureSize $asset.Texture `
      -SimplifyRatio $asset.Ratio `
      -SimplifyError $asset.Error `
      -PreserveParts:$($asset.PreserveParts -eq $true)
  }
} finally {
  Pop-Location
}

Write-Host "Sanctuary V3 detail assets built in $outputRoot"
