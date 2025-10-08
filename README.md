# uhcat-cloud
# Hashcat Codespace Environment

This is a fully configured GitHub Codespace environment for running Hashcat with automatic session management, backup, and resumability.

## 🚀 Features

- **Hashcat Pre-installed**: Latest version with CPU support
- **Auto-commit & Push**: Changes automatically committed and pushed every 5 minutes
- **Resumable Sessions**: All Hashcat sessions can be resumed after interruption
- **Shutdown Hooks**: Automatic status reporting before environment shutdown
- **Keep-alive**: Environment stays active even when disconnected
- **Session Manager**: Easy-to-use command-line tool for managing hashcat sessions

## 📋 Setup Instructions

### 1. Repository Setup

1. Create a new repository or use an existing one
2. Create a `.devcontainer` directory in your repository root
3. Copy all the configuration files to `.devcontainer/`:
   - `devcontainer.json`
   - `setup.sh`
   - `startup.sh`
   - `autocommit.sh`
   - `shutdown-hook.sh`
   - `keepalive.sh`

4. Make all scripts executable:
```bash
chmod +x .devcontainer/*.sh
```

5. Commit and push to your repository

### 2. Launch Codespace

1. Go to your repository on GitHub
2. Click "Code" → "Codespaces" → "Create codespace on main"
3. Wait for the environment to build (first time takes ~5-10 minutes)

### 3. Configure Git Credentials

**Good news!** GitHub Codespaces automatically provides authentication. The setup script will configure everything for you.

To verify it's working:

```bash
# Check if token is available
echo $GITHUB_TOKEN  # Should show a token

# Test push
echo "test" > test.txt
git add test.txt
git commit -m "test"
git push  # Should work without prompting for credentials
```

**If you encounter authentication issues**, see [GITHUB_AUTH.md](GITHUB_AUTH.md) for detailed troubleshooting.

## 🎯 Usage

### Session Manager Commands

The environment includes a custom `hashcat-session` command for easy session management:

```bash
# Start a new session
hashcat-session start my-job -m 0 -a 0 /root/hashcat-work/hashes/hashes.txt /root/hashcat-work/wordlists/rockyou.txt

# Resume an interrupted session
hashcat-session resume my-job

# Check session status
hashcat-session status my-job

# List all sessions
hashcat-session list
```

### Directory Structure

```
/root/hashcat-work/
├── hashes/        # Place your hash files here
├── wordlists/     # Place your wordlists here
├── rules/         # Place your rule files here
├── masks/         # Place your mask files here
└── results/       # Results and status files
```

### Example Workflows

#### Password Recovery Example

```bash
# 1. Upload your hash file to the hashes directory
echo "5f4dcc3b5aa765d61d8327deb882cf99" > /root/hashcat-work/hashes/my-hashes.txt

# 2. Start a hashcat session
hashcat-session start recovery-job -m 0 -a 0 \
  /root/hashcat-work/hashes/my-hashes.txt \
  /root/hashcat-work/wordlists/rockyou.txt \
  -o /root/hashcat-work/results/recovered.txt

# 3. Session will automatically save progress
# If interrupted, resume with:
hashcat-session resume recovery-job
```

#### Checking Status After Shutdown

```bash
# View the last shutdown status
cat /root/hashcat-work/results/last-shutdown-status.txt

# Or check the full log
cat /var/log/hashcat-shutdown.log
```

## 🔄 Automatic Features

### Auto-commit (Every 5 Minutes)

The environment automatically:
- Detects changes in your workspace
- Commits changes with timestamp
- Pushes to your GitHub repository
- Logs all activity to `/var/log/autocommit.log`

### Auto-resume on Restart

When you restart the Codespace:
- All interrupted sessions are detected
- You'll see a list of resumable sessions
- Use `hashcat-session resume <name>` to continue

### Keep-alive Service

- Prevents automatic shutdown due to inactivity
- Creates minimal filesystem activity
- Logs system status hourly

## 📊 Monitoring

### Check Auto-commit Status

```bash
# View auto-commit log
tail -f /var/log/autocommit.log

# Check if service is running
systemctl status hashcat-autocommit
```

### Check Keep-alive Status

```bash
# View keep-alive log
tail -f /var/log/keepalive.log

# Check if service is running
systemctl status codespace-keepalive
```

### Monitor Hashcat Progress

```bash
# While hashcat is running, press 's' in the terminal for status
# Or check running processes
ps aux | grep hashcat

# View session restore files
ls -lh /root/.hashcat/restore/
```

## 🛡️ Important Notes

### Legal and Ethical Use

**⚠️ This environment is designed for legitimate security testing and password recovery purposes only.**

Always ensure you have:
- Proper authorization before testing any systems
- Legal right to access the passwords you're recovering
- Compliance with all applicable laws and regulations

Unauthorized password cracking is illegal and unethical.

### Resource Considerations

- GitHub Codespaces have usage limits based on your plan
- CPU-based hashcat is slower than GPU-based operations
- Long-running sessions may consume significant compute time
- Monitor your usage at: https://github.com/settings/billing

### Data Privacy

- Your workspace is automatically committed and pushed to GitHub
- Ensure sensitive data (hashes, passwords, results) are in `.gitignore` if needed
- Consider using private repositories for sensitive work

## 🔧 Troubleshooting

### Auto-commit Not Working

```bash
# Check if the service is running
systemctl status hashcat-autocommit

# Manually restart the service
systemctl restart hashcat-autocommit

# Check the logs
tail -f /var/log/autocommit.log
```

### Session Won't Resume

```bash
# Check if restore file exists
ls -la /root/.hashcat/restore/

# Try manual resume
hashcat --session=<session-name> --restore

# Check hashcat logs
cat ~/.hashcat/hashcat.log
```

### Codespace Timing Out

```bash
# Check keep-alive service
systemctl status codespace-keepalive

# Restart keep-alive
systemctl restart codespace-keepalive

# Check keep-alive logs
tail -f /var/log/keepalive.log
```

## 📚 Additional Resources

- [Hashcat Wiki](https://hashcat.net/wiki/)
- [Hashcat Example Hashes](https://hashcat.net/wiki/doku.php?id=example_hashes)
- [GitHub Codespaces Documentation](https://docs.github.com/en/codespaces)
- [Hashcat Forums](https://hashcat.net/forum/)

## 🤝 Contributing

Feel free to submit issues and enhancement requests!

## 📄 License

This configuration is provided as-is for legitimate security research and password recovery purposes.
