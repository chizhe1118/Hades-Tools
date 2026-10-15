[CmdletBinding()]
param(
    [string]$Python = 'python',
    [string]$QtRoot = 'D:\Dev\Qt\6.8.3\mingw_64',
    [string]$MingwRoot = 'D:\Dev\Qt\Tools\mingw1310_64',
    [string]$Version = '0.2.6'
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
if ($Version -ne '0.2.6') { throw 'Update the application version before packaging a new release' }
$originalPath = $env:Path
Push-Location $PSScriptRoot
try {
    $distRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot 'dist'))
    $packageDir = [IO.Path]::GetFullPath((Join-Path $distRoot "HadesTools-v$Version"))
    if (!$packageDir.StartsWith($distRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
        throw 'Distribution path is outside the build output directory'
    }
    $running = @(Get-CimInstance Win32_Process | Where-Object {
        $_.ExecutablePath -and $_.ExecutablePath.StartsWith($packageDir + '\', [StringComparison]::OrdinalIgnoreCase)
    })
    if ($running.Count) { throw 'Close the release application and its bridge before packaging' }
    if (!(Test-Path build\bin\HadesTools.exe) -or !(Test-Path bridge-dist\HadesToolsBridge\HadesToolsBridge.exe)) {
        throw 'Run build.ps1 first'
    }
    if (Test-Path $packageDir) { Remove-Item -LiteralPath $packageDir -Recurse -Force }
    New-Item -ItemType Directory -Path $packageDir | Out-Null
    Copy-Item build\bin\HadesTools.exe $packageDir
    Copy-Item translations (Join-Path $packageDir 'translations') -Recurse
    Copy-Item bridge-dist\HadesToolsBridge (Join-Path $packageDir 'bridge') -Recurse
    $env:Path = "$(Join-Path $MingwRoot 'bin');$(Join-Path $QtRoot 'bin');$originalPath"
    & (Join-Path $QtRoot 'bin\windeployqt.exe') --release --qmldir src\qml --qmlimport build\qml `
        --no-translations --compiler-runtime (Join-Path $packageDir 'HadesTools.exe')
    if ($LASTEXITCODE -ne 0) { throw 'Qt dependency deployment failed' }
    Copy-Item licenses (Join-Path $packageDir 'licenses') -Recurse
    Copy-Item README.md,THIRD_PARTY_NOTICES.md,LICENSE $packageDir
    Copy-Item third_party\material-components-qml\README.md (Join-Path $packageDir 'licenses\material-components-qml-README.md')
    $exe = Join-Path $packageDir 'HadesTools.exe'
    $md3Revision = (Get-Content third_party\material-components-qml.revision -Raw).Trim()
    $versions = (& $Python tools\package_versions.py) | ConvertFrom-Json
    if ($LASTEXITCODE -ne 0) { throw 'Dependency version collection failed' }
    $profile = Get-Content ..\analysis\hades_trainer\hades_runtime_profile.json -Raw | ConvertFrom-Json
    $manifest = [ordered]@{
        name='Hades Tools'; version=$Version; platform='Windows x64'; builtAt=(Get-Date).ToUniversalTime().ToString('o')
        qt='6.8.3'; mingw='13.1.0'; dependencies=$versions; materialComponentsQml=$md3Revision
        game=[ordered]@{name='Hades'; steamBuildId=$profile.steam_buildid; engineSha256=$profile.engine_sha256}
        executableSha256=(Get-FileHash $exe -Algorithm SHA256).Hash.ToLowerInvariant()
        bridgeSha256=(Get-FileHash (Join-Path $packageDir 'bridge\HadesToolsBridge.exe') -Algorithm SHA256).Hash.ToLowerInvariant()
        catalogTranslationsSha256=(Get-FileHash (Join-Path $packageDir 'translations\catalog.zh-CN.json') -Algorithm SHA256).Hash.ToLowerInvariant()
    }
    $manifest | ConvertTo-Json -Depth 6 | Set-Content (Join-Path $packageDir 'release-manifest.json') -Encoding UTF8
    $zip = Join-Path $distRoot "HadesTools-v$Version-win64.zip"
    Compress-Archive -Path $packageDir -DestinationPath $zip -CompressionLevel Optimal -Force
    "$( (Get-FileHash $zip -Algorithm SHA256).Hash.ToLowerInvariant() )  $([IO.Path]::GetFileName($zip))" |
        Set-Content "$zip.sha256" -Encoding ASCII
    Write-Output $exe
    Write-Output $zip
} finally {
    $env:Path = $originalPath
    Pop-Location
}
