#!/usr/bin/bash
# Copyright (C) 1999-2004,2007-2011 Red Hat, Inc. All rights reserved. This
# copyrighted material is made available to anyone wishing to use, modify,
# copy, or redistribute it subject to the terms and conditions of the
# GNU General Public License version 2.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the
# Free Software Foundation, Inc., 51 Franklin Street, Fifth
# Floor, Boston, MA  02110-1301  USA
#
# X Input method setup script

. /usr/libexec/imsettings-functions

XCONFIGDIR="${XDG_CONFIG_HOME:-$HOME/.config}"
CONFIGDIR="$XCONFIGDIR/imsettings"
USER_XINPUTRC="$CONFIGDIR/xinputrc"
SYS_XINPUTRC="/etc/X11/xinit//xinputrc"
READ_XINPUTRC="N/A"

# Load up the user and system locale settings
oldterm=$TERM
unset TERM
if [ -r /etc/profile.d/lang.sh ]; then
    # for Fedora etc
    source /etc/profile.d/lang.sh
elif [ -r /etc/default/locale ]; then
    # for Debian
    source /etc/default/locale
elif [ -r /etc/env.d/02locale ]; then
    # for Gentoo
    source /etc/env.d/02locale
fi
[ -n "$oldterm" ] && export TERM=$oldterm

tmplang=${LC_CTYPE:-${LANG:-"en_US.UTF-8"}}

# unset env vars to be safe
unset AUXILIARY_PROGRAM AUXILIARY_ARGS GTK_IM_MODULE ICON IMSETTINGS_IGNORE_ME IMSETTINGS_IGNORE_SESSION LONG_DESC NOT_RUN PREFERENCE_PROGRAM PREFERENCE_ARGS QT_IM_MODULE SHORT_DESC XIM XIM_PROGRAM XIM_ARGS XMODIFIERS

[ -z "${IMSETTINGS_DISABLE_USER_XINPUTRC-}" ] && IMSETTINGS_DISABLE_USER_XINPUTRC=no
[ -z "${IMSETTINGS_DISABLE_SYS_XINPUTRC-}" ] && IMSETTINGS_DISABLE_SYS_XINPUTRC=no

if ! is_desktop_supported; then
    IMSETTINGS_DISABLE_SYS_XINPUTRC=yes
    if [ "x$(get_desktop)" = "xGNOME" ]; then
        # We don't support GNOME but GNOME Xorg seems still needing QT_IM_MODULE and XMODIFIERS
        GNOME_IMSETTINGS_DISABLE_SYS_XINPUTRC=yes
        IMSETTINGS_DISABLE_SYS_XINPUTRC=no
    fi
fi

# migrate old configuration file
[ ! -d $CONFIGDIR ] && mkdir -p $CONFIGDIR || :
[ -f "$HOME/.xinputrc" ] && mv $HOME/.xinputrc $CONFIGDIR/xinputrc
[ -f "$HOME/.xinputrc.bak" ] && mv $HOME/.xinputrc.bak $CONFIGDIR/xinputrc.bak

# remove systemd environment files
rm -f $XCONFIGDIR/environment.d/imsettings*.conf || :

if [ -r "$USER_XINPUTRC" -a "x$IMSETTINGS_DISABLE_USER_XINPUTRC" = "xno" ]; then
    source "$USER_XINPUTRC"
    READ_XINPUTRC=$USER_XINPUTRC
    if [ ! -h "$USER_XINPUTRC" ]; then
	SHORT_DESC="User Specific"
    fi
elif [ -r "$SYS_XINPUTRC" -a "x$IMSETTINGS_DISABLE_SYS_XINPUTRC" = "xno" ]; then
    # FIXME: This hardcoded list has to be gone in the future.
    # Locales that normally use input-method for native input
    _im_language_list="as bn gu hi ja kn ko mai ml mr ne or pa si ta te th ur vi zh"
    _sourced_xinputrc=0
    for i in $_im_language_list; do
        if echo $tmplang | grep -q -E "^$i"; then
            source "$SYS_XINPUTRC"
            READ_XINPUTRC=$SYS_XINPUTRC
            _sourced_xinputrc=1
            break
        fi
    done
    # Locales that usually use X locale compose
    # FIXME: which other locales should be included here?
    if [ $_sourced_xinputrc -eq 0 ]; then
        _xcompose_language_list="am_ET el_GR fi_FI pt_BR ru_RU"
        for i in $_xcompose_language_list; do
            if echo $tmplang | grep -q -E "^$i"; then
                source /etc/X11/xinit/xinput.d//xcompose.conf
                READ_XINPUTRC=/etc/X11/xinit/xinput.d//xcompose.conf
                _sourced_xinputrc=1
                break
            fi
        done
    fi
    if [ $_sourced_xinputrc -eq 0 ]; then
        # Read none.conf to set up properly for locales not listed the above.
        source /etc/X11/xinit/xinput.d//none.conf
        READ_XINPUTRC=/etc/X11/xinit/xinput.d//none.conf
    fi
fi

[ -z "${IMSETTINGS_INTEGRATE_DESKTOP-}" ] && IMSETTINGS_INTEGRATE_DESKTOP=yes
export IMSETTINGS_INTEGRATE_DESKTOP

[ -z "$XIM" -a "x$IMSETTINGS_DISABLE_SYS_XINPUTRC" = "xno" ] && XIM=none

# start IM via imsettings
IMSETTINGS_MODULE=${SHORT_DESC:-${XIM}}
[ -z "$IMSETTINGS_MODULE" ] && IMSETTINGS_MODULE="none"
export IMSETTINGS_MODULE

if [ "x$GNOME_IMSETTINGS_DISABLE_SYS_XINPUTRC" = "xyes" ]; then
    unset GTK_IM_MODULE
    IMSETTINGS_DISABLE_SYS_XINPUTRC=yes
fi

##
log_init
setup_gtk_immodule
setup_qt_immodule
setup_xim

# NOTE: Please make sure the session bus is established before running this script.
if ! is_dbus_enabled; then
    log "***"
    log "*** No DBus session hasn't been established yet. giving up to deal with Input Method with imsettings."
    log "***"

    run_xim
elif ! is_imsettings_enabled; then
    log "***"
    log "*** imsettings is explicitly disabled."
    log "***"

    run_xim
else
    # Yes, we are in the dbus session
    run_imsettings
fi
