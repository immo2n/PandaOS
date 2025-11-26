#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/../utils/config.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../utils/colors.sh"

add_nano() {
    local INITRAMFS_DIR="$1"
    
    print_step "Adding nano editor"
    
    if command -v nano &> /dev/null; then
        NANO_PATH=$(which nano)
        mkdir -p "$INITRAMFS_DIR/usr/bin" "$INITRAMFS_DIR/lib64"
        
        print_progress "Copying nano binary..."
        cp "$NANO_PATH" "$INITRAMFS_DIR/usr/bin/nano"
        chmod +x "$INITRAMFS_DIR/usr/bin/nano"
        
        print_progress "Copying required libraries..."
        for lib in $(ldd "$NANO_PATH" 2>/dev/null | grep -E '=>' | awk '{print $3}' | grep -v '^$'); do
            if [ -f "$lib" ]; then
                cp "$lib" "$INITRAMFS_DIR/lib64/" 2>/dev/null || true
            fi
        done
        
        if [ -f /lib64/ld-linux-x86-64.so.2 ]; then
            cp /lib64/ld-linux-x86-64.so.2 "$INITRAMFS_DIR/lib64/" 2>/dev/null || true
        fi
        
        print_progress "Copying terminfo database..."
        mkdir -p "$INITRAMFS_DIR/usr/share/terminfo/l"
        if [ -f /usr/share/terminfo/l/linux ]; then
            cp /usr/share/terminfo/l/linux "$INITRAMFS_DIR/usr/share/terminfo/l/" 2>/dev/null || true
        fi
        if [ -d /usr/share/terminfo ]; then
            mkdir -p "$INITRAMFS_DIR/usr/share/terminfo"
            for term in linux xterm xterm-256color vt100; do
                TERM_DIR=$(echo "$term" | cut -c1)
                if [ -f "/usr/share/terminfo/$TERM_DIR/$term" ]; then
                    mkdir -p "$INITRAMFS_DIR/usr/share/terminfo/$TERM_DIR"
                    cp "/usr/share/terminfo/$TERM_DIR/$term" "$INITRAMFS_DIR/usr/share/terminfo/$TERM_DIR/" 2>/dev/null || true
                fi
            done
        fi
        
        print_complete "Nano added successfully"
    else
        print_warning "nano not found, skipping..."
    fi
}
