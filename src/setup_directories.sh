#!/bin/bash
# Setup and clean build directories

source "$(dirname "${BASH_SOURCE[0]}")/config.sh"
source "$(dirname "${BASH_SOURCE[0]}")/colors.sh"

setup_directories() {
    print_step "Setting up build directories"
    
    # Clean previous build
    print_progress "Cleaning previous build..."
    rm -rf "$ISO_DIR"
    
    print_progress "Creating directory structure..."
    mkdir -p "$ISO_DIR"/{boot/grub,kernel}
    
    print_complete "Directories ready"
}

