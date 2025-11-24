#!/bin/bash
# PandaOS Build Configuration

# Get the root directory of the project
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Directory paths
ISO_DIR="$ROOT_DIR/iso"
ROOTFS_DIR="$ROOT_DIR/rootfs"
BOOT_DIR="$ROOT_DIR/boot"
KERNEL_DIR="$ROOT_DIR/kernel"

# Source directory (where build scripts are located)
SRC_DIR="$ROOT_DIR/src"

