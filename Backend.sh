#!/bin/bash

ID=$(id -u) # Get the current user ID
TIME_STAMP=$(date +%F-%H-%M-%S) # Create a timestamp in the format YYYY-MM-DD-HH-MM-SS
SCRIPT_NAME=$(basename "$0" | cut -d "." -f1) # Extract script name without the extension
LOG_FILE="/tmp/${SCRIPT_NAME}-${TIME_STAMP}.log" # Define the log file path

echo "Script started executing at timestamp: $TIME_STAMP" | tee -a "$LOG_FILE"

# Colors
G="\e[32m" # Green for success
R="\e[31m" # Red for failure
B="\e[34m" # Blue for informational
N="\e[0m"  # Reset to default

# Function to validate command execution
VALIDATE() {
    if [ $1 -eq 0 ]; then
        echo -e "${G}..$2 is successful${N}" | tee -a "$LOG_FILE"
    else
        echo -e "${R}..$2 is failure${N}" | tee -a "$LOG_FILE"
        exit 1
    fi
}

# Ensure the script is run as root
if [ $ID -eq 0 ]; then
    echo -e "${G}You are a superuser.${N}" | tee -a "$LOG_FILE"
else
    echo -e "${R}You require root permissions to execute this script.${N}" | tee -a "$LOG_FILE"
    exit 1
fi

# Example commands to validate
# dnf install -y httpd
# VALIDATE $? "Installing Apache HTTP Server"

