#!/bin/bash

# Build script for NeutralinoJS app with Bun extension
# Builds for all platforms sequentially

# Exit on error for critical commands, but allow cleanup to continue
set +e  # Don't exit immediately on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Platform configurations
declare -a PLATFORMS=(
    "darwin-arm64:main-app-arm64"
    "darwin-x64:main-app-x64"
    "windows-x64:main-app.exe"
    "linux-x64:main-app"
)

# Function to print colored output
print_step() {
    echo -e "${BLUE}==>${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    print_step "Checking prerequisites..."

    if ! command -v bun &> /dev/null; then
        print_error "Bun is not installed. Install it with: curl -fsSL https://bun.sh/install | bash"
        exit 1
    fi

    if ! command -v neu &> /dev/null; then
        print_error "Neutralino CLI is not installed. Install it with: npm install -g @neutralinojs/neu"
        exit 1
    fi

    print_success "Prerequisites check passed"
}

# Clean up before building
cleanup_before_build() {
    print_step "Cleaning up before build..."

    # Remove any existing compiled executables
    cd extensions/bun
    rm -f main-app-* main-app main-app.exe 2>/dev/null || true
    cd ../..

    # Create releases directory
    mkdir -p dist/releases

    print_success "Cleanup complete"
}

# Build Bun extension for a specific platform
build_bun_extension() {
    local target=$1
    local outfile=$2

    print_step "Building Bun extension for $target..."

    cd extensions/bun

    bun build src/main.ts --compile --target=bun-$target --outfile "$outfile"

    if [ -f "$outfile" ]; then
        print_success "Bun extension compiled: $outfile"
        cd ../..
        return 0
    else
        print_error "Failed to compile Bun extension for $target"
        cd ../..
        return 1
    fi
}

# Build Neutralino app
build_neutralino() {
    local platform_name=$1

    print_step "Building Neutralino app (builds for all platforms)..."

    # Check if we have any macOS Bun executables, use --macos-bundle if so
    if [ -f "extensions/bun/main-app-arm64" ] || [ -f "extensions/bun/main-app-x64" ]; then
        neu build --macos-bundle
        # Fix macOS app bundles: neu build creates executables, not proper bundles
        fix_macos_bundles
    else
        neu build
    fi

    print_success "Neutralino app built (for all platforms, but only current platform's Bun executable is included)"
}

# Package platform-specific build into a single distributable file
package_platform() {
    local target=$1
    local outfile=$2
    local dist_dir="dist/app"
    local output_dir="dist/releases"
    local app_name="app"

    # Ensure output directory exists (absolute path)
    mkdir -p "$output_dir"
    output_dir=$(cd "$output_dir" && pwd)

    if [[ "$target" == darwin-* ]]; then
        # macOS: Package as .app bundle
        local arch=$(echo "$target" | cut -d'-' -f2)
        local bundle_name="${app_name}-mac_${arch}.app"
        local bundle_path="${dist_dir}/${bundle_name}"

        if [ -d "$bundle_path" ]; then
            # Create a zip of the .app bundle for distribution
            local zip_name="${app_name}-mac-${arch}.zip"
            local zip_path="${output_dir}/${zip_name}"
            print_step "Packaging macOS ${arch} as ${zip_name}..."
            cd "$dist_dir"
            # Use zip with -X to preserve extended attributes and ensure permissions are set
            # Note: macOS requires execute permissions to be set after extraction
            if zip -r -X "$zip_path" "$bundle_name" > /dev/null 2>&1; then
                cd ../..
                if [ -f "$zip_path" ]; then
                    print_success "Created ${zip_name} ($(du -h "$zip_path" | cut -f1))"
                else
                    print_error "Failed to create ${zip_name}"
                fi
            else
                cd ../..
                print_error "Failed to create zip file"
            fi
        else
            print_error "Bundle not found: $bundle_path"
        fi

    elif [[ "$target" == windows-* ]]; then
        # Windows: Package as .zip with .exe + resources.neu + extensions
        local exe_name="${app_name}-win_x64.exe"
        local zip_name="${app_name}-win-x64.zip"

        print_step "Packaging Windows x64 as ${zip_name}..."

        if [ ! -f "${dist_dir}/${exe_name}" ]; then
            print_error "Windows executable not found: ${dist_dir}/${exe_name}"
            return 1
        fi

        local temp_dir=$(mktemp -d)
        cp "${dist_dir}/${exe_name}" "$temp_dir/" || { print_error "Failed to copy executable"; rm -rf "$temp_dir"; return 1; }

        if [ -f "${dist_dir}/resources.neu" ]; then
            cp "${dist_dir}/resources.neu" "$temp_dir/"
        fi

        # Copy extensions folder if it exists
        if [ -d "${dist_dir}/extensions" ]; then
            cp -r "${dist_dir}/extensions" "$temp_dir/"
        fi

        cd "$temp_dir"
        local zip_path="${output_dir}/${zip_name}"
        if zip -r "$zip_path" . > /dev/null 2>&1; then
            cd - > /dev/null
            rm -rf "$temp_dir"
            if [ -f "$zip_path" ]; then
                print_success "Created ${zip_name} ($(du -h "$zip_path" | cut -f1))"
            else
                print_error "Failed to create ${zip_name}"
            fi
        else
            cd - > /dev/null
            rm -rf "$temp_dir"
            print_error "Failed to create zip file"
        fi

    elif [[ "$target" == linux-* ]]; then
        # Linux: Package as .tar.gz with executable + resources.neu + extensions
        local arch=$(echo "$target" | cut -d'-' -f2)
        local exe_name="${app_name}-linux_${arch}"
        local tar_name="${app_name}-linux-${arch}.tar.gz"

        print_step "Packaging Linux ${arch} as ${tar_name}..."

        if [ ! -f "${dist_dir}/${exe_name}" ]; then
            print_error "Linux executable not found: ${dist_dir}/${exe_name}"
            return 1
        fi

        local temp_dir=$(mktemp -d)
        cp "${dist_dir}/${exe_name}" "$temp_dir/" || { print_error "Failed to copy executable"; rm -rf "$temp_dir"; return 1; }
        chmod +x "${temp_dir}/${exe_name}"

        if [ -f "${dist_dir}/resources.neu" ]; then
            cp "${dist_dir}/resources.neu" "$temp_dir/"
        fi

        # Copy extensions folder if it exists
        if [ -d "${dist_dir}/extensions" ]; then
            cp -r "${dist_dir}/extensions" "$temp_dir/"
        fi

        cd "$temp_dir"
        local tar_path="${output_dir}/${tar_name}"
        if tar -czf "$tar_path" . 2>/dev/null; then
            cd - > /dev/null
            rm -rf "$temp_dir"
            if [ -f "$tar_path" ]; then
                print_success "Created ${tar_name} ($(du -h "$tar_path" | cut -f1))"
            else
                print_error "Failed to create ${tar_name}"
            fi
        else
            cd - > /dev/null
            rm -rf "$temp_dir"
            print_error "Failed to create tar.gz file"
        fi
    fi
}

