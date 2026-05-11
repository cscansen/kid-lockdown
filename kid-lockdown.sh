#!/usr/bin/env bash
# kid-lockdown.sh — hide admin/system apps, add Google Docs/Sheets launchers
# Usage: sudo ./kid-lockdown.sh [username] [profile]
# Profiles: restricted (default) | tween | teen
# Default username: ohmankids

set -euo pipefail

[[ $EUID -eq 0 ]] || { echo "Run as root (sudo)"; exit 1; }

KID_USER="${1:-ohmankids}"
PROFILE="${2:-restricted}"

KID_HOME=$(getent passwd "$KID_USER" | cut -d: -f6)
[[ -n "$KID_HOME" ]] || { echo "User '$KID_USER' not found"; exit 1; }

# ── Profile definitions ───────────────────────────────────────────────────────
# Always hidden regardless of profile — never appropriate for a kid account
HIDE_ALWAYS=(
    # Mint system tools
    mintinstall mintinstall-fp-handler mintinstall-kde
    mintdrivers mintsources mint-meta-codecs
    timeshift-gtk
    mintstick mintstick-format mintstick-format-kde mintstick-kde
    mintbackup mintsysadm mintreport mintreport-tray
    mintlocale mintlocale-im mintwelcome
    cinnamon-settings-users cinnamon-settings-user
    org.gnome.DiskUtility gnome-disk-image-mounter gnome-disk-image-writer
    nm-connection-editor
    # Office suite — replaced by Google Docs/Sheets in Chromium
    libreoffice-startcenter libreoffice-writer libreoffice-calc
    libreoffice-impress libreoffice-draw libreoffice-base libreoffice-math
    # Email
    thunderbird
)

case "$PROFILE" in
    restricted)
        # Age ~6: no terminal, no update viewer, maximum lockdown
        HIDE_PROFILE=(
            mintupdate mintupdate-kde
            org.gnome.Terminal org.gnome.Terminal.Preferences
        )
        ;;
    tween)
        # Age ~9-11: terminal + update viewer visible (planned — not yet implemented)
        echo "  [warn] profile 'tween' not yet implemented — applying 'restricted'"
        HIDE_PROFILE=(
            mintupdate mintupdate-kde
            org.gnome.Terminal org.gnome.Terminal.Preferences
        )
        ;;
    teen)
        # Age ~13+: most admin tools still hidden, productivity unlocked (planned)
        echo "  [warn] profile 'teen' not yet implemented — applying 'restricted'"
        HIDE_PROFILE=(
            mintupdate mintupdate-kde
            org.gnome.Terminal org.gnome.Terminal.Preferences
        )
        ;;
    *)
        echo "Unknown profile '$PROFILE'. Valid profiles: restricted, tween, teen"
        exit 1
        ;;
esac

HIDE=("${HIDE_ALWAYS[@]}" "${HIDE_PROFILE[@]}")

# ── Apply menu overrides ──────────────────────────────────────────────────────
LOCAL_APPS="$KID_HOME/.local/share/applications"
mkdir -p "$LOCAL_APPS"

echo "Applying profile '$PROFILE' for '$KID_USER' (${#HIDE[@]} entries)..."
for app in "${HIDE[@]}"; do
    target="$LOCAL_APPS/${app}.desktop"
    if [[ ! -f "$target" ]]; then
        printf '[Desktop Entry]\nNoDisplay=true\n' > "$target"
        echo "  hidden: $app"
    else
        echo "  already hidden: $app"
    fi
done
chown -R "$KID_USER:$KID_USER" "$LOCAL_APPS"

# ── Ensure Google Chrome is installed ────────────────────────────────────────
# chromium-browser is a snap stub on Linux Mint / Ubuntu 22.04+ — use Chrome .deb
echo ""
if ! command -v google-chrome-stable &>/dev/null; then
    echo "Installing Google Chrome..."
    wget -qO /tmp/google-chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
    apt-get install -y /tmp/google-chrome.deb
    rm -f /tmp/google-chrome.deb
    echo "  google-chrome-stable: installed"
else
    echo "  google-chrome-stable: already installed"
fi

# ── Google Docs / Google Sheets app launchers ────────────────────────────────
echo ""
echo "Creating Google Docs and Sheets launchers..."

cat > /usr/share/applications/google-docs.desktop <<'EOF'
[Desktop Entry]
Name=Google Docs
Exec=google-chrome-stable --app=https://docs.google.com/ --password-store=basic
Icon=google-chrome
Type=Application
Categories=Office;WordProcessor;
StartupNotify=true
EOF

cat > /usr/share/applications/google-sheets.desktop <<'EOF'
[Desktop Entry]
Name=Google Sheets
Exec=google-chrome-stable --app=https://sheets.google.com/ --password-store=basic
Icon=google-chrome
Type=Application
Categories=Office;Spreadsheet;
StartupNotify=true
EOF

DESKTOP_DIR="$KID_HOME/Desktop"
mkdir -p "$DESKTOP_DIR"

cp /usr/share/applications/google-docs.desktop   "$DESKTOP_DIR/google-docs.desktop"
cp /usr/share/applications/google-sheets.desktop "$DESKTOP_DIR/google-sheets.desktop"

for f in "$DESKTOP_DIR/google-docs.desktop" "$DESKTOP_DIR/google-sheets.desktop"; do
    chmod +x "$f"
    gio set -t string "$f" metadata::trusted "yes" 2>/dev/null || true
done

chown -R "$KID_USER:$KID_USER" "$DESKTOP_DIR"
echo "  Google Docs:   /usr/share/applications + $KID_USER Desktop"
echo "  Google Sheets: /usr/share/applications + $KID_USER Desktop"

# Suppress keyring prompt on passwordless auto-login accounts.
# --password-store=basic tells Chrome not to use the system keyring.
# Override the system Chrome .desktop for this user only (leaves admin unaffected).
if [[ -f /usr/share/applications/google-chrome.desktop ]]; then
    sed 's|Exec=/usr/bin/google-chrome-stable|Exec=/usr/bin/google-chrome-stable --password-store=basic|g' \
        /usr/share/applications/google-chrome.desktop > "$LOCAL_APPS/google-chrome.desktop"
    chown "$KID_USER:$KID_USER" "$LOCAL_APPS/google-chrome.desktop"
    echo "  Chrome launcher: --password-store=basic applied for $KID_USER"
fi

# ── Auto-updates (system-wide, run once) ─────────────────────────────────────
echo ""
echo "Configuring automatic updates..."

SENTINEL="/var/lib/linuxmint/mintupdate-automatic-upgrades-enabled"
[[ -f "$SENTINEL" ]] || { touch "$SENTINEL"; echo "  created upgrade sentinel"; }
systemctl enable --now mintupdate-automation-upgrade.timer
echo "  mintupdate-automation-upgrade.timer: enabled"

AUTOREMOVE_SENTINEL="/var/lib/linuxmint/mintupdate-automatic-removals-enabled"
[[ -f "$AUTOREMOVE_SENTINEL" ]] || { touch "$AUTOREMOVE_SENTINEL"; echo "  created autoremove sentinel"; }
systemctl enable --now mintupdate-automation-autoremove.timer
echo "  mintupdate-automation-autoremove.timer: enabled"

echo ""
echo "Done. Profile '$PROFILE' applied for '$KID_USER'."
echo ""
echo "  Note: for Google Docs/Sheets offline mode, open each app in Chromium"
echo "  while online and enable 'Make available offline' in Google Drive settings."
