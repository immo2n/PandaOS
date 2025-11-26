#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/../utils/config.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../utils/colors.sh"

create_initramfs_archive() {
    local INITRAMFS_DIR="$1"
    
    print_step "Creating initramfs archive"
    
    print_progress "Packaging files into cpio archive..."
    cd "$INITRAMFS_DIR"
    find . | cpio -o -H newc | gzip > "$ISO_DIR/kernel/initramfs.gz"
    
    print_progress "Cleaning up temporary files..."
    rm -rf "$INITRAMFS_DIR"
    
    print_complete "Initramfs archive created"
}
