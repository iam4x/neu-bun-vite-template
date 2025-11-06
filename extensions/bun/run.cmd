@echo off
REM Smart detection: Use compiled executable if available, fallback to source with global Bun

REM Check for compiled executable first
if exist "%~1\extensions\bun\main-app.exe" (
    "%~1\extensions\bun\main-app.exe" %2 %3 %4
) else if exist "%~1\extensions\bun\src\main.ts" (
    REM Development mode: use global Bun installation
    bun run "%~1\extensions\bun\src\main.ts"
) else (
    echo Error: Could not find Bun extension at %~1\extensions\bun >&2
    echo Looking for: main-app.exe or src\main.ts >&2
    exit /b 1
)
