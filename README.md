# DownOrNot

A lightweight website uptime monitoring system written in Bash.

## Overview

DownOrNot continuously monitors a website's availability and alerts you via email when it goes down. It also logs all check results for historical analysis and includes a companion script to calculate your uptime percentage.

## Features

- **Simple Setup** - Interactive wizard generates customized monitoring scripts
- **Continuous Monitoring** - Checks your site every few seconds (configurable)
- **Email Alerts** - Notifies you when your site goes down and when it recovers
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

Run directly:
```bash
./mysite.generated.sh
```

Run in background:
```bash
nohup ./mysite.generated.sh &
```

Add to crontab (starts on boot):
```bash
@reboot /path/to/mysite.generated.sh
```

### Checking Uptime

```bash
./uptime.sh              # Interactive - prompts for project name
./uptime.sh mysite       # Direct - specify project name
```

## Configuration

The monitoring script supports these environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `CHECK_INTERVAL` | 3 | Seconds between checks |
| `FAILURE_THRESHOLD` | 4 | Consecutive failures before alerting |
| `REQUEST_TIMEOUT` | 10 | HTTP request timeout in seconds |

Example:
```bash
CHECK_INTERVAL=5 FAILURE_THRESHOLD=3 ./mysite.generated.sh
```

## Log Format

Logs are stored in `~/logs/<project>/YYYY/MM/YYYY-MM-DD.log`:

```
[OK] 2026-01-03 10:15:30 - https://example.com is up and running
[FAIL] 2026-01-03 10:15:33 - https://example.com IS DOWN! (Failure #1)
[INFO] 2026-01-03 10:00:00 - Monitoring started for https://example.com
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Credits

**Author:** Léon "Avic" Simmons ([@Avicennasis](https://github.com/Avicennasis))
