#!/bin/bash

PROFILE_DIR="/usr/local/libexec/cpu-power-profiles"

set_cpu_profile() {
    case "$1" in
        power-saver)
            "$PROFILE_DIR/minimum-power"
            ;;
        balanced)
            "$PROFILE_DIR/medium-power"
            ;;
        performance)
            "$PROFILE_DIR/ultra-power"
            ;;
    esac
}

# Detect the actual TLP profile at startup
if [ "$(/usr/bin/tlp-stat -s 2>/dev/null | grep -q 'TLP profile    = power-saver/SAV'; echo $?)" -eq 0 ]; then
    set_cpu_profile "power-saver"
elif [ "$(/usr/bin/tlp-stat -s 2>/dev/null | grep -q 'TLP profile    = balanced/BAT'; echo $?)" -eq 0 ]; then
    set_cpu_profile "balanced"
else
    set_cpu_profile "performance"
fi

# Monitor ActiveProfile changes
/usr/bin/gdbus monitor \
    --system \
    --dest org.freedesktop.UPower.PowerProfiles \
    --object-path /org/freedesktop/UPower/PowerProfiles |
while IFS= read -r line; do
    if [[ "$line" == *"ActiveProfile"* ]]; then
        profile=$(echo "$line" | sed -n "s/.*ActiveProfile.*<'\([^']*\)'.*/\1/p")

        if [[ -n "$profile" ]]; then
            set_cpu_profile "$profile"
        fi
    fi
done