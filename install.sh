#!/bin/bash

set -e

INSTALL_DIR="/usr/local/libexec/cpu-power-profiles"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "==> Installing TLP Dynamic CPU Limit..."

# Check required commands
for cmd in tlp tlp-stat cpupower gdbus systemctl; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "ERROR: Required command not found: $cmd"
        exit 1
    fi
done

# Create installation directory
echo "==> Creating $INSTALL_DIR"
mkdir -p "$INSTALL_DIR"

# Install scripts
echo "==> Installing CPU profile scripts"
cp "$SCRIPT_DIR/scripts/minimum-power" "$INSTALL_DIR/"
cp "$SCRIPT_DIR/scripts/medium-power" "$INSTALL_DIR/"
cp "$SCRIPT_DIR/scripts/ultra-power" "$INSTALL_DIR/"
cp "$SCRIPT_DIR/scripts/profile-listener.sh" "$INSTALL_DIR/"

chmod 755 "$INSTALL_DIR"/minimum-power
chmod 755 "$INSTALL_DIR"/medium-power
chmod 755 "$INSTALL_DIR"/ultra-power
chmod 755 "$INSTALL_DIR"/profile-listener.sh

# Install systemd service
echo "==> Installing systemd service"
cp "$SCRIPT_DIR/systemd/cpu-power-profile.service" \
   /etc/systemd/system/cpu-power-profile.service

# Install tlp-pd drop-in
echo "==> Installing tlp-pd drop-in"
mkdir -p /etc/systemd/system/tlp-pd.service.d

cp "$SCRIPT_DIR/systemd/tlp-pd-override.conf" \
   /etc/systemd/system/tlp-pd.service.d/override.conf

# Reload systemd
echo "==> Reloading systemd"
systemctl daemon-reload

# Make sure TLP services are enabled
echo "==> Enabling TLP services"
systemctl enable tlp.service
systemctl enable tlp-pd.service

# Do NOT independently enable cpu-power-profile.service.
# It is started through the tlp-pd dependency.
systemctl disable cpu-power-profile.service 2>/dev/null || true

# Restart TLP profile daemon
echo "==> Restarting tlp-pd"
systemctl restart tlp-pd.service

echo
echo "==> Installation complete."
echo
echo "Check the current profile with:"
echo "  tlp-stat -s"
echo
echo "Check the CPU frequency policy with:"
echo "  cpupower frequency-info | grep \"current policy\""
echo
echo "Expected limits:"
echo "  Power Saver  -> 1.0 GHz"
echo "  Balanced     -> 2.6 GHz"
echo "  Performance  -> 4.5 GHz"