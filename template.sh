# =============================================================================
# DownOrNot - Monitoring Template
# =============================================================================
#
# Description:
#   This is the template file that contains the core monitoring logic.
#   It is appended to generated monitoring scripts by setup.sh.
#   DO NOT run this file directly - use setup.sh to create a configured script.
#
# How it works:
#   1. Continuously checks if the configured URL is accessible
#   2. Logs all check results to organized log files
#   3. Sends email alerts when the site goes down
#   4. Sends recovery notification when the site comes back up
#
# Log format:
#   Logs are stored in ~/logs/<Name>/YYYY/MM/YYYY-MM-DD.log
#   Each entry is prefixed with:
#     - "OK" for successful checks
#     - "FAIL" for failed checks
#
# Author: Léon "Avic" Simmons (@Avicennasis)
# License: MIT
# Repository: https://github.com/Avicennasis/downornot
# =============================================================================

# -----------------------------------------------------------------------------
# ARGUMENT PARSING
# Parse command-line arguments before setting defaults
# -----------------------------------------------------------------------------

# Flag to control HTML email formatting (default: enabled)
USE_HTML_EMAIL=1

# Parse command line arguments
for arg in "$@"; do
    case "$arg" in
        --html-off)
            USE_HTML_EMAIL=0
            shift
            ;;
    esac
done

# -----------------------------------------------------------------------------
# CONFIGURATION DEFAULTS
# These can be overridden by setting them before sourcing this template
# -----------------------------------------------------------------------------

# Number of consecutive failures before sending an alert email
# This prevents alert spam for brief network hiccups
readonly FAILURE_THRESHOLD="${FAILURE_THRESHOLD:-4}"

# Time in seconds between each check
# Default: 3 seconds (be mindful of rate limiting on target servers)
readonly CHECK_INTERVAL="${CHECK_INTERVAL:-3}"

# Timeout in seconds for each HTTP request
readonly REQUEST_TIMEOUT="${REQUEST_TIMEOUT:-10}"

# -----------------------------------------------------------------------------
# RUNTIME VARIABLES
# -----------------------------------------------------------------------------

# Counter for consecutive failed checks
FailCount=0

# Flag to track if we've already sent a "down" alert
AlertSent=0

# -----------------------------------------------------------------------------
# FUNCTIONS
# -----------------------------------------------------------------------------

# Get current timestamp in ISO 8601 format for logging
# This format is unambiguous and sorts correctly
get_timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

# Get date components for log file organization
get_year() {
    date '+%Y'
}

get_month() {
    date '+%m'
}

get_date_filename() {
    date '+%Y-%m-%d'
}

# Ensure the log directory exists for the current date
# Creates: ~/logs/<Name>/YYYY/MM/
ensure_log_dir() {
    local log_dir="${HOME}/logs/${Name}/$(get_year)/$(get_month)"
    mkdir -p "$log_dir"
    echo "$log_dir"
}

# Write a log entry to the daily log file
# Arguments:
#   $1 - Status prefix ("OK" or "FAIL")
#   $2 - Message to log
write_log() {
    local status="$1"
    local message="$2"
    local log_dir
    local log_file
    
    log_dir="$(ensure_log_dir)"
    log_file="${log_dir}/$(get_date_filename).log"
    
    echo "[${status}] $(get_timestamp) - ${message}" >> "$log_file"
}

