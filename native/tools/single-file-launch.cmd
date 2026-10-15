@echo off
setlocal EnableExtensions
set "ROOT=%~dp0"
set "TARGET=%TEMP%\HadesTools-v0.2.6-%RANDOM%-%RANDOM%"
if not exist "%TARGET%" mkdir "%TARGET%"
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -LiteralPath '%ROOT%payload.zip' -DestinationPath '%TARGET%' -Force"
if errorlevel 1 exit /b 1
for /d %%D in ("%TARGET%\HadesTools-v0.2.6") do set "APP=%%~fD"
if not defined APP exit /b 1
start "Hades Tools" "%APP%\HadesTools.exe"
exit /b 0
