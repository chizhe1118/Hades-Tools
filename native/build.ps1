[CmdletBinding()]
param(
    [string]$Python = 'python',
    [string]$QtRoot = 'D:\Dev\Qt\6.8.3\mingw_64',
    [string]$MingwRoot = 'D:\Dev\Qt\Tools\mingw1310_64',
    [int]$Parallel = 6
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$originalPath = $env:Path
Push-Location $PSScriptRoot
try {
    $cmakeBin = (& $Python -c 'import cmake; print(cmake.CMAKE_BIN_DIR)').Trim()
    if ($LASTEXITCODE -ne 0) { throw 'CMake Python package is missing' }
    $ninjaBin = (& $Python -c 'import ninja; print(ninja.BIN_DIR)').Trim()
    if ($LASTEXITCODE -ne 0) { throw 'Ninja Python package is missing' }
    $cmake = Join-Path $cmakeBin 'cmake.exe'
    $env:Path = "$(Join-Path $MingwRoot 'bin');$(Join-Path $QtRoot 'bin');$cmakeBin;$ninjaBin;$originalPath"
    & $cmake -S . -B build -G Ninja '-DCMAKE_BUILD_TYPE=Release' `
        "-DCMAKE_PREFIX_PATH=$QtRoot" "-DCMAKE_CXX_COMPILER=$(Join-Path $MingwRoot 'bin\c++.exe')" `
        "-DCMAKE_MAKE_PROGRAM=$(Join-Path $ninjaBin 'ninja.exe')"
    if ($LASTEXITCODE -ne 0) { throw 'CMake configuration failed' }
    & $cmake --build build --parallel $Parallel
    if ($LASTEXITCODE -ne 0) { throw 'Native application build failed' }
    & $Python -m PyInstaller --noconfirm --clean --distpath bridge-dist --workpath bridge-build HadesToolsBridge.spec
    if ($LASTEXITCODE -ne 0) { throw 'Bridge packaging failed' }
    Write-Output (Join-Path $PSScriptRoot 'build\bin\HadesTools.exe')
} finally {
    $env:Path = $originalPath
    Pop-Location
}
