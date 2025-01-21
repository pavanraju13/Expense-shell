#!/bin/bash

ID=$( id -u )
TIME_STAMP=$( date +%F-%H-%M-%S )
SCRIPTNAME=$( basename "$0" | cut -d "." f1 )
LOG_FILE="\tmp\${SCRIPTNAME}+${TIME_STAMP}}.log"

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
        exit 1
    fi
}

# Ensure the script is run as root
if [ $ID -ne 0 ]; then
    echo -e "${R}You must run this script as root or using sudo.${N}" | tee -a "$LOG_FILE"
    exit 1
fi
dnf install mysql-server -y &>>$LOGFILE

VALIDATE $? "Installing mysql"
systemctl enable mysqld
VALIDATE $? "Enabling mysql"

systemctl start mysqld &>>$LOGFILE

VALIDATE $? "STARTING MYSQL"

mysql_secure_installation --set-root-pass ExpenseApp@1 &>>$LOGFILE

validate $? "Setting username and Password"

