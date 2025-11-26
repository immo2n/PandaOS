#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/../utils/config.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../utils/colors.sh"

copy_kernel() {
    print_step "Copying kernel"
    
    print_progress "Copying vmlinuz to ISO directory..."
    cp "$KERNEL_DIR/vmlinuz" "$ISO_DIR/kernel/"
    
    print_complete "Kernel copied successfully"
}
