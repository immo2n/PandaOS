#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/../utils/config.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../utils/colors.sh"

setup_xorg() {
    local INITRAMFS_DIR="$1"
    
    print_step "Setting up X.org Server"
    
    if ! command -v Xorg &> /dev/null && ! command -v X &> /dev/null; then
        print_error "Xorg not found. Please install X.org server."
        echo -e "${YELLOW}On Fedora: sudo dnf install xorg-x11-server-Xorg${NC}"
        echo -e "${YELLOW}On Debian: sudo apt-get install xserver-xorg${NC}"
        return 1
    fi
    
    # Find Xorg binary - the actual binary is in /usr/libexec/Xorg
    if [ -f /usr/libexec/Xorg ]; then
        XORG_BINARY="/usr/libexec/Xorg"
    elif [ -f /usr/bin/Xorg ] && [ ! -L /usr/bin/Xorg ]; then
        XORG_BINARY="/usr/bin/Xorg"
    else
        print_error "Could not find Xorg binary"
        return 1
    fi
    
    # Find X wrapper script - on Fedora, /usr/bin/X is a symlink, /usr/bin/Xorg is the script
    if [ -f /usr/bin/Xorg ] && [ ! -L /usr/bin/Xorg ]; then
        X_WRAPPER="/usr/bin/Xorg"
    elif [ -f /usr/bin/X ] && [ ! -L /usr/bin/X ]; then
        X_WRAPPER="/usr/bin/X"
    else
        X_WRAPPER=""
    fi
    
    PACKAGE_XORG_DIR="$PACKAGE_DIR/xorg"
    
    # Create package directory structure
    mkdir -p "$PACKAGE_XORG_DIR/usr/bin" "$PACKAGE_XORG_DIR/usr/libexec" "$PACKAGE_XORG_DIR/usr/lib" \
             "$PACKAGE_XORG_DIR/usr/lib64" "$PACKAGE_XORG_DIR/lib64" "$PACKAGE_XORG_DIR/etc/X11" \
             "$PACKAGE_XORG_DIR/usr/share/X11"
    mkdir -p "$INITRAMFS_DIR/usr/bin" "$INITRAMFS_DIR/usr/libexec" "$INITRAMFS_DIR/usr/lib" \
             "$INITRAMFS_DIR/usr/lib64" "$INITRAMFS_DIR/lib64" "$INITRAMFS_DIR/etc/X11" \
             "$INITRAMFS_DIR/usr/share/X11"
    
    # Copy Xorg binary from /usr/libexec/Xorg to package if not already there
    if [ ! -f "$PACKAGE_XORG_DIR/usr/libexec/Xorg" ]; then
        print_progress "Copying Xorg binary from host to package cache..."
        cp "$XORG_BINARY" "$PACKAGE_XORG_DIR/usr/libexec/Xorg"
        chmod +x "$PACKAGE_XORG_DIR/usr/libexec/Xorg"
    else
        print_progress "Xorg binary already in package cache, skipping..."
    fi
    
    # Copy X wrapper script - always create X as the script file
    print_progress "Setting up X wrapper script..."
    mkdir -p "$PACKAGE_XORG_DIR/usr/bin"
    
    # Remove any existing X (file or symlink) to avoid issues
    rm -f "$PACKAGE_XORG_DIR/usr/bin/X" 2>/dev/null || true
    
    if [ -n "$X_WRAPPER" ] && [ -f "$X_WRAPPER" ]; then
        print_progress "Copying X wrapper script from host to package cache..."
        cp "$X_WRAPPER" "$PACKAGE_XORG_DIR/usr/bin/X"
        # Fix shebang to use /bin/sh instead of /usr/bin/sh
        sed -i '1s|#!/usr/bin/sh|#!/bin/sh|' "$PACKAGE_XORG_DIR/usr/bin/X" 2>/dev/null || \
        sed -i '1s|#! /usr/bin/sh|#!/bin/sh|' "$PACKAGE_XORG_DIR/usr/bin/X" 2>/dev/null || true
    else
        # Create a simple X wrapper script that calls /usr/libexec/Xorg directly
        print_progress "Creating X wrapper script..."
        cat > "$PACKAGE_XORG_DIR/usr/bin/X" << 'EOF'
#!/bin/sh
basedir="/usr/libexec"
if [ -x "$basedir"/Xorg.wrap ]; then
	exec "$basedir"/Xorg.wrap "$@"
else
	exec "$basedir"/Xorg "$@"
fi
EOF
    fi
    chmod +x "$PACKAGE_XORG_DIR/usr/bin/X"
    
    # Verify X was created
    if [ ! -f "$PACKAGE_XORG_DIR/usr/bin/X" ]; then
        print_error "Failed to create X wrapper script!"
        return 1
    fi
    
    # Create Xorg symlink in /usr/bin pointing to X (remove any existing first to avoid loops)
    cd "$PACKAGE_XORG_DIR/usr/bin"
    rm -f Xorg 2>/dev/null || true
    ln -sf X Xorg
    
    # Copy Xorg binary from package to initramfs
    print_progress "Copying Xorg binary to initramfs..."
    cp "$PACKAGE_XORG_DIR/usr/libexec/Xorg" "$INITRAMFS_DIR/usr/libexec/Xorg"
    chmod +x "$INITRAMFS_DIR/usr/libexec/Xorg"
    
    # Copy X wrapper script to initramfs
    if [ -f "$PACKAGE_XORG_DIR/usr/bin/X" ]; then
        print_progress "Copying X wrapper script to initramfs..."
        cp "$PACKAGE_XORG_DIR/usr/bin/X" "$INITRAMFS_DIR/usr/bin/X"
        chmod +x "$INITRAMFS_DIR/usr/bin/X"
    else
        print_error "X wrapper script not found in package cache!"
        return 1
    fi
    
    # Create Xorg symlink in initramfs (remove any existing first to avoid loops)
    cd "$INITRAMFS_DIR/usr/bin"
    rm -f Xorg 2>/dev/null || true
    ln -sf X Xorg
    
    # Copy startx and xinit from host to package if not already there
    if [ ! -f "$PACKAGE_XORG_DIR/usr/bin/startx" ]; then
        print_progress "Copying startx from host to package cache..."
        if [ -f /usr/bin/startx ]; then
            cp /usr/bin/startx "$PACKAGE_XORG_DIR/usr/bin/startx"
            # Fix shebang to use /bin/sh instead of /usr/bin/sh
            sed -i '1s|#!/usr/bin/sh|#!/bin/sh|' "$PACKAGE_XORG_DIR/usr/bin/startx" 2>/dev/null || \
            sed -i '1s|#! /usr/bin/sh|#!/bin/sh|' "$PACKAGE_XORG_DIR/usr/bin/startx" 2>/dev/null || true
            chmod +x "$PACKAGE_XORG_DIR/usr/bin/startx"
        fi
    fi
    
    if [ ! -f "$PACKAGE_XORG_DIR/usr/bin/xinit" ]; then
        print_progress "Copying xinit from host to package cache..."
        if command -v xinit &> /dev/null; then
            XINIT_PATH=$(which xinit)
            cp "$XINIT_PATH" "$PACKAGE_XORG_DIR/usr/bin/xinit"
            chmod +x "$PACKAGE_XORG_DIR/usr/bin/xinit"
        elif [ -f /usr/bin/xinit ]; then
            cp /usr/bin/xinit "$PACKAGE_XORG_DIR/usr/bin/xinit"
            chmod +x "$PACKAGE_XORG_DIR/usr/bin/xinit"
        fi
    fi
    
    if [ ! -f "$PACKAGE_XORG_DIR/usr/bin/xauth" ]; then
        print_progress "Copying xauth from host to package cache..."
        if command -v xauth &> /dev/null; then
            XAUTH_PATH=$(which xauth)
            cp "$XAUTH_PATH" "$PACKAGE_XORG_DIR/usr/bin/xauth"
            chmod +x "$PACKAGE_XORG_DIR/usr/bin/xauth"
        elif [ -f /usr/bin/xauth ]; then
            cp /usr/bin/xauth "$PACKAGE_XORG_DIR/usr/bin/xauth"
            chmod +x "$PACKAGE_XORG_DIR/usr/bin/xauth"
        fi
    fi
    
    if [ ! -f "$PACKAGE_XORG_DIR/usr/bin/mcookie" ]; then
        print_progress "Copying mcookie from host to package cache..."
        if command -v mcookie &> /dev/null; then
            MCOOKIE_PATH=$(which mcookie)
            cp "$MCOOKIE_PATH" "$PACKAGE_XORG_DIR/usr/bin/mcookie"
            chmod +x "$PACKAGE_XORG_DIR/usr/bin/mcookie"
        elif [ -f /usr/bin/mcookie ]; then
            cp /usr/bin/mcookie "$PACKAGE_XORG_DIR/usr/bin/mcookie"
            chmod +x "$PACKAGE_XORG_DIR/usr/bin/mcookie"
        fi
    fi
    
    # Copy xinit, xauth, and mcookie libraries if they exist
    for bin in xinit xauth mcookie; do
        if [ -f "$PACKAGE_XORG_DIR/usr/bin/$bin" ]; then
            print_progress "Copying $bin libraries from host to package cache..."
            for lib in $(ldd "$PACKAGE_XORG_DIR/usr/bin/$bin" 2>/dev/null | grep -E '=>' | awk '{print $3}' | grep -v '^$'); do
                if [ -f "$lib" ]; then
                    local lib_name=$(basename "$lib")
                    local lib_dir=$(dirname "$lib")
                    local dest_dir=""
                    
                    if [[ "$lib_dir" == /usr/lib64/* ]] || [[ "$lib_dir" == /lib64/* ]]; then
                        dest_dir="$PACKAGE_XORG_DIR/lib64"
                    elif [[ "$lib_dir" == /usr/lib/* ]]; then
                        dest_dir="$PACKAGE_XORG_DIR/usr/lib"
                    else
                        dest_dir="$PACKAGE_XORG_DIR/lib64"
                    fi
                    
                    if [ ! -f "$dest_dir/$lib_name" ]; then
                        mkdir -p "$dest_dir"
                        cp "$lib" "$dest_dir/" 2>/dev/null || true
                    fi
                fi
            done
        fi
    done
    
    # Xorg binary and X wrapper are already copied above (lines 84-96)
    # No need to copy again here
    
    # Copy Xorg libraries from host to package if not already there
    print_progress "Copying Xorg libraries from host to package cache..."
    for lib in $(ldd "$XORG_BINARY" 2>/dev/null | grep -E '=>' | awk '{print $3}' | grep -v '^$'); do
        if [ -f "$lib" ]; then
            local lib_name=$(basename "$lib")
            local lib_dir=$(dirname "$lib")
            local dest_dir=""
            
            # Determine destination based on source location
            if [[ "$lib_dir" == /usr/lib64/* ]] || [[ "$lib_dir" == /lib64/* ]]; then
                dest_dir="$PACKAGE_XORG_DIR/lib64"
            elif [[ "$lib_dir" == /usr/lib/* ]]; then
                dest_dir="$PACKAGE_XORG_DIR/usr/lib"
            else
                dest_dir="$PACKAGE_XORG_DIR/lib64"
            fi
            
            if [ ! -f "$dest_dir/$lib_name" ]; then
                mkdir -p "$dest_dir"
                cp "$lib" "$dest_dir/" 2>/dev/null || true
            fi
        fi
    done
    
    # Copy Xorg driver modules
    print_progress "Copying Xorg driver modules from host to package cache..."
    if [ -d /usr/lib64/xorg/modules ]; then
        if [ ! -d "$PACKAGE_XORG_DIR/usr/lib64/xorg/modules" ]; then
            mkdir -p "$PACKAGE_XORG_DIR/usr/lib64/xorg"
            cp -r /usr/lib64/xorg/modules "$PACKAGE_XORG_DIR/usr/lib64/xorg/" 2>/dev/null || true
        fi
    fi
    
    # Copy Xorg configuration files
    print_progress "Copying Xorg configuration files..."
    if [ -d /etc/X11 ] && [ -z "$(ls -A "$PACKAGE_XORG_DIR/etc/X11" 2>/dev/null)" ]; then
        cp -r /etc/X11/* "$PACKAGE_XORG_DIR/etc/X11/" 2>/dev/null || true
    fi
    
    # Copy X11 fonts (minimal set)
    print_progress "Copying X11 fonts..."
    if [ -d /usr/share/fonts ] && [ -z "$(ls -A "$PACKAGE_XORG_DIR/usr/share/fonts" 2>/dev/null)" ]; then
        mkdir -p "$PACKAGE_XORG_DIR/usr/share/fonts"
        # Copy basic fonts only
        for font_dir in misc 75dpi 100dpi; do
            if [ -d "/usr/share/fonts/$font_dir" ]; then
                cp -r "/usr/share/fonts/$font_dir" "$PACKAGE_XORG_DIR/usr/share/fonts/" 2>/dev/null || true
            fi
        done
    fi
    
    # Copy ld-linux-x86-64.so.2 if not already copied
    if [ -f /lib64/ld-linux-x86-64.so.2 ]; then
        if [ ! -f "$PACKAGE_XORG_DIR/lib64/ld-linux-x86-64.so.2" ]; then
            cp /lib64/ld-linux-x86-64.so.2 "$PACKAGE_XORG_DIR/lib64/" 2>/dev/null || true
        fi
    fi
    
    # Copy remaining files from package to initramfs (X and Xorg are already copied above at lines 84-96)
    print_progress "Copying remaining Xorg files from package cache to initramfs..."
    # Copy other binaries (excluding X and Xorg which are already copied)
    for file in "$PACKAGE_XORG_DIR/usr/bin/"*; do
        local filename=$(basename "$file")
        # Skip X and Xorg as they're already copied above
        if [ "$filename" != "X" ] && [ "$filename" != "Xorg" ]; then
            if [ -f "$file" ] && [ ! -L "$file" ]; then
                cp "$file" "$INITRAMFS_DIR/usr/bin/" 2>/dev/null || true
                chmod +x "$INITRAMFS_DIR/usr/bin/$filename" 2>/dev/null || true
            fi
        fi
    done
    # Copy other directories
    cp -r "$PACKAGE_XORG_DIR/lib64/"* "$INITRAMFS_DIR/lib64/" 2>/dev/null || true
    cp -r "$PACKAGE_XORG_DIR/usr/lib/"* "$INITRAMFS_DIR/usr/lib/" 2>/dev/null || true
    cp -r "$PACKAGE_XORG_DIR/usr/lib64/"* "$INITRAMFS_DIR/usr/lib64/" 2>/dev/null || true
    cp -r "$PACKAGE_XORG_DIR/etc/X11/"* "$INITRAMFS_DIR/etc/X11/" 2>/dev/null || true
    cp -r "$PACKAGE_XORG_DIR/usr/share/"* "$INITRAMFS_DIR/usr/share/" 2>/dev/null || true
    
    # Ensure /usr/bin/sh exists (symlink to /bin/sh) for scripts that need it
    print_progress "Creating /usr/bin/sh symlink..."
    mkdir -p "$INITRAMFS_DIR/usr/bin"
    if [ ! -e "$INITRAMFS_DIR/usr/bin/sh" ]; then
        ln -sf /bin/sh "$INITRAMFS_DIR/usr/bin/sh"
    fi
    
    # Create /var/log directory for X server logs
    print_progress "Creating /var/log directory for X server..."
    mkdir -p "$INITRAMFS_DIR/var/log"
    chmod 755 "$INITRAMFS_DIR/var/log" 2>/dev/null || true
    
    # Create a simple .xinitrc for fluxbox if it doesn't exist
    if [ ! -f "$INITRAMFS_DIR/etc/X11/xinit/xinitrc" ] && [ ! -f "$INITRAMFS_DIR/root/.xinitrc" ]; then
        print_progress "Creating default .xinitrc for fluxbox..."
        mkdir -p "$INITRAMFS_DIR/etc/X11/xinit"
        echo '#!/bin/sh' > "$INITRAMFS_DIR/etc/X11/xinit/xinitrc"
        echo 'exec fluxbox' >> "$INITRAMFS_DIR/etc/X11/xinit/xinitrc"
        chmod +x "$INITRAMFS_DIR/etc/X11/xinit/xinitrc"
    fi
    
    print_complete "X.org setup complete"
    return 0
}
