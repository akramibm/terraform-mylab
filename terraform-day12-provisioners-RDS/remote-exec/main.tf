terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

resource "aws_vpc" "main" {
  cidr_block           = "10.20.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "rds-provisioner-vpc"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "rds-provisioner-igw"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.20.1.0/24"
  availability_zone       = var.availability_zone_a
  map_public_ip_on_launch = true

  tags = {
    Name = "rds-provisioner-public-subnet"
  }
}

resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.20.11.0/24"
  availability_zone = var.availability_zone_a

  tags = {
    Name = "rds-provisioner-private-subnet-a"
  }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.20.12.0/24"
  availability_zone = var.availability_zone_b

  tags = {
    Name = "rds-provisioner-private-subnet-b"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "ec2" {
  name        = "rds-provisioner-ec2-sg"
  description = "Allow SSH access to the RDS client instance"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_allowed_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "rds" {
  name        = "rds-provisioner-db-sg"
  description = "Allow MySQL only from the EC2 client"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "MySQL from EC2"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2.id]
  }
}

resource "aws_db_subnet_group" "main" {
  name       = "rds-provisioner-subnet-group"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]

  tags = {
    Name = "rds-provisioner-subnet-group"
  }
}

resource "aws_db_instance" "mysql" {
  identifier             = "rds-provisioner-mysql"
  allocated_storage      = 20
  engine                 = "mysql"
  instance_class         = var.db_instance_class
  db_name                = "appdb"
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false
  skip_final_snapshot    = var.skip_final_snapshot

  tags = {
    Name = "rds-provisioner-mysql"
  }
}

resource "aws_instance" "rds_client" {
  ami                         = var.ami_id
  instance_type               = var.ec2_instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.ec2.id]
  key_name                    = var.key_name
  associate_public_ip_address = true

  tags = {
    Name = "rds-provisioner-client"
  }
}

resource "null_resource" "run_test_sql" {
  triggers = {
    ec2_instance_id = aws_instance.rds_client.id
    rds_endpoint    = aws_db_instance.mysql.address
    test_sql_hash   = filesha256("${path.module}/test.sql")
  }

  connection {
    type        = "ssh"
    host        = aws_instance.rds_client.public_ip
    user        = var.ssh_user
    private_key = file(pathexpand(var.private_key_path))
  }

  provisioner "file" {
    source      = "${path.module}/test.sql"
    destination = "/tmp/test.sql"
  }

  provisioner "remote-exec" {
    inline = [
      "if command -v dnf >/dev/null 2>&1; then sudo dnf install -y mariadb105 || sudo dnf install -y mariadb; elif command -v yum >/dev/null 2>&1; then sudo yum install -y mariadb; else sudo apt-get update -y && sudo apt-get install -y mysql-client; fi",
      "MYSQL_PWD='${var.db_password}' mysql --host=${aws_db_instance.mysql.address} --port=3306 --user=${var.db_username} < /tmp/test.sql",
    ]
  }

  depends_on = [
    aws_db_instance.mysql,
    aws_route_table_association.public,
  ]
}

output "rds_endpoint" {
  description = "Private RDS endpoint used by the EC2 provisioner."
  value       = aws_db_instance.mysql.address
}

output "ec2_public_ip" {
  description = "Public IP address of the EC2 RDS client."
  value       = aws_instance.rds_client.public_ip
}
