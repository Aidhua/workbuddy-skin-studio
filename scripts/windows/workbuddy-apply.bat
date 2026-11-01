@echo off
setlocal
REM ASCII-only: Chinese messages are printed by PowerShell (UTF-8).
powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%~dp0workbuddy-apply.ps1" %*
set "HEIGE_EXIT=%ERRORLEVEL%"
if not "%HEIGE_EXIT%"=="0" (
  if /I not "%HEIGE_NO_PAUSE%"=="1" pause
  exit /b %HEIGE_EXIT%
)
exit /b 0
