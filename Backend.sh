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


# Function to validate command execution
VALIDATE() {
    if [ $1 -eq 0 ]; then
        echo -e "$2.. ${G}...success${N}" | tee -a "$LOG_FILE" # Green for success
    else
        echo -e "$2.. ${R}...failure${N}" | tee -a "$LOG_FILE" # Red for failure
        
    fi
}

# Ensure the script is run as root
if [ $ID -ne 0 ]; then
    echo -e "${R}You must run this script as root or using sudo.${N}" | tee -a "$LOG_FILE"
    exit 1
fi

dnf module disable nodejs -y | tee -a "$LOG_FILE"
VALIDATE $? "disable nodejs"

dnf module enable nodejs:20 -y | tee -a "$LOG_FILE"
VALIDATE $? "enabling nodejs:20"

dnf install nodejs -y | tee -a "$LOG_FILE"
VALIDATE $? "Install nodejs"

useradd expense | tee -a "$LOG_FILE"
VALIDATE $? "creating user account to start the service"

mkdir /app
VALIDATE $? "creating the APP directory"

curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip
VALIDATE $? "downloading the zip file and storing in the temporary directory as backend folder"

cd /app
VALIDATE $? "change directory to app"

dnf install unzip -y | tee -a "$LOG_FILE"
unzip /tmp/backend.zip | tee -a "$LOG_FILE"
VALIDATE $? "unzip the file"

npm install | tee -a "$LOG_FILE"
VALIDATE $? "install the dependencies"

vim /etc/systemd/system/backend.service
[Unit]
Description = Backend Service

[Service]
User=expense
Environment=DB_HOST="172.31.85.105"
ExecStart=/bin/node /app/index.js
SyslogIdentifier=backend

[Install]
WantedBy=multi-user.target

VALIDATE $? "setup a new service in systemd so systemctl can manage this service"

systemctl daemon-reload | tee -a "$LOG_FILE"

VALIDATE $? "to reload the systemd file"

systemctl start backend | tee -a "$LOG_FILE"

VALIDATE $? "to start the backend service"

systemctl enable backend | tee -a "$LOG_FILE"

VALIDATE $? " to enable the backend service"

dnf install mysql -y | tee -a "$LOG_FILE"

VALIDATE $? "TO load schema we require mysql client to install"

#mysql_secure_installation --set-root-pass ExpenseApp@1 | tee -a "$LOG_FILE"
#VALIDATE $? "Setting username and Password"

#below command is used for idempotency

mysql -h 172.31.85.105 -uroot -pExpenseApp@1 -e 'SHOW DATABASES;'| tee -a "$LOG_FILE"

if [ $? -ne 0 ]
then
mysql_secure_installation --set-root-pass ExpenseApp@1 

VALIDATE $? "Root password setup"

else 
echo -e "mysql password is already set $R ..Skipping $N"

fi

VALIDATE $? "to load the schema from backend.sql to database server"

systemctl restart backend | tee -a "$LOG_FILE"

VALIDATE $? "restart the backend service"

echo -e "${G} Completed the script successfully!${N}" | tee -a "$LOG_FILE"


echo "Thank you"


