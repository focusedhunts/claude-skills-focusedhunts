@echo off
REM Dependency Check Script for Windows
REM Analyzes Flutter/Dart dependencies for updates and vulnerabilities
REM Usage: dependency_check.bat

setlocal enabledelayedexpansion

echo =========================================
echo Dependency Analysis Report
echo =========================================
echo.

REM Check if we're in a Flutter project
if not exist "pubspec.yaml" (
    echo Error: pubspec.yaml not found. Please run from Flutter project root.
    exit /b 1
)

echo 1. Checking Dependency Status
echo ----------------------------
echo.

REM Run flutter pub outdated
if exist "flutter.bat" (
    flutter pub outdated
) else (
    where flutter >nul 2>nul
    if !ERRORLEVEL! EQU 0 (
        flutter pub outdated
    ) else (
        echo Error: flutter command not found
        exit /b 1
    )
)

echo.
echo 2. Direct Dependencies
echo ---------------------
echo.

REM Extract dependencies from pubspec.yaml
for /f "tokens=*" %%a in ('findstr /R "^[a-z]" pubspec.yaml') do (
    echo   %%a
)

echo.
echo 3. Checking for Security-Sensitive Packages
echo ------------------------------------------
echo.

setlocal enabledelayedexpansion
set SECURITY_PACKAGES=crypto pointycastle flutter_secure_storage local_auth http dio

for %%p in (%SECURITY_PACKAGES%) do (
    findstr /I "%%p" pubspec.yaml >nul 2>nul
    if !ERRORLEVEL! EQU 0 (
        echo [OK] %%p found ^(security-relevant^)
    )
)

echo.
echo 4. Checking for Deprecated Packages
echo ---------------------------------
echo.

setlocal enabledelayedexpansion
set DEPRECATED_PACKAGES=pedantic effective_dart intl_translation

set DEPRECATED_COUNT=0
for %%p in (%DEPRECATED_PACKAGES%) do (
    findstr /I "%%p" pubspec.yaml >nul 2>nul
    if !ERRORLEVEL! EQU 0 (
        echo [WARNING] %%p is deprecated
        set /a DEPRECATED_COUNT+=1
    )
)

if %DEPRECATED_COUNT% EQU 0 (
    echo [OK] No known deprecated packages found
)

echo.
echo 5. Pub Get Status
echo ----------------
echo.

if exist "pubspec.lock" (
    echo [OK] pubspec.lock exists ^(dependencies locked^)
) else (
    echo [WARNING] pubspec.lock not found
    echo           Run 'flutter pub get' to lock dependencies
)

echo.
echo 6. Flutter/Dart Version Requirements
echo ----------------------------------
echo.

findstr /N "environment:" pubspec.yaml >nul 2>nul
if !ERRORLEVEL! EQU 0 (
    echo Environment constraints specified
    for /f "tokens=*" %%a in ('findstr /A "environment:" pubspec.yaml') do (
        echo   %%a
    )
) else (
    echo [WARNING] No environment section specified
)

echo.
echo 7. Common Dependency Issues
echo -------------------------
echo.

set ISSUES=0

REM Check for exact versions
findstr "\"[0-9]" pubspec.yaml >nul 2>nul
if !ERRORLEVEL! EQU 0 (
    echo [WARNING] Some dependencies use exact versions
    set /a ISSUES+=1
)

REM Check for path dependencies
findstr /I "path:" pubspec.yaml >nul 2>nul
if !ERRORLEVEL! EQU 0 (
    echo [WARNING] Path-based dependencies found
    set /a ISSUES+=1
)

REM Check SDK constraints
findstr "sdk:" pubspec.yaml >nul 2>nul
if !ERRORLEVEL! NEQ 0 (
    echo [WARNING] No SDK version constraint specified
    set /a ISSUES+=1
)

if %ISSUES% EQU 0 (
    echo [OK] No obvious dependency issues detected
)

echo.
echo =========================================
echo Recommendations:
echo =========================================
echo.
echo   1. Run 'flutter pub get' to fetch latest compatible versions
echo   2. Run 'flutter pub upgrade' to update to latest versions
echo   3. Check CHANGELOG of major dependencies for breaking changes
echo   4. Use 'flutter pub outdated' regularly to stay updated
echo   5. Review security advisories for critical packages
echo.
echo =========================================