# Fix macOS app bundles - neu build creates executables, not proper app bundles
fix_macos_bundles() {
    print_step "Fixing macOS app bundle structure..."

    local dist_dir="dist/app"
    local app_name="app"

    # Process each macOS app executable
    for app_exe in "${dist_dir}/${app_name}-mac_arm64.app" "${dist_dir}/${app_name}-mac_x64.app" "${dist_dir}/${app_name}-mac_universal.app"; do
        # Check if it exists as a file (executable) or directory (already a bundle)
        if [ -f "$app_exe" ]; then
            # It's an executable file, need to convert to bundle
            local bundle_name=$(basename "$app_exe")
            local bundle_dir="${dist_dir}/${bundle_name}"
            local bundle_contents="${bundle_dir}/Contents"
            local bundle_macos="${bundle_contents}/MacOS"
            local bundle_resources="${bundle_contents}/Resources"

            # Save the executable content before removing the file
            local temp_exe=$(mktemp)
            cp "$app_exe" "$temp_exe"

            # Remove the file and create directory structure
            rm -f "$app_exe"
            mkdir -p "$bundle_macos"
            mkdir -p "$bundle_resources"

            # Move the executable into bundle
            mv "$temp_exe" "${bundle_macos}/${app_name}"
            chmod +x "${bundle_macos}/${app_name}"

            # Copy resources.neu into bundle
            # Neutralino looks for resources.neu relative to the executable
            # Place it in both MacOS (same dir as executable) and Resources (standard macOS location)
            if [ -f "${dist_dir}/resources.neu" ]; then
                cp "${dist_dir}/resources.neu" "${bundle_macos}/"
                cp "${dist_dir}/resources.neu" "$bundle_resources/"
            fi

            # Copy extensions into bundle
            # NL_PATH points to Contents/MacOS/ in macOS bundles, so we need extensions there too
            if [ -d "${dist_dir}/extensions" ]; then
                # Copy to Resources (standard macOS location)
                cp -r "${dist_dir}/extensions" "$bundle_resources/"
                # Also copy to MacOS (where NL_PATH points to)
                cp -r "${dist_dir}/extensions" "${bundle_macos}/"
                # Ensure execute permissions on run script and Bun executables in both locations
                for ext_dir in "${bundle_resources}/extensions/bun" "${bundle_macos}/extensions/bun"; do
                    chmod +x "${ext_dir}/run" 2>/dev/null || true
                    chmod +x "${ext_dir}/main-app-arm64" 2>/dev/null || true
                    chmod +x "${ext_dir}/main-app-x64" 2>/dev/null || true
                    chmod +x "${ext_dir}/main-app" 2>/dev/null || true
                done
            fi

            # Create Info.plist
            local arch_suffix=""
            if [[ "$bundle_name" == *"arm64"* ]]; then
                arch_suffix=" (ARM64)"
            elif [[ "$bundle_name" == *"x64"* ]]; then
                arch_suffix=" (Intel)"
            elif [[ "$bundle_name" == *"universal"* ]]; then
                arch_suffix=" (Universal)"
            fi

            cat > "${bundle_contents}/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>${app_name}</string>
    <key>CFBundleIdentifier</key>
    <string>js.neutralino.sample</string>
    <key>CFBundleName</key>
    <string>${app_name}${arch_suffix}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleVersion</key>
    <string>1.0.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>10.13</string>
</dict>
</plist>
EOF

            print_success "Fixed bundle: $bundle_name"
        elif [ -d "$app_exe" ]; then
            # Already a bundle directory, just ensure it has everything
            local bundle_name=$(basename "$app_exe")
            local bundle_dir="${dist_dir}/${bundle_name}"
            local bundle_contents="${bundle_dir}/Contents"
            local bundle_resources="${bundle_contents}/Resources"

            mkdir -p "$bundle_resources"

            # Copy resources.neu if missing
            # Neutralino looks for resources.neu relative to the executable
            # Place it in both MacOS (same dir as executable) and Resources (standard macOS location)
            local bundle_macos="${bundle_contents}/MacOS"
            if [ -f "${dist_dir}/resources.neu" ]; then
                if [ ! -f "${bundle_macos}/resources.neu" ]; then
                    cp "${dist_dir}/resources.neu" "${bundle_macos}/"
                fi
                if [ ! -f "${bundle_resources}/resources.neu" ]; then
                    cp "${dist_dir}/resources.neu" "$bundle_resources/"
                fi
            fi

            # Copy extensions if missing
            # NL_PATH points to Contents/MacOS/ in macOS bundles, so we need extensions there too
            if [ -d "${dist_dir}/extensions" ]; then
                # Copy to Resources if missing (standard macOS location)
                if [ ! -d "${bundle_resources}/extensions" ]; then
                    cp -r "${dist_dir}/extensions" "$bundle_resources/"
                fi
                # Also copy to MacOS if missing (where NL_PATH points to)
                if [ ! -d "${bundle_macos}/extensions" ]; then
                    cp -r "${dist_dir}/extensions" "${bundle_macos}/"
                fi
                # Ensure execute permissions on run script and Bun executables in both locations
                for ext_dir in "${bundle_resources}/extensions/bun" "${bundle_macos}/extensions/bun"; do
                    chmod +x "${ext_dir}/run" 2>/dev/null || true
                    chmod +x "${ext_dir}/main-app-arm64" 2>/dev/null || true
                    chmod +x "${ext_dir}/main-app-x64" 2>/dev/null || true
                    chmod +x "${ext_dir}/main-app" 2>/dev/null || true
                done
            fi

            print_success "Verified bundle: $bundle_name"
        fi
    done
}

