#!/usr/bin/sh
## @file
# Start the Guest Additions X11 Client
#

#
# Copyright (C) 2007-2024 Oracle and/or its affiliates.
#
# This file is part of VirtualBox base platform packages, as
# available from https://www.virtualbox.org.
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation, in version 3 of the
# License.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, see <https://www.gnu.org/licenses>.
#
# SPDX-License-Identifier: GPL-3.0-only
#

# Sanity check: if non-writeable PID-files are present in the user home
# directory VBoxClient will fail to start.
for i in $HOME/.vboxclient-*.pid; do
    test -w $i || rm -f $i
done

# Do not start if the kernel module is not present; or if this script is
# triggered by a connection over SSH.
if [ -c /dev/vboxguest -a -z "${SSH_CONNECTION}" ]; then
    # Check wheather X11 or Wayland version of VBoxClient should be started.
    vbox_wl_check=$(/usr/bin/vboxwl --check 2> /dev/null)
    if test "$vbox_wl_check" = "WL"; then
        /usr/bin/VBoxClient --wayland
    else
        /usr/bin/VBoxClient --clipboard
        /usr/bin/VBoxClient --seamless
        /usr/bin/VBoxClient --draganddrop
    fi

    /usr/bin/VBoxClient --checkhostversion
fi
