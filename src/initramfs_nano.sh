#!/bin/bash
# Add nano editor to initramfs

source "$(dirname "${BASH_SOURCE[0]}")/config.sh"
source "$(dirname "${BASH_SOURCE[0]}")/colors.sh"

add_nano() {
    local INITRAMFS_DIR="$1"
    
    print_step "Adding nano editor"
    
    if command -v nano &> /dev/null; then
        NANO_PATH=$(which nano)
        mkdir -p "$INITRAMFS_DIR/usr/bin" "$INITRAMFS_DIR/lib64"
        
        # Copy nano binary
        print_progress "Copying nano binary..."
        cp "$NANO_PATH" "$INITRAMFS_DIR/usr/bin/nano"
        chmod +x "$INITRAMFS_DIR/usr/bin/nano"
        
        # Copy required libraries
        print_progress "Copying required libraries..."
        # Get library dependencies and copy them
        for lib in $(ldd "$NANO_PATH" 2>/dev/null | grep -E '=>' | awk '{print $3}' | grep -v '^$'); do
            if [ -f "$lib" ]; then
                cp "$lib" "$INITRAMFS_DIR/lib64/" 2>/dev/null || true
            fi
        done
        
        # Copy dynamic linker if needed
        if [ -f /lib64/ld-linux-x86-64.so.2 ]; then
            cp /lib64/ld-linux-x86-64.so.2 "$INITRAMFS_DIR/lib64/" 2>/dev/null || true
        fi
        
        # Copy terminfo database for ncurses (needed for nano)
        print_progress "Copying terminfo database..."
        mkdir -p "$INITRAMFS_DIR/usr/share/terminfo/l"
        if [ -f /usr/share/terminfo/l/linux ]; then
            cp /usr/share/terminfo/l/linux "$INITRAMFS_DIR/usr/share/terminfo/l/" 2>/dev/null || true
        fi
        # Also try alternative locations
        if [ -d /usr/share/terminfo ]; then
            # Copy common terminfo entries
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

