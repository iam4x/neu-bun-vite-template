#!/bin/bash

# Development script for NeutralinoJS app with Bun extension
# Installs Bun runtime for development and launches the app

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Check if Neutralino CLI is installed
check_neu() {
    print_step "Checking if Neutralino CLI is installed..."

    if command -v neu &> /dev/null; then
        print_success "Neutralino CLI is installed"
        return 0
    else
        print_error "Neutralino CLI is not installed"
        print_error "Install it with: npm install -g @neutralinojs/neu"
        exit 1
    fi
}

# Install extension dependencies
install_extension_dependencies() {
    print_step "Installing extension dependencies..."

    if [ ! -d "extensions/bun" ]; then
        print_error "Extension directory not found: extensions/bun"
        exit 1
    fi

    cd extensions/bun

    if [ ! -f "package.json" ]; then
        print_warning "package.json not found in extensions/bun, skipping dependency installation"
        cd ../..
        return 0
    fi

    if bun install; then
        print_success "Extension dependencies installed"
        cd ../..
    else
        print_error "Failed to install extension dependencies"
        cd ../..
        exit 1
    fi
}

install_frontend_dependencies() {
    print_step "Installing frontend dependencies..."

    if [ ! -d "frontend" ]; then
        print_error "Frontend directory not found: frontend"
        exit 1
    fi

    cd frontend

    if [ ! -f "package.json" ]; then
        print_warning "package.json not found in frontend, skipping dependency installation"
        cd ..
        return 0
    fi


    if bun install; then
        print_success "Frontend dependencies installed"
        cd ..
    else
        print_error "Failed to install frontend dependencies"
        cd ..
        exit 1
    fi
}


# Launch the application
launch_app() {
    print_step "Launching Neutralino app..."
    echo ""

    neu run
}

# Main function
main() {
    echo ""
    echo "=========================================="
    echo "  NeutralinoJS + Bun Extension Dev"
    echo "=========================================="
    echo ""

    # Check Neutralino CLI
    check_neu

    # Install extension dependencies
    install_extension_dependencies

    # Install frontend dependencies
    install_frontend_dependencies

    echo ""
    print_success "Setup complete! Launching app..."
    echo ""

    # Launch the app
    launch_app
}

# Run main function
main

