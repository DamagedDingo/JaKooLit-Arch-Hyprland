#!/bin/bash

# Cache sudo creds to avoid password prompt repeating
# sudo -v

set -e

# ─── Colour Tags (JaKooLit Style) ──────────────────────────────
OK="$(tput setaf 2)[OK]$(tput sgr0)"
ERROR="$(tput setaf 1)[ERROR]$(tput sgr0)"
NOTE="$(tput setaf 3)[NOTE]$(tput sgr0)"
INFO="$(tput setaf 4)[INFO]$(tput sgr0)"
WARN="$(tput setaf 1)[WARN]$(tput sgr0)"
CAT="$(tput setaf 6)[ACTION]$(tput sgr0)"
RESET="$(tput sgr0)"


# ─── Config ─────────────────────────────────────────────────────
terminal=kitty
USER_SCRIPT_DIR="$HOME/.config/hypr/UserScripts"
WATCHER_SCRIPT="$USER_SCRIPT_DIR/WallpaperWatcher.sh"
DUPLICATOR_SCRIPT="/usr/local/bin/sddm-copy-wallpaper.sh"
POLKIT_RULE="/etc/polkit-1/rules.d/90-sddm-wallpaper.rules"
SYSTEMD_UNIT="$HOME/.config/systemd/user/wallpaper-watcher.service"
WATCH_FILE="$HOME/.config/hypr/wallpaper_effects/.wallpaper_current"
DEST_DIR="/usr/share/sddm/themes/sequoia_2/backgrounds/"
iDIR="$HOME/.config/swaync/images/bell.png"


# ─── Dependency Check ───────────────────────────────────────────
# Terminal check 
if ! command -v "$terminal" &>/dev/null; then
    notify-send -i "$iDIR" "Missing $terminal" "Install $terminal to enable setting of wallpaper watcher"
    echo -e "$WARN => Terminal not found: $terminal"
    exit 1
fi

# inotify-tools check
if ! command -v inotifywait &>/dev/null; then
    echo -ne "\n$INFO => [ Installing inotify-tools... ]\n"
    sudo pacman -Sy --noconfirm inotify-tools
    echo -e "$OK inotify-tools installed."
fi

# ─── Create WallpaperWatcher.sh ──────────────────────────────────
echo -ne "\n$INFO => [ Creating WallpaperWatcher.sh... ]\n"

# Create a watcher script that monitors the existing wallpaper file
cat > "$WATCHER_SCRIPT" <<EOF
#!/bin/bash

# Watch the wallpaper file that's created from the existing wallpaper scripts
WATCH_FILE="$WATCH_FILE"

while inotifywait -e close_write "\$WATCH_FILE"; do
    pkexec $DUPLICATOR_SCRIPT "\$WATCH_FILE"
done
EOF

# Make the script executable
chmod +x "$WATCHER_SCRIPT"
echo -e "$OK Watcher script written."

# ─── Write sddm-copy-wallpaper Script ───────────────────────────
echo -ne "\n$INFO => [ Creating sddm-copy-wallpaper script... ]\n"

# This script will be executed with root privileges
sudo tee "$DUPLICATOR_SCRIPT" >/dev/null <<EOF
#!/bin/bash

DEST_DIR="$DEST_DIR"

# Sleep for a few seconds to allow the wallpaper to be fully written and have the blur version created.
sleep 3.2

if cp "\$1" "\$DEST_DIR"; then
    msg="SDDM Background image has been updated"
else
    msg="Failed to update SDDM background image"
fi

# Watch out for Swaync restarting and clearing notification before it's seen
if [ -n "\$SUDO_USER" ]; then
    USER_ID=\$(id -u "\$SUDO_USER")
    export DISPLAY=:0
    export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/\$USER_ID/bus"
    sudo -u "\$SUDO_USER" notify-send -t 5000 -i "$iDIR" "\$msg"
else
    notify-send -i "$iDIR" "\$msg"
fi
EOF

# Make the script executable
sudo chmod +x "$DUPLICATOR_SCRIPT"
echo -e "$OK Duplicator script installed to $DUPLICATOR_SCRIPT."

# ─── Write Polkit Rule ──────────────────────────────────────────
echo -ne "\n$INFO => [ Installing polkit rule... ]\n"

# Create a polkit rule to allow the user to run the duplicator script with root privileges
sudo tee "$POLKIT_RULE" >/dev/null <<EOF
polkit.addRule(function(action, subject) {
    if (
        action.id == "org.freedesktop.policykit.exec" &&
        action.lookup("program") == "$DUPLICATOR_SCRIPT" &&
        subject.isInGroup("wheel")
    ) {
        return polkit.Result.YES;
    }
});
EOF

echo -e "$OK Polkit rule installed."

# ─── Write systemd user service ─────────────────────────────────
echo -ne "\n$INFO => [ Creating systemd user service... ]\n"

mkdir -p "$(dirname "$SYSTEMD_UNIT")"

cat > "$SYSTEMD_UNIT" <<EOF
[Unit]
Description=Watch Hyprland wallpaper file and update SDDM background

[Service]
ExecStart=$WATCHER_SCRIPT
Restart=on-failure

[Install]
WantedBy=default.target
EOF

# ─── Enable and Start ───────────────────────────────────────────
echo -ne "\n$INFO => [ Enabling and starting service... ]\n"

# Reload systemd user manager configuration
systemctl --user daemon-reexec
# Enable the service to start on boot
systemctl --user enable --now wallpaper-watcher.service

# ─── Notify and Done ────────────────────────────────────────────
notify-send -i "$iDIR" "Wallpaper Watcher Installed" "SDDM background auto-sync is now active"
echo -e "$OK Wallpaper watcher setup complete!"
