#!/bin/bash
# Build initramfs - orchestrates all initramfs components

source "$(dirname "${BASH_SOURCE[0]}")/config.sh"
source "$(dirname "${BASH_SOURCE[0]}")/colors.sh"
source "$(dirname "${BASH_SOURCE[0]}")/initramfs_bash.sh"
source "$(dirname "${BASH_SOURCE[0]}")/initramfs_coreutils.sh"
source "$(dirname "${BASH_SOURCE[0]}")/initramfs_devtools.sh"
source "$(dirname "${BASH_SOURCE[0]}")/initramfs_init.sh"
source "$(dirname "${BASH_SOURCE[0]}")/initramfs_nano.sh"
source "$(dirname "${BASH_SOURCE[0]}")/initramfs_fastfetch.sh"
source "$(dirname "${BASH_SOURCE[0]}")/initramfs_archive.sh"

build_initramfs() {
    print_header "Building initramfs"
    
    # Create temporary directory for initramfs
    print_progress "Creating temporary initramfs directory..."
    INITRAMFS_DIR=$(mktemp -d)
    mkdir -p "$INITRAMFS_DIR"/{bin,sbin,usr/bin,usr/lib,usr/libexec,lib64,etc,proc,sys,dev,tmp,root}
    
    # Setup bash (must be first - provides shell)
    if ! setup_bash "$INITRAMFS_DIR"; then
        rm -rf "$INITRAMFS_DIR"
        return 1
    fi
    
    # Setup GNU coreutils (critical - must succeed)
    if ! setup_coreutils "$INITRAMFS_DIR"; then
        print_error "Failed to setup GNU coreutils"
        rm -rf "$INITRAMFS_DIR"
        return 1
    fi
    
    # Setup development tools (GCC, make, etc.)
    setup_devtools "$INITRAMFS_DIR"
    
    # Setup init script and ASCII art
    if ! setup_init "$INITRAMFS_DIR"; then
        rm -rf "$INITRAMFS_DIR"
        return 1
    fi
    
    # Add optional components
    add_nano "$INITRAMFS_DIR"
    add_fastfetch "$INITRAMFS_DIR"
    
    # Create archive
    create_initramfs_archive "$INITRAMFS_DIR"
    
    return 0
}

