#!/bin/bash
set -e

apt update -y
apt install -y openjdk-17-jdk maven git awscli

cd /opt
git clone https://github.com/mukitshaikh/student-registration-aws.git
cd /opt/student-registration-aws/backend

DB_PASSWORD=$(aws ssm get-parameter \
  --name "/studentapp/db/password" \
  --with-decryption \
  --region us-east-1 \
  --query "Parameter.Value" \
  --output text)

cat > src/main/resources/application.properties <<APP
server.port=8080

spring.datasource.url=jdbc:mysql://studentapp-db.ckje4akakntr.us-east-1.rds.amazonaws.com:3306/student_db
spring.datasource.username=admin
spring.datasource.password=\${DB_PASSWORD}

spring.datasource.driver-class-name=com.mysql.cj.jdbc.Driver

spring.jpa.hibernate.ddl-auto=update
spring.jpa.show-sql=true
APP

mvn clean package -DskipTests

mkdir -p /opt/studentapp
cp target/*.jar /opt/studentapp/studentapp.jar

cat > /etc/systemd/system/studentapp.service <<SERVICE
[Unit]
Description=Student Registration Spring Boot Application
After=network.target

[Service]
User=root
WorkingDirectory=/opt/studentapp
ExecStart=/usr/bin/java -jar /opt/studentapp/studentapp.jar
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
SERVICE

systemctl daemon-reload
systemctl enable studentapp
systemctl start studentapp
