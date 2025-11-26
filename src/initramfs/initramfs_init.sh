#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/../utils/config.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../utils/colors.sh"

setup_init() {
    local INITRAMFS_DIR="$1"
    
    print_step "Setting up init script"
    
    print_progress "Copying init script..."
    cp "$ROOTFS_DIR/init" "$INITRAMFS_DIR/init"
    chmod +x "$INITRAMFS_DIR/init"
    
    if [ -f "$ROOTFS_DIR/panda.art.txt" ]; then
        print_progress "Adding ASCII art..."
        mkdir -p "$INITRAMFS_DIR/etc"
        cp "$ROOTFS_DIR/panda.art.txt" "$INITRAMFS_DIR/etc/panda.art.txt"
        print_complete "ASCII art added"
    fi
    
    if [ ! -e "$INITRAMFS_DIR/bin/sh" ]; then
        print_error "/bin/sh not found in initramfs!"
        return 1
    fi
    
    print_complete "Init script setup complete"
    return 0
}
