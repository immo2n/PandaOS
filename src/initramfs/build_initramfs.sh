#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/../utils/config.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../utils/colors.sh"
source "$(dirname "${BASH_SOURCE[0]}")/initramfs_bash.sh"
source "$(dirname "${BASH_SOURCE[0]}")/initramfs_coreutils.sh"
source "$(dirname "${BASH_SOURCE[0]}")/initramfs_devtools.sh"
source "$(dirname "${BASH_SOURCE[0]}")/initramfs_init.sh"
source "$(dirname "${BASH_SOURCE[0]}")/initramfs_nano.sh"
source "$(dirname "${BASH_SOURCE[0]}")/initramfs_fastfetch.sh"
source "$(dirname "${BASH_SOURCE[0]}")/initramfs_xorg.sh"
source "$(dirname "${BASH_SOURCE[0]}")/initramfs_fluxbox.sh"
source "$(dirname "${BASH_SOURCE[0]}")/initramfs_archive.sh"

build_initramfs() {
    print_header "Building initramfs"
    
    print_progress "Creating temporary initramfs directory..."
    INITRAMFS_DIR=$(mktemp -d)
    mkdir -p "$INITRAMFS_DIR"/{bin,sbin,usr/bin,usr/lib,usr/libexec,lib64,etc,proc,sys,dev,tmp,root,var/log}
    
    if ! setup_bash "$INITRAMFS_DIR"; then
        rm -rf "$INITRAMFS_DIR"
        return 1
    fi
    
    if ! setup_coreutils "$INITRAMFS_DIR"; then
        print_error "Failed to setup GNU coreutils"
        rm -rf "$INITRAMFS_DIR"
        return 1
    fi
    
    setup_devtools "$INITRAMFS_DIR"
    
    if ! setup_init "$INITRAMFS_DIR"; then
        rm -rf "$INITRAMFS_DIR"
        return 1
    fi
    
    add_nano "$INITRAMFS_DIR"
    add_fastfetch "$INITRAMFS_DIR"
    
    if ! setup_xorg "$INITRAMFS_DIR"; then
        print_error "Failed to setup X.org"
        rm -rf "$INITRAMFS_DIR"
        return 1
    fi
    
    if ! setup_fluxbox "$INITRAMFS_DIR"; then
        print_error "Failed to setup Fluxbox"
        rm -rf "$INITRAMFS_DIR"
        return 1
    fi
    
    create_initramfs_archive "$INITRAMFS_DIR"
    
    return 0
}
