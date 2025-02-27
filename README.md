# tf-aws-infra
Terraform AWS Infrastructure Repository
# Terraform AWS Infrastructure Setup

This repository contains Terraform configurations to provision AWS networking infrastructure, including VPCs, subnets, internet gateways, route tables, and other networking components.
---

## **📌 Prerequisites**
Before running Terraform, ensure you have the following installed:
- [Terraform](https://developer.hashicorp.com/terraform/downloads) (>= v1.5.0)
- [AWS CLI](https://aws.amazon.com/cli/) (Configured with `dev` and `demo` profiles)
- Git (to clone this repository)
- An AWS account with necessary IAM permissions

---

## **🚀 Setup Instructions**


### **1️⃣ Clone the Repository**
```sh
git clone https://github.com/username/tf-aws-infra.git
cd tf-aws-infra


# Terraform Infrastructure Deployment (Assignment 4)

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
This project provisions cloud infrastructure using **Terraform** and deploys a Flask-based WebApp on AWS & GCP using **Packer-built custom images**. The deployment is automated via **GitHub Actions CI/CD**.

### ✅ **Key Components:**
- **Infrastructure as Code (IaC)** with Terraform.
- **Custom AMI & GCP Machine Image** built with Packer.
- **Automated deployment using Terraform & CI/CD**.

---

## **Prerequisites**
Ensure you have the following installed:
- Terraform (`>=1.0`)
- Packer (`>=1.7`)
- AWS CLI (`>=2.0`)
- GCP CLI (`>= 399.0`)
- GitHub Actions configured with IAM roles for AWS & GCP

---

## **Infrastructure Setup**
### **Terraform Configurations**
Terraform provisions:
- **VPC, subnets, Internet Gateway, Route Tables**
- **EC2 instance using a Packer-built AMI**
- **Security groups (allowing SSH, HTTP, and app ports)**
- **GCP Compute Instance using the custom image**

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
Packer is used to create a **custom AMI (AWS)** and **Machine Image (GCP)** that includes:
- **Ubuntu 24.04 LTS**
- **MySQL, Python, pip, nginx**

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
4. Build the image (AWS & GCP):
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
### **Health Check API (`/healthz`)**
- Test via `curl`:
  ```sh
  curl -X GET http://<server-ip>:8080/healthz
  ```

### **Troubleshooting Common Issues**
**1. Terraform Errors**
   - Ensure correct AWS/GCP credentials are set.
   - Verify Terraform version compatibility.

**2. Deployment Issues**
   - Check logs using `terraform show` or `terraform output`.

---

## **🚀 Conclusion**
This assignment integrates **Terraform, Packer, and CI/CD** to provision cloud infrastructure for the WebApp deployment.