# Clean up Bun executable for a platform
cleanup_bun_executable() {
    local outfile=$1

    if [ -f "extensions/bun/$outfile" ]; then
        rm -f "extensions/bun/$outfile"
        print_success "Cleaned up $outfile"
    fi
}

# Main build process
main() {
    echo ""
    echo "=========================================="
    echo "  NeutralinoJS + Bun Extension Builder"
    echo "=========================================="
    echo ""

    check_prerequisites
    cleanup_before_build

    local total=${#PLATFORMS[@]}
    local current=0

    # Build sequentially: compile Bun extension, build Neutralino, then clean up before next platform
    for platform_config in "${PLATFORMS[@]}"; do
        current=$((current + 1))
        IFS=':' read -r target outfile <<< "$platform_config"

        echo ""
        echo "----------------------------------------"
        echo "Platform $current/$total: $target"
        echo "----------------------------------------"
        echo ""

        # Step 1: Build Bun extension for this platform
        print_step "Building Bun extension for $target..."
        if ! build_bun_extension "$target" "$outfile"; then
            print_error "Failed to build Bun extension for $target. Skipping Neutralino build for this platform..."
            cleanup_bun_executable "$outfile"
            continue
        fi

        # Step 2: Build Neutralino app (builds for all platforms, but only current platform's Bun executable exists)
        print_step "Building Neutralino app..."
        if ! build_neutralino "$target"; then
            print_error "Failed to build Neutralino app"
            cleanup_bun_executable "$outfile"
            continue
        fi

        # Step 3: Package this platform's build into a single distributable file
        print_step "Packaging $target distribution..."
        package_platform "$target" "$outfile"

        print_success "Completed build and packaging for $target"

        # Step 4: Clean up dist/app before next platform build (but keep releases)
        if [ -d "dist/app" ]; then
            rm -rf dist/app
        fi

        # Step 5: Clean up Bun executable before next platform
        cleanup_bun_executable "$outfile"
    done

    echo ""
    echo "=========================================="
    print_success "All builds completed!"
    echo "=========================================="
    echo ""
    echo "Distributable packages are in dist/releases/:"
    ls -lh dist/releases/ 2>/dev/null | tail -n +2 | awk '{print "  - " $9 " (" $5 ")"}'
    echo ""
    echo "Each package contains:"
    echo "  - Executable"
    echo "  - resources.neu"
    echo "  - extensions/ folder (with Bun extension)"
    echo ""
    echo "Note: All Bun executables have been cleaned up from extensions/bun/"
    echo "      They are bundled in the distribution packages"
    echo ""
}

# Run main function
main

