#!/bin/bash
# Setup development tools (GCC, make, etc.) in initramfs

source "$(dirname "${BASH_SOURCE[0]}")/config.sh"
source "$(dirname "${BASH_SOURCE[0]}")/colors.sh"

setup_devtools() {
    local INITRAMFS_DIR="$1"
    
    print_step "Setting up development tools"
    
    mkdir -p "$INITRAMFS_DIR/usr/bin" "$INITRAMFS_DIR/usr/lib" "$INITRAMFS_DIR/lib64"
    
    # Development tools to include
    DEVTOOLS=(
        "gcc" "g++" "make" "ld" "as" "ar" "nm" "strip" "objcopy" "objdump"
        "readelf" "size" "strings" "file" "diff" "patch"
    )
    
    COPIED_COUNT=0
    
    # Copy GCC and related tools
    print_progress "Copying GCC and development tools..."
    for tool in "${DEVTOOLS[@]}"; do
        if command -v "$tool" &> /dev/null; then
            TOOL_PATH=$(which "$tool")
            if [ -f "$TOOL_PATH" ]; then
                # Determine if it should go in /usr/bin or /bin
                if [[ "$tool" == "gcc" || "$tool" == "g++" || "$tool" == "make" ]]; then
                    DEST_DIR="$INITRAMFS_DIR/usr/bin"
                else
                    DEST_DIR="$INITRAMFS_DIR/usr/bin"
                fi
                
                cp "$TOOL_PATH" "$DEST_DIR/$tool" 2>/dev/null || true
                chmod +x "$DEST_DIR/$tool" 2>/dev/null || true
                COPIED_COUNT=$((COPIED_COUNT + 1))
            fi
        fi
    done
    
    # Copy GCC libraries and runtime
    if command -v gcc &> /dev/null; then
        print_progress "Copying GCC libraries and runtime..."
        
        # Find GCC library paths
        GCC_LIBDIR=$(gcc -print-search-dirs 2>/dev/null | grep "^libraries:" | sed 's/libraries: =//' | awk '{print $1}' | head -1)
        
        # Copy common GCC runtime libraries
        for lib_pattern in "libgcc_s.so*" "libstdc++.so*" "libc.so*"; do
            find /usr/lib* /lib* -name "$lib_pattern" 2>/dev/null | head -5 | while read lib; do
                if [ -f "$lib" ]; then
                    cp "$lib" "$INITRAMFS_DIR/lib64/" 2>/dev/null || true
                fi
            done
        done
        
        # Copy GCC executables from /usr/libexec/gcc if they exist
        if [ -d /usr/libexec/gcc ]; then
            mkdir -p "$INITRAMFS_DIR/usr/libexec/gcc"
            find /usr/libexec/gcc -type f -executable 2>/dev/null | head -10 | while read exe; do
                REL_PATH=$(echo "$exe" | sed "s|^/usr/libexec/||")
                mkdir -p "$INITRAMFS_DIR/usr/libexec/$(dirname "$REL_PATH")"
                cp "$exe" "$INITRAMFS_DIR/usr/libexec/$REL_PATH" 2>/dev/null || true
            done
        fi
    fi
    
    # Copy libraries for all development tools
    print_progress "Copying required libraries for dev tools..."
    for bin_file in "$INITRAMFS_DIR/usr/bin"/*; do
        if [ -f "$bin_file" ] && [ -x "$bin_file" ]; then
            for lib in $(ldd "$bin_file" 2>/dev/null | grep -E '=>' | awk '{print $3}' | grep -v '^$'); do
                if [ -f "$lib" ]; then
                    cp "$lib" "$INITRAMFS_DIR/lib64/" 2>/dev/null || true
                fi
            done
        fi
    done
    
    # Ensure dynamic linker is present
    if [ -f /lib64/ld-linux-x86-64.so.2 ]; then
        cp /lib64/ld-linux-x86-64.so.2 "$INITRAMFS_DIR/lib64/" 2>/dev/null || true
    fi
    
    if [ $COPIED_COUNT -gt 0 ]; then
        print_complete "Development tools setup complete ($COPIED_COUNT tools installed)"
    else
        print_warning "No development tools found. Install gcc, make, etc. to enable development."
        echo -e "${YELLOW}On Fedora: sudo dnf install gcc gcc-c++ make binutils${NC}"
        echo -e "${YELLOW}On Debian: sudo apt-get install build-essential${NC}"
    fi
    
    return 0
}

