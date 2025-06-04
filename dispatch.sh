#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"

mkdir -p $LOGS_FOLDER
echo "Script started executing at: $(date)" | tee -a $LOG_FILE

# check the user has root priveleges or not
if [ $USERID -ne 0 ]
then
    echo -e "$R ERROR:: Please run this script with root access $N" | tee -a $LOG_FILE
    exit 1 #give other than 0 upto 127
else
    echo "You are running with root access" | tee -a $LOG_FILE
fi

echo "Please enter user password"
read -s 
# validate functions takes input as exit status, what command they tried to install
VALIDATE(){
    if [ $1 -eq 0 ]
    then
        echo -e "$2 is ... $G SUCCESS $N" | tee -a $LOG_FILE
    else
        echo -e "$2 is ... $R FAILURE $N" | tee -a $LOG_FILE
        exit 1
    fi
}

dnf install golang -y

id roboshop
if [ $? -ne 0 ]
then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "System User Roboshop created"
else
    echo -e "System user Roboshop is already created... $Y Skipping $N"
fi

mkdir /app
VALIDATE $? "Created App Dir"

curl -L -o /tmp/dispatch.zip https://roboshop-artifacts.s3.amazonaws.com/dispatch-v3.zip &>>$LOG_FILE
cd /app &>>$LOG_FILE
unzip /tmp/dispatch.zip &>>$LOG_FILE
VALIDATE $? "Unzipping Dispatch code"


cd /app &>>$LOG_FILE
go mod init dispatch &>>$LOG_FILE

go get &>>$LOG_FILE

go build &>>$LOG_FILE

cp $SCRIPT_DIR/dispatch.service /etc/systemd/system/dispatch.service &>>$LOG_FILE
VALIDATE $? "moving dispatch file"

systemctl daemon-reload &>>$LOG_FILE
systemctl enable shipping &>>$LOG_FILE
systemctl start shipping &>>$LOG_FILE
VALIDATE $? "Start Shipping"