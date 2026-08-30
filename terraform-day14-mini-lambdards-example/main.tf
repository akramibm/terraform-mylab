terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  type        = string
  description = "AWS Region to deploy resources"
  default     = "us-east-1"
}

# -----------------------------------------------------------------------------
# 1. VPC & Subnets
# -----------------------------------------------------------------------------

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "rds-mysql-lambda-vpc"
  }
}

# Subnet A (Private)
resource "aws_subnet" "private_subnet_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "private-subnet-a"
  }
}

# Subnet B (Private - Required for RDS DB Subnet Group multi-AZ requirement)
resource "aws_subnet" "private_subnet_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "private-subnet-b"
  }
}

# -----------------------------------------------------------------------------
# 2. Security Groups
# -----------------------------------------------------------------------------

# Security Group for Lambda ENI
resource "aws_security_group" "lambda_sg" {
  name        = "lambda-eni-sg"
  description = "Security group assigned to the Lambda Function ENI"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "lambda-eni-sg"
  }
}

# Security Group for RDS MySQL (Allows Port 3306 from Lambda only)
resource "aws_security_group" "rds_sg" {
  name        = "rds-mysql-sg"
  description = "Allow inbound MySQL traffic (3306) exclusively from Lambda"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.lambda_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rds-mysql-sg"
  }
}

# Security Group for VPC Interface Endpoints (Port 443 from Lambda only)
resource "aws_security_group" "vpce_sg" {
  name        = "vpce-https-sg"
  description = "Allow inbound HTTPS (443) traffic from Lambda ENI"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.lambda_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "vpce-https-sg"
  }
}

# -----------------------------------------------------------------------------
# 3. VPC Interface Endpoints (PrivateLink)
# -----------------------------------------------------------------------------

# Secrets Manager Interface Endpoint
resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private_subnet_a.id, aws_subnet.private_subnet_b.id]
  security_group_ids  = [aws_security_group.vpce_sg.id]
  private_dns_enabled = true

  tags = {
    Name = "vpce-secretsmanager"
  }
}

# CloudWatch Logs Interface Endpoint (Allows Lambda to write logs privately)
resource "aws_vpc_endpoint" "logs" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private_subnet_a.id, aws_subnet.private_subnet_b.id]
  security_group_ids  = [aws_security_group.vpce_sg.id]
  private_dns_enabled = true

  tags = {
    Name = "vpce-cloudwatch-logs"
  }
}

# -----------------------------------------------------------------------------
# 4. Single-AZ RDS MySQL Instance
# -----------------------------------------------------------------------------

resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds-mysql-private-subnet-group"
  subnet_ids = [aws_subnet.private_subnet_a.id, aws_subnet.private_subnet_b.id]

  tags = {
    Name = "rds-mysql-subnet-group"
  }
}

resource "aws_db_instance" "mysql_db" {
  identifier                  = "mysql-database-instance"
  allocated_storage           = 20
  engine                      = "mysql"
  engine_version              = "8.0"
  instance_class              = "db.t4g.micro"
  db_name                     = "appdb"
  username                    = "dbadmin"
  manage_master_user_password = true # Auto-generated & managed by AWS Secrets Manager
  multi_az                    = false # Single instance
  publicly_accessible         = false # Private access only
  skip_final_snapshot         = true
  db_subnet_group_name        = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids      = [aws_security_group.rds_sg.id]

  tags = {
    Name = "rds-mysql-single-instance"
  }
}

# -----------------------------------------------------------------------------
# 5. Lambda IAM Role & Policies
# -----------------------------------------------------------------------------

resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda_mysql_private_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

# AWS Managed policy to create and manage ENIs inside your private subnets
resource "aws_iam_role_policy_attachment" "lambda_vpc_execution" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# Policy allowing Lambda to fetch the secret created by RDS
resource "aws_iam_policy" "lambda_secrets_access" {
  name        = "LambdaReadRDSSecretPolicy"
  description = "Allows Lambda to fetch the managed master password secret"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ]
      Resource = aws_db_instance.mysql_db.master_user_secret[0].secret_arn
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_secrets_attach" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_secrets_access.policy_arn
}

# -----------------------------------------------------------------------------
# 6. Lambda Function Definition & Code Packaging
# -----------------------------------------------------------------------------

data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "${path.module}/lambda.zip"
  source {
    content  = <<EOF
import json
import boto3
import os

secrets_client = boto3.client('secretsmanager')

def lambda_handler(event, context):
    secret_arn = os.environ['SECRET_ARN']
    
    # Retrieves secret from Secrets Manager over the VPC Endpoint
    response = secrets_client.get_secret_value(SecretId=secret_arn)
    secret_data = json.loads(response['SecretString'])
    
    # Secret payload contains keys: host, port, username, password, dbname, engine
    return {
        'statusCode': 200,
        'body': json.dumps({
            'status': 'SUCCESS',
            'message': 'Secret successfully fetched via VPC Endpoint without internet!',
            'engine': secret_data.get('engine'),
            'host': secret_data.get('host'),
            'port': secret_data.get('port'),
            'username': secret_data.get('username'),
            'database': secret_data.get('dbname')
        })
    }
EOF
    filename = "index.py"
  }
}

resource "aws_lambda_function" "mysql_connector" {
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  function_name    = "rds_mysql_internal_connector"
  role             = aws_iam_role.lambda_exec_role.arn
  handler          = "index.lambda_handler"
  runtime          = "python3.11"
  timeout          = 30

  vpc_config {
    subnet_ids         = [aws_subnet.private_subnet_a.id, aws_subnet.private_subnet_b.id]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  environment {
    variables = {
      SECRET_ARN = aws_db_instance.mysql_db.master_user_secret[0].secret_arn
    }
  }

  depends_on = [
    aws_vpc_endpoint.secretsmanager,
    aws_vpc_endpoint.logs,
    aws_iam_role_policy_attachment.lambda_vpc_execution
  ]

  tags = {
    Name = "rds-mysql-internal-connector"
  }
}

# -----------------------------------------------------------------------------
# 7. Outputs
# -----------------------------------------------------------------------------

output "rds_endpoint" {
  description = "RDS MySQL Host/Endpoint"
  value       = aws_db_instance.mysql_db.endpoint
}

output "secret_arn" {
  description = "Secrets Manager Secret ARN generated by RDS"
  value       = aws_db_instance.mysql_db.master_user_secret[0].secret_arn
}

output "lambda_function_name" {
  description = "Name of deployed Lambda function"
  value       = aws_lambda_function.mysql_connector.function_name
}