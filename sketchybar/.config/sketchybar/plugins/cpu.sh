#!/bin/bash

CORE_COUNT=$(sysctl -n machdep.cpu.thread_count)
CPU_INFO=$(ps -eo pcpu,user)

# System CPU usage (excluding the current user)
CPU_SYS=$(echo "$CPU_INFO" | awk -v user=$(whoami) -v cores=$CORE_COUNT '{if ($2 != user && $1 != "") sum+=$1} END {print sum / cores}')

# User CPU usage (for the current user)
CPU_USER=$(echo "$CPU_INFO" | awk -v user=$(whoami) -v cores=$CORE_COUNT '{if ($2 == user && $1 != "") sum+=$1} END {print sum / cores}')

# Calculate the total CPU usage percentage
CPU_PERCENT=$(echo "$CPU_SYS $CPU_USER" | awk '{printf "%.0f\n", $1 + $2}')

# Set the label with sketchybar
sketchybar --set 'cpu' label="  $CPU_PERCENT%"
