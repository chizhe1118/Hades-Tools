[CmdletBinding()]
param([string]$Version = '0.2.6', [string]$MingwRoot = 'D:\Dev\Qt\Tools\mingw1310_64')
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
if ($Version -ne '0.2.6') { throw 'Update the application version before packaging a new release' }
Push-Location $PSScriptRoot
try {
    $distRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot 'dist'))
    $zip = Join-Path $distRoot "HadesTools-v$Version-win64.zip"
    if (!(Test-Path $zip)) { throw 'Run package.ps1 first' }
    $launcher = Join-Path $distRoot "HadesTools-v$Version-single.exe"
    $object = Join-Path $distRoot '_single_launcher.o'
    $source = Join-Path $PSScriptRoot 'tools\single_file_launcher.cpp'
    $compiler = Join-Path $MingwRoot 'bin\g++.exe'
    & $compiler -std=c++17 -O2 -static -municode -mwindows $source -o $launcher
    if ($LASTEXITCODE -ne 0) { throw 'Single-file launcher compilation failed' }
    $payload = [IO.File]::ReadAllBytes($zip)
    $marker = [Text.Encoding]::ASCII.GetBytes("HADES_TOOLS_PAYLOAD_V1`n")
    $stream = [IO.File]::Open($launcher, [IO.FileMode]::Append)
    try {
        $stream.Write($payload, 0, $payload.Length)
        $lengthBytes = [BitConverter]::GetBytes([UInt64]$payload.Length)
        $stream.Write($lengthBytes, 0, $lengthBytes.Length)
        $stream.Write($marker, 0, $marker.Length)
    } finally { $stream.Dispose() }
    $hash = (Get-FileHash $launcher -Algorithm SHA256).Hash.ToLowerInvariant()
    "$hash  $([IO.Path]::GetFileName($launcher))" | Set-Content "$launcher.sha256" -Encoding ASCII
    Write-Output $launcher
} finally { Pop-Location }
