#create vpc
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = var.vpc_name
  }
}

# Public subnet: instances launched here receive public IP addresses.
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr_block
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.vpc_name}-public-subnet"
  }
}

# Private subnet: instances launched here do not receive public IP addresses.
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr_block
  availability_zone = var.availability_zone

  tags = {
    Name = "${var.vpc_name}-private-subnet"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.vpc_name}-igw"
  }
}

# Public route table: routes internet traffic through the Internet Gateway.
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.vpc_name}-public-route-table"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Private route table: has only the VPC's default local route.
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name = "${var.vpc_name}-private-route-table"
  }
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

# A NAT Gateway lets private-subnet resources access the internet outbound.
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "${var.vpc_name}-nat-eip"
  }
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id

  tags = {
    Name = "${var.vpc_name}-nat-gateway"
  }

  depends_on = [aws_internet_gateway.main]
}

# Allows web traffic and SSH administration for resources in this VPC.
resource "aws_security_group" "ssh_http" {
  name        = "${var.vpc_name}-ssh-http-sg"
  description = "Allow SSH and HTTP inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.vpc_name}-ssh-http-sg"
  }
}

resource "aws_instance" "web" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.ssh_http.id]
  key_name                    = var.key_name
  associate_public_ip_address = true

  user_data = <<-EOF
    #!/bin/bash
    set -e

    if command -v dnf >/dev/null 2>&1; then
      dnf install -y httpd
      systemctl enable --now httpd
    elif command -v yum >/dev/null 2>&1; then
      yum install -y httpd
      systemctl enable --now httpd
    elif command -v apt-get >/dev/null 2>&1; then
      apt-get update -y
      DEBIAN_FRONTEND=noninteractive apt-get install -y apache2
      systemctl enable --now apache2
    fi

    rm -f /var/www/html/index.html /var/www/html/index.htm
    echo '<!DOCTYPE html><html><head><title>Terraform Web Server</title></head><body><h1>Welcome to my Terraform web server!</h1><p>This custom page was deployed with EC2 user data.</p></body></html>' > /var/www/html/index.html
  EOF

  tags = {
    Name = "${var.vpc_name}-web-server"
  }

  # connection {
  #   type        = "ssh"
  #   host        = self.public_ip
  #   user        = var.ssh_user
  #   private_key = file(pathexpand(var.private_key_path))
  # }

  # provisioner "file" {
  #   source      = "${path.module}/File10"
  #   destination = "/tmp/File10"
  # }

  # provisioner "remote-exec" {
  #   inline = [
  #     "sudo mkdir -p /opt/terraform",
  #     "sudo mv /tmp/File10 /opt/terraform/File10",
  #     "sudo chmod 644 /opt/terraform/File10",
  #   ]
  # }

  # provisioner "local-exec" {
  #   command = "echo ${self.public_ip} > instance_public_ip.txt"
  # }
}
