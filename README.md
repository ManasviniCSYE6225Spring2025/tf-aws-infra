# tf-aws-infra
Terraform AWS Infrastructure Repository

# Terraform AWS Infrastructure Setup

This repository contains Terraform configurations to provision AWS networking infrastructure, including VPCs, subnets, internet gateways, route tables, security groups, EC2 instances, RDS instances, IAM roles, and an S3 bucket for file storage.

---

## **📌 Prerequisites**
Before running Terraform, ensure you have the following installed:
- [Terraform](https://developer.hashicorp.com/terraform/downloads) (>= v1.5.0)
- [AWS CLI](https://aws.amazon.com/cli/) (Configured with `dev` and `demo` profiles)
- [Git](https://git-scm.com/) (to clone this repository)
- An AWS account with necessary IAM permissions

---

## **🚀 Setup Instructions**

### **1️⃣ Clone the Repository**
```sh
git clone https://github.com/username/tf-aws-infra.git
cd tf-aws-infra
```


# Terraform Infrastructure Deployment (Assignment 5)

## 📌 Table of Contents
- [Project Overview](#project-overview)
- [Prerequisites](#prerequisites)
- [Infrastructure Setup](#infrastructure-setup)
- [Packer: Custom Image Creation](#packer-custom-image-creation)
- [Terraform Deployment](#terraform-deployment)
- [CI/CD Pipeline](#ci-cd-pipeline)
- [Testing & Troubleshooting](#testing-troubleshooting)

---

## **Project Overview**
This project provisions cloud infrastructure using **Terraform** and deploys a Flask-based WebApp on AWS using a **Packer-built custom AMI**. The infrastructure includes an **RDS instance for database storage**, an **S3 bucket for file storage**, and IAM roles to enable secure access.

### ✅ **Key Components:**
- **Infrastructure as Code (IaC)** with Terraform.
- **Custom AMI built with Packer**.
- **Automated deployment using Terraform & CI/CD**.
- **EC2 instance with User Data script for environment setup**.
- **RDS instance in private subnet with custom security group**.
- **S3 bucket with encryption and lifecycle policies**.

---

## **Prerequisites**
Ensure you have the following installed:
- Terraform (`>=1.0`)
- Packer (`>=1.7`)
- AWS CLI (`>=2.0`)
- GitHub Actions configured with IAM roles for AWS

---

## **Infrastructure Setup**
### **Terraform Configurations**
Terraform provisions:
- **VPC, subnets, Internet Gateway, Route Tables**
- **EC2 instance using a Packer-built AMI**
- **RDS instance (MySQL) in a private subnet**
- **Security groups (allowing only necessary access)**
- **IAM roles for EC2 and S3 access**
- **S3 bucket for file storage with encryption and lifecycle policy**

### **Steps to Deploy Terraform**
1. Clone the repository:
   ```sh
   git clone <repository-url>
   cd terraform-infra
   ```
2. Initialize Terraform:
   ```sh
   terraform init
   ```
3. Validate configuration:
   ```sh
   terraform validate
   ```
4. Preview infrastructure changes:
   ```sh
   terraform plan -var-file="terraform.tfvars"
   ```
5. Deploy the infrastructure:
   ```sh
   terraform apply -var-file="terraform.tfvars"
   ```

---

## **Packer: Custom Image Creation**
Packer is used to create a **custom AMI (AWS)** that includes:
- **Ubuntu 24.04 LTS**
- **MySQL Client, Python, pip, nginx**

### **Building the Image**
1. Navigate to the Packer directory:
   ```sh
   cd packer/
   ```
2. Initialize Packer:
   ```sh
   packer init ubuntu_webapp.pkr.hcl
   ```
3. Validate the configuration:
   ```sh
   packer validate ubuntu_webapp.pkr.hcl
   ```
4. Build the image (AWS):
   ```sh
   packer build ubuntu_webapp.pkr.hcl
   ```

---

## **CI/CD Pipeline**
### **GitHub Actions CI/CD**
The pipeline automates:
- **Terraform validation & plan checks**
- **Packer validation & build on PR merges**
- **Automated infrastructure provisioning**

### **Branch Protection Rules**
1. **Require Terraform & Packer checks before merging**
2. **Ensure branch is up-to-date before merging**

---

## **Testing & Troubleshooting**
### **1. Verify Database Connectivity from EC2**
```bash
mysql -h <rds-endpoint> -u csye6225 -p
```
Run SQL commands to verify data:
```sql
SHOW DATABASES;
USE csye6225;
SHOW TABLES;
SELECT * FROM files;
```

### **2. Verify API Endpoints**
Test file upload:
```sh
curl -X POST "http://<your-ec2-ip>:8080/upload" -F "profilePic=@/path/to/file.jpg"
```
Test health check:
```sh
curl -X GET http://<your-ec2-ip>:8080/healthz
```

### **3. Restart Application via Systemd**
```sh
sudo systemctl restart myapp
```
Check status:
```sh
sudo systemctl status myapp
```

### **4. Verify File Upload to S3**
List S3 objects:
```bash
aws s3 ls s3://your-s3-bucket-name/
```
To delete all objects manually:
```bash
aws s3 rm s3://your-s3-bucket-name --recursive
```

---

# Terraform AWS Infrastructure - CSYE6225

## 🧱 Overview

This repo defines the **Infrastructure-as-Code (IaC)** for deploying a Python Flask-based web application to AWS using **Terraform**.

### ☁️ Provisioned Components

- ✅ VPC with Public & Private Subnets
- ✅ Internet Gateway and Route Tables
- ✅ EC2 instance (with custom AMI built via Packer)
- ✅ RDS MySQL DB in private subnet
- ✅ S3 Bucket for file upload
- ✅ IAM Role for EC2 with:
  - Access to S3
  - Access to CloudWatch (Logs & Metrics)
- ✅ CloudWatch Logs & Custom Metrics (via StatsD)
- ✅ Route53 DNS Setup (optional)

---

## 📦 Module Structure


---

## 🚀 Usage

### 1. Initialize Terraform

```bash
terraform init
terrafor plan
terrafom apply

---

# TF-AWS-INFRA (Assignment 08)

This repository contains Terraform configurations to provision scalable, secure, and highly available infrastructure for deploying a Flask WebApp on AWS.

---

## 📀 Table of Contents
- [Project Overview](#project-overview)
- [Prerequisites](#prerequisites)
- [Infrastructure Components](#infrastructure-components)
- [Terraform Setup](#terraform-setup)
- [Applying Configuration](#applying-configuration)
- [Destroying Infrastructure](#destroying-infrastructure)
- [Scaling & Load Balancing](#scaling--load-balancing)
- [SSL Certificate Handling](#ssl-certificate-handling)
- [DNS with Route53](#dns-with-route53)
- [CI/CD Workflow](#cicd-workflow)

---

## 📁 Project Overview
This project provisions an AWS infrastructure with Terraform and deploys a Flask WebApp using a custom AMI. It includes:

- VPC with public/private subnets
- EC2 Auto Scaling Group
- Application Load Balancer (ALB)
- RDS MySQL Database
- S3 Bucket with encryption & lifecycle
- IAM Roles & Instance Profiles
- DNS records managed via Route 53

---

## ⚙️ Prerequisites
- Terraform (>=1.0)
- AWS CLI (>=2.0)
- AWS Account with sufficient permissions
- Packer (for AMI creation)
- IAM credentials configured with proper access

---

## 🧱 Infrastructure Components
The Terraform code provisions:

- ✅ **Custom VPC** with CIDR block
- ✅ **3 Public & 3 Private Subnets** (across multiple AZs)
- ✅ **Internet Gateway**
- ✅ **Security Groups** for ALB, EC2, and RDS
- ✅ **EC2 Launch Template** using Packer-built AMI
- ✅ **Auto Scaling Group (ASG)** with min=3, max=5 instances
- ✅ **Application Load Balancer** with HTTPS listener
- ✅ **RDS Instance** with custom parameter group
- ✅ **S3 Bucket** with server-side encryption & lifecycle policy
- ✅ **Route 53 DNS record** pointing to ALB

---

## 🛠️ Terraform Setup

### 1. Clone the Repo:
```bash
git clone <repo-url>
cd tf-aws-infra-remote
```

### 2. Initialize Terraform:
```bash
terraform init
```

### 3. Validate the Configuration:
```bash
terraform validate
```

### 4. Plan Infrastructure Changes:
```bash
terraform plan -var-file="dev.tfvars"
```

---

## 🚀 Applying Configuration
```bash
terraform apply -var-file="dev.tfvars"
```

Once applied, the ALB will route traffic to instances in the ASG, and the app will be accessible at:
```
https://<env>.<your-domain>.me/healthz
```

---

## 💣 Destroying Infrastructure
```bash
terraform destroy -var-file="dev.tfvars"
```
⚠️ Use caution—this will delete all provisioned AWS resources.

---

## 📊 Scaling & Load Balancing

- **Auto Scaling Group (ASG)** handles scaling:
  - **Min Instances:** 3
  - **Max Instances:** 5
  - **Scale Up:** CPU > 8%
  - **Scale Down:** CPU < 6%

- **Application Load Balancer (ALB)**
  - Listens on **HTTPS (443)**
  - Health checks `/healthz`
  - Routes traffic to ASG

---

## 🚧 SSL Certificate Handling

### 📄 Dev Environment (AWS Certificate Manager)
- Use an ACM certificate issued in us-east-1.
- Set the `acm_certificate_arn` in your `dev.tfvars` file.

### 📄 Switch to Demo Environment
- Make sure you're in the `demo` profile before importing the certificate:

```bash
aws configure --profile demo
```

### 📄 Demo Environment (3rd-Party Certificate)
- Buy a certificate (e.g., from Namecheap).
- Import it to ACM with:

```bash
aws acm import-certificate \
  --certificate fileb://<cert.crt> \
  --private-key fileb://<private.key> \
  --certificate-chain fileb://<ca-bundle.crt> \
  --region us-east-1
```

- Use the resulting ARN in `demo.tfvars`.

---

## 🌐 DNS with Route 53

- Hosted Zone configured for domain (e.g., `buildwithlokesh.me`)
- Alias A Record created pointing to ALB
- Domain: `dev.buildwithlokesh.me` or `demo.buildwithlokesh.me`

Ensure your domain is updated to use Route 53 nameservers.

---

## 🛡️ CI/CD Workflow

### GitHub Actions:
- `terraform fmt`
- `terraform validate`
- `terraform plan`

### Branch Protection:
- ✅ All checks must pass before merging.
- ✅ Up-to-date branches required.
- ❌ No direct commits to `main`.

---

## ✅ Conclusion
This Terraform setup fully automates a secure and scalable cloud environment ready for production workloads with custom domain, SSL, and monitoring.


## **🚀 Conclusion**
This assignment integrates **Terraform, Packer, and CI/CD** to provision cloud infrastructure for the WebApp deployment. The infrastructure is secured using IAM roles, private RDS instances, and encrypted S3 storage.

