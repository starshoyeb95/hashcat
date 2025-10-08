#!/bin/bash

# Auto-commit script - runs every 5 minutes
WORKSPACE_DIR="/workspaces/$(basename $PWD)"
LOG_FILE="/var/log/autocommit.log"

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Ensure GitHub authentication is configured
setup_github_auth() {
    if [ -n "$GITHUB_TOKEN" ]; then
        git config --global credential.helper store
        git config --global url."https://oauth2:${GITHUB_TOKEN}@github.com/".insteadOf "https://github.com/"
        return 0
    else
        log_message "WARNING: GITHUB_TOKEN not available"
        return 1
    fi
}

# Change to workspace directory
cd "$WORKSPACE_DIR" 2>/dev/null || cd /workspaces/* 2>/dev/null || {
    log_message "ERROR: Could not find workspace directory"
    exit 1
}

# Setup authentication on first run
setup_github_auth

# Main loop - run indefinitely with 5-minute intervals
while true; do
    log_message "Starting auto-commit process..."
    
    # Check if there are any changes
    if [[ -n $(git status -s) ]]; then
        log_message "Changes detected, committing..."
        
        # Add all changes
        git add -A
        
        # Create commit message with timestamp and hashcat status
        COMMIT_MSG="Auto-commit: $(date '+%Y-%m-%d %H:%M:%S')"
        
        # Check for running hashcat processes
        if pgrep -x hashcat > /dev/null; then
            HASHCAT_STATUS=$(ps aux | grep hashcat | grep -v grep | head -1)
            COMMIT_MSG="$COMMIT_MSG - Hashcat running"
            log_message "Hashcat process detected"
        fi
        
        # Commit changes
        git commit -m "$COMMIT_MSG" >> "$LOG_FILE" 2>&1
        
        # Push to remote
        git push origin HEAD 2>&1 | tee -a "$LOG_FILE"
        PUSH_EXIT_CODE=${PIPESTATUS[0]}
        
        if [ $PUSH_EXIT_CODE -eq 0 ]; then
            log_message "Successfully pushed changes to remote"
        else
            log_message "WARNING: Failed to push changes (Exit code: $PUSH_EXIT_CODE)"
            log_message "Attempting to re-authenticate..."
            setup_github_auth
        fi
    else
        log_message "No changes to commit"
    fi
    
    # Wait 5 minutes before next iteration
    sleep 300
done