# Generate HTML email body with nice formatting
# Arguments:
#   $1 - Alert type ("DOWN" or "RECOVERED")
#   $2 - Message details
#   $3 - Timestamp
#   $4 - Additional info (e.g., failure count)
generate_html_email() {
    local alert_type="$1"
    local message="$2"
    local timestamp="$3"
    local additional_info="$4"

    # Set colors based on alert type
    local header_color="#dc3545"  # Red for DOWN
    local status_color="#dc3545"
    local status_text="DOWN"

    if [[ "$alert_type" == "RECOVERED" ]]; then
        header_color="#28a745"  # Green for RECOVERED
        status_color="#28a745"
        status_text="ONLINE"
    fi

    cat << EOF
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 600px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f5f5f5;
        }
        .container {
            background-color: #ffffff;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            overflow: hidden;
        }
        .header {
            background-color: ${header_color};
            color: white;
            padding: 30px 20px;
            text-align: center;
        }
        .header h1 {
            margin: 0;
            font-size: 24px;
            font-weight: 600;
        }
        .content {
            padding: 30px 20px;
        }
        .info-table {
            width: 100%;
            border-collapse: collapse;
            margin: 20px 0;
        }
        .info-table td {
            padding: 12px;
            border-bottom: 1px solid #e9ecef;
        }
        .info-table td:first-child {
            font-weight: 600;
            color: #495057;
            width: 40%;
        }
        .info-table td:last-child {
            color: #212529;
        }
        .status-badge {
            display: inline-block;
            padding: 6px 12px;
            border-radius: 4px;
            font-weight: 600;
            color: white;
            background-color: ${status_color};
        }
        .footer {
            padding: 20px;
            background-color: #f8f9fa;
            text-align: center;
            font-size: 14px;
            color: #6c757d;
        }
        .url {
            color: #007bff;
            text-decoration: none;
            word-break: break-all;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🔔 Website Monitor Alert</h1>
        </div>
        <div class="content">
            <p>${message}</p>
            <table class="info-table">
                <tr>
                    <td>Website</td>
                    <td><a href="${URL}" class="url">${URL}</a></td>
                </tr>
                <tr>
                    <td>Status</td>
                    <td><span class="status-badge">${status_text}</span></td>
                </tr>
                <tr>
                    <td>Timestamp</td>
                    <td>${timestamp}</td>
                </tr>
                <tr>
                    <td>${additional_info%:*}</td>
                    <td>${additional_info#*: }</td>
                </tr>
            </table>
        </div>
        <div class="footer">
            <p>This alert was generated by DownOrNot monitoring system</p>
            <p>Monitor: ${Name}</p>
        </div>
    </div>
</body>
</html>
EOF
}

# Send an email notification
# Arguments:
#   $1 - Email subject
#   $2 - Email body (plain text, optional)
#   $3 - Alert type for HTML ("DOWN" or "RECOVERED", optional)
send_notification() {
    local subject="$1"
    local body="${2:-$(get_timestamp)}"
    local alert_type="${3:-}"

    if [[ "$USE_HTML_EMAIL" -eq 1 && -n "$alert_type" ]]; then
        # Send HTML email
        local timestamp
        local additional_info
        timestamp="$(get_timestamp)"

        if [[ "$alert_type" == "DOWN" ]]; then
            additional_info="Consecutive failures: ${FailCount}"
            local html_body
            html_body=$(generate_html_email "DOWN" "Alert! Your website is not responding." "$timestamp" "$additional_info")
            echo "$html_body" | mail -s "$subject" -a "Content-Type: text/html; charset=UTF-8" "$Email"
        else
            additional_info="Total failed checks: ${FailCount}"
            local html_body
            html_body=$(generate_html_email "RECOVERED" "Good news! Your website is back up and running." "$timestamp" "$additional_info")
            echo "$html_body" | mail -s "$subject" -a "Content-Type: text/html; charset=UTF-8" "$Email"
        fi
    else
        # Send plain text email
        echo "$body" | mail -s "$subject" "$Email"
    fi
}

# Handle successful URL check
handle_success() {
    local timestamp
    timestamp="$(get_timestamp)"
    
    # Log the successful check
    echo "${timestamp} - [OK] ${URL} is up and running"
    write_log "OK" "${URL} is up and running"
    
    # Check if we need to send a recovery notification
    # Only send if we previously sent a down alert
    if [[ "$AlertSent" -eq 1 ]]; then
        echo "${timestamp} - [RECOVERY] Sending recovery notification (was down for ${FailCount} checks)"
        send_notification "[RECOVERED] ${URL} is back online" \
            "Good news! ${URL} is back up and running.\n\nRecovered at: ${timestamp}\nTotal failed checks: ${FailCount}" \
            "RECOVERED"
        AlertSent=0
    fi
    
    # Reset the failure counter
    FailCount=0
}

# Handle failed URL check
handle_failure() {
    local timestamp
    timestamp="$(get_timestamp)"
    
    # Increment the failure counter using proper arithmetic
    ((FailCount++)) || true
    
    # Log the failed check
    echo "${timestamp} - [FAIL] ${URL} IS DOWN! (Failure #${FailCount})"
    write_log "FAIL" "${URL} IS DOWN! (Failure #${FailCount})"
    
    # Send alert email only when we hit the threshold
    # This prevents alert spam for brief network hiccups
    if [[ "$FailCount" -eq "$FAILURE_THRESHOLD" && "$AlertSent" -eq 0 ]]; then
        echo "${timestamp} - [ALERT] Sending down notification after ${FAILURE_THRESHOLD} consecutive failures"
        send_notification "[DOWN] ${URL} IS DOWN!" \
            "Alert! ${URL} is not responding.\n\nDetected at: ${timestamp}\nConsecutive failures: ${FailCount}" \
            "DOWN"
        AlertSent=1
    fi
}

# Check if the URL is accessible
# Uses curl instead of wget for better exit codes and modern compatibility
# Returns:
#   0 if URL is accessible
#   non-zero if URL is not accessible
check_url() {
    # curl options:
    #   -s: Silent mode (no progress meter)
    #   -S: Show errors (even in silent mode)
    #   -f: Fail silently on HTTP errors (returns exit code 22)
    #   -o /dev/null: Discard response body
    #   -w '%{http_code}': Output only the HTTP status code
    #   --max-time: Maximum time for the operation
    #   -L: Follow redirects
    curl -sSf -o /dev/null --max-time "$REQUEST_TIMEOUT" -L "$URL" 2>/dev/null
}

# Handle graceful shutdown on SIGINT (Ctrl+C) or SIGTERM
cleanup() {
    echo ""
    echo "$(get_timestamp) - [SHUTDOWN] Monitoring stopped for ${URL}"
    write_log "INFO" "Monitoring stopped by user"
    exit 0
}

# -----------------------------------------------------------------------------
# MAIN MONITORING LOOP
# -----------------------------------------------------------------------------

# Set up signal handlers for graceful shutdown
trap cleanup SIGINT SIGTERM

# Display startup information
echo "============================================="
echo "   DownOrNot - Website Monitor"
echo "============================================="
echo "Monitoring: ${URL}"
echo "Alerts to:  ${Email}"
echo "Check interval: ${CHECK_INTERVAL} seconds"
echo "Failure threshold: ${FAILURE_THRESHOLD} consecutive failures"
echo "============================================="
echo ""
echo "$(get_timestamp) - [STARTUP] Starting monitoring..."
echo "Press Ctrl+C to stop"
echo ""

# Ensure log directory exists at startup
ensure_log_dir > /dev/null

# Write startup entry to log
write_log "INFO" "Monitoring started for ${URL}"

# Main infinite loop for continuous monitoring
while true; do
    # Perform the URL check and handle the result
    if check_url; then
        handle_success
    else
        handle_failure
    fi
    
    # Wait before the next check
    # Using sleep with the configured interval
    sleep "$CHECK_INTERVAL"
done
