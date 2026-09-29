# Student Registration Application — AWS Multi-Tier Deployment

A full-stack **Student Registration Application** built with a **React frontend**, **Spring Boot backend**, and **MySQL database**, deployed on **Amazon Web Services (AWS)** using a highly available multi-tier architecture.

The application uses private frontend, backend, and database subnets across two Availability Zones, Application Load Balancers, Auto Scaling Groups, Amazon RDS, NAT Gateway, IAM, and AWS Systems Manager Parameter Store.

---

## Table of Contents

- [Project Overview](#project-overview)
- [Features](#features)
- [Technology Stack](#technology-stack)
- [Repository Structure](#repository-structure)
- [Application Architecture](#application-architecture)
- [AWS Architecture](#aws-architecture)
- [VPC and Networking](#vpc-and-networking)
- [Subnets](#subnets)
- [Route Tables](#route-tables)
- [Internet Gateway](#internet-gateway)
- [NAT Gateway](#nat-gateway)
- [Security Groups](#security-groups)
- [Frontend Tier](#frontend-tier)
- [Backend Tier](#backend-tier)
- [Database Tier](#database-tier)
- [Load Balancers](#load-balancers)
- [Target Groups](#target-groups)
- [Auto Scaling](#auto-scaling)
- [AWS Systems Manager Parameter Store](#aws-systems-manager-parameter-store)
- [IAM](#iam)
- [API Endpoints](#api-endpoints)
- [Frontend Deployment](#frontend-deployment)
- [Backend Deployment](#backend-deployment)
- [Application Request Flow](#application-request-flow)
- [Security Architecture](#security-architecture)
- [Testing](#testing)
- [Local Development](#local-development)
- [AWS Deployment Scripts](#aws-deployment-scripts)
- [Future Improvements](#future-improvements)
- [Author](#author)

---

# Project Overview

This project demonstrates the deployment of a full-stack Student Registration Application on AWS.

The system consists of three main application layers:

1. **Frontend Layer**
   - React
   - Vite
   - Nginx

2. **Backend Layer**
   - Java
   - Spring Boot
   - Maven
   - REST API
   - Spring Data JPA

3. **Database Layer**
   - Amazon RDS
   - MySQL

The infrastructure is designed so that only the **public Application Load Balancer** is directly accessible from the Internet.

Frontend EC2 instances, backend EC2 instances, the internal backend load balancer, and the RDS database remain inside private subnets.

---

# Features

The application supports:

- Registering students
- Viewing registered students
- Deleting students
- REST API communication
- Persistent MySQL storage
- Load-balanced frontend servers
- Load-balanced backend servers
- Automatic EC2 instance management through Auto Scaling
- Multi-Availability-Zone application architecture
- Private database networking
- Secure database password retrieval using AWS Systems Manager Parameter Store

---

# Technology Stack

## Frontend

- React
- JavaScript
- Vite
- HTML
- CSS
- Node.js
- npm
- Nginx

## Backend

- Java
- Spring Boot
- Maven
- Spring Data JPA
- REST API

## Database

- MySQL
- Amazon RDS

## AWS

- Amazon VPC
- Amazon EC2
- Application Load Balancer
- EC2 Auto Scaling
- Amazon RDS
- Internet Gateway
- NAT Gateway
- Elastic IP
- Security Groups
- IAM
- AWS Systems Manager Parameter Store
- Launch Templates
- Target Groups

---

# Repository Structure

```text
student-registration-aws/
│
├── frontend/
│   ├── src/
│   ├── public/
│   ├── package.json
│   ├── vite.config.js
│   └── ...
│
├── backend/
│   ├── src/
│   ├── pom.xml
│   ├── mvnw
│   ├── mvnw.cmd
│   └── ...
│
├── aws/
│   ├── frontend-user-data.sh
│   └── backend-user-data.sh
│
├── .gitignore
└── README.md
```

The repository contains the complete frontend and backend source code together with the EC2 bootstrap scripts used for AWS deployment.

---

# Application Architecture

```text
                    INTERNET
                        |
                        |
                        v
             +----------------------+
             |   Public Frontend    |
             | Application Load     |
             |      Balancer        |
             |      HTTP :80        |
             +----------+-----------+
                        |
              +---------+---------+
              |                   |
              v                   v
       +-------------+     +-------------+
       | Frontend    |     | Frontend    |
       | EC2         |     | EC2         |
       | React/Nginx |     | React/Nginx |
       | AZ-1        |     | AZ-2        |
       +------+------+     +------+------+
              |                   |
              +---------+---------+
                        |
                     /api
                        |
                        v
             +----------------------+
             | Internal Backend     |
             | Application Load     |
             | Balancer :8080       |
             +----------+-----------+
                        |
              +---------+---------+
              |                   |
              v                   v
       +-------------+     +-------------+
       | Backend EC2 |     | Backend EC2 |
       | Spring Boot |     | Spring Boot |
       | AZ-1        |     | AZ-2        |
       | Port 8080   |     | Port 8080   |
       +------+------+     +------+------+
              |                   |
              +---------+---------+
                        |
                        v
                +---------------+
                | Amazon RDS    |
                | MySQL         |
                | Port 3306     |
                | student_db    |
                +---------------+
```

---

# AWS Architecture

AWS Region:

```text
us-east-1
```

VPC:

```text
Name: studentapp-vpc
CIDR: 10.0.0.0/16
```

The architecture uses **8 subnets across two Availability Zones**.

The subnet groups are:

- 2 Public Subnets
- 2 Frontend Private Subnets
- 2 Backend Private Subnets
- 2 Database Private Subnets

---

# VPC and Networking

## VPC

```text
Name: studentapp-vpc
CIDR: 10.0.0.0/16
```

The VPC provides network isolation for the entire application infrastructure.

---

# Subnets

## Availability Zone — us-east-1a

| Subnet | CIDR | Purpose |
|---|---|---|
| public-subnet-1 | 10.0.1.0/24 | Public ALB / NAT |
| frontend-private-1 | 10.0.3.0/24 | Frontend EC2 |
| backend-private-1 | 10.0.5.0/24 | Backend EC2 |
| database-private-1 | 10.0.7.0/24 | Amazon RDS |

## Availability Zone — us-east-1b

| Subnet | CIDR | Purpose |
|---|---|---|
| public-subnet-2 | 10.0.2.0/24 | Public ALB |
| frontend-private-2 | 10.0.4.0/24 | Frontend EC2 |
| backend-private-2 | 10.0.6.0/24 | Backend EC2 |
| database-private-2 | 10.0.8.0/24 | Amazon RDS |

---

# Route Tables

Three route-table groups are used.

## Public Route Table

```text
Name: studentapp-public-rt
```

Associated with:

```text
public-subnet-1
public-subnet-2
```

Routes:

```text
10.0.0.0/16  -> local
0.0.0.0/0    -> Internet Gateway
```

This allows Internet-facing AWS resources in the public subnets to communicate with the Internet.

---

## Private Application Route Table

```text
Name: studentapp-private-app-rt
```

Associated with:

```text
frontend-private-1
frontend-private-2
backend-private-1
backend-private-2
```

Routes:

```text
10.0.0.0/16  -> local
0.0.0.0/0    -> NAT Gateway
```

Frontend and backend EC2 instances can therefore initiate outbound Internet connections without being publicly reachable.

This is required for operations such as:

- apt package installation
- Git repository cloning
- npm installation
- Maven dependency downloads
- AWS API access

---

## Database Route Table

```text
Name: studentapp-database-rt
```

Associated with:

```text
database-private-1
database-private-2
```

Route:

```text
10.0.0.0/16 -> local
```

There is no default Internet route for the database subnets.

---

# Internet Gateway

Internet Gateway:

```text
studentapp-igw
```

The Internet Gateway is attached to:

```text
studentapp-vpc
```

It provides Internet connectivity for resources using the public route table.

---

# NAT Gateway

NAT Gateway:

```text
studentapp-nat
```

The NAT Gateway is located inside:

```text
public-subnet-1
```

It uses an Elastic IP address.

Private frontend and backend instances use the NAT Gateway for outbound Internet connectivity.

The NAT Gateway does **not** make those EC2 instances publicly accessible.

---

# Security Groups

The application uses separate security groups for each infrastructure layer.

This provides controlled communication between tiers.

---

## Public ALB Security Group

```text
studentapp-public-alb-sg
```

Inbound:

```text
HTTP
TCP 80
Source: 0.0.0.0/0
```

Purpose:

Allows users on the Internet to access the public frontend Application Load Balancer.

---

## Frontend Security Group

```text
studentapp-frontend-sg
```

Inbound:

```text
HTTP
TCP 80
Source: studentapp-public-alb-sg
```

Frontend EC2 instances therefore accept web traffic from the public ALB rather than directly from the Internet.

---

## Internal Backend ALB Security Group

```text
studentapp-internal-alb-sg
```

Inbound:

```text
Custom TCP
Port 8080
Source: studentapp-frontend-sg
```

Only the frontend tier can send application traffic to the internal backend load balancer.

---

## Backend Security Group

```text
studentapp-backend-sg
```

Inbound:

```text
Custom TCP
Port 8080
Source: studentapp-internal-alb-sg
```

Backend EC2 instances accept application traffic from the internal backend ALB.

---

## RDS Security Group

```text
studentapp-rds-sg
```

Inbound:

```text
MySQL/Aurora
TCP 3306
Source: studentapp-backend-sg
```

Only backend EC2 instances can connect to the MySQL database.

---

# Security Group Flow

```text
Internet
   |
   | HTTP :80
   v
Public ALB Security Group
   |
   | HTTP :80
   v
Frontend Security Group
   |
   | TCP :8080
   v
Internal ALB Security Group
   |
   | TCP :8080
   v
Backend Security Group
   |
   | MySQL :3306
   v
RDS Security Group
```

---

# Frontend Tier

The frontend is built using React and served using Nginx.

Frontend EC2 instances run inside:

```text
frontend-private-1
frontend-private-2
```

They do not require public IP addresses.

The frontend is exposed through the public Application Load Balancer.

Nginx serves the React production build and acts as a reverse proxy for `/api` requests.

Example:

```nginx
location / {
    try_files $uri $uri/ /index.html;
}

location /api/ {
    proxy_pass http://INTERNAL-BACKEND-ALB:8080/api/;
}
```

This means the browser does not need direct access to the internal backend ALB.

---

# Backend Tier

The backend is implemented using Spring Boot.

Backend instances run inside:

```text
backend-private-1
backend-private-2
```

Spring Boot listens on:

```text
8080
```

The backend communicates with Amazon RDS MySQL on:

```text
3306
```

The backend is accessed through the internal Application Load Balancer.

---

# Database Tier

Amazon RDS MySQL provides persistent application storage.

Configuration:

```text
Identifier: studentapp-db
Engine: MySQL
Database: student_db
Port: 3306
Storage: 20 GiB gp3
Public Access: Disabled
```

The database uses dedicated private database subnets.

DB subnet group:

```text
studentapp-db-subnet-group
```

Subnets:

```text
database-private-1
database-private-2
```

The database cannot be directly accessed from the public Internet.

---

# Load Balancers

Two Application Load Balancers are used.

---

## Public Frontend Application Load Balancer

```text
Name: studentapp-frontend-alb
Scheme: Internet-facing
Listener: HTTP :80
```

Subnets:

```text
public-subnet-1
public-subnet-2
```

Traffic flow:

```text
Internet
   ↓
Frontend ALB
   ↓
Frontend Target Group
   ↓
Frontend EC2 instances
```

---

## Internal Backend Application Load Balancer

```text
Name: studentapp-backend-alb
Scheme: Internal
Listener: HTTP :8080
```

Subnets:

```text
backend-private-1
backend-private-2
```

Traffic flow:

```text
Frontend EC2
   ↓
Internal Backend ALB
   ↓
Backend Target Group
   ↓
Backend EC2 instances
```

Because this ALB is internal, it is not directly reachable from the public Internet.

---

# Target Groups

## Frontend Target Group

```text
Name: studentapp-frontend-tg
Target Type: Instances
Protocol: HTTP
Port: 80
Health Check: /
```

The target group contains frontend EC2 instances managed by the frontend Auto Scaling Group.

---

## Backend Target Group

```text
Name: studentapp-backend-tg
Target Type: Instances
Protocol: HTTP
Port: 8080
Health Check: /api/users
```

The target group contains backend EC2 instances managed by the backend Auto Scaling Group.

---

# Auto Scaling

Both application tiers use EC2 Auto Scaling.

---

## Frontend Auto Scaling Group

```text
Name: studentapp-frontend-asg

Minimum Capacity: 2
Desired Capacity: 2
Maximum Capacity: 4
```

Subnets:

```text
frontend-private-1
frontend-private-2
```

The frontend ASG is attached to:

```text
studentapp-frontend-tg
```

Health checks use ELB health information.

---

## Backend Auto Scaling Group

```text
Name: studentapp-backend-asg

Minimum Capacity: 2
Desired Capacity: 2
Maximum Capacity: 4
```

Subnets:

```text
backend-private-1
backend-private-2
```

The backend ASG is attached to:

```text
studentapp-backend-tg
```

Health checks use ELB health information.

---

# Launch Templates

Separate EC2 launch templates are used for the frontend and backend.

## Frontend Launch Template

```text
studentapp-frontend-lt
```

Configuration includes:

- Ubuntu 24.04 LTS
- t3.micro
- Frontend security group
- 8 GiB gp3 storage
- Frontend user-data bootstrap script

---

## Backend Launch Template

```text
studentapp-backend-lt
```

Configuration includes:

- Ubuntu 24.04 LTS
- t3.micro
- Backend security group
- Backend IAM instance profile
- 8 GiB gp3 storage
- Backend user-data bootstrap script

---

# AWS Systems Manager Parameter Store

The RDS password is not stored in this GitHub repository.

It is stored as a SecureString in AWS Systems Manager Parameter Store.

Parameter:

```text
/studentapp/db/password
```

The backend EC2 instance retrieves the value during initialization.

Example:

```bash
DB_PASSWORD=$(aws ssm get-parameter \
  --name "/studentapp/db/password" \
  --with-decryption \
  --region us-east-1 \
  --query "Parameter.Value" \
  --output text)
```

This prevents database passwords from being committed to source control.

---

# IAM

Backend EC2 instances use an IAM role:

```text
studentapp-backend-role
```

The role allows the backend instance to retrieve the required configuration from AWS Systems Manager Parameter Store.

The IAM role is attached to backend EC2 instances through an instance profile configured in the backend launch template.

---

# Backend Database Configuration

The repository does not contain production database passwords.

The application can use environment variables for local or external configuration.

Example:

```properties
spring.datasource.url=${DB_URL:jdbc:mariadb://localhost:3306/student_db}
spring.datasource.username=${DB_USERNAME:root}
spring.datasource.password=${DB_PASSWORD:}
```

During AWS deployment, the EC2 bootstrap process generates the runtime database configuration using the password retrieved from Parameter Store.

---

# API Endpoints

The Spring Boot backend provides REST endpoints under `/api`.

---

## Get All Students

```http
GET /api/users
```

Returns the registered students.

---

## Register Student

```http
POST /api/register
```

Creates a new student record.

---

## Delete Student

```http
DELETE /api/users/{id}
```

Deletes a student using its ID.

---

# Frontend Deployment

Frontend deployment is automated using:

```text
aws/frontend-user-data.sh
```

When a frontend EC2 instance launches, the script performs the following operations:

1. Updates Ubuntu packages.
2. Installs Nginx.
3. Installs Git.
4. Installs Node.js.
5. Installs npm.
6. Clones the GitHub repository.
7. Opens the frontend project.
8. Configures:

```text
VITE_API_URL=/api
```

9. Installs frontend dependencies.
10. Builds the React application.
11. Copies the production build to `/var/www/html`.
12. Configures Nginx.
13. Configures `/api` reverse proxying.
14. Validates the Nginx configuration.
15. Enables Nginx.
16. Starts/restarts Nginx.

---

# Backend Deployment

Backend deployment is automated using:

```text
aws/backend-user-data.sh
```

When a backend EC2 instance launches, the script:

1. Updates Ubuntu packages.
2. Installs Java 17.
3. Installs Maven.
4. Installs Git.
5. Installs AWS CLI.
6. Clones the GitHub repository.
7. Retrieves the RDS password from AWS Systems Manager Parameter Store.
8. Generates the Spring Boot database configuration.
9. Builds the application using Maven.
10. Copies the JAR into `/opt/studentapp`.
11. Creates a systemd service.
12. Enables the service.
13. Starts the Spring Boot backend.

The backend listens on:

```text
8080
```

---

# Application Request Flow

A normal browser request follows this path:

```text
User Browser
      |
      | HTTP :80
      v
Public Frontend ALB
      |
      v
Frontend EC2
      |
      | Nginx serves React
      |
      | /api request
      v
Nginx Reverse Proxy
      |
      | HTTP :8080
      v
Internal Backend ALB
      |
      v
Backend EC2
      |
      | Spring Boot
      |
      | MySQL :3306
      v
Amazon RDS
```

The response travels back through the same application tiers.

---

# Security Architecture

The deployment uses several security controls.

## Private Application Instances

Frontend and backend EC2 instances are deployed in private subnets.

They do not need direct inbound Internet access.

## Private Database

Amazon RDS is configured with:

```text
Publicly Accessible: No
```

## Internal Backend ALB

The backend Application Load Balancer uses the internal scheme.

Therefore, users cannot access the backend ALB directly from the Internet.

## Security Group Referencing

Security groups reference other application security groups instead of exposing internal services publicly.

## Parameter Store

Database credentials are stored outside the Git repository.

## Git Secret Protection

The repository `.gitignore` excludes:

```text
.env
.env.*
*.pem
*.key
frontend/node_modules/
frontend/dist/
backend/target/
*.jar
```

Secrets, private keys, build artifacts, and dependency directories should never be committed.

---

# Testing

The deployed application was functionally tested after deployment.

## Frontend Test

The public frontend ALB successfully returned the React application.

## Registration Test

A student was registered through the frontend.

The frontend sent the request through:

```text
Frontend
   ↓
Nginx /api
   ↓
Internal Backend ALB
   ↓
Spring Boot
   ↓
RDS
```

The registration completed successfully.

## Database Persistence Test

The RDS database was queried after registration.

The registered student existed in the `user` table.

The application was refreshed and the record remained available, confirming database persistence.

## Read Test

```http
GET /api/users
```

successfully returned student records.

## Delete Test

A student was deleted through the frontend.

```http
DELETE /api/users/{id}
```

completed successfully.

## Load Balancer Health

Both frontend target-group instances reached a healthy state.

Both backend target-group instances reached a healthy state.

---

# Local Development

## Backend

Requirements:

- Java 17+
- Maven
- MySQL/MariaDB

Configure environment variables:

```bash
export DB_URL="jdbc:mariadb://localhost:3306/student_db"
export DB_USERNAME="root"
export DB_PASSWORD="YOUR_LOCAL_PASSWORD"
```

Move into the backend:

```bash
cd backend
```

Run:

```bash
mvn spring-boot:run
```

The backend is available on the configured Spring Boot port.

---

## Frontend

Requirements:

- Node.js
- npm

Move into:

```bash
cd frontend
```

Install dependencies:

```bash
npm install
```

Create a local `.env` file if required:

```text
VITE_API_URL=http://localhost:8080/api
```

Start the development server:

```bash
npm run dev
```

---

# AWS Deployment Scripts

The repository contains two EC2 initialization scripts.

```text
aws/
├── backend-user-data.sh
└── frontend-user-data.sh
```

## `backend-user-data.sh`

Responsible for:

- Backend dependency installation
- Repository cloning
- Parameter Store retrieval
- Spring Boot configuration
- Maven build
- JAR deployment
- systemd service configuration

## `frontend-user-data.sh`

Responsible for:

- Frontend dependency installation
- Repository cloning
- React production build
- Nginx configuration
- SPA routing
- Backend reverse proxy configuration

---

# Availability Design

Application resources are distributed across:

```text
us-east-1a
us-east-1b
```

The frontend ASG maintains two frontend instances.

The backend ASG maintains two backend instances.

Application Load Balancers distribute requests between healthy instances registered with their respective target groups.

This design reduces dependence on a single application EC2 instance or a single application Availability Zone.

---

# Infrastructure Summary

| Component | Configuration |
|---|---|
| AWS Region | us-east-1 |
| VPC | studentapp-vpc |
| VPC CIDR | 10.0.0.0/16 |
| Availability Zones | 2 |
| Total Subnets | 8 |
| Public Subnets | 2 |
| Frontend Private Subnets | 2 |
| Backend Private Subnets | 2 |
| Database Private Subnets | 2 |
| Internet Gateway | studentapp-igw |
| NAT Gateway | studentapp-nat |
| Public ALB | studentapp-frontend-alb |
| Internal ALB | studentapp-backend-alb |
| Frontend Target Group | studentapp-frontend-tg |
| Backend Target Group | studentapp-backend-tg |
| Frontend ASG | studentapp-frontend-asg |
| Backend ASG | studentapp-backend-asg |
| Frontend ASG Capacity | Min 2 / Desired 2 / Max 4 |
| Backend ASG Capacity | Min 2 / Desired 2 / Max 4 |
| Frontend Port | 80 |
| Backend Port | 8080 |
| Database Port | 3306 |
| Database | Amazon RDS MySQL |
| Database Name | student_db |
| RDS Public Access | Disabled |
| Secret Storage | AWS Systems Manager Parameter Store |

---

# Deployment Flow

```text
GitHub Repository
       |
       +-----------------------------+
       |                             |
       v                             v
Frontend Launch Template      Backend Launch Template
       |                             |
       v                             v
Frontend Auto Scaling         Backend Auto Scaling
       |                             |
       v                             v
Frontend EC2                  Backend EC2
       |                             |
       v                             v
React + Nginx                 Spring Boot
       |                             |
       +---------- API --------------+
                                     |
                                     v
                                Amazon RDS
```

---

# Important Security Note

No real database passwords, private keys, PEM files, access keys, or other secrets should be committed to this repository.

Production credentials should be stored using AWS-managed secret/configuration services such as AWS Systems Manager Parameter Store or AWS Secrets Manager and accessed through appropriately scoped IAM permissions.

If a credential is accidentally committed, removing it from the latest file alone is not sufficient. The credential should be rotated and the repository history reviewed.

---

# Future Improvements

Possible improvements include:

- HTTPS using AWS Certificate Manager
- Custom domain using Amazon Route 53
- HTTP-to-HTTPS redirection
- AWS Secrets Manager
- More restrictive IAM policies
- CloudWatch monitoring and alarms
- Auto Scaling policies based on CPU or request load
- CI/CD using GitHub Actions
- AWS WAF
- Infrastructure as Code using Terraform or AWS CloudFormation
- Automated application testing
- Centralized application logging

---

# Conclusion

This project demonstrates the deployment of a full-stack application using a multi-tier AWS architecture.

The final request path is:

```text
Internet
   ↓
Public Application Load Balancer
   ↓
Frontend Auto Scaling Group
   ↓
React + Nginx
   ↓
Internal Application Load Balancer
   ↓
Backend Auto Scaling Group
   ↓
Spring Boot
   ↓
Amazon RDS MySQL
```

The architecture separates public, frontend, backend, and database resources into dedicated network tiers and uses load balancing, Auto Scaling, private networking, security groups, IAM, and Parameter Store to operate the application.

---

# Author

**Mukit Shaikh**

GitHub: [mukitshaikh](https://github.com/mukitshaikh)

Repository: [student-registration-aws](https://github.com/mukitshaikh/student-registration-aws)
