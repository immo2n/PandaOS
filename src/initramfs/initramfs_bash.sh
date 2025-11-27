#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/../utils/config.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../utils/colors.sh"

setup_bash() {
    local INITRAMFS_DIR="$1"
    
    print_step "Setting up Bash"
    
    if ! command -v bash &> /dev/null; then
        print_error "bash not found. Please install bash."
        echo -e "${YELLOW}On Fedora: sudo dnf install bash${NC}"
        echo -e "${YELLOW}On Debian: sudo apt-get install bash${NC}"
        return 1
    fi
    
    BASH_PATH=$(which bash)
    PACKAGE_BASH_DIR="$PACKAGE_DIR/bash"
    
    # Create package directory structure
    mkdir -p "$PACKAGE_BASH_DIR/bin" "$PACKAGE_BASH_DIR/lib64"
    mkdir -p "$INITRAMFS_DIR/bin" "$INITRAMFS_DIR/lib64"
    
    # Copy bash binary from host to package if not already there
    if [ ! -f "$PACKAGE_BASH_DIR/bin/bash" ]; then
        print_progress "Copying bash binary from host to package cache..."
        cp "$BASH_PATH" "$PACKAGE_BASH_DIR/bin/bash"
        chmod +x "$PACKAGE_BASH_DIR/bin/bash"
    else
        print_progress "Bash binary already in package cache, skipping..."
    fi
    
    # Copy bash binary from package to initramfs
    print_progress "Copying bash binary to initramfs..."
    cp "$PACKAGE_BASH_DIR/bin/bash" "$INITRAMFS_DIR/bin/bash"
    chmod +x "$INITRAMFS_DIR/bin/bash"
    
    # Create sh symlink in initramfs
    print_progress "Creating sh symlink..."
    cd "$INITRAMFS_DIR/bin"
    ln -sf bash sh
    
    # Copy bash libraries from host to package if not already there
    print_progress "Copying bash libraries from host to package cache..."
    for lib in $(ldd "$BASH_PATH" 2>/dev/null | grep -E '=>' | awk '{print $3}' | grep -v '^$'); do
        if [ -f "$lib" ]; then
            local lib_name=$(basename "$lib")
            if [ ! -f "$PACKAGE_BASH_DIR/lib64/$lib_name" ]; then
                cp "$lib" "$PACKAGE_BASH_DIR/lib64/" 2>/dev/null || true
            fi
        fi
    done
    
    # Copy ld-linux-x86-64.so.2 from host to package if not already there
    if [ -f /lib64/ld-linux-x86-64.so.2 ]; then
        if [ ! -f "$PACKAGE_BASH_DIR/lib64/ld-linux-x86-64.so.2" ]; then
            cp /lib64/ld-linux-x86-64.so.2 "$PACKAGE_BASH_DIR/lib64/" 2>/dev/null || true
        fi
    fi
    
    # Copy all libraries from package to initramfs
    print_progress "Copying libraries from package cache to initramfs..."
    cp -r "$PACKAGE_BASH_DIR/lib64/"* "$INITRAMFS_DIR/lib64/" 2>/dev/null || true
    
    print_complete "Bash setup complete"
    return 0
}
