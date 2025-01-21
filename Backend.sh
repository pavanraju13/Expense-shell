#!/bin/bash

# Variables
ID=$(id -u) # Get the current user ID
TIME_STAMP=$(date +%F-%H-%M-%S) # Create a timestamp in the format YYYY-MM-DD-HH-MM-SS
SCRIPT_NAME=$(basename "$0" | cut -d "." -f1) # Extract script name without the extension
LOG_FILE="/tmp/${SCRIPT_NAME}-${TIME_STAMP}.log" # Define the log file path

# Colors for output
G="\e[32m" # Green for success
R="\e[31m" # Red for failure
B="\e[34m" # Blue for informational
N="\e[0m"  # Reset to default

echo " MYSQL PASSWORD :"
read -s mysql_root_password

echo "Script started executing at timestamp: $TIME_STAMP" | tee -a "$LOG_FILE"

# Function to validate command execution
VALIDATE() {
    if [ $1 -eq 0 ]; then
        echo -e "$2.. ${G}success${N}" | tee -a "$LOG_FILE" # Green for success
    else
        echo -e "$2.. ${R}failure${N}" | tee -a "$LOG_FILE" # Red for failure
        
    fi
}

# Ensure the script is run as root
if [ $ID -ne 0 ]; then
    echo -e "${R}You must run this script as root or using sudo.${N}" | tee -a "$LOG_FILE"
    exit 1
fi

# Step 1: Disable existing Node.js module
dnf module disable nodejs -y &>>"$LOG_FILE"
VALIDATE $? "Disabling existing Node.js module"

# Step 2: Enable Node.js version 20
dnf module enable nodejs:20 -y &>>"$LOG_FILE"
VALIDATE $? "Enabling Node.js version 20"

# Step 3: Install Node.js
dnf install nodejs -y &>>"$LOG_FILE"
VALIDATE $? "Installing Node.js"

# Step 4: Create user for the backend service
useradd -r expense &>>"$LOG_FILE"
VALIDATE $? "Creating user 'expense'"

# Step 5: Create application directory
mkdir -p /app &>>"$LOG_FILE"
VALIDATE $? "Creating application directory '/app'"

# Step 6: Download the backend application
curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip &>>"$LOG_FILE"
VALIDATE $? "Downloading the backend application"

# Step 7: Extract the backend application
dnf install unzip -y &>>"$LOG_FILE"
VALIDATE $? "Installing 'unzip' utility"
unzip -o /tmp/backend.zip -d /app &>>"$LOG_FILE"
VALIDATE $? "Extracting the backend application"

# Step 8: Install application dependencies
cd /app || exit
npm install &>>"$LOG_FILE"
VALIDATE $? "Installing application dependencies"

# Step 9: Create systemd service file for the backend
cat <<EOF >/etc/systemd/system/backend.service
[Unit]
Description=Backend Service
After=network.target

[Service]
User=expense
Environment=DB_HOST="172.31.85.105"
ExecStart=/bin/node /app/index.js
Restart=always
SyslogIdentifier=backend

[Install]
WantedBy=multi-user.target
EOF
VALIDATE $? "Creating systemd service for backend"

# Step 10: Reload systemd and start the backend service
systemctl daemon-reload &>>"$LOG_FILE"
VALIDATE $? "Reloading systemd"
systemctl start backend &>>"$LOG_FILE"
VALIDATE $? "Starting backend service"
systemctl enable backend &>>"$LOG_FILE"
VALIDATE $? "Enabling backend service"

# Step 11: Install MySQL client
dnf install mysql -y &>>"$LOG_FILE"
VALIDATE $? "Installing MySQL client"


mysql -h 172.31.85.105  -uroot -p${mysql_root_password} < /app/schema/backend.sql &>>"$LOG_FILE"
VALIDATE $? "Setting up MySQL root password"


# Step 13: Restart backend service after configuration
systemctl restart backend &>>"$LOG_FILE"
VALIDATE $? "Restarting backend service"

# Final success message
echo -e "${G}Script execution completed successfully!${N}" | tee -a "$LOG_FILE"
echo "Log file: $LOG_FILE"
