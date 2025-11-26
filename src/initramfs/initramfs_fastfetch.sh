#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/../utils/config.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../utils/colors.sh"

add_fastfetch() {
    local INITRAMFS_DIR="$1"
    
    print_step "Adding fastfetch"
    
    if command -v fastfetch &> /dev/null; then
        FASTFETCH_PATH=$(which fastfetch)
        mkdir -p "$INITRAMFS_DIR/usr/bin" "$INITRAMFS_DIR/lib64"
        
        print_progress "Copying fastfetch binary..."
        cp "$FASTFETCH_PATH" "$INITRAMFS_DIR/usr/bin/fastfetch"
        chmod +x "$INITRAMFS_DIR/usr/bin/fastfetch"
        
        print_progress "Copying required libraries..."
        for lib in $(ldd "$FASTFETCH_PATH" 2>/dev/null | grep -E '=>' | awk '{print $3}' | grep -v '^$'); do
            if [ -f "$lib" ]; then
                cp "$lib" "$INITRAMFS_DIR/lib64/" 2>/dev/null || true
            fi
        done
        
        if [ -f /lib64/ld-linux-x86-64.so.2 ] && [ ! -f "$INITRAMFS_DIR/lib64/ld-linux-x86-64.so.2" ]; then
            cp /lib64/ld-linux-x86-64.so.2 "$INITRAMFS_DIR/lib64/" 2>/dev/null || true
        fi
        
        print_complete "Fastfetch added successfully"
    else
        print_warning "fastfetch not found, skipping..."
    fi
}
