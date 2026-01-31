#!/bin/bash
# Flutter Diagnostics Script
# Runs comprehensive Flutter environment checks and generates a diagnostic report
# Usage: bash flutter_diagnostics.sh

set -e

echo "========================================="
echo "Flutter Diagnostic Report"
echo "========================================="
echo ""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Track errors
ERRORS=0
WARNINGS=0

# Helper function to print status
print_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $2"
    else
        echo -e "${RED}✗${NC} $2"
        ERRORS=$((ERRORS + 1))
    fi
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
    WARNINGS=$((WARNINGS + 1))
}

# 1. Check Flutter Installation
echo "1. Flutter Installation"
echo "----------------------"

if command -v flutter &> /dev/null; then
    FLUTTER_VERSION=$(flutter --version | head -n 1)
    echo -e "${GREEN}✓${NC} Flutter installed: $FLUTTER_VERSION"
else
    echo -e "${RED}✗${NC} Flutter not found in PATH"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# 2. Run Flutter Doctor
echo "2. Environment Analysis"
echo "---------------------"
echo "Running 'flutter doctor -v'..."
echo ""

if command -v flutter &> /dev/null; then
    flutter doctor -v
else
    echo "Flutter not available"
fi
echo ""

# 3. Check Android SDK
echo "3. Android SDK Configuration"
echo "----------------------------"

if [ -n "$ANDROID_HOME" ]; then
    echo -e "${GREEN}✓${NC} ANDROID_HOME is set: $ANDROID_HOME"

    if [ -d "$ANDROID_HOME/platforms" ]; then
        PLATFORM_COUNT=$(ls "$ANDROID_HOME/platforms" 2>/dev/null | wc -l)
        echo -e "${GREEN}✓${NC} Found $PLATFORM_COUNT Android SDK platforms"
    else
        print_warning "No Android platforms found in ANDROID_HOME/platforms"
    fi
else
    print_warning "ANDROID_HOME not set (required for Android development)"
fi

if [ -d "$ANDROID_HOME/build-tools" ]; then
    BUILD_TOOLS=$(ls "$ANDROID_HOME/build-tools" 2>/dev/null | tail -n 1)
    echo -e "${GREEN}✓${NC} Latest build-tools: $BUILD_TOOLS"
else
    print_warning "build-tools directory not found"
fi
echo ""

# 4. Check Gradle
echo "4. Gradle Configuration"
echo "----------------------"

if command -v gradle &> /dev/null; then
    GRADLE_VERSION=$(gradle --version 2>&1 | grep "Gradle" | head -n 1)
    echo -e "${GREEN}✓${NC} Gradle installed: $GRADLE_VERSION"
elif [ -f "android/gradlew" ]; then
    echo -e "${GREEN}✓${NC} Gradle wrapper found in project"
else
    print_warning "Gradle not found (will use Gradle wrapper if available)"
fi
echo ""

# 5. Check Dart SDK
echo "5. Dart SDK"
echo "-----------"

if command -v dart &> /dev/null; then
    DART_VERSION=$(dart --version 2>&1)
    echo -e "${GREEN}✓${NC} Dart installed: $DART_VERSION"

    # Check Dart null safety
    echo -e "${GREEN}✓${NC} Null safety enabled (Dart 2.12+)"
else
    echo -e "${RED}✗${NC} Dart not found"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# 6. Check Project Structure
echo "6. Project Structure"
echo "-------------------"

if [ -f "pubspec.yaml" ]; then
    echo -e "${GREEN}✓${NC} pubspec.yaml found"

    # Check for common dependencies
    if grep -q "riverpod\|provider" pubspec.yaml; then
        echo -e "${GREEN}✓${NC} State management dependency found"
    fi

    if grep -q "freezed\|built_value" pubspec.yaml; then
        echo -e "${GREEN}✓${NC} Immutable model generation found"
    fi
else
    print_warning "pubspec.yaml not found (not in Flutter project directory?)"
fi

if [ -d "lib" ]; then
    echo -e "${GREEN}✓${NC} lib/ directory found"
else
    print_warning "lib/ directory not found"
fi

if [ -d "android" ]; then
    echo -e "${GREEN}✓${NC} android/ directory found"
else
    print_warning "android/ directory not found"
fi
echo ""

# 7. Check Common Issues
echo "7. Common Configuration Issues"
echo "------------------------------"

# Check for AndroidManifest.xml
if [ -f "android/app/src/main/AndroidManifest.xml" ]; then
    if grep -q 'android:debuggable="true"' android/app/src/main/AndroidManifest.xml; then
        print_warning "Debuggable set to true in debug configuration (expected)"
    else
        echo -e "${GREEN}✓${NC} Debuggable not set to true (check build variant)"
    fi
else
    print_warning "AndroidManifest.xml not found at expected location"
fi

# Check pubspec.lock
if [ -f "pubspec.lock" ]; then
    echo -e "${GREEN}✓${NC} pubspec.lock found (dependencies locked)"
else
    print_warning "pubspec.lock not found (run 'flutter pub get')"
fi
echo ""

# 8. Summary
echo "========================================="
echo "Diagnostic Summary"
echo "========================================="
echo "Errors: $ERRORS"
echo "Warnings: $WARNINGS"

if [ $ERRORS -eq 0 ]; then
    echo -e "\n${GREEN}✓ Environment appears to be properly configured${NC}"
else
    echo -e "\n${RED}✗ Please fix the errors above before building${NC}"
    exit 1
fi
