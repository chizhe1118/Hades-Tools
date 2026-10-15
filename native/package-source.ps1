[CmdletBinding()]
param([string]$Version = '0.2.6')
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
if ($Version -ne '0.2.6') { throw 'Update the source version before packaging a new release' }
Push-Location $PSScriptRoot
try {
    $distRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot 'dist'))
    $sourceRoot = [IO.Path]::GetFullPath((Join-Path $distRoot "HadesTools-v$Version-source"))
    if (!$sourceRoot.StartsWith($distRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
        throw 'Source staging path is outside the build output directory'
    }
    if (Test-Path $sourceRoot) { Remove-Item -LiteralPath $sourceRoot -Recurse -Force }
    $nativeDir = Join-Path $sourceRoot 'native'
    $thirdPartyDir = Join-Path $nativeDir 'third_party'
    $bridgeDir = Join-Path $sourceRoot 'analysis\hades_trainer'
    New-Item -ItemType Directory -Path $nativeDir,$thirdPartyDir,$bridgeDir -Force | Out-Null
    Copy-Item src,tools,licenses,translations $nativeDir -Recurse
    Copy-Item LICENSE $sourceRoot
    Copy-Item CMakeLists.txt,HadesToolsBridge.spec,requirements-build.txt,requirements-translation.txt,README.md,THIRD_PARTY_NOTICES.md,LICENSE,*.ps1 $nativeDir
    Copy-Item .gitignore $nativeDir
    Copy-Item third_party\material-components-qml.revision $thirdPartyDir
    $vendorSource = (Resolve-Path third_party\material-components-qml).Path
    $vendorTarget = Join-Path $thirdPartyDir 'material-components-qml'
    New-Item -ItemType Directory -Path $vendorTarget | Out-Null
    Copy-Item (Join-Path $vendorSource 'README.md') $vendorTarget
    New-Item -ItemType Directory -Path (Join-Path $vendorTarget 'src'),(Join-Path $vendorTarget '3rdparty') | Out-Null
    Copy-Item (Join-Path $vendorSource 'src\Core') (Join-Path $vendorTarget 'src\Core') -Recurse
    Copy-Item (Join-Path $vendorSource '3rdparty\material-color-utilities') `
        (Join-Path $vendorTarget '3rdparty\material-color-utilities') -Recurse
    foreach ($name in @('hades_tools_backend.py','hades_tools_runtime.js','hades_tools_commands.lua','hades_tools_json.lua','hades_tools_ui.html','hades_runtime_profile.json')) {
        Copy-Item (Join-Path '..\analysis\hades_trainer' $name) $bridgeDir
    }
    $verificationDir = Join-Path $nativeDir 'verification'
    New-Item -ItemType Directory -Path $verificationDir | Out-Null
    foreach ($pattern in @('v028-*','v027-*','v026-*','v025-*','v024-*')) {
        Get-ChildItem -Path (Join-Path verification $pattern) -File -ErrorAction SilentlyContinue | ForEach-Object {
            Copy-Item -LiteralPath $_.FullName $verificationDir
        }
    }
    Get-ChildItem -Path verification\v023-* -File -ErrorAction SilentlyContinue | ForEach-Object {
        Copy-Item -LiteralPath $_.FullName $verificationDir
    }
    foreach ($pattern in @('v022-REPORT.md','v022-build.log','v022-final-build.log','v022-final-package.log','v022-release.err','v022-release-manifest.json','v022-ui-checks.json','v022-final-state.json','v022-final-command-check.json','v022-desktop-check.py','v022-desktop-check.log','v022-layout-check.py','v022-layout-check.log','v022-final-*.png','v022-*-default-*.png','v022-*-min-*.png','v022-*tooltip*.png','v022-focused-draft.png','v022-logs-zh.png')) {
        Get-ChildItem -Path (Join-Path verification $pattern) -File -ErrorAction SilentlyContinue | ForEach-Object {
            Copy-Item -LiteralPath $_.FullName $verificationDir
        }
    }
    foreach ($pattern in @('v021-REPORT.md','v021-build.log','v021-package.log','v021-release.err','v021-ui.err','v021-state.json','v021-final-state.json','v021-final-preview.png','v021-transitions.gif','v021-about-*.png','v021-logs-*.png')) {
        Get-ChildItem -Path (Join-Path verification $pattern) -File -ErrorAction SilentlyContinue | ForEach-Object {
            Copy-Item -LiteralPath $_.FullName $verificationDir
        }
    }
    foreach ($pattern in @('REPORT.md','v020-REPORT.md','v020-release*.png','v020-release*.json','v020-release.err','v020-release.out','v020-lifecycle.err','v020-logs-error-en.png','v020-logs-idle-en.png','v020-final-build.log','v020-final-package.log','v020-ui-checks.json','v020-desktop-check.py','v020-live-speed.png','v020-focused-draft.png','v020-resources-live-en.png','v020-overview-*.png','v020-resources-*.png','v020-items-*.png','v020-boons-*.png','v020-rewards-*.png','v020-weapons-*.png','final-release*','final-build.log','final-package.log','standalone-ui*.json','standalone-catalog.json','standalone-spawn*.json','standalone-spawn.png','standalone-weapons.png','standalone-traits.png','standalone-loot.png','standalone-resources.png')) {
        Get-ChildItem -Path (Join-Path verification $pattern) -File -ErrorAction SilentlyContinue | ForEach-Object {
            Copy-Item -LiteralPath $_.FullName $verificationDir
        }
    }
    Get-ChildItem -LiteralPath $sourceRoot -Directory -Recurse -Filter '__pycache__' | ForEach-Object {
        Remove-Item -LiteralPath $_.FullName -Recurse -Force
    }
    $zip = Join-Path $distRoot "HadesTools-v$Version-source.zip"
    Compress-Archive -Path $sourceRoot -DestinationPath $zip -CompressionLevel Optimal -Force
    "$( (Get-FileHash $zip -Algorithm SHA256).Hash.ToLowerInvariant() )  $([IO.Path]::GetFileName($zip))" |
        Set-Content "$zip.sha256" -Encoding ASCII
    Write-Output $zip
} finally { Pop-Location }
