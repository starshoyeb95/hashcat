#!/bin/bash
set -e

echo "================================================"
echo "Setting up Hashcat Environment"
echo "================================================"

# Update system
apt-get update
apt-get upgrade -y

# Install dependencies
apt-get install -y \
    build-essential \
    git \
    p7zip-full \
    wget \
    curl \
    make \
    libssl-dev \
    zlib1g-dev \
    libbz2-dev \
    libreadline-dev \
    libsqlite3-dev \
    llvm \
    libncurses5-dev \
    libncursesw5-dev \
    xz-utils \
    tk-dev \
    libffi-dev \
    liblzma-dev \
    libgmp-dev \
    libpcap-dev \
    pkg-config \
    pocl-opencl-icd \
    ocl-icd-opencl-dev \
    opencl-headers

# Install Hashcat
echo "Installing Hashcat..."
cd /opt
git clone https://github.com/hashcat/hashcat.git
cd hashcat
make
make install

# Create hashcat directories
mkdir -p /root/.hashcat/{sessions,restore}
mkdir -p /workspace/hashcat-work/{hashes,wordlists,rules,masks,results}

# Create symlinks for easy access
ln -sf /workspace/hashcat-work /root/hashcat-work

# Configure Git with GitHub Codespaces token
git config --global user.name "${GITHUB_USER:-codespace}"
git config --global user.email "${GITHUB_USER:-codespace}@users.noreply.github.com"

# Use GitHub CLI for authentication in Codespaces
# GitHub Codespaces automatically provides GITHUB_TOKEN
if [ -n "$GITHUB_TOKEN" ]; then
    echo "Configuring Git with GitHub token..."
    git config --global credential.helper store
    git config --global url."https://oauth2:${GITHUB_TOKEN}@github.com/".insteadOf "https://github.com/"
    echo "GitHub authentication configured successfully"
else
    echo "WARNING: GITHUB_TOKEN not found. Auto-commit may not work."
    echo "Please authenticate manually with: gh auth login"
fi

# Create auto-commit service
cat > /etc/systemd/system/hashcat-autocommit.service << 'EOF'
[Unit]
Description=Hashcat Auto Commit Service
After=network.target

[Service]
Type=simple
ExecStart=/workspaces/.devcontainer/autocommit.sh
Restart=always
RestartSec=300
User=root
WorkingDirectory=/workspaces

[Install]
WantedBy=multi-user.target
EOF

# Create shutdown hook service
cat > /etc/systemd/system/hashcat-shutdown.service << 'EOF'
[Unit]
Description=Hashcat Shutdown Status Reporter
DefaultDependencies=no
Before=shutdown.target

[Service]
Type=oneshot
ExecStart=/workspaces/.devcontainer/shutdown-hook.sh
TimeoutStartSec=0

[Install]
WantedBy=shutdown.target
EOF

# Create keepalive service
cat > /etc/systemd/system/codespace-keepalive.service << 'EOF'
[Unit]
Description=Codespace Keep Alive Service
After=network.target

[Service]
Type=simple
ExecStart=/workspaces/.devcontainer/keepalive.sh
Restart=always
RestartSec=60
User=root

[Install]
WantedBy=multi-user.target
EOF

# Create cron job for auto-commit as fallback
echo "*/5 * * * * /workspaces/.devcontainer/autocommit.sh >> /var/log/autocommit.log 2>&1" | crontab -

# Install session manager
cat > /usr/local/bin/hashcat-session << 'SCRIPT'
#!/bin/bash
# Hashcat Session Manager

SESSION_DIR="/root/.hashcat/sessions"
RESTORE_DIR="/root/.hashcat/restore"

case "$1" in
    start)
        if [ -z "$2" ]; then
            echo "Usage: hashcat-session start <session-name> <hashcat-args>"
            exit 1
        fi
        SESSION_NAME="$2"
        shift 2
        mkdir -p "$SESSION_DIR/$SESSION_NAME"
        hashcat --session="$SESSION_NAME" --restore-file-path="$RESTORE_DIR/$SESSION_NAME.restore" "$@"
        ;;
    resume)
        if [ -z "$2" ]; then
            echo "Usage: hashcat-session resume <session-name>"
            exit 1
        fi
        SESSION_NAME="$2"
        hashcat --session="$SESSION_NAME" --restore
        ;;
    status)
        if [ -z "$2" ]; then
            echo "Active sessions:"
            ls -1 "$SESSION_DIR" 2>/dev/null || echo "No sessions found"
        else
            SESSION_NAME="$2"
            if [ -f "$RESTORE_DIR/$SESSION_NAME.restore" ]; then
                echo "Session '$SESSION_NAME' has restore data available"
                hashcat --session="$SESSION_NAME" --restore --status --machine-readable 2>/dev/null || echo "Session exists but cannot retrieve status"
            else
                echo "No restore data found for session '$SESSION_NAME'"
            fi
        fi
        ;;
    list)
        echo "Available sessions:"
        ls -1 "$SESSION_DIR" 2>/dev/null || echo "No sessions found"
        echo ""
        echo "Restore files:"
        ls -1 "$RESTORE_DIR" 2>/dev/null || echo "No restore files found"
        ;;
    *)
        echo "Hashcat Session Manager"
        echo "Usage: hashcat-session {start|resume|status|list} [session-name] [args]"
        echo ""
        echo "Commands:"
        echo "  start <name> <args>  - Start a new hashcat session"
        echo "  resume <name>        - Resume an existing session"
        echo "  status [name]        - Show session status"
        echo "  list                 - List all sessions"
        exit 1
        ;;
esac
SCRIPT

chmod +x /usr/local/bin/hashcat-session

echo "================================================"
echo "Hashcat Environment Setup Complete!"
echo "================================================"
echo "Hashcat version: $(hashcat --version)"
echo ""
echo "Usage:"
echo "  hashcat-session start my-job -m 0 -a 0 hashes.txt wordlist.txt"
echo "  hashcat-session resume my-job"
echo "  hashcat-session status my-job"
echo "  hashcat-session list"
echo ""
echo "Work directory: /root/hashcat-work"
echo "Sessions directory: /root/.hashcat/sessions"
echo "================================================"
