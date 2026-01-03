#!/bin/bash
# =============================================================================
# DownOrNot - Setup Script
# =============================================================================
# 
# Description:
#   Interactive setup script that creates a customized website monitoring
#   script. It prompts the user for configuration details and generates
#   a standalone monitoring script by combining user settings with the
#   template.sh file.
#
# Usage:
#   ./setup.sh
#
# The script will prompt for:
#   1. Process name - A unique identifier for this monitoring job
#   2. URL - The website URL to monitor
#   3. Email - Email address(es) for alert notifications
#
# Output:
#   Creates a file named "<process_name>.generated.sh" that can be run
#   directly or scheduled via cron.
#
# Author: Léon "Avic" Simmons (@Avicennasis)
# License: MIT
# Repository: https://github.com/Avicennasis/downornot
# =============================================================================

# -----------------------------------------------------------------------------
# Enable strict mode for better error handling:
#   -e: Exit immediately if any command exits with a non-zero status
#   -u: Treat unset variables as an error
#   -o pipefail: Return the exit status of the last command in a pipeline
#                that returned a non-zero status
# -----------------------------------------------------------------------------
set -euo pipefail

# -----------------------------------------------------------------------------
# CONSTANTS
# -----------------------------------------------------------------------------
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly TEMPLATE_FILE="${SCRIPT_DIR}/template.sh"

# -----------------------------------------------------------------------------
# FUNCTIONS
# -----------------------------------------------------------------------------

# Display an error message and exit
# Arguments:
#   $1 - Error message to display
error_exit() {
    echo "ERROR: $1" >&2
    exit 1
}

# Validate that a URL looks reasonable (basic check)
# Arguments:
#   $1 - URL to validate
# Returns:
#   0 if valid, 1 if invalid
validate_url() {
    local url="$1"
    # Check for basic URL pattern (http:// or https://)
    if [[ "$url" =~ ^https?:// ]]; then
        return 0
    else
        return 1
    fi
}

# Validate that an email address looks reasonable (basic check)
# Arguments:
#   $1 - Email address(es) to validate
# Returns:
#   0 if valid, 1 if invalid
validate_email() {
    local email="$1"
    # Basic email pattern check (contains @ and .)
    if [[ "$email" =~ @.*\. ]]; then
        return 0
    else
        return 1
    fi
}

# Prompt user for input with a message
# Arguments:
#   $1 - Prompt message
#   $2 - Variable name to store result
prompt_input() {
    local prompt_msg="$1"
    local var_name="$2"
    local input=""
    
    echo -n "$prompt_msg"
    read -r input
    
    # Use indirect variable assignment
    printf -v "$var_name" '%s' "$input"
}

# -----------------------------------------------------------------------------
# MAIN SCRIPT
# -----------------------------------------------------------------------------

echo "============================================="
echo "   DownOrNot - Website Monitor Setup"
echo "============================================="
echo ""

# Check that template file exists
if [[ ! -f "$TEMPLATE_FILE" ]]; then
    error_exit "Template file not found: $TEMPLATE_FILE"
fi

# Prompt for process name
# This will be used as the identifier for logs and the output filename
prompt_input "Enter a name for this monitoring process: " name

# Validate process name is not empty and contains only safe characters
if [[ -z "$name" ]]; then
    error_exit "Process name cannot be empty"
fi

if [[ ! "$name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    error_exit "Process name can only contain letters, numbers, underscores, and hyphens"
fi

# Prompt for URL to monitor
prompt_input "Enter the URL to monitor (e.g., https://example.com): " url

# Validate URL format
if ! validate_url "$url"; then
    error_exit "Invalid URL format. URL must start with http:// or https://"
fi

# Prompt for notification email
prompt_input "Enter email address(es) for alerts (comma-separated for multiple): " email

# Validate email format
if ! validate_email "$email"; then
    error_exit "Invalid email format. Please enter a valid email address"
fi

# Generate the output filename
filename="${name}.generated.sh"
output_path="${SCRIPT_DIR}/${filename}"

# Remove existing file if it exists
# This ensures we start fresh with each setup
if [[ -f "$output_path" ]]; then
    echo "Removing existing file: $filename"
    rm "$output_path"
fi

# Create the generated monitoring script
# First, write the shebang and configuration variables
cat > "$output_path" << EOF
#!/bin/bash
# =============================================================================
# DownOrNot - Generated Monitoring Script
# =============================================================================
# 
# Auto-generated by setup.sh on $(date '+%Y-%m-%d %H:%M:%S')
#
# Configuration:
#   Process Name: ${name}
#   URL: ${url}
#   Email: ${email}
#
# =============================================================================

# Configuration variables (set by setup.sh)
Name="${name}"
URL="${url}"
Email="${email}"

EOF

# Append the template script content
cat "$TEMPLATE_FILE" >> "$output_path"

# Make the generated script executable
chmod 755 "$output_path"

# Display success message with next steps
echo ""
echo "============================================="
echo "   Setup Complete!"
echo "============================================="
echo ""
echo "Generated script: $filename"
echo ""
echo "To start monitoring, run:"
echo "  ./${filename}"
echo ""
echo "To run as a background process:"
echo "  nohup ./${filename} &"
echo ""
echo "To add to cron (runs on system startup):"
echo "  @reboot /path/to/${filename}"
echo ""
echo "Logs will be stored in: ~/logs/${name}/"
echo "============================================="
