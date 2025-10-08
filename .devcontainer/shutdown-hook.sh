#!/bin/bash

# Shutdown hook - captures hashcat status before shutdown
LOG_FILE="/var/log/hashcat-shutdown.log"
STATUS_FILE="/root/hashcat-work/results/last-shutdown-status.txt"

echo "========================================" | tee -a "$LOG_FILE" "$STATUS_FILE"
echo "CODESPACE SHUTDOWN: $(date)" | tee -a "$LOG_FILE" "$STATUS_FILE"
echo "========================================" | tee -a "$LOG_FILE" "$STATUS_FILE"

# Check for running hashcat processes
if pgrep -x hashcat > /dev/null; then
    echo "Active Hashcat processes detected!" | tee -a "$LOG_FILE" "$STATUS_FILE"
    echo "" | tee -a "$LOG_FILE" "$STATUS_FILE"
    
    # List all hashcat processes
    echo "Process Information:" | tee -a "$LOG_FILE" "$STATUS_FILE"
    ps aux | grep hashcat | grep -v grep | tee -a "$LOG_FILE" "$STATUS_FILE"
    echo "" | tee -a "$LOG_FILE" "$STATUS_FILE"
    
    # Try to get status from each process
    echo "Attempting to capture status..." | tee -a "$LOG_FILE" "$STATUS_FILE"
    
    # Send status request to hashcat (it responds to 's' key)
    # Note: This may not work for all scenarios
    for pid in $(pgrep -x hashcat); do
        echo "Process ID: $pid" | tee -a "$LOG_FILE" "$STATUS_FILE"
        
        # Check if session file exists
        SESSION_DIR="/root/.hashcat/sessions"
        RESTORE_DIR="/root/.hashcat/restore"
        
        if [ -d "$SESSION_DIR" ]; then
            echo "Active sessions:" | tee -a "$LOG_FILE" "$STATUS_FILE"
            ls -lh "$SESSION_DIR" | tee -a "$LOG_FILE" "$STATUS_FILE"
        fi
        
        if [ -d "$RESTORE_DIR" ]; then
            echo "Restore files:" | tee -a "$LOG_FILE" "$STATUS_FILE"
            ls -lh "$RESTORE_DIR" | tee -a "$LOG_FILE" "$STATUS_FILE"
        fi
        
        # Send SIGUSR1 to trigger status output (hashcat feature)
        kill -USR1 $pid 2>/dev/null
        sleep 2
    done
    
    echo "" | tee -a "$LOG_FILE" "$STATUS_FILE"
    echo "Hashcat sessions will be automatically resumed on next startup" | tee -a "$LOG_FILE" "$STATUS_FILE"
    echo "Use 'hashcat-session resume <session-name>' to continue" | tee -a "$LOG_FILE" "$STATUS_FILE"
else
    echo "No active Hashcat processes" | tee -a "$LOG_FILE" "$STATUS_FILE"
fi

echo "" | tee -a "$LOG_FILE" "$STATUS_FILE"

# Check restore files
RESTORE_DIR="/root/.hashcat/restore"
if [ -d "$RESTORE_DIR" ] && [ "$(ls -A $RESTORE_DIR)" ]; then
    echo "Available restore points:" | tee -a "$LOG_FILE" "$STATUS_FILE"
    for restore_file in "$RESTORE_DIR"/*.restore; do
        if [ -f "$restore_file" ]; then
            session_name=$(basename "$restore_file" .restore)
            file_size=$(du -h "$restore_file" | cut -f1)
            file_date=$(date -r "$restore_file" '+%Y-%m-%d %H:%M:%S')
            echo "  - $session_name (Size: $file_size, Modified: $file_date)" | tee -a "$LOG_FILE" "$STATUS_FILE"
        fi
    done
else
    echo "No restore points found" | tee -a "$LOG_FILE" "$STATUS_FILE"
fi

echo "" | tee -a "$LOG_FILE" "$STATUS_FILE"
echo "Workspace state:" | tee -a "$LOG_FILE" "$STATUS_FILE"
cd /workspaces/* 2>/dev/null
git status -s | tee -a "$LOG_FILE" "$STATUS_FILE" || echo "Unable to check git status" | tee -a "$LOG_FILE" "$STATUS_FILE"

echo "========================================" | tee -a "$LOG_FILE" "$STATUS_FILE"

# Try to commit and push final state
if [ -d "/workspaces" ]; then
    cd /workspaces/* 2>/dev/null
    
    # Setup GitHub auth for final push
    if [ -n "$GITHUB_TOKEN" ]; then
        git config --global url."https://oauth2:${GITHUB_TOKEN}@github.com/".insteadOf "https://github.com/"
    fi
    
    if [ -n "$(git status -s)" ]; then
        git add -A
        git commit -m "Auto-commit before shutdown: $(date)" >> "$LOG_FILE" 2>&1
        
        # Try to push with timeout
        timeout 30 git push origin HEAD >> "$LOG_FILE" 2>&1
        if [ $? -eq 0 ]; then
            echo "Successfully pushed final commit" | tee -a "$LOG_FILE"
        else
            echo "Failed to push final commit (will be available on next start)" | tee -a "$LOG_FILE"
        fi
    fi
fi

# Copy status to workspace for access after restart
cp "$STATUS_FILE" /workspaces/last-shutdown-status.txt 2>/dev/null || true

echo "Shutdown hook complete" | tee -a "$LOG_FILE"
