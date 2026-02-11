#!/bin/bash

# Kill any running background bluetoothctl processes to prevent duplicates
pkill -f "bluetoothctl --monitor"

# Listen to bluetooth events in real-time
bluetoothctl --monitor | while read -r line; do
    # Look for the "Connected: yes" event
    if echo "$line" | grep -q "Connected: yes"; then
        
        # Extract the MAC address (The 3rd word in the line: "[CHG] Device XX:XX... Connected: yes")
        DEVICE_MAC=$(echo "$line" | awk '{print $3}')
        
        # Wait a moment for battery info to populate
        sleep 3

        # Get Device Name
        DEVICE_NAME=$(bluetoothctl info "$DEVICE_MAC" | grep "Alias" | cut -d: -f2 | xargs)

        # Retry loop for Battery (Bluetooth is slow to report battery)
        BATTERY_LEVEL=""
        for i in {1..4}; do
            BATTERY_LEVEL=$(bluetoothctl info "$DEVICE_MAC" | grep "Battery Percentage" | cut -d"(" -f2 | cut -d")" -f1)
            
            # If found, stop looking
            if [ -n "$BATTERY_LEVEL" ]; then break; fi
            
            # If not found, check UPower (fallback)
            UPOWER_MAC="dev_$(echo "$DEVICE_MAC" | tr ':' '_')"
            BATTERY_LEVEL=$(upower -i "/org/freedesktop/UPower/devices/headset_$UPOWER_MAC" 2>/dev/null | grep "percentage" | awk '{print $2}')
            
            if [ -n "$BATTERY_LEVEL" ]; then break; fi
            
            sleep 1
        done

        # Prepare Notification Body
        if [ -n "$BATTERY_LEVEL" ]; then
            BODY="<b>$DEVICE_NAME</b>\nBattery: $BATTERY_LEVEL"
        else
            BODY="<b>$DEVICE_NAME</b>\n(Battery info unavailable)"
        fi

        # Send Notification (-r 9991 ensures we replace old notifications instead of stacking)
        dunstify "Bluetooth Connected" "$BODY" -i bluetooth -r 9991
    fi
done
