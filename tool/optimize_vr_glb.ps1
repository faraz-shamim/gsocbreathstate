param(
  [Parameter(Mandatory = $true)]
  [string]$InputAsset,

  [Parameter(Mandatory = $true)]
  [string]$OutputAsset,

  [ValidateSet('webp', 'uastc', 'etc1s')]
  [string]$TextureCodec = 'webp',

  [int]$TextureSize = 2048,
  [double]$SimplifyRatio = 1.0,
  [double]$SimplifyError = 0.001,
  [switch]$PreserveParts
)

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$inputPath = (Resolve-Path $InputAsset).Path
$outputPath = [System.IO.Path]::GetFullPath((Join-Path (Get-Location) $OutputAsset))
$outputDirectory = Split-Path -Parent $outputPath
if (-not (Test-Path $outputDirectory)) {
  New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null
}

$env:npm_config_cache = Join-Path $repoRoot '.npm-cache'
$cli = '@gltf-transform/cli@4.4.1'
$stagePath = if ($TextureCodec -eq 'webp') {
  $outputPath
} else {
  [System.IO.Path]::ChangeExtension($outputPath, '.meshopt-stage.glb')
}

$optimizeArgs = @(
  '--yes', $cli, 'optimize', $inputPath, $stagePath,
  '--compress', 'meshopt',
  '--texture-compress', 'webp',
  '--texture-size', $TextureSize
)

if ($PreserveParts) {
  $optimizeArgs += @(
    '--flatten', 'false',
    '--join', 'false',
    '--instance', 'false',
    '--palette', 'false'
  )
}

if ($SimplifyRatio -lt 1.0) {
  $optimizeArgs += @(
    '--simplify', 'true',
    '--simplify-ratio', $SimplifyRatio,
    '--simplify-error', $SimplifyError
  )
} else {
  $optimizeArgs += @('--simplify', 'false')
}

& npx.cmd @optimizeArgs
if ($LASTEXITCODE -ne 0) {
  throw "glTF optimization failed with exit code $LASTEXITCODE"
}

if ($TextureCodec -ne 'webp') {
  $textureArgs = @('--yes', $cli, $TextureCodec, $stagePath, $outputPath)
  if ($TextureCodec -eq 'uastc') {
    $textureArgs += @('--level', '2', '--rdo', '4')
  } else {
    $textureArgs += @('--quality', '180')
  }
  try {
    & npx.cmd @textureArgs
    if ($LASTEXITCODE -ne 0) {
      throw "KTX2 texture compression failed with exit code $LASTEXITCODE"
    }
  } finally {
    if (Test-Path $stagePath) {
      Remove-Item -LiteralPath $stagePath -Force
    }
  }
}

Write-Host "Optimized GLB written to $outputPath"
