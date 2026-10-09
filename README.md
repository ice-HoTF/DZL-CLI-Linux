# A Konsole-based DayZ Mod Launcher For Linux!
\
 **Released 16/04/2026**
\
\
By: ice_hotf
\
\
Supported Distros:
\
Tested with Arch Linux. 
\
\
Other Distros:
\
The steam path "/home/$USER/.steam/steam/steamapps/" might need to be changed for other distros. 
\
Replace it with yours.
\
\
\
**FLATPAK STEAM NOT TESTED/SUPPORTED!**
\
This script was only tested with the official steam package.
\
\
**Dependencies:**
\
gawk
\
curl
\
jq
\
\
\
\
**About This Script:**
\
\
   This script will identify missing mods, download them and launch DayZ with the mods. 
   This script will also allow you to delete mods and save Favorite Servers.
   Just follow the instructions in the terminal window and that's it.
\
\
   This script supports modded servers and vanilla servers.
\
\
\
\
**How To:**
\
\
1: Extract <DZL.zip> and Open Terminal in the Extracted Folder.
\
\
2: Install DZL by running <install_DZL.sh> in the Terminal:
\
   sh install_DZL.sh
\
\
3: Start DZL by Opening the Application Menu Shortcut <DZL> 
\
or Start DZL with a Terminal Command: 
\
bash /home/$USER/DZL/DZL.sh
\
\
\
**Video: How To Setup and Launch DZL (Old UI Version):**
https://www.youtube.com/watch?v=bssSaxZ6hS4
\
\
\
\
\
\
**Add DZL as a Application Entry and Open it as an Application** 
\
This is automatically done through the <install_DZL.sh> script, but this is how you do it manually:
\
\
1: Copy <DZL.desktop> to /home/$USER/.local/share/applications/ and in the Terminal:
\
cp /home/$USER/DZL-Beta-Linux-main/DZL.desktop /home/$USER/.local/share/applications/DZL.desktop
\
\
2: Copy the .png-icon to the </usr/share/icons> folder in the Terminal:
\
sudo cp /home/$USER/DZL-Beta-Linux-main/DZL/dzl.png /usr/share/icons/
\
\
\
\
**FAQ:**
\
\
I can't join the server:
- Restart Steam if you can't join the server and try again.
- On heavily modded servers, steam once in a while glitches right after downloading the mods and. A steam restart solves it.
