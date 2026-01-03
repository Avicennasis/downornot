#!/bin/bash
# =============================================================================
# DownOrNot - Uptime Calculator
# =============================================================================
#
# Description:
#   Companion script to the DownOrNot monitoring system that analyzes log
#   files and calculates the uptime percentage for a monitored website.
#
# Usage:
#   ./uptime.sh              # Interactive mode - prompts for project name
#   ./uptime.sh <project>    # Direct mode - specify project name as argument
#
# How it works:
#   1. Reads all log files for the specified project from ~/logs/<project>/
#   2. Counts successful checks (lines containing "[OK]")
#   3. Counts failed checks (lines containing "[FAIL]")
#   4. Calculates and displays the uptime percentage
#
# Output format:
#   Displays a summary table with total checks, successes, failures,
#   and the calculated uptime percentage.
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
readonly LOGS_BASE_DIR="${HOME}/logs"

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

# Display usage information
show_usage() {
    echo "Usage: $0 [project_name]"
    echo ""
    echo "If project_name is not provided, you will be prompted to enter it."
    echo ""
    echo "Available projects:"
    list_projects
}

# List all available projects (directories in ~/logs/)
list_projects() {
    if [[ -d "$LOGS_BASE_DIR" ]]; then
        local projects
        projects=$(find "$LOGS_BASE_DIR" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; 2>/dev/null | sort)
        if [[ -n "$projects" ]]; then
            echo "$projects" | sed 's/^/  - /'
        else
            echo "  (no projects found)"
        fi
    else
        echo "  (no logs directory found)"
    fi
}

# Count occurrences of a pattern in log files
# Arguments:
#   $1 - Log directory path
#   $2 - Pattern to search for (grep pattern)
# Returns:
#   Count of matching lines (prints to stdout)
count_log_entries() {
    local log_dir="$1"
    local pattern="$2"
    
    # Use grep to count lines matching the pattern
    # -r: Recursive search
    # -h: Suppress filename prefix
    # grep returns exit code 1 if no matches, so we use || true
    grep -rh "$pattern" "$log_dir" 2>/dev/null | wc -l || echo "0"
}

# Calculate and display uptime statistics
# Arguments:
#   $1 - Project name
calculate_uptime() {
    local project="$1"
    local log_dir="${LOGS_BASE_DIR}/${project}"
    
    # Validate that the project log directory exists
    if [[ ! -d "$log_dir" ]]; then
        error_exit "No logs found for project '${project}'. Directory not found: ${log_dir}"
    fi
    
    # Count successful and failed checks from log files
    # OK entries indicate successful checks
    # FAIL entries indicate failed checks
    local success_count
    local fail_count
    
    # Count lines that contain [OK] for successful checks
    success_count=$(count_log_entries "$log_dir" '\[OK\]')
    
    # Count lines that contain [FAIL] for failed checks
    fail_count=$(count_log_entries "$log_dir" '\[FAIL\]')
    
    # Calculate total checks
    local total_count
    total_count=$((success_count + fail_count))
    
    # Handle edge case: no data found
    if [[ "$total_count" -eq 0 ]]; then
        echo ""
        echo "No check data found for project '${project}'."
        echo "The logs may be empty or contain only startup/shutdown entries."
        exit 0
    fi
    
    # Calculate uptime percentage using awk for floating-point arithmetic
    # This is more portable than bc and handles precision well
    local uptime_percent
    uptime_percent=$(awk "BEGIN {printf \"%.4f\", ($success_count / $total_count) * 100}")
    
    # Display the results in a formatted table
    echo ""
    echo "============================================="
    echo "   Uptime Report: ${project}"
    echo "============================================="
    echo ""
    printf "  %-20s %s\n" "Total Checks:" "$total_count"
    printf "  %-20s %s\n" "Successful Checks:" "$success_count"
    printf "  %-20s %s\n" "Failed Checks:" "$fail_count"
    echo "  -------------------------------------------"
    printf "  %-20s %s%%\n" "Uptime Percentage:" "$uptime_percent"
    echo ""
    echo "============================================="
    
    # Provide context for uptime levels
    # Industry standards for comparison
    local uptime_num
    uptime_num=$(awk "BEGIN {printf \"%.2f\", $uptime_percent}")
    
    echo ""
    if awk "BEGIN {exit !($uptime_percent >= 99.99)}"; then
        echo "Status: EXCELLENT - Four nines availability (99.99%+)"
    elif awk "BEGIN {exit !($uptime_percent >= 99.9)}"; then
        echo "Status: GREAT - Three nines availability (99.9%+)"
    elif awk "BEGIN {exit !($uptime_percent >= 99.0)}"; then
        echo "Status: GOOD - Two nines availability (99%+)"
    elif awk "BEGIN {exit !($uptime_percent >= 95.0)}"; then
        echo "Status: FAIR - Below industry standard (95%+)"
    else
        echo "Status: POOR - Significant downtime detected"
    fi
    echo ""
}

# -----------------------------------------------------------------------------
# MAIN SCRIPT
# -----------------------------------------------------------------------------

# Get project name from command line argument or prompt user
project_name=""

if [[ $# -ge 1 ]]; then
    # Check for help flag
    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        show_usage
        exit 0
    fi
    project_name="$1"
else
    # Interactive mode - prompt for project name
    echo "============================================="
    echo "   DownOrNot - Uptime Calculator"
    echo "============================================="
    echo ""
    echo "Available projects:"
    list_projects
    echo ""
    echo -n "Enter project name: "
    read -r project_name
fi

# Validate project name is provided
if [[ -z "$project_name" ]]; then
    error_exit "Project name cannot be empty"
fi

# Validate project name contains only safe characters
if [[ ! "$project_name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    error_exit "Invalid project name. Use only letters, numbers, underscores, and hyphens"
fi

# Calculate and display uptime statistics
calculate_uptime "$project_name"
