#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/../utils/config.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../utils/colors.sh"

setup_directories() {
    print_step "Setting up build directories"
    
    print_progress "Cleaning previous build..."
    rm -rf "$ISO_DIR"
    
    print_progress "Creating directory structure..."
    mkdir -p "$ISO_DIR"/{boot/grub,kernel}
    
    print_complete "Directories ready"
}
