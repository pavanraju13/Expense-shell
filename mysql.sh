#!/bin/bash

ID=$(id -u) # Get the current user ID
TIME_STAMP=$(date +%F-%H-%M-%S) # Create a timestamp in the format YYYY-MM-DD-HH-MM-SS
SCRIPT_NAME=$(basename "$0" | cut -d "." -f1) # Extract script name without the extension
LOG_FILE="/tmp/${SCRIPT_NAME}-${TIME_STAMP}.log" # Define the log file path

echo "Script started executing at timestamp: $TIME_STAMP"

#colours

G="\e[32m" # Green for success
R="\e[31m" # Red for failure
B="\e[34m" # Blue for informational
N="\e[0m"  # Reset to default

echo " MYSQL PASSWORD :"
read -s "mysql_root_password :"


# Function to validate command execution
VALIDATE() {
    if [ $1 -eq 0 ]; then
        echo -e "$2.. ${G}...success${N}" | tee -a "$LOG_FILE" # Green for success
    else
        echo -e "$2.. ${R}...failure${N}" | tee -a "$LOG_FILE" # Red for failure
        exit 1
    fi
}

# Ensure the script is run as root
if [ $ID -ne 0 ]; then
    echo -e "${R}You must run this script as root or using sudo.${N}" | tee -a "$LOG_FILE"
    exit 1
fi
dnf install mysql-server -y | tee -a "$LOG_FILE"

VALIDATE $? "Installing mysql"
systemctl enable mysqld
VALIDATE $? "Enabling mysql"

systemctl start mysqld | tee -a "$LOG_FILE"

VALIDATE $? "STARTING MYSQL"

# Step 12: Configure MySQL root password
mysql -h 172.31.85.105 -uroot -p${mysql_root_password} -e 'SHOW DATABASES;' &>>"$LOG_FILE"
if [ $? -ne 0 ]; then
    mysql_secure_installation --set-root-pass${mysql_root_password} &>>"$LOG_FILE"
    VALIDATE $? "Setting up MySQL root password"
else
    echo -e "${B}MySQL root password is already set. Skipping.${N}" | tee -a "$LOG_FILE"
fi




echo "Thank you"


