# Get total system memory in bytes
TOTAL_MEM=$(sysctl -n hw.memsize)

# Get page size (in bytes)
PAGE_SIZE=$(vm_stat | grep "page size of" | awk '{print $8}')

# Get the number of free, active, inactive, and wired pages
FREE_PAGES=$(vm_stat | grep "Pages free:" | awk '{print $3}' | sed 's/\.//')
ACTIVE_PAGES=$(vm_stat | grep "Pages active:" | awk '{print $3}' | sed 's/\.//')
INACTIVE_PAGES=$(vm_stat | grep "Pages inactive:" | awk '{print $3}' | sed 's/\.//')
WIRED_PAGES=$(vm_stat | grep "Pages wired down:" | awk '{print $4}' | sed 's/\.//')

# Calculate total used memory: active + inactive + wired (in bytes)
USED_MEM=$(echo "($ACTIVE_PAGES + $INACTIVE_PAGES + $WIRED_PAGES) * $PAGE_SIZE" | bc)

# Convert bytes to gigabytes for display
USED_MEM_GB=$(echo "scale=2; $USED_MEM / (1024^3)" | bc)

# Combine Used GB and Total GB in one text
MEMORY_LABEL="$USED_MEM_GB GB" 

# Display the memory usage as one label in sketchybar
sketchybar --set 'memory' label="  $MEMORY_LABEL"
