terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
  }
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = var.vpc_name
  }
}

# Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.vpc_name}-igw"
  }
}

# Public Subnets
resource "aws_subnet" "public" {
  count = length(var.public_subnets)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnets[count.index]
  availability_zone       = element(var.availability_zones, count.index)
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.vpc_name}-public-${count.index}"
  }
}

# Private Subnets
resource "aws_subnet" "private" {
  count = length(var.private_subnets)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnets[count.index]
  availability_zone = element(var.availability_zones, count.index)

  tags = {
    Name = "${var.vpc_name}-private-${count.index}"
  }
}

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.vpc_name}-public-rt"
  }
}

# Public Route
resource "aws_route" "public_internet_access" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id
}

# Associate Public Subnets with Public Route Table
resource "aws_route_table_association" "public" {
  count = length(var.public_subnets)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Private Route Table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.vpc_name}-private-rt"
  }
}

# Associate Private Subnets with Private Route Table
resource "aws_route_table_association" "private" {
  count = length(var.private_subnets)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# Lookup existing Route 53 hosted zone
data "aws_route53_zone" "primary" {
  name         = "${var.subdomain}.${var.domain_name}"
  private_zone = false
}

# Application Security Group
resource "aws_security_group" "app_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = var.app_port
    to_port     = var.app_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.vpc_name}-app-sg"
  }
}
# Security Group for Database
resource "aws_security_group" "db_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create RDS Parameter Group
resource "aws_db_parameter_group" "mysql_parameter_group" {
  name        = "mysql-parameter-group"
  family      = "mysql8.0"
  description = "Custom MySQL parameter group"

  parameter {
    name  = "log_bin_trust_function_creators"
    value = "1"
  }

  parameter {
    name  = "max_connections"
    value = "200"
  }

  tags = {
    Name = "mysql-parameter-group"
  }
}


# RDS Subnet Group
resource "aws_db_subnet_group" "private_db_subnet" {
  name       = "private-db-subnet-group"
  subnet_ids = aws_subnet.private[*].id
  tags = {
    Name = "private-db-subnet-group"
  }
}

resource "aws_security_group" "rds_sg" {
  name        = "rds-security-group"
  description = "Allow access only from EC2"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id]
  }

  egress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id]
  }
}

# RDS Instance
resource "aws_db_instance" "webapp_db" {
  identifier             = "csye6225"
  engine                 = "mysql"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  db_name                = "csye6225"
  username               = "csye6225"
  password               = var.db_password
  skip_final_snapshot    = true
  db_subnet_group_name   = aws_db_subnet_group.private_db_subnet.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  publicly_accessible    = false
  multi_az               = false

  # Attach the custom parameter group
  parameter_group_name = aws_db_parameter_group.mysql_parameter_group.name

  tags = {
    Name = "csye6225-db"
  }
}

# Create S3 Bucket
resource "random_uuid" "s3_bucket_name" {}

# 1) Assume-Role Policy Document for EC2
data "aws_iam_policy_document" "ec2_assume_role_doc" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# 2) Create the IAM Role for EC2
resource "aws_iam_role" "ec2_s3_role" {
  name               = "ec2-s3-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role_doc.json
}

# 3) S3 Access Policy
resource "aws_iam_policy" "s3_access_policy" {
  name        = "ec2-s3-access-policy"
  description = "Allows EC2 to list, get, put, and delete objects in our S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ],
        Resource = [
          # Replace 'my-bucket-name' with your actual bucket name
          "arn:aws:s3:::${aws_s3_bucket.app_bucket.id}",
          "arn:aws:s3:::${aws_s3_bucket.app_bucket.id}/*"
        ]
      }
    ]
  })
}

# 4) Attach the S3 Policy to the EC2 Role
resource "aws_iam_role_policy_attachment" "ec2_s3_attach" {
  role       = aws_iam_role.ec2_s3_role.name
  policy_arn = aws_iam_policy.s3_access_policy.arn
}

