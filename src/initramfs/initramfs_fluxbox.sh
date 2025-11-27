#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/../utils/config.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../utils/colors.sh"

setup_fluxbox() {
    local INITRAMFS_DIR="$1"
    
    print_step "Setting up Fluxbox"
    
    if ! command -v fluxbox &> /dev/null; then
        print_error "fluxbox not found. Please install fluxbox."
        echo -e "${YELLOW}On Fedora: sudo dnf install fluxbox${NC}"
        echo -e "${YELLOW}On Debian: sudo apt-get install fluxbox${NC}"
        return 1
    fi
    
    FLUXBOX_PATH=$(which fluxbox)
    PACKAGE_FLUXBOX_DIR="$PACKAGE_DIR/fluxbox"
    
    # Create package directory structure
    mkdir -p "$PACKAGE_FLUXBOX_DIR/usr/bin" "$PACKAGE_FLUXBOX_DIR/usr/lib" "$PACKAGE_FLUXBOX_DIR/usr/lib64" \
             "$PACKAGE_FLUXBOX_DIR/lib64" "$PACKAGE_FLUXBOX_DIR/usr/share/fluxbox"
    mkdir -p "$INITRAMFS_DIR/usr/bin" "$INITRAMFS_DIR/usr/lib" "$INITRAMFS_DIR/usr/lib64" \
             "$INITRAMFS_DIR/lib64" "$INITRAMFS_DIR/usr/share/fluxbox"
    
    # Copy fluxbox binary from host to package if not already there
    if [ ! -f "$PACKAGE_FLUXBOX_DIR/usr/bin/fluxbox" ]; then
        print_progress "Copying fluxbox binary from host to package cache..."
        cp "$FLUXBOX_PATH" "$PACKAGE_FLUXBOX_DIR/usr/bin/fluxbox"
        chmod +x "$PACKAGE_FLUXBOX_DIR/usr/bin/fluxbox"
    else
        print_progress "Fluxbox binary already in package cache, skipping..."
    fi
    
    # Copy fluxbox utilities
    print_progress "Copying fluxbox utilities from host to package cache..."
    for util in fluxbox-generate_menu fluxbox-remote fluxbox-update_configs; do
        if command -v "$util" &> /dev/null; then
            UTIL_PATH=$(which "$util")
            if [ ! -f "$PACKAGE_FLUXBOX_DIR/usr/bin/$util" ]; then
                cp "$UTIL_PATH" "$PACKAGE_FLUXBOX_DIR/usr/bin/$util"
                chmod +x "$PACKAGE_FLUXBOX_DIR/usr/bin/$util"
            fi
        fi
    done
    
    # Copy fluxbox binary from package to initramfs
    print_progress "Copying fluxbox binary to initramfs..."
    cp "$PACKAGE_FLUXBOX_DIR/usr/bin/fluxbox" "$INITRAMFS_DIR/usr/bin/fluxbox"
    chmod +x "$INITRAMFS_DIR/usr/bin/fluxbox"
    
    # Copy fluxbox utilities to initramfs
    cp "$PACKAGE_FLUXBOX_DIR/usr/bin/fluxbox-"* "$INITRAMFS_DIR/usr/bin/" 2>/dev/null || true
    
    # Copy fluxbox libraries from host to package if not already there
    print_progress "Copying fluxbox libraries from host to package cache..."
    for lib in $(ldd "$FLUXBOX_PATH" 2>/dev/null | grep -E '=>' | awk '{print $3}' | grep -v '^$'); do
        if [ -f "$lib" ]; then
            local lib_name=$(basename "$lib")
            local lib_dir=$(dirname "$lib")
            local dest_dir=""
            
            # Determine destination based on source location
            if [[ "$lib_dir" == /usr/lib64/* ]] || [[ "$lib_dir" == /lib64/* ]]; then
                dest_dir="$PACKAGE_FLUXBOX_DIR/lib64"
            elif [[ "$lib_dir" == /usr/lib/* ]]; then
                dest_dir="$PACKAGE_FLUXBOX_DIR/usr/lib"
            else
                dest_dir="$PACKAGE_FLUXBOX_DIR/lib64"
            fi
            
            if [ ! -f "$dest_dir/$lib_name" ]; then
                mkdir -p "$dest_dir"
                cp "$lib" "$dest_dir/" 2>/dev/null || true
            fi
        fi
    done
    
    # Copy fluxbox data files (themes, styles, etc.)
    print_progress "Copying fluxbox data files from host to package cache..."
    if [ -d /usr/share/fluxbox ] && [ -z "$(ls -A "$PACKAGE_FLUXBOX_DIR/usr/share/fluxbox" 2>/dev/null)" ]; then
        cp -r /usr/share/fluxbox/* "$PACKAGE_FLUXBOX_DIR/usr/share/fluxbox/" 2>/dev/null || true
    fi
    
    # Copy ld-linux-x86-64.so.2 if not already copied
    if [ -f /lib64/ld-linux-x86-64.so.2 ]; then
        if [ ! -f "$PACKAGE_FLUXBOX_DIR/lib64/ld-linux-x86-64.so.2" ]; then
            cp /lib64/ld-linux-x86-64.so.2 "$PACKAGE_FLUXBOX_DIR/lib64/" 2>/dev/null || true
        fi
    fi
    
    # Copy all files from package to initramfs
    print_progress "Copying fluxbox files from package cache to initramfs..."
    cp -r "$PACKAGE_FLUXBOX_DIR/usr/bin/"* "$INITRAMFS_DIR/usr/bin/" 2>/dev/null || true
    cp -r "$PACKAGE_FLUXBOX_DIR/lib64/"* "$INITRAMFS_DIR/lib64/" 2>/dev/null || true
    cp -r "$PACKAGE_FLUXBOX_DIR/usr/lib/"* "$INITRAMFS_DIR/usr/lib/" 2>/dev/null || true
    cp -r "$PACKAGE_FLUXBOX_DIR/usr/lib64/"* "$INITRAMFS_DIR/usr/lib64/" 2>/dev/null || true
    cp -r "$PACKAGE_FLUXBOX_DIR/usr/share/fluxbox/"* "$INITRAMFS_DIR/usr/share/fluxbox/" 2>/dev/null || true
    
    print_complete "Fluxbox setup complete"
    return 0
}
