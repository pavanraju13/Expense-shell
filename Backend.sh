#!/bin/bash

# Get the current user ID
ID=$(id -u)
# Create a timestamp in the format YYYY-MM-DD-HH-MM-SS
TIME_STAMP=$(date +%F-%H-%M-%S)
# Extract script name without the extension
SCRIPT_NAME=$(basename "$0" | cut -d "." -f1)
# Define the log file path
LOG_FILE="/tmp/${SCRIPT_NAME}-${TIME_STAMP}.log"

# Log the script start time
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
        echo -e "$2 ..${G}is successful${N}" | tee -a "$LOG_FILE"
    else
        echo -e "$2 ..${R}is failure${N}" | tee -a "$LOG_FILE"
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

# Disable and enable Node.js module
dnf module disable nodejs -y &>> "$LOG_FILE"
VALIDATE $? "Disable Node.js module"

dnf module enable nodejs:20 -y &>> "$LOG_FILE"
VALIDATE $? "Enable Node.js module version 20"

dnf install nodejs -y &>> "$LOG_FILE"
VALIDATE $? "Installing Node.js"

# Ensure the 'expense' user exists
id expense &>> "$LOG_FILE"
if [ $? -ne 0 ]; then
    useradd expense &>> "$LOG_FILE"
    VALIDATE $? "Creating the 'expense' user"
else
    echo "User 'expense' already exists. Skipping user creation." | tee -a "$LOG_FILE"
fi

# Create the application directory
mkdir -p /app &>> "$LOG_FILE"
VALIDATE $? "Creating the app directory"

# Download the backend code
curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip &>> "$LOG_FILE"
VALIDATE $? "Downloading the backend code"

# Unzip the backend code
cd /app &>> "$LOG_FILE"
unzip -o /tmp/backend.zip &>> "$LOG_FILE"
VALIDATE $? "Unzipping the backend code"

# Install Node.js dependencies
npm install &>> "$LOG_FILE"
VALIDATE $? "Installing Node.js dependencies"

# Copy the systemd service file for the backend
cp /home/ec2-user/Expense-shell/backend.service /etc/systemd/system/backend.service &>> "$LOG_FILE"
VALIDATE $? "Copying backend service to systemd"

# Reload systemd, start, and enable the backend service
systemctl daemon-reload &>> "$LOG_FILE"
VALIDATE $? "Reloading systemd"

systemctl start backend &>> "$LOG_FILE"
VALIDATE $? "Starting the backend service"

systemctl enable backend &>> "$LOG_FILE"
VALIDATE $? "Enabling the backend service"

# Install MySQL if not already installed
dnf list installed mysql &>> "$LOG_FILE"
if [ $? -ne 0 ]; then
    dnf install mysql -y &>> "$LOG_FILE"
    VALIDATE $? "Installing MySQL"
else
    echo "MySQL is already installed." | tee -a "$LOG_FILE"
fi

# Load the schema into MySQL
mysql -h 172.31.85.105 -uroot -p"${mysql_root_password}" < /app/schema/backend.sql &>> "$LOG_FILE"
VALIDATE $? "Loading the database schema"

# Restart the backend service
systemctl restart backend &>> "$LOG_FILE"
VALIDATE $? "Restarting the backend service"

# Completion message
echo -e "${G}Script completed successfully!${N}" | tee -a "$LOG_FILE"
