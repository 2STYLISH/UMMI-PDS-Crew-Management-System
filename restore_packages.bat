@echo off
REM ============================================================
REM UMMI Crew Management Module ? NuGet Package Restore
REM Run this BEFORE opening in Visual Studio for the first time
REM Requires: nuget.exe in PATH or in this directory
REM ============================================================
ECHO Restoring NuGet packages for CrewMgmt...
nuget restore "%~dp0CrewMgmt\CrewMgmt.vbproj" -PackagesDirectory "%~dp0packages"
IF %ERRORLEVEL% NEQ 0 (
    ECHO.
    ECHO nuget.exe not found. Downloading...
    powershell -Command "Invoke-WebRequest https://dist.nuget.org/win-x86-commandline/latest/nuget.exe -OutFile nuget.exe"
    nuget.exe restore "%~dp0CrewMgmt\CrewMgmt.vbproj" -PackagesDirectory "%~dp0packages"
)
ECHO Done. Open CrewMgmt.sln in Visual Studio.
PAUSE
