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
    mkdir -p "$INITRAMFS_DIR/bin" "$INITRAMFS_DIR/lib64"
    
    print_progress "Copying bash binary..."
    cp "$BASH_PATH" "$INITRAMFS_DIR/bin/bash"
    chmod +x "$INITRAMFS_DIR/bin/bash"
    
    print_progress "Creating sh symlink..."
    cd "$INITRAMFS_DIR/bin"
    ln -sf bash sh
    
    print_progress "Copying bash libraries..."
    for lib in $(ldd "$BASH_PATH" 2>/dev/null | grep -E '=>' | awk '{print $3}' | grep -v '^$'); do
        if [ -f "$lib" ]; then
            cp "$lib" "$INITRAMFS_DIR/lib64/" 2>/dev/null || true
        fi
    done
    
    if [ -f /lib64/ld-linux-x86-64.so.2 ]; then
        cp /lib64/ld-linux-x86-64.so.2 "$INITRAMFS_DIR/lib64/" 2>/dev/null || true
    fi
    
    print_complete "Bash setup complete"
    return 0
}
