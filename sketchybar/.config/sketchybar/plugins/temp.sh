# Fetch CPU temperature using powermetrics (requires sudo)
TEMP=$(sudo powermetrics --samplers smc -n1 | grep "CPU die temperature" | awk '{print $4}')

# Check if the temperature was fetched successfully
if [ "$TEMP" = "" ]; then
    # If no temperature reading, animate the temperature item and clear the label
    sketchybar --animate circ 15 --set temperature y_offset=70
    sleep 0.2 && sketchybar --set temperature label=""
else
    # Format temperature and append "°C"
    TEMP_LABEL="${TEMP}°C"

    # Only update the sketchybar label if the temperature has changed
    if [ "$(sketchybar --query temperature | jq -r '.label.value')" != "$TEMP_LABEL" ]; then
        sketchybar --animate circ 15 --set temperature y_offset=70 \
                   --animate circ 10 --set temperature y_offset=7 \
                   --animate circ 15 --set temperature y_offset=0

        # Set the label to the current temperature after animation
        sleep 0.15 && sketchybar --set temperature label="$TEMP_LABEL"
    fi
fi

