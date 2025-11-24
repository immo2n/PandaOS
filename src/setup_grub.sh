#!/bin/bash
# Setup GRUB configuration

source "$(dirname "${BASH_SOURCE[0]}")/config.sh"
source "$(dirname "${BASH_SOURCE[0]}")/colors.sh"

setup_grub() {
    print_step "Setting up GRUB"
    
    print_progress "Copying GRUB configuration..."
    cp "$BOOT_DIR/grub/grub.cfg" "$ISO_DIR/boot/grub/"
    
    print_complete "GRUB configuration copied"
}

