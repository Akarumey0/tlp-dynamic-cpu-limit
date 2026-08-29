#!/bin/bash

set -e

INSTALL_DIR="/usr/local/libexec/cpu-power-profiles"
SERVICE_FILE="/etc/systemd/system/cpu-power-profile.service"
DROPIN_DIR="/etc/systemd/system/tlp-pd.service.d"
DROPIN_FILE="$DROPIN_DIR/override.conf"

echo "==> Uninstalling TLP Dynamic CPU Limit..."

# Stop the custom service if it is running
if systemctl is-active --quiet cpu-power-profile.service; then
    echo "==> Stopping cpu-power-profile.service"
    systemctl stop cpu-power-profile.service
fi

# Disable the custom service
systemctl disable cpu-power-profile.service 2>/dev/null || true

# Remove systemd service
if [ -f "$SERVICE_FILE" ]; then
    echo "==> Removing systemd service"
    rm -f "$SERVICE_FILE"
fi

# Remove tlp-pd drop-in
if [ -f "$DROPIN_FILE" ]; then
    echo "==> Removing tlp-pd drop-in"
    rm -f "$DROPIN_FILE"
fi

# Remove empty drop-in directory
if [ -d "$DROPIN_DIR" ] && [ -z "$(ls -A "$DROPIN_DIR")" ]; then
    rmdir "$DROPIN_DIR"
fi

# Remove installed scripts
if [ -d "$INSTALL_DIR" ]; then
    echo "==> Removing $INSTALL_DIR"
    rm -rf "$INSTALL_DIR"
fi

# Reload systemd
echo "==> Reloading systemd"
systemctl daemon-reload

# Restart TLP profile daemon if available
if systemctl is-enabled --quiet tlp-pd.service 2>/dev/null; then
    echo "==> Restarting tlp-pd"
    systemctl restart tlp-pd.service
fi

echo
echo "==> Uninstallation complete."
echo
echo "The custom CPU frequency profile service has been removed."
echo "TLP itself has not been removed."