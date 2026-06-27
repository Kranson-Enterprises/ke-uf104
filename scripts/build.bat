@echo off
setlocal
REM ============================================================================
REM  build.bat - compile the Uniface 10 project from the command line.
REM
REM  Usage:
REM    build.bat                 production compile (/all /nodebug, non-debuggable)
REM    build.bat /cpt            all components (debuggable)
REM    build.bat /svc *VAL       targeted compile (wildcards allowed)
REM    build.bat /all /aft=15-09-2024   changed-since compile
REM
REM  Mirrors the /uniface-compile slash command - see
REM  .claude\commands\uniface-compile.md and worklog/006.
REM
REM  Notes:
REM   * Spaced paths are quoted as WHOLE tokens, incl. the /adm switch value
REM     (.claude\rules\quote-paths-with-spaces.md).
REM   * CLI compile FAILS if the Repository is unmigrated/incompatible - open the
REM     interactive IDE once to migrate first (worklog/006).
REM   * Output lands in the project resources dir, packaged as UAR.
REM ============================================================================

REM -- Ensure the environment is configured. Idempotent and needed in CI, where
REM    each step is a fresh shell so setup-env's vars don't carry over. --------
if not defined IDE_EXE call "%~dp0setup-env.bat"

REM -- No usable install -> skip gracefully so CI stays green on runners
REM    without Uniface (preserves the original scaffold's placeholder contract).
if not exist "%IDE_EXE%" (
  echo [build] No Uniface install at "%IDE_EXE%" - skipping build.
  exit /b 0
)

REM -- Compile switches: default to a non-debuggable production build. ---------
set "SWITCHES=%*"
if not defined SWITCHES set "SWITCHES=/all /nodebug"

echo [build] Compiling: %SWITCHES%
pushd "%UNIFACE_PROJECT%"
"%IDE_EXE%" "/adm=%UNIFACE_ADM%" %SWITCHES%
set "RC=%ERRORLEVEL%"
popd

REM -- ide.exe returns 0 success / 1 failure - gate the build on it. -----------
if not "%RC%"=="0" (
  echo [build] FAILED - ide.exe returned %RC%.
  exit /b %RC%
)
echo [build] OK - compile succeeded.
exit /b 0