# 5) Create an Instance Profile for That Role
resource "aws_iam_instance_profile" "ec2_s3_profile" {
  name = "ec2-s3-instance-profile"
  role = aws_iam_role.ec2_s3_role.name
}

# Create Bucket
resource "aws_s3_bucket" "app_bucket" {
  bucket        = "my-app-bucket-${random_uuid.s3_bucket_name.result}"
  force_destroy = true # Allows Terraform to delete the bucket if needed

  tags = {
    Name = "app-bucket"
  }
}

# Separate resource for server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "app_bucket_encryption" {
  bucket = aws_s3_bucket.app_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Lifecycle rule (Objects transition to STANDARD_IA after 30 days)
resource "aws_s3_bucket_lifecycle_configuration" "app_bucket_lifecycle" {
  bucket = aws_s3_bucket.app_bucket.id

  rule {
    id     = "transition-to-IA"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
  }
}

# --- IAM Policy for CloudWatch Agent ---

resource "aws_iam_policy" "cloudwatch_agent_policy" {
  name        = "CloudWatchAgentPolicy"
  description = "Policy for EC2 to push logs and metrics to CloudWatch"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams",
          "cloudwatch:PutMetricData"
        ],
        Resource = "*"
      }
    ]
  })
}



# IAM Role for CloudWatch Agent on EC2
resource "aws_iam_role" "cloudwatch_ec2_role" {
  name               = "cloudwatch-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role_doc.json
}



# Attach CloudWatch Policy to Role
resource "aws_iam_role_policy_attachment" "attach_cloudwatch_policy" {
  role       = aws_iam_role.cloudwatch_ec2_role.name
  policy_arn = aws_iam_policy.cloudwatch_agent_policy.arn
}



# Create new instance profile for EC2 with CloudWatch
resource "aws_iam_instance_profile" "ec2_combined_profile" {
  name = "ec2-combined-instance-profile"
  role = aws_iam_role.cloudwatch_ec2_role.name
}



# EC2 Role needs both S3 and CloudWatch policies
resource "aws_iam_role_policy_attachment" "ec2_cloudwatch_s3_attach" {
  role       = aws_iam_role.cloudwatch_ec2_role.name
  policy_arn = aws_iam_policy.s3_access_policy.arn
}


# Remove local MySQL variables in EC2 user_data
# EC2 Instance
resource "aws_instance" "app_server" {
  ami                         = var.custom_ami
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public[0].id
  vpc_security_group_ids      = [aws_security_group.app_sg.id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.ec2_combined_profile.name
  key_name                    = "AWSkeypair"


  root_block_device {
    volume_size           = 25
    volume_type           = "gp2"
    delete_on_termination = true
  }

  user_data = <<EOF
#!/bin/bash
mkdir -p /opt/csye6225
echo "DB_HOST='${aws_db_instance.webapp_db.endpoint}'" > /opt/csye6225/.env
echo "DB_USER='${aws_db_instance.webapp_db.username}'" >> /opt/csye6225/.env
echo "DB_PASSWORD='${var.db_password}'" >> /opt/csye6225/.env
echo "DB_NAME='${aws_db_instance.webapp_db.db_name}'" >> /opt/csye6225/.env
echo "S3_BUCKET_NAME='${aws_s3_bucket.app_bucket.id}'" >> /opt/csye6225/.env
sudo systemctl restart myapp
EOF

  tags = {
    Name = "${var.vpc_name}-app-server"
  }
}

# DNS A record for pointing to EC2 public IP
resource "aws_route53_record" "a_record" {
  zone_id    = data.aws_route53_zone.primary.zone_id
  name       = "${var.subdomain}.${var.domain_name}"
  type       = "A"
  ttl        = 300
  records    = [aws_instance.app_server.public_ip]
  depends_on = [aws_instance.app_server]
}
