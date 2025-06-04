#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$PWD

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

echo "Please enter root password"
read -s MySQL_Root_Password
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

dnf install maven -y &>>$LOG_FILE
VALIDATE $? "Installing maven"

id roboshop
if [ $? -ne 0 ]
then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "System User Roboshop created"
else
    echo -e "System user Roboshop is already created... $Y Skipping $N"
fi

mkdir /app &>>$LOG_FILE
VALIDATE $? "App directory created"

curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip 
VALIDATE $? "Shipping code downloaded"

rm -rf /app/*
cd /app 
unzip /tmp/shipping.zip &>>$LOG_FILE
VALIDATE $? "Unzipping Shipping code"

mvn clean package &>>$LOG_FILE
VALIDATE $? "Packaging mvn application"

mv target/shipping-1.0.jar shipping.jar &>>$LOG_FILE
VALIDATE $? "moving remaining jar file"

cp $SCRIPT_DIR/shipping.service etc/systemd/system/shipping.service

systemctl daemon-reload &>>$LOG_FILE
systemctl enable shipping &>>$LOG_FILE
systemctl start shipping &>>$LOG_FILE
VALIDATE $? "Start Shipping"

dnf install mysql -y &>>$LOG_FILE
VALIDATE $? "Installing MySQL"

mysql -h mysql.vishnuv8.fun -u root -p$MySQL_Root_Password -e 'use cities' &>>$LOG_FILE
if [ $? -ne 0 ]
then
    mysql -h mysql.vishnuv8.fun -uroot -p$MySQL_Root_Password < /app/db/schema.sql &>>$LOG_FILE
    mysql -h mysql.vishnuv8.fun -uroot -p$MySQL_Root_Password < /app/db/app-user.sql &>>$LOG_FILE
    mysql -h mysql.vishnuv8.fun -uroot -p$MySQL_Root_Password < /app/db/master-data.sql &>>$LOG_FILE
    VALIDATE $? "Loading Data in MySQL"
else
    echo "Data is already loaded in MySQL"
fi

systemctl restart shipping &>>$LOG_FILE
VALIDATE $? "Restarting Shipping"