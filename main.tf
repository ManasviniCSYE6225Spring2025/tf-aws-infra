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

#random password generate
resource "random_password" "db_password" {
  length  = 16
  special = false
}

# KMS key for ec2,s3,RDS

data "aws_caller_identity" "current" {}

resource "aws_kms_key" "ec2_kms" {
  description         = "KMS key for EC2 EBS encryption"
  enable_key_rotation = true
  rotation_period_in_days = 90

  policy = jsonencode({
    Version = "2012-10-17",
    Id      = "key-default-1",
    Statement = [
      {
        Sid : "Enable IAM User Permissions",
        Effect : "Allow",
        Principal : {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        Action : "kms:*",
        Resource : "*"
      },
      {
        Sid : "Allow cli-user full access",
        Effect : "Allow",
        Principal : {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/${var.iam_username}"
        },
        Action : "kms:*",
        Resource : "*"
      },
      {
        Sid : "Allow Secrets Manager",
        Effect : "Allow",
        Principal : {
          Service : "ec2.amazonaws.com"
        },
        Action : [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ],
        Resource : "*"
      }
    ]
  })

}

resource "aws_kms_key" "rds_kms" {
  description         = "KMS key for RDS encryption"
  enable_key_rotation = true
  rotation_period_in_days = 90

  policy = jsonencode({
    Version = "2012-10-17",
    Id      = "key-default-1",
    Statement = [
      {
        Sid : "Enable IAM User Permissions",
        Effect : "Allow",
        Principal : {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        Action : "kms:*",
        Resource : "*"
      },
      {
        Sid : "Allow cli-user full access",
        Effect : "Allow",
        Principal : {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/${var.iam_username}"
        },
        Action : "kms:*",
        Resource : "*"
      },
      {
        Sid : "Allow Secrets Manager",
        Effect : "Allow",
        Principal : {
          Service : "rds.amazonaws.com"
        },
        Action : [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ],
        Resource : "*"
      }
    ]
  })

}

resource "aws_kms_key" "s3_kms" {
  description         = "KMS key for S3 encryption"
  enable_key_rotation = true
  rotation_period_in_days = 90

  policy = jsonencode({
    Version = "2012-10-17",
    Id      = "key-default-1",
    Statement = [
      {
        Sid : "Enable IAM User Permissions",
        Effect : "Allow",
        Principal : {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        Action : "kms:*",
        Resource : "*"
      },
      {
        Sid : "Allow cli-user full access",
        Effect : "Allow",
        Principal : {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/${var.iam_username}"
        },
        Action : "kms:*",
        Resource : "*"
      },
      {
        Sid : "AllowEC2RoleAccess",
        Effect : "Allow",
        Principal : {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/cloudwatch-ec2-role"
        },
        Action : [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ],
        Resource : "*"
      },
      {
        Sid : "Allow S3 Service Use",
        Effect : "Allow",
        Principal : {
          Service : "s3.amazonaws.com"
        },
        Action : [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ],
        Resource : "*"
      }
    ]
  })
}


resource "aws_kms_key" "secrets_kms" {
  description         = "KMS key for Secrets Manager"
  enable_key_rotation = true
  rotation_period_in_days = 90

  policy = jsonencode({
    Version = "2012-10-17",
    Id      = "key-default-1",
    Statement = [
      {
        Sid : "Enable IAM User Permissions",
        Effect : "Allow",
        Principal : {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        Action : "kms:*",
        Resource : "*"
      },
      {
        Sid : "Allow cli-user full access",
        Effect : "Allow",
        Principal : {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/${var.iam_username}"
        },
        Action : "kms:*",
        Resource : "*"
      },
      {
        Sid : "Allow Secrets Manager",
        Effect : "Allow",
        Principal : {
          Service : "secretsmanager.amazonaws.com"
        },
        Action : [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ],
        Resource : "*"
      }
    ]
  })
}

resource "aws_secretsmanager_secret" "infra_metadata" {
  name       = var.metadata_secret_name
  kms_key_id = aws_kms_key.secrets_kms.arn
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "infra_metadata_version" {
  secret_id = aws_secretsmanager_secret.infra_metadata.id
  secret_string = jsonencode({
    launch_template_name = aws_launch_template.webapp_lt.name
    asg_name             = aws_autoscaling_group.webapp_asg.name
  })
}


# DB or Secrets-related block
resource "aws_secretsmanager_secret" "db_credentials" {
  name       = var.secretsmanager_db_secret_name
  kms_key_id = aws_kms_key.secrets_kms.arn
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "db_credentials_version" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    password = random_password.db_password.result
  })
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
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [aws_security_group.load_balancer.id]
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

# security group for Load Balancer
resource "aws_security_group" "load_balancer" {
  name        = "load_balancer"
  description = "Allow HTTP/HTTPS"
  vpc_id      = aws_vpc.main.id

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

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Add loadbalancer, target group and listener
resource "aws_lb" "app_lb" {
  name               = "app-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.load_balancer.id]
  subnets            = aws_subnet.public[*].id
}

resource "aws_lb_target_group" "app_tg" {
  name     = "app-tg"
  port     = var.app_port
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/healthz"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 2
    matcher             = "200"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}


data "aws_acm_certificate" "demo_cert" {
  domain   = "${var.subdomain}.${var.domain_name}"
  statuses = ["ISSUED"]
  most_recent = true
}


# demo & dev certificate arn
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = data.aws_acm_certificate.demo_cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
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
  identifier        = "csye6225"
  engine            = "mysql"
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  db_name           = "csye6225"
  username          = "csye6225"
  password          = jsondecode(aws_secretsmanager_secret_version.db_credentials_version.secret_string)["password"]
  #password               = var.db_password
  skip_final_snapshot    = true
  db_subnet_group_name   = aws_db_subnet_group.private_db_subnet.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  publicly_accessible    = false
  multi_az               = false
  storage_encrypted      = true
  kms_key_id             = aws_kms_key.rds_kms.arn


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
          "arn:aws:s3:::${aws_s3_bucket.app_bucket.id}/*",
        ]
      }
    ]
  })
}

