#!/bin/bash


# --- ADD THIS BLOCK FOR UDEV AUTOMATION ---
USER_NAME="sai"
USER_ID=$(id -u "$USER_NAME")

# Point to the user's display and notification bus
export DISPLAY=:0
export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$USER_ID/bus"



# 1. Determine the MAC Address
# If an argument is passed (from udev), use it.
# If not, find the first connected device via bluetoothctl.
DEVICE_MAC=$1

if [ -z "$DEVICE_MAC" ]; then
    # Grab the MAC of the first connected device found
    DEVICE_MAC=$(bluetoothctl devices Connected | head -n 1 | awk '{print $2}')
fi

# If we still don't have a MAC, exit (no device connected)
if [ -z "$DEVICE_MAC" ]; then
    echo "No connected Bluetooth device found."
    exit 1
fi

# 2. Get Device Name (Alias)
# We use xargs to trim whitespace
DEVICE_NAME=$(bluetoothctl info "$DEVICE_MAC" | grep "Alias" | cut -d: -f2 | xargs)

# 3. Get Battery Level
# Battery info often takes a few seconds to sync after connection. 
# We try up to 3 times (waiting 1s each time) if it's empty.
BATTERY_LEVEL=""
for i in {1..3}; do
    # Try bluetoothctl first
    BATTERY_LEVEL=$(bluetoothctl info "$DEVICE_MAC" | grep "Battery Percentage" | cut -d"(" -f2 | cut -d")" -f1)
    
    # If bluetoothctl failed, try UPower (common fallback)
    if [ -z "$BATTERY_LEVEL" ]; then
        # Find path for this specific device MAC (converted to underscore format for upower)
        UPOWER_MAC="dev_$(echo "$DEVICE_MAC" | tr ':' '_')"
        BATTERY_LEVEL=$(upower -i "/org/freedesktop/UPower/devices/headset_$UPOWER_MAC" 2>/dev/null | grep "percentage" | awk '{print $2}')
    fi

    # If we found it, break the loop
    if [ -n "$BATTERY_LEVEL" ]; then
        break
    fi
    sleep 1
done

# 4. Construct Notification
if [ -n "$BATTERY_LEVEL" ]; then
    BODY="<b>$DEVICE_NAME</b>\nBattery: $BATTERY_LEVEL"
else
    BODY="<b>$DEVICE_NAME</b>\n(Battery info unavailable)"
fi

# 5. Send to Dunst
# -u normal: Normal urgency
# -r 9991: Replace ID (prevents stacking notifications)
dunstify "Bluetooth Connected" "$BODY" -i bluetooth -r 9991
