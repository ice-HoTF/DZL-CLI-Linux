#!/usr/bin/env bash

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="$SRC/DZL"

clear
echo "DZL Installer"
echo ""

steamos=0
if command -v steamos-readonly >/dev/null 2>&1; then
    steamos=1
fi

install_cmd=()
if command -v pacman >/dev/null 2>&1; then
    if (( steamos )); then
        install_cmd=(sudo pacman -Sy --needed --noconfirm)
    else
        install_cmd=(sudo pacman -S --needed --noconfirm)
    fi
elif command -v apt >/dev/null 2>&1; then
    install_cmd=(sudo apt install -y)
fi

steamos_lock() {
    echo ""
    echo "Enabling SteamOS read-only mode:"
    sudo steamos-readonly enable
}

if (( steamos )); then
    echo "Disabling SteamOS read-only mode:"
    sudo steamos-readonly disable || { echo "Could not disable read-only mode. If you never set a password, run 'passwd' first."; exit 1; }
    trap steamos_lock EXIT
    echo ""
fi



echo "Installing Dependencies:"
echo ""
missing=()
for dep in gawk curl jq; do
    command -v "$dep" >/dev/null 2>&1 || missing+=("$dep")
done

if (( ${#missing[@]} )); then
    echo "Missing: ${missing[*]}"
    echo ""
    if (( steamos )); then
        sudo pacman-key --init
        sudo pacman-key --populate archlinux
        sudo pacman-key --populate holo
        echo ""
    fi
    (( ${#install_cmd[@]} )) || { echo "No supported package manager. Install manually: ${missing[*]}"; exit 1; }
    "${install_cmd[@]}" "${missing[@]}" || { echo "Dependency install failed. Stopping."; exit 1; }
else
    echo "gawk, curl and jq are already installed."
fi
echo ""
echo ""

echo "Making the DZL folder contents executable."
chmod +x "$DEST"/*
echo ""
echo ""

mkdir -p "/home/$USER/.local/share/applications"
cp "$DEST/DZL.desktop" "/home/$USER/.local/share/applications/DZL.desktop"
sed -i "s|/path/to/file.sh|$DEST/DZL.sh|" "/home/$USER/.local/share/applications/DZL.desktop"
echo "DZL.desktop was copied to '/home/$USER/.local/share/applications/' and should be available in the application menu."
echo ""
echo ""

if (( steamos )); then
    sudo steamos-readonly disable
fi
sudo cp "$DEST/dzl.png" /usr/share/icons/
echo "Application Icon copied to '/usr/share/icons'"
echo ""
echo ""

if (( steamos )); then
    trap - EXIT
    steamos_lock
    echo ""
fi

echo ""
echo "All Done! Launch DZL by Using the Application Menu Entry or through Terminal: bash $DEST/DZL.sh"
