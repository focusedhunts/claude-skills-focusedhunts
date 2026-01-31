@echo off
REM Flutter Diagnostics Script for Windows
REM Runs comprehensive Flutter environment checks and generates a diagnostic report
REM Usage: flutter_diagnostics.bat

setlocal enabledelayedexpansion
set ERRORS=0
set WARNINGS=0

echo =========================================
echo Flutter Diagnostic Report
echo =========================================
echo.

REM 1. Check Flutter Installation
echo 1. Flutter Installation
echo ----------------------

where flutter >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    echo [OK] Flutter is in PATH
    for /f "tokens=*" %%i in ('flutter --version 2^>nul') do (
        echo      %%i
        goto flutter_found
    )
) else (
    echo [ERROR] Flutter not found in PATH
    set /a ERRORS+=1
)

:flutter_found
echo.

REM 2. Run Flutter Doctor
echo 2. Environment Analysis
echo ---------------------
echo Running 'flutter doctor -v'...
echo.

if exist flutter.bat (
    flutter doctor -v
) else (
    where flutter >nul 2>nul
    if %ERRORLEVEL% EQU 0 (
        flutter doctor -v
    ) else (
        echo Flutter not available
    )
)
echo.

REM 3. Check Android SDK
echo 3. Android SDK Configuration
echo ----------------------------

if defined ANDROID_HOME (
    echo [OK] ANDROID_HOME is set: %ANDROID_HOME%

    if exist "%ANDROID_HOME%\platforms" (
        for /d %%i in ("%ANDROID_HOME%\platforms\*") do set /a SDK_COUNT+=1
        echo [OK] Found Android SDK platforms
    ) else (
        echo [WARNING] No Android platforms found in ANDROID_HOME\platforms
        set /a WARNINGS+=1
    )
) else (
    echo [WARNING] ANDROID_HOME not set (required for Android development)
    set /a WARNINGS+=1
)

if exist "%ANDROID_HOME%\build-tools" (
    for /d %%i in ("%ANDROID_HOME%\build-tools\*") do set LATEST_BUILD_TOOLS=%%~nxi
    if defined LATEST_BUILD_TOOLS (
        echo [OK] Latest build-tools: !LATEST_BUILD_TOOLS!
    )
) else (
    echo [WARNING] build-tools directory not found
    set /a WARNINGS+=1
)
echo.

REM 4. Check Gradle
echo 4. Gradle Configuration
echo ----------------------

where gradle >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    echo [OK] Gradle installed
) else (
    if exist "android\gradlew.bat" (
        echo [OK] Gradle wrapper found in project
    ) else (
        echo [WARNING] Gradle not found
        set /a WARNINGS+=1
    )
)
echo.

REM 5. Check Dart SDK
echo 5. Dart SDK
echo -----------

where dart >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    echo [OK] Dart SDK found
    dart --version
) else (
    echo [ERROR] Dart not found
    set /a ERRORS+=1
)
echo.

REM 6. Check Project Structure
echo 6. Project Structure
echo -------------------

if exist "pubspec.yaml" (
    echo [OK] pubspec.yaml found
) else (
    echo [WARNING] pubspec.yaml not found (not in Flutter project?)
    set /a WARNINGS+=1
)

if exist "lib" (
    echo [OK] lib\ directory found
) else (
    echo [WARNING] lib\ directory not found
    set /a WARNINGS+=1
)

if exist "android" (
    echo [OK] android\ directory found
) else (
    echo [WARNING] android\ directory not found
    set /a WARNINGS+=1
)
echo.

REM 7. Check pubspec.lock
echo 7. Dependency Lock File
echo ----------------------

if exist "pubspec.lock" (
    echo [OK] pubspec.lock found (dependencies locked)
) else (
    echo [WARNING] pubspec.lock not found (run 'flutter pub get')
    set /a WARNINGS+=1
)
echo.

REM 8. Summary
echo =========================================
echo Diagnostic Summary
echo =========================================
echo Errors: %ERRORS%
echo Warnings: %WARNINGS%

if %ERRORS% EQU 0 (
    echo.
    echo [OK] Environment appears to be properly configured
    exit /b 0
) else (
    echo.
    echo [ERROR] Please fix the errors above before building
    exit /b 1
)
