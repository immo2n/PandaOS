#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/../utils/config.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../utils/colors.sh"

setup_coreutils() {
    local INITRAMFS_DIR="$1"
    
    print_step "Setting up GNU Coreutils"
    
    COREUTILS_COMMANDS=(
        "ls" "cat" "echo" "mkdir" "rmdir" "rm" "cp" "mv" "ln" "chmod" "chown"
        "pwd" "cd" "head" "tail" "grep" "find" "sort" "uniq" "wc" "cut" "paste"
        "tr" "sed" "awk" "basename" "dirname" "realpath" "readlink" "stat"
        "touch" "test" "[" "printf" "true" "false" "yes" "seq" "sleep"
        "id" "whoami" "groups" "uname" "hostname" "date" "env" "printenv"
        "df" "du" "free" "ps" "kill" "killall" "nice" "nohup" "timeout"
        "sync" "dmesg" "stty" "tty" "clear" "reset" "expr"
    )
    
    SBIN_COMMANDS=(
        "mount" "umount" "mknod" "mkfs" "fsck" "swapon" "swapoff"
    )
    
    mkdir -p "$INITRAMFS_DIR/bin" "$INITRAMFS_DIR/sbin" "$INITRAMFS_DIR/lib64"
    
    print_progress "Copying GNU coreutils binaries..."
    COPIED_COUNT=0
    MISSING_COUNT=0
    
    for cmd in "${COREUTILS_COMMANDS[@]}"; do
        case "$cmd" in
            "echo"|"cd"|"test"|"["|"true"|"false")
                CMD_PATH=$(/usr/bin/which "$cmd" 2>/dev/null || /bin/which "$cmd" 2>/dev/null || which "$cmd" 2>/dev/null || echo "")
                ;;
            *)
                CMD_PATH=$(command -v "$cmd" 2>/dev/null || which "$cmd" 2>/dev/null || echo "")
                ;;
        esac
        
        if [ -n "$CMD_PATH" ] && [ -f "$CMD_PATH" ]; then
            if ! file "$CMD_PATH" 2>/dev/null | grep -q "busybox"; then
                if cp "$CMD_PATH" "$INITRAMFS_DIR/bin/$cmd" 2>/dev/null; then
                    chmod +x "$INITRAMFS_DIR/bin/$cmd" 2>/dev/null || true
                    COPIED_COUNT=$((COPIED_COUNT + 1))
                fi
            fi
        else
            MISSING_COUNT=$((MISSING_COUNT + 1))
        fi
    done
    
    for cmd in "${SBIN_COMMANDS[@]}"; do
        CMD_PATH=$(command -v "$cmd" 2>/dev/null || which "$cmd" 2>/dev/null || echo "")
        if [ -n "$CMD_PATH" ] && [ -f "$CMD_PATH" ]; then
            if ! file "$CMD_PATH" 2>/dev/null | grep -q "busybox"; then
                if cp "$CMD_PATH" "$INITRAMFS_DIR/sbin/$cmd" 2>/dev/null; then
                    chmod +x "$INITRAMFS_DIR/sbin/$cmd" 2>/dev/null || true
                    COPIED_COUNT=$((COPIED_COUNT + 1))
                fi
            fi
        fi
    done
    
    print_progress "Copying required libraries..."
    for bin_file in "$INITRAMFS_DIR/bin"/* "$INITRAMFS_DIR/sbin"/*; do
        if [ -f "$bin_file" ] && [ -x "$bin_file" ]; then
            for lib in $(ldd "$bin_file" 2>/dev/null | grep -E '=>' | awk '{print $3}' | grep -v '^$'); do
                if [ -f "$lib" ]; then
                    cp "$lib" "$INITRAMFS_DIR/lib64/" 2>/dev/null || true
                fi
            done
        fi
    done
    
    if [ -f /lib64/ld-linux-x86-64.so.2 ]; then
        cp /lib64/ld-linux-x86-64.so.2 "$INITRAMFS_DIR/lib64/" 2>/dev/null || true
    fi
    
    print_progress "Verifying critical commands..."
    CRITICAL_COMMANDS=("cat" "ls" "echo" "mkdir" "rm" "cp" "mv" "chmod")
    MISSING_CRITICAL=0
    for cmd in "${CRITICAL_COMMANDS[@]}"; do
        if [ ! -f "$INITRAMFS_DIR/bin/$cmd" ]; then
            print_warning "Critical command '$cmd' not found, attempting to locate..."
            for path in /usr/bin/$cmd /bin/$cmd /usr/local/bin/$cmd; do
                if [ -f "$path" ] && ! file "$path" 2>/dev/null | grep -q "busybox"; then
                    cp "$path" "$INITRAMFS_DIR/bin/$cmd" 2>/dev/null && break
                fi
            done
            if [ ! -f "$INITRAMFS_DIR/bin/$cmd" ]; then
                MISSING_CRITICAL=$((MISSING_CRITICAL + 1))
                print_error "Critical command '$cmd' still not found!"
            fi
        fi
    done
    
    if [ $MISSING_CRITICAL -gt 0 ]; then
        print_error "Some critical commands are missing! Build may fail."
        return 1
    fi
    
    print_complete "GNU Coreutils setup complete ($COPIED_COUNT commands installed)"
    if [ $MISSING_COUNT -gt 0 ]; then
        print_warning "$MISSING_COUNT commands not found (may be builtins or missing)"
    fi
    
    return 0
}
