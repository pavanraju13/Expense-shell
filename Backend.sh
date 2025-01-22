#!/bin/bash

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

VALIDATE(){
    if [ $1 -eq 0 ]
    then
    echo -e "${G} ..$2 is successfull ${N}" &>>"$LOG_FILE"
    else
    echo -e "${R}..$2 is failure ${N}" &>>"$LOG_FILE"
    fi
}

if [ $id -eq 0 ]
then
echo -e "${G} you are a super user${N}"
else
echo -e "${R} you require root permissions${N}"
fi
