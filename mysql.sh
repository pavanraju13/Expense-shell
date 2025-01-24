#!/bin/bash

ID=$(id -u) # Get the current user ID
TIME_STAMP=$(date +%F-%H-%M-%S) # Create a timestamp in the format YYYY-MM-DD-HH-MM-SS
SCRIPT_NAME=$(basename "$0" | cut -d "." -f1) # Extract script name without the extension
LOG_FILE="/tmp/${SCRIPT_NAME}-${TIME_STAMP}.log" # Define the log file path

echo "Script started executing at timestamp: $TIME_STAMP" | tee -a "$LOG_FILE"

# Colors for output
G="\e[32m" # Green for success
R="\e[31m" # Red for failure
B="\e[34m" # Blue for informational
N="\e[0m"  # Reset to default

# Prompt for MySQL root password securely
echo "MYSQL PASSWORD:"
read -s mysql_root_password

# Function to validate command execution
VALIDATE() {
    if [ $1 -eq 0 ]; then
        echo -e "$2... ${G}success${N}" | tee -a "$LOG_FILE"
    else
        echo -e "$2... ${R}failure${N}" | tee -a "$LOG_FILE"
        exit 1
    fi
}

# Ensure the script is run as root
if [ $ID -ne 0 ]; then
    echo -e "${R}You must run this script as root or using sudo.${N}" | tee -a "$LOG_FILE"
    exit 1
fi

# Install MySQL Server
dnf install mysql-server -y &>>"$LOG_FILE"
VALIDATE $? "Installing MySQL server"

# Enable MySQL service to start at boot
systemctl enable mysqld &>>"$LOG_FILE"
VALIDATE $? "Enabling MySQL service"

# Start MySQL service
systemctl start mysqld &>>"$LOG_FILE"
VALIDATE $? "Starting MySQL service"

# Configure MySQL root password
mysql -h 172.31.25.0 -uroot -p"${mysql_root_password}" -e 'SHOW DATABASES;' &>>"$LOG_FILE"
if [ $? -ne 0 ]; then
    echo "Configuring MySQL root password..." | tee -a "$LOG_FILE"
    mysql_secure_installation --set-root-pass="${mysql_root_password}" &>>"$LOG_FILE"
    VALIDATE $? "Setting up MySQL root password"
else
    echo -e "${B}MySQL root password is already set. Skipping configuration.${N}" | tee -a "$LOG_FILE"
fi

echo -e "${G}MySQL setup completed successfully!${N}" | tee -a "$LOG_FILE"
echo "Thank you!" | tee -a "$LOG_FILE"