# screct manager iam policy
# resource "aws_iam_policy" "secrets_manager_access" {
#   name        = "ec2-secretsmanager-access"
#   description = "Allow EC2 to get secret value from Secrets Manager"

#   policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Effect = "Allow",
#         Action = [
#           "secretsmanager:GetSecretValue"
#         ],
#         Resource = "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:${var.secretsmanager_db_secret_name}*"
#       }
#     ]
#   })
# }

data "aws_secretsmanager_secret" "db_secret" {
  name = var.secretsmanager_db_secret_name
  depends_on = [ aws_secretsmanager_secret.db_credentials ]

}

data "aws_secretsmanager_secret" "infra_secret" {
  name = var.metadata_secret_name
  depends_on = [ aws_secretsmanager_secret.infra_metadata ]
}

resource "aws_iam_policy" "secrets_manager_access" {
  name        = "ec2-secretsmanager-access"
  description = "Allow EC2 to get secret value from Secrets Manager and decrypt using KMS"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowSecretsManagerAccess",
        Effect = "Allow",
        Action = [
          "secretsmanager:GetSecretValue"
        ],
        Resource = [data.aws_secretsmanager_secret.db_secret.arn,data.aws_secretsmanager_secret.infra_secret.arn]
      },
      { 
        Sid    = "AllowKMSDecrypt",
        Effect = "Allow",
        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ],
        Resource = aws_kms_key.secrets_kms.arn
      },
      { 
        Sid    = "AllowS3KMSDecrypt",
        Effect = "Allow",
        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ],
        Resource = aws_kms_key.s3_kms.arn
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "ec2_secretsmanager_attach" {
  role       = aws_iam_role.cloudwatch_ec2_role.name
  policy_arn = aws_iam_policy.secrets_manager_access.arn
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

# #6) Attach Secrets Manager Policy to cloudwatch-ec2-role
# resource "aws_iam_role_policy_attachment" "ec2_secretsmanager_attach" {
#   role       = aws_iam_role.cloudwatch_ec2_role.name
#   policy_arn = aws_iam_policy.secrets_manager_access.arn
# }

# data "aws_caller_identity" "current" {}


# Adding launch templet
resource "aws_launch_template" "webapp_lt" {
  name   = "csye6225-asg-lt"
  image_id      = var.custom_ami
  instance_type = var.instance_type
  key_name      = "AWSkeypair"

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_combined_profile.name
  }

  user_data = base64encode(<<-EOF
  #!/bin/bash
  set -e

  echo "Installing jq and awscli"
  sudo apt update && sudo apt install -y unzip curl jq

  mkdir -p /opt/csye6225

  echo "DB_HOST='${aws_db_instance.webapp_db.endpoint}'" >> /opt/csye6225/.env
  echo "DB_USER='${aws_db_instance.webapp_db.username}'" >> /opt/csye6225/.env
  echo "DB_NAME='${aws_db_instance.webapp_db.db_name}'" >> /opt/csye6225/.env
  echo "S3_BUCKET_NAME='${aws_s3_bucket.app_bucket.id}'" >> /opt/csye6225/.env

  # Try to fetch secret and parse it
  secret=$(aws secretsmanager get-secret-value --region ${var.aws_region} --secret-id ${var.secretsmanager_db_secret_name} --query SecretString --output text || echo "")
  if [ -n "$secret" ]; then
    db_pass=$(echo "$secret" | jq -r '.password')
    echo "DB_PASSWORD=$db_pass" >> /opt/csye6225/.env
  else
    echo "DB_PASSWORD=" >> /opt/csye6225/.env
    echo "Failed to retrieve DB password from Secrets Manager" >> /var/log/user_data.log
  fi


  chmod 600 /opt/csye6225/.env

    echo "Restarting myapp..." >> /var/log/user-data.log
  systemctl restart myapp
EOF
)

  tags = {
    Name = "${var.vpc_name}-app-server"
  } # This file should create .env and start app

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.app_sg.id]
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "csye6225-instance"
    }
  }
}

