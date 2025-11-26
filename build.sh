#!/bin/bash

set -e

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$ROOT_DIR/src"

source "$SRC_DIR/utils/config.sh"
source "$SRC_DIR/utils/colors.sh"
source "$SRC_DIR/setup/setup_directories.sh"
source "$SRC_DIR/iso/copy_kernel.sh"
source "$SRC_DIR/initramfs/build_initramfs.sh"
source "$SRC_DIR/iso/setup_grub.sh"
source "$SRC_DIR/iso/create_iso.sh"

echo -e "${BOLD}${CYAN}"
echo "╔════════════════════════════════════════╗"
echo "║     ${PANDA}  PandaOS Build System  ${PANDA}     ║"
echo "╚════════════════════════════════════════╝"
echo -e "${NC}"

TOTAL_STEPS=5
CURRENT_STEP=0

CURRENT_STEP=$((CURRENT_STEP + 1))
show_progress $CURRENT_STEP $TOTAL_STEPS
setup_directories

CURRENT_STEP=$((CURRENT_STEP + 1))
show_progress $CURRENT_STEP $TOTAL_STEPS
copy_kernel

CURRENT_STEP=$((CURRENT_STEP + 1))
show_progress $CURRENT_STEP $TOTAL_STEPS
if ! build_initramfs; then
    print_error "Failed to build initramfs"
    exit 1
fi

CURRENT_STEP=$((CURRENT_STEP + 1))
show_progress $CURRENT_STEP $TOTAL_STEPS
setup_grub

CURRENT_STEP=$((CURRENT_STEP + 1))
show_progress $CURRENT_STEP $TOTAL_STEPS
if ! create_iso; then
    print_error "Failed to create ISO"
    exit 1
fi

echo ""
echo -e "${BOLD}${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${GREEN}║  ${CHECKMARK}  Build completed successfully!  ${CHECKMARK}  ║${NC}"
echo -e "${BOLD}${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""
