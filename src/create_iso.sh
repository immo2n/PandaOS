#!/bin/bash
# Create ISO image

source "$(dirname "${BASH_SOURCE[0]}")/config.sh"
source "$(dirname "${BASH_SOURCE[0]}")/colors.sh"

create_iso() {
    print_step "Creating ISO image"
    
    ISO_NAME="pandaos-$(date +%Y%m%d).iso"
    
    # Try grub2-mkrescue (Fedora/RHEL) first, then grub-mkrescue (Debian/Ubuntu)
    if command -v grub2-mkrescue &> /dev/null; then
        print_progress "Using grub2-mkrescue to create ISO..."
        grub2-mkrescue -o "$ROOT_DIR/$ISO_NAME" "$ISO_DIR" 2>/dev/null
        echo ""
        print_success "ISO created: ${BOLD}$ROOT_DIR/$ISO_NAME${NC}"
    elif command -v grub-mkrescue &> /dev/null; then
        print_progress "Using grub-mkrescue to create ISO..."
        grub-mkrescue -o "$ROOT_DIR/$ISO_NAME" "$ISO_DIR" 2>/dev/null
        echo ""
        print_success "ISO created: ${BOLD}$ROOT_DIR/$ISO_NAME${NC}"
    else
        print_error "grub2-mkrescue or grub-mkrescue not found."
        echo -e "${YELLOW}Please install grub2-tools (Fedora/RHEL) or grub-pc-bin (Debian/Ubuntu).${NC}"
        return 1
    fi
    
    return 0
}

