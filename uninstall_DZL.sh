#!/bin/bash

echo "Removing DZL.desktop from '/home/$USER/.local/share/applications'"
rm -f "/home/$USER/.local/share/applications/DZL.desktop"

echo "Removing dzl.png from '/usr/share/icons'"
if [[ -f /usr/share/icons/dzl.png ]]; then
    if command -v steamos-readonly >/dev/null 2>&1; then
        sudo steamos-readonly disable
        sudo rm -f /usr/share/icons/dzl.png
        sudo steamos-readonly enable
    else
        sudo rm -f /usr/share/icons/dzl.png
    fi
fi

echo "Removing folder 'DZL' from '/home/$USER/DZL'"
rm -rf "/home/$USER/DZL/"

echo "Uninstallation Successful"
