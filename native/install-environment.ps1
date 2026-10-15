[CmdletBinding()]
param(
    [string]$Python = 'python',
    [string]$QtInstallRoot = 'D:\Dev\Qt'
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
Push-Location $PSScriptRoot
try {
    & $Python -m pip install -r requirements-build.txt
    if ($LASTEXITCODE -ne 0) { throw 'Python dependency installation failed' }
    $qtRoot = Join-Path $QtInstallRoot '6.8.3\mingw_64'
    $mingwRoot = Join-Path $QtInstallRoot 'Tools\mingw1310_64'
    if (!(Test-Path (Join-Path $qtRoot 'bin\qmake.exe'))) {
        & $Python -m aqt install-qt windows desktop 6.8.3 win64_mingw -O $QtInstallRoot
        if ($LASTEXITCODE -ne 0) { throw 'Qt installation failed' }
    }
    if (!(Test-Path (Join-Path $mingwRoot 'bin\g++.exe'))) {
        & $Python -m aqt install-tool windows desktop tools_mingw1310 qt.tools.win64_mingw1310 -O $QtInstallRoot
        if ($LASTEXITCODE -ne 0) { throw 'MinGW installation failed' }
    }
    # GCC's compiler subprocess loads this DLL from its own executable directory.
    $compilerDirectory = Join-Path $mingwRoot 'libexec\gcc\x86_64-w64-mingw32\13.1.0'
    Copy-Item (Join-Path $mingwRoot 'bin\libwinpthread-1.dll') $compilerDirectory -Force
    & (Join-Path $compilerDirectory 'cc1plus.exe') --version
    if ($LASTEXITCODE -ne 0) { throw 'Compiler subprocess dependency check failed' }
    Write-Output "Environment ready: $qtRoot; $mingwRoot"
} finally { Pop-Location }
