#!/bin/bash

# VisionOS-specific linting script
# Checks for proper VisionOS development patterns and best practices

set -euo pipefail

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to check for proper @MainActor usage
check_mainactor_usage() {
    print_status "$BLUE" "🎯 Checking @MainActor usage..."

    local issues=0

    # Find Swift files that might need @MainActor
    while IFS= read -r -d '' file; do
        if [[ -f "$file" ]]; then
            # Check for UI operations without @MainActor
            if grep -q "\.window\|\.scene\|\.immersiveSpace\|View.*{" "$file"; then
                if ! grep -q "@MainActor" "$file"; then
                    print_status "$YELLOW" "⚠️  Consider adding @MainActor to: $file"
                    ((issues++))
                fi
            fi

            # Check for improper @MainActor placement
            if grep -q "@MainActor.*struct.*View" "$file"; then
                print_status "$YELLOW" "⚠️  @MainActor on View struct may be redundant: $file"
            fi
        fi
    done < <(find . -name "*.swift" -type f -print0 2>/dev/null || true)

    if [[ $issues -eq 0 ]]; then
        print_status "$GREEN" "✅ @MainActor usage looks good"
    fi
}

# Function to validate spatial modifiers
check_spatial_modifiers() {
    print_status "$BLUE" "🌐 Checking spatial modifiers..."

    local issues=0

    while IFS= read -r -d '' file; do
        if [[ -f "$file" ]]; then
            # Check for deprecated spatial modifiers
            if grep -q "\.immersiveContentPlacement\|\.defaultPlacement" "$file"; then
                print_status "$YELLOW" "⚠️  Check spatial modifier usage in: $file"
                ((issues++))
            fi

            # Check for missing spatial configuration
            if grep -q "ImmersiveSpace\|WindowGroup.*immersive" "$file"; then
                if ! grep -q "\.immersiveContentPlacement\|\.preferredSurroundingsEffect\|\.immersiveSpaceSize" "$file"; then
                    print_status "$YELLOW" "⚠️  Immersive space missing spatial configuration: $file"
                    ((issues++))
                fi
            fi
        fi
    done < <(find . -name "*.swift" -type f -print0 2>/dev/null || true)

    if [[ $issues -eq 0 ]]; then
        print_status "$GREEN" "✅ Spatial modifiers look good"
    fi
}

# Function to check immersive space setup
check_immersive_space_setup() {
    print_status "$BLUE" "🥽 Checking immersive space setup..."

    local issues=0
    local has_immersive_space=false

    while IFS= read -r -d '' file; do
        if [[ -f "$file" ]]; then
            if grep -q "ImmersiveSpace\|openImmersiveSpace\|dismissImmersiveSpace" "$file"; then
                has_immersive_space=true

                # Check for proper environment handling
                if ! grep -q "@Environment(\.openImmersiveSpace)\|@Environment(\.dismissImmersiveSpace)" "$file"; then
                    print_status "$YELLOW" "⚠️  Immersive space without proper environment: $file"
                    ((issues++))
                fi

                # Check for error handling
                if grep -q "openImmersiveSpace" "$file" && ! grep -q "try await\|Task\|\.catch\|do.*catch" "$file"; then
                    print_status "$YELLOW" "⚠️  Immersive space operations should handle errors: $file"
                    ((issues++))
                fi
            fi
        fi
    done < <(find . -name "*.swift" -type f -print0 2>/dev/null || true)

    if $has_immersive_space && [[ $issues -eq 0 ]]; then
        print_status "$GREEN" "✅ Immersive space setup looks good"
    elif ! $has_immersive_space; then
        print_status "$BLUE" "ℹ️  No immersive spaces detected"
    fi
}

# Function to verify proper RealityKit imports
check_realitykit_imports() {
    print_status "$BLUE" "🎮 Checking RealityKit imports..."

    local issues=0

    while IFS= read -r -d '' file; do
        if [[ -f "$file" ]]; then
            # Check for RealityKit usage without import
            if grep -q "Entity\|ModelEntity\|RealityView\|\.reality" "$file"; then
                if ! grep -q "import RealityKit" "$file"; then
                    print_status "$RED" "❌ RealityKit usage without import: $file"
                    ((issues++))
                fi
            fi

            # Check for ARKit usage without import
            if grep -q "ARSession\|WorldTrackingProvider\|HandTrackingProvider" "$file"; then
                if ! grep -q "import ARKit" "$file"; then
                    print_status "$RED" "❌ ARKit usage without import: $file"
                    ((issues++))
                fi
            fi

            # Check for unused imports
            if grep -q "import RealityKit" "$file"; then
                if ! grep -q "Entity\|ModelEntity\|RealityView\|RealityKit\." "$file"; then
                    print_status "$YELLOW" "⚠️  Potentially unused RealityKit import: $file"
                fi
            fi
        fi
    done < <(find . -name "*.swift" -type f -print0 2>/dev/null || true)

    if [[ $issues -eq 0 ]]; then
        print_status "$GREEN" "✅ RealityKit imports look good"
    fi

    return $issues
}

# Main execution
main() {
    print_status "$BLUE" "🍎 Starting VisionOS linting..."
    echo

    local total_issues=0

    check_mainactor_usage
    echo

    check_spatial_modifiers
    echo

    check_immersive_space_setup
    echo

    check_realitykit_imports
    local import_issues=$?
    ((total_issues += import_issues))
    echo

    if [[ $total_issues -eq 0 ]]; then
        print_status "$GREEN" "🎉 VisionOS linting completed successfully!"
    else
        print_status "$YELLOW" "⚠️  VisionOS linting found $total_issues potential issues"
    fi

    return $total_issues
}

# Handle script being sourced vs executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi