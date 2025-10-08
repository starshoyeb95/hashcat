#!/bin/bash

# Keep-alive script to prevent Codespace timeout
LOG_FILE="/var/log/keepalive.log"
KEEPALIVE_FILE="/tmp/keepalive_activity"

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log_message "Keep-alive service started"

while true; do
    # Update keepalive timestamp
    date > "$KEEPALIVE_FILE"
    
    # Create minimal activity to keep the environment alive
    # This simulates user activity without excessive resource use
    
    # Touch a file to create filesystem activity
    touch /tmp/.keepalive_$(date +%s)
    
    # Clean up old keepalive markers (keep last 10)
    ls -t /tmp/.keepalive_* 2>/dev/null | tail -n +11 | xargs rm -f 2>/dev/null
    
    # Check system resources
    LOAD=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | tr -d ',')
    MEM=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}')
    
    # Log status periodically (every hour)
    CURRENT_MINUTE=$(date +%M)
    if [ "$CURRENT_MINUTE" = "00" ]; then
        log_message "Status - Load: $LOAD, Memory: ${MEM}%"
        
        # Check if hashcat is running
        if pgrep -x hashcat > /dev/null; then
            HASHCAT_COUNT=$(pgrep -x hashcat | wc -l)
            log_message "Hashcat processes running: $HASHCAT_COUNT"
        fi
    fi
    
    # Sleep for 60 seconds before next check
    sleep 60
done
