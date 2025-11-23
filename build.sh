#!/bin/bash
# PandaOS Build Script

set -e

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ISO_DIR="$ROOT_DIR/iso"
ROOTFS_DIR="$ROOT_DIR/rootfs"
BOOT_DIR="$ROOT_DIR/boot"
KERNEL_DIR="$ROOT_DIR/kernel"

echo "Building PandaOS..."

# Clean previous build
rm -rf "$ISO_DIR"
mkdir -p "$ISO_DIR"/{boot/grub,kernel}

# Copy kernel
echo "Copying kernel..."
cp "$KERNEL_DIR/vmlinuz" "$ISO_DIR/kernel/"

# Create initramfs
echo "Creating initramfs..."
INITRAMFS_DIR=$(mktemp -d)
mkdir -p "$INITRAMFS_DIR"/{bin,sbin,etc,proc,sys,dev,tmp,root}

# Copy busybox FIRST (before init) so /bin/sh is available
if command -v busybox &> /dev/null; then
    BUSYBOX_PATH=$(which busybox)
    cp "$BUSYBOX_PATH" "$INITRAMFS_DIR/bin/busybox"
    chmod +x "$INITRAMFS_DIR/bin/busybox"
    
    # Create symlinks for common commands - sh MUST be created first
    cd "$INITRAMFS_DIR/bin"
    ln -s busybox sh
    # Add all essential commands including uname, clear, and others
    # Note: cttyhack, setsid, script are important for fixing TTY issues
    for cmd in ls cat echo mount umount mkdir rmdir rm cp mv ln chmod chown \
               uname clear pwd cd ps kill sleep sync dmesg head tail grep \
               find df du free whoami id env export unset setsid cttyhack \
               script openvt; do
        ln -s busybox "$cmd" 2>/dev/null || true
    done
    
    cd "$INITRAMFS_DIR/sbin"
    for cmd in mount umount mknod; do
        ln -s ../bin/busybox "$cmd" 2>/dev/null || true
    done
else
    echo "Error: busybox not found. Please install busybox."
    echo "On Fedora: sudo dnf install busybox"
    echo "On Debian: sudo apt-get install busybox"
    rm -rf "$INITRAMFS_DIR"
    exit 1
fi

# Copy init script AFTER busybox is set up
cp "$ROOTFS_DIR/init" "$INITRAMFS_DIR/init"
chmod +x "$INITRAMFS_DIR/init"

# Copy ASCII art if it exists
if [ -f "$ROOTFS_DIR/panda.art.txt" ]; then
    mkdir -p "$INITRAMFS_DIR/etc"
    cp "$ROOTFS_DIR/panda.art.txt" "$INITRAMFS_DIR/etc/panda.art.txt"
    echo "  ASCII art added"
fi

# Verify /bin/sh exists
if [ ! -e "$INITRAMFS_DIR/bin/sh" ]; then
    echo "Error: /bin/sh not found in initramfs!"
    rm -rf "$INITRAMFS_DIR"
    exit 1
fi

# Add nano editor if available
echo "Adding nano editor..."
if command -v nano &> /dev/null; then
    NANO_PATH=$(which nano)
    mkdir -p "$INITRAMFS_DIR/usr/bin" "$INITRAMFS_DIR/lib64"
    
    # Copy nano binary
    cp "$NANO_PATH" "$INITRAMFS_DIR/usr/bin/nano"
    chmod +x "$INITRAMFS_DIR/usr/bin/nano"
    
    # Copy required libraries
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
    echo "  Copying terminfo database..."
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
    
    echo "  nano added successfully"
else
    echo "  Warning: nano not found, skipping..."
fi

# Add fastfetch if available
echo "Adding fastfetch..."
if command -v fastfetch &> /dev/null; then
    FASTFETCH_PATH=$(which fastfetch)
    mkdir -p "$INITRAMFS_DIR/usr/bin" "$INITRAMFS_DIR/lib64"
    
    # Copy fastfetch binary
    cp "$FASTFETCH_PATH" "$INITRAMFS_DIR/usr/bin/fastfetch"
    chmod +x "$INITRAMFS_DIR/usr/bin/fastfetch"
    
    # Copy required libraries
    echo "  Copying libraries..."
    for lib in $(ldd "$FASTFETCH_PATH" 2>/dev/null | grep -E '=>' | awk '{print $3}' | grep -v '^$'); do
        if [ -f "$lib" ]; then
            cp "$lib" "$INITRAMFS_DIR/lib64/" 2>/dev/null || true
        fi
    done
    
    # Ensure dynamic linker is present (should already be there from nano)
    if [ -f /lib64/ld-linux-x86-64.so.2 ] && [ ! -f "$INITRAMFS_DIR/lib64/ld-linux-x86-64.so.2" ]; then
        cp /lib64/ld-linux-x86-64.so.2 "$INITRAMFS_DIR/lib64/" 2>/dev/null || true
    fi
    
    echo "  fastfetch added successfully"
else
    echo "  Warning: fastfetch not found, skipping..."
fi

# Create initramfs cpio archive
cd "$INITRAMFS_DIR"
find . | cpio -o -H newc | gzip > "$ISO_DIR/kernel/initramfs.gz"
rm -rf "$INITRAMFS_DIR"

# Copy GRUB configuration
echo "Setting up GRUB..."
cp "$BOOT_DIR/grub/grub.cfg" "$ISO_DIR/boot/grub/"

# Create ISO
echo "Creating ISO image..."
ISO_NAME="pandaos-$(date +%Y%m%d).iso"

# Try grub2-mkrescue (Fedora/RHEL) first, then grub-mkrescue (Debian/Ubuntu)
if command -v grub2-mkrescue &> /dev/null; then
    grub2-mkrescue -o "$ROOT_DIR/$ISO_NAME" "$ISO_DIR"
    echo "ISO created: $ROOT_DIR/$ISO_NAME"
elif command -v grub-mkrescue &> /dev/null; then
    grub-mkrescue -o "$ROOT_DIR/$ISO_NAME" "$ISO_DIR"
    echo "ISO created: $ROOT_DIR/$ISO_NAME"
else
    echo "Error: grub2-mkrescue or grub-mkrescue not found."
    echo "Please install grub2-tools (Fedora/RHEL) or grub-pc-bin (Debian/Ubuntu)."
    exit 1
fi

echo "Build complete!"
