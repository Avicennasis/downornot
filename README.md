# DownOrNot

A lightweight website uptime monitoring system written in Bash.

## Overview

DownOrNot continuously monitors a website's availability and alerts you via email when it goes down. It also logs all check results for historical analysis and includes a companion script to calculate your uptime percentage.

## Features

- **Simple Setup** - Interactive wizard generates customized monitoring scripts
- **Continuous Monitoring** - Checks your site every few seconds (configurable)
- **HTML Email Alerts** - Beautiful, color-coded email notifications with tables (plain text option available)
- **Systemd Integration** - Native systemd service files for reliable system startup
- **Organized Logging** - Logs stored by date in `~/logs/<project>/YYYY/MM/`
- **Uptime Reports** - Calculate uptime percentage from historical logs
- **Graceful Shutdown** - Signal handling for clean process termination

## Requirements

- Bash 4.0 or higher
- `curl` - Used for HTTP requests
- `mail` - For email notifications (e.g., `mailutils`, `sendmail`, or `postfix`)

## Installation

```bash
git clone https://github.com/Avicennasis/downornot.git
cd downornot
chmod +x setup.sh uptime.sh
```

## Usage

### Creating a Monitor

Run the setup script and follow the prompts:

```bash
./setup.sh
```

You'll be asked for:
1. **Process name** - A unique identifier for this monitoring job
2. **URL** - The website URL to monitor (must include `http://` or `https://`)
3. **Email** - Email address for alert notifications

This generates a `<name>.generated.sh` script ready to run.

### Starting the Monitor

#### Option 1: Systemd (Recommended)

The setup script generates systemd service files for automatic startup and management.

**Install and start the service:**
```bash
sudo cp mysite.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable mysite.service
sudo systemctl start mysite.service
```

**Check service status:**
```bash
sudo systemctl status mysite.service
```

**View logs:**
```bash
sudo journalctl -u mysite.service -f
```

**Stop or restart the service:**
```bash
sudo systemctl stop mysite.service
sudo systemctl restart mysite.service
```

#### Option 2: Crontab (Fallback)

If systemd is not available or you prefer crontab:

```bash
crontab -e
```

Add this line:
```bash
@reboot /full/path/to/mysite.generated.sh
```

#### Option 3: Manual Execution

Run directly:
```bash
./mysite.generated.sh
```

Run in background:
```bash
nohup ./mysite.generated.sh &
```

### Checking Uptime

```bash
./uptime.sh              # Interactive - prompts for project name
./uptime.sh mysite       # Direct - specify project name
```

## Configuration

### Command-Line Options

| Option | Description |
|--------|-------------|
| `--html-off` | Disable HTML email formatting (use plain text instead) |

Example:
```bash
./mysite.generated.sh --html-off
```

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `CHECK_INTERVAL` | 3 | Seconds between checks |
| `FAILURE_THRESHOLD` | 4 | Consecutive failures before alerting |
| `REQUEST_TIMEOUT` | 10 | HTTP request timeout in seconds |

Example:
```bash
CHECK_INTERVAL=5 FAILURE_THRESHOLD=3 ./mysite.generated.sh
```

To use `--html-off` with systemd, edit the service file and modify the `ExecStart` line:
```ini
ExecStart=/path/to/mysite.generated.sh --html-off
```

## Log Format

Logs are stored in `~/logs/<project>/YYYY/MM/YYYY-MM-DD.log`:

```
[OK] 2026-01-03 10:15:30 - https://example.com is up and running
[FAIL] 2026-01-03 10:15:33 - https://example.com IS DOWN! (Failure #1)
[INFO] 2026-01-03 10:00:00 - Monitoring started for https://example.com
```

## Systemd Troubleshooting

### Service won't start

**Check service status and errors:**
```bash
sudo systemctl status mysite.service
sudo journalctl -u mysite.service -n 50
```

**Common issues:**
- **Permission denied**: Ensure the script is executable (`chmod +x mysite.generated.sh`)
- **Script not found**: Use absolute paths in the service file's `ExecStart` directive
- **User doesn't exist**: Verify the `User=` setting in the service file matches an existing user

### Service starts but stops immediately

**Check for script errors:**
```bash
sudo journalctl -u mysite.service -n 100
```

**Verify dependencies:**
- Ensure `curl` is installed: `which curl`
- Test mail functionality: `echo "test" | mail -s "Test" your@email.com`
- Check network connectivity: `curl -I https://example.com`

### Service running but no emails received

**Test email configuration:**
```bash
# Check if mail command works
echo "Test email" | mail -s "Test Subject" your@email.com

# Check system mail logs
sudo journalctl -u postfix -n 50  # for postfix
sudo tail -f /var/log/mail.log     # for other mail systems
```

**Common email issues:**
- Mail server not configured (install `mailutils` or `sendmail`)
- Firewall blocking SMTP ports
- Email marked as spam (check spam folder)
- HTML email not supported by mail server (use `--html-off` flag)

### Service not starting on boot

**Verify service is enabled:**
```bash
sudo systemctl is-enabled mysite.service
```

**Enable if not already:**
```bash
sudo systemctl enable mysite.service
```

**Check for failed units:**
```bash
sudo systemctl list-units --failed
```

### Viewing real-time logs

**Follow logs as they happen:**
```bash
# System logs (from journalctl)
sudo journalctl -u mysite.service -f

# Application logs (in ~/logs/)
tail -f ~/logs/mysite/$(date +%Y/%m/%Y-%m-%d).log
```

### Reloading after configuration changes

**After modifying the service file:**
```bash
sudo systemctl daemon-reload
sudo systemctl restart mysite.service
```

**After modifying the monitoring script:**
```bash
sudo systemctl restart mysite.service
```

### Checking system resource usage

**View CPU and memory usage:**
```bash
sudo systemctl status mysite.service
```

**Detailed resource info:**
```bash
ps aux | grep mysite.generated.sh
```

### Removing the service

**Stop and disable:**
```bash
sudo systemctl stop mysite.service
sudo systemctl disable mysite.service
sudo rm /etc/systemd/system/mysite.service
sudo systemctl daemon-reload
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Credits

**Author:** Léon "Avic" Simmons ([@Avicennasis](https://github.com/Avicennasis))
