#!/bin/bash
# Dependency Check Script
# Analyzes Flutter/Dart dependencies for updates and vulnerabilities
# Usage: bash dependency_check.sh

set -e

echo "========================================="
echo "Dependency Analysis Report"
echo "========================================="
echo ""

# Check if we're in a Flutter project
if [ ! -f "pubspec.yaml" ]; then
    echo "Error: pubspec.yaml not found. Please run this from a Flutter project root."
    exit 1
fi

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "1. Checking Dependency Status"
echo "----------------------------"
echo ""

# Run flutter pub outdated
if command -v flutter &> /dev/null; then
    echo "Running 'flutter pub outdated'..."
    echo ""

    flutter pub outdated || true  # Don't fail if no outdated deps

    echo ""
    echo "2. Direct Dependencies in pubspec.yaml"
    echo "-------------------------------------"
    echo ""

    # Extract direct dependencies
    if grep -A 50 "^dependencies:" pubspec.yaml | grep "^[a-z]" | head -20
    then
        :
    fi

    echo ""
    echo "3. Checking for Common Security-Sensitive Packages"
    echo "-------------------------------------------------"
    echo ""

    # Check for security-critical packages
    SECURITY_PACKAGES=(
        "crypto"
        "pointycastle"
        "flutter_secure_storage"
        "local_auth"
        "http"
        "dio"
    )

    for package in "${SECURITY_PACKAGES[@]}"; do
        if grep -q "$package" pubspec.yaml 2>/dev/null; then
            echo -e "${GREEN}✓${NC} $package found (security-relevant)"
        fi
    done

    echo ""
    echo "4. Checking for Deprecated Packages"
    echo "---------------------------------"
    echo ""

    # List of known deprecated packages
    DEPRECATED=(
        "pedantic"
        "effective_dart"
        "intl_translation"
    )

    FOUND_DEPRECATED=0
    for package in "${DEPRECATED[@]}"; do
        if grep -q "$package" pubspec.yaml 2>/dev/null; then
            echo -e "${YELLOW}⚠${NC} $package is deprecated"
            FOUND_DEPRECATED=$((FOUND_DEPRECATED + 1))
        fi
    done

    if [ $FOUND_DEPRECATED -eq 0 ]; then
        echo -e "${GREEN}✓${NC} No known deprecated packages found"
    fi

    echo ""
    echo "5. Pub Get Status"
    echo "----------------"
    echo ""

    if [ -f "pubspec.lock" ]; then
        echo -e "${GREEN}✓${NC} pubspec.lock exists (dependencies locked)"

        # Count dependencies
        DEP_COUNT=$(grep -c "^  " pubspec.lock 2>/dev/null || echo "unknown")
        echo "  Total locked dependencies: $DEP_COUNT"
    else
        echo -e "${YELLOW}⚠${NC} pubspec.lock not found"
        echo "  Run 'flutter pub get' to lock dependencies"
    fi

    echo ""
    echo "6. Flutter/Dart Version Requirements"
    echo "----------------------------------"
    echo ""

    if grep "^environment:" pubspec.yaml > /dev/null 2>&1; then
        echo "Environment constraints:"
        sed -n '/^environment:/,/^[^ ]/p' pubspec.yaml | head -5
    else
        echo -e "${YELLOW}⚠${NC} No environment section specified"
    fi

    echo ""
    echo "7. Common Dependency Issues"
    echo "-------------------------"
    echo ""

    # Check for common issues
    ISSUES=0

    # Check for exact versions
    if grep "^dependencies:" pubspec.yaml -A 20 | grep '": *"[0-9]' | grep -v "^  " > /dev/null 2>&1; then
        echo -e "${YELLOW}⚠${NC} Some dependencies use exact versions (consider relaxing)"
        ISSUES=$((ISSUES + 1))
    fi

    # Check for path dependencies in production
    if grep "path:" pubspec.yaml > /dev/null 2>&1; then
        echo -e "${YELLOW}⚠${NC} Path-based dependencies found (ensure not in production)"
        ISSUES=$((ISSUES + 1))
    fi

    # Check SDK constraints
    if ! grep -q "sdk:" pubspec.yaml; then
        echo -e "${YELLOW}⚠${NC} No SDK version constraint specified"
        ISSUES=$((ISSUES + 1))
    fi

    if [ $ISSUES -eq 0 ]; then
        echo -e "${GREEN}✓${NC} No obvious dependency issues detected"
    fi

else
    echo "Error: flutter command not found"
    exit 1
fi

echo ""
echo "========================================="
echo "Recommendations:"
echo "========================================="
echo ""
echo "  1. Run 'flutter pub get' to fetch latest compatible versions"
echo "  2. Run 'flutter pub upgrade' to update to latest versions"
echo "  3. Check CHANGELOG.md of major dependencies for breaking changes"
echo "  4. Use 'flutter pub outdated' regularly to stay updated"
echo "  5. Review security advisories for critical packages"
echo ""
echo "========================================="
