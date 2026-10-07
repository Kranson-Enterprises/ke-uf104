@echo off
REM ============================================================================
REM  setup-env.bat - configure the environment for a Uniface 10 CLI build.
REM
REM  Edit UNIFACE_HOME below to match this machine. build.bat calls this script
REM  automatically; CI also runs it as its own step before build.bat.
REM
REM  RULE: quote any path with spaces as a WHOLE token. The Community Edition
REM  install root has TWO spaced segments ("Program Files" and "Rocket Uniface
REM  10 Community Edition"), so the  set "NAME=VALUE"  form (quotes around the
REM  whole assignment) is mandatory - see
REM  .claude\rules\quote-paths-with-spaces.md and worklog/002-003.
REM ============================================================================

REM -- Install root (contains common\bin\ide.exe and uniface\adm). -------------
REM    This machine's install is C:\ref (space-free, chosen deliberately - see
REM    worklog/011). Change to your install root if different.
set "UNIFACE_HOME=C:\ref"

REM -- Derived locations (normally no need to edit). ---------------------------
set "IDE_EXE=%UNIFACE_HOME%\common\bin\ide.exe"
set "UNIFACE_ADM=%UNIFACE_HOME%\uniface\adm"

REM -- Project working dir = the  [install] project=  value in usys.ini.
REM    Resolve it FROM usys.ini so a moved project self-heals (workspace rule:
REM    resolve paths from usys.ini [install]). Fall back to the in-repo
REM    uniface\project if the ini cannot be read. ----------------------------
set "UNIFACE_PROJECT="
if exist "%UNIFACE_ADM%\usys.ini" (
  for /f "usebackq tokens=1,* delims==" %%A in (`findstr /b /i "project=" "%UNIFACE_ADM%\usys.ini"`) do set "UNIFACE_PROJECT=%%B"
)
if not defined UNIFACE_PROJECT set "UNIFACE_PROJECT=%~dp0..\uniface\project"

REM -- Put the Uniface binaries on PATH (quoted because of the spaces). --------
set "PATH=%UNIFACE_HOME%\common\bin;%PATH%"

REM -- Report config. Missing install is NOT fatal here: build.bat skips
REM    gracefully so CI stays green on runners without Uniface installed. ------
echo [setup-env] UNIFACE_HOME = %UNIFACE_HOME%
echo [setup-env] IDE_EXE      = %IDE_EXE%
echo [setup-env] PROJECT      = %UNIFACE_PROJECT%
if not exist "%IDE_EXE%" (
  echo [setup-env] NOTE: ide.exe not found - edit UNIFACE_HOME in this script.
  echo [setup-env]       ^(Expected on CI runners without Uniface; build is skipped.^)
)
exit /b 0
