#!/bin/bash
# PandaOS Build Script - Main Orchestrator

set -e

# Get the root directory and source directory
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$ROOT_DIR/src"

# Source all build modules
source "$SRC_DIR/config.sh"
source "$SRC_DIR/colors.sh"
source "$SRC_DIR/setup_directories.sh"
source "$SRC_DIR/copy_kernel.sh"
source "$SRC_DIR/build_initramfs.sh"
source "$SRC_DIR/setup_grub.sh"
source "$SRC_DIR/create_iso.sh"

# Print welcome banner
echo -e "${BOLD}${CYAN}"
echo "╔════════════════════════════════════════╗"
echo "║     ${PANDA}  PandaOS Build System  ${PANDA}     ║"
echo "╚════════════════════════════════════════╝"
echo -e "${NC}"

# Track progress
TOTAL_STEPS=5
CURRENT_STEP=0

# Setup directories
CURRENT_STEP=$((CURRENT_STEP + 1))
show_progress $CURRENT_STEP $TOTAL_STEPS
setup_directories

# Copy kernel
CURRENT_STEP=$((CURRENT_STEP + 1))
show_progress $CURRENT_STEP $TOTAL_STEPS
copy_kernel

# Build initramfs (includes bash, GNU coreutils, GCC, init, nano, fastfetch, and archive creation)
CURRENT_STEP=$((CURRENT_STEP + 1))
show_progress $CURRENT_STEP $TOTAL_STEPS
if ! build_initramfs; then
    print_error "Failed to build initramfs"
    exit 1
fi

# Setup GRUB
CURRENT_STEP=$((CURRENT_STEP + 1))
show_progress $CURRENT_STEP $TOTAL_STEPS
setup_grub

# Create ISO
CURRENT_STEP=$((CURRENT_STEP + 1))
show_progress $CURRENT_STEP $TOTAL_STEPS
if ! create_iso; then
    print_error "Failed to create ISO"
    exit 1
fi

# Success message
echo ""
echo -e "${BOLD}${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${GREEN}║  ${CHECKMARK}  Build completed successfully!  ${CHECKMARK}  ║${NC}"
echo -e "${BOLD}${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""