# Creating Auto Scaling group
resource "aws_autoscaling_group" "webapp_asg" {
  name                      = "csye6225-asg"
  desired_capacity          = 3
  max_size                  = 5
  min_size                  = 3
  health_check_type         = "EC2"
  health_check_grace_period = 300
  vpc_zone_identifier       = aws_subnet.public[*].id

  launch_template {
    id      = aws_launch_template.webapp_lt.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.app_tg.arn]

  tag {
    key                 = "Name"
    value               = "csye6225-asg-instance"
    propagate_at_launch = true
  }
}

# Auto Scaling plicies and alarms
resource "aws_autoscaling_policy" "scale_up" {
  name                   = "scale-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 60
  autoscaling_group_name = aws_autoscaling_group.webapp_asg.name
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "scale-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 60
  autoscaling_group_name = aws_autoscaling_group.webapp_asg.name
}

resource "aws_cloudwatch_metric_alarm" "scale_up" {
  alarm_name          = "cpu-utilization-scale-up"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 7
  alarm_actions       = [aws_autoscaling_policy.scale_up.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.webapp_asg.name
  }
}

resource "aws_cloudwatch_metric_alarm" "scale_down" {
  alarm_name          = "cpu-utilization-scale-down"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 6
  alarm_actions       = [aws_autoscaling_policy.scale_down.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.webapp_asg.name
  }
}

# Route 53 records with ALB
resource "aws_route53_record" "alb_record" {
  zone_id = data.aws_route53_zone.primary.zone_id
  name    = "${var.subdomain}.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_lb.app_lb.dns_name
    zone_id                = aws_lb.app_lb.zone_id
    evaluate_target_health = true
  }
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
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3_kms.arn
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
          "cloudwatch:PutMetricData",
          "cloudwatch:ListTagsForResource"
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
# EC2 Instance removed

