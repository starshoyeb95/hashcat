#!/bin/bash

echo "Starting Hashcat environment services..."

# Start cron for autocommit fallback
service cron start

# Start systemd services if available
if command -v systemctl &> /dev/null; then
    systemctl daemon-reload
    systemctl enable hashcat-autocommit.service 2>/dev/null || true
    systemctl start hashcat-autocommit.service 2>/dev/null || true
    systemctl enable hashcat-shutdown.service 2>/dev/null || true
    systemctl enable codespace-keepalive.service 2>/dev/null || true
    systemctl start codespace-keepalive.service 2>/dev/null || true
fi

# Start autocommit in background as fallback
nohup /workspaces/.devcontainer/autocommit.sh > /tmp/autocommit.log 2>&1 &

# Start keepalive in background as fallback
nohup /workspaces/.devcontainer/keepalive.sh > /tmp/keepalive.log 2>&1 &

# Resume any interrupted hashcat sessions
echo "Checking for interrupted Hashcat sessions..."
RESTORE_DIR="/root/.hashcat/restore"
if [ -d "$RESTORE_DIR" ]; then
    for restore_file in "$RESTORE_DIR"/*.restore; do
        if [ -f "$restore_file" ]; then
            session_name=$(basename "$restore_file" .restore)
            echo "Found interrupted session: $session_name"
            echo "To resume, run: hashcat-session resume $session_name"
        fi
    done
fi

echo "Environment ready!"
echo "Run 'hashcat-session list' to see available sessions"
