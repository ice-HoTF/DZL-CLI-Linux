#!/usr/bin/env bash

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="/home/$USER/DZL"

clear
echo "DZL Installer"
echo ""
echo "What Linux distro are you using?"
echo ""
echo " 1) Debian"
echo " 2) Arch"
echo " 3) SteamOS (Steam Deck)"
echo ""

choice=""
until [[ $choice == [123] ]]; do
    read -r -p "Enter 1, 2 or 3: " choice
done
echo ""

steamos=0
case $choice in
    1)
        distro="Debian"
        steamdir="debian-installation"
        install_cmd=(sudo apt install -y)
        ;;
    2)
        distro="Arch"
        steamdir="steam"
        install_cmd=(sudo pacman -S --needed --noconfirm)
        ;;
    3)
        distro="SteamOS"
        steamdir="steam"
        install_cmd=(sudo pacman -Sy --needed --noconfirm)
        steamos=1
        ;;
esac

echo "Distro:       $distro"
echo "Steam folder: /home/$USER/.steam/$steamdir"
echo ""

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

echo "Copying 'DZL Folder' to /home/$USER/"
cp -R "$SRC/DZL/" "/home/$USER/" || { echo "Could not copy the DZL folder from $SRC. Stopping."; exit 1; }
echo ""
echo ""

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
echo "All Done! Launch DZL by Using the Application Menu Entry or through Terminal: bash /home/$USER/DZL/DZL.sh"
