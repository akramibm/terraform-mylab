terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# The GitHub provider uses the GITHUB_TOKEN environment variable in CI
provider "github" {
  owner = var.github_owner
}

# --- 1. Zero-Touch SSH Key Pair Generation ---
resource "tls_private_key" "deployer_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = "${var.project_name}-deployer-key"
  public_key = tls_private_key.deployer_key.public_key_openssh
}

# --- 2. Networking (VPC, Subnets, Gateways) ---
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "${var.project_name}-vpc" }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.project_name}-igw" }
}

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true
  tags                    = { Name = "${var.project_name}-public-subnet" }
}

resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.10.0/24"
  availability_zone = "${var.aws_region}a"
  tags              = { Name = "${var.project_name}-private-subnet-a" }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = "${var.aws_region}b"
  tags              = { Name = "${var.project_name}-private-subnet-b" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = { Name = "${var.project_name}-public-rt" }
}

resource "aws_route_table_association" "pub_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

# --- 3. Security Groups ---
resource "aws_security_group" "app_sg" {
  name        = "${var.project_name}-app-sg"
  description = "Security group for App Server (Frontend & Backend)"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Frontend HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Spring Boot Port"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-app-sg" }
}

resource "aws_security_group" "sonar_sg" {
  name        = "${var.project_name}-sonar-sg"
  description = "Security group for SonarQube Server"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SonarQube Web Console"
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-sonar-sg" }
}

resource "aws_security_group" "db_sg" {
  name        = "${var.project_name}-db-sg"
  description = "MySQL access restricted to App Server"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "MySQL from App SG only"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id]
  }

  tags = { Name = "${var.project_name}-db-sg" }
}

# --- 4. Amazon RDS MySQL ---
resource "aws_db_subnet_group" "db_subs" {
  name       = "${var.project_name}-db-subnets"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]
}

resource "aws_db_parameter_group" "mysql_params" {
  name   = "${var.project_name}-mysql8-params"
  family = "mysql8.0"

  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }

  parameter {
    name  = "collation_server"
    value = "utf8mb4_unicode_ci"
  }
}

resource "aws_db_instance" "mysql_db" {
  identifier             = "${var.project_name}-mysql"
  allocated_storage      = 20
  max_allocated_storage  = 50
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  db_name                = "appdb"
  username               = "admin"
  password               = var.db_password
  parameter_group_name   = aws_db_parameter_group.mysql_params.name
  db_subnet_group_name   = aws_db_subnet_group.db_subs.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  skip_final_snapshot    = true
}

# --- 5. EC2 Instances ---
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

# App Server: Runs Nginx + Spring Boot (Systemd)
resource "aws_instance" "app_server" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = "t3.small"
  key_name                    = aws_key_pair.generated_key.key_name
  subnet_id                   = aws_subnet.public_a.id
  vpc_security_group_ids      = [aws_security_group.app_sg.id]
  associate_public_ip_address = true

  root_block_device {
    volume_size           = 25
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  user_data = <<-EOF
    #!/bin/bash
    set -e

    dnf update -y
    dnf install -y java-17-amazon-corretto-devel git nginx mariadb105

    useradd -m -s /bin/bash appuser
    mkdir -p /opt/backend /usr/share/nginx/html
    chown -R appuser:appuser /opt/backend
    chown -R appuser:appuser /usr/share/nginx/html

    cat << 'ENVFILE' > /opt/backend/application.env
    SPRING_DATASOURCE_URL=jdbc:mysql://${aws_db_instance.mysql_db.endpoint}/appdb?useSSL=true&requireSSL=false&serverTimezone=UTC
    SPRING_DATASOURCE_USERNAME=admin
    SPRING_DATASOURCE_PASSWORD=${var.db_password}
    ENVFILE
    chown appuser:appuser /opt/backend/application.env
    chmod 600 /opt/backend/application.env

    cat << 'SERVICE' > /etc/systemd/system/backend.service
    [Unit]
    Description=Spring Boot Production Application
    After=syslog.target network.target

    [Service]
    User=appuser
    WorkingDirectory=/opt/backend
    EnvironmentFile=/opt/backend/application.env
    ExecStart=/usr/bin/java -jar -Dspring.profiles.active=prod /opt/backend/app.jar
    SuccessExitStatus=143
    Restart=always
    RestartSec=10

    [Install]
    WantedBy=multi-user.target
    SERVICE
    systemctl daemon-reload
    systemctl enable backend

    cat << 'NGINX' > /etc/nginx/conf.d/production.conf
    server {
        listen 80;
        server_name _;

        root /usr/share/nginx/html;
        index index.html;

        location / {
            try_files \$uri \$uri/ /index.html;
        }

        location /api/ {
            proxy_pass http://127.0.0.1:8080/;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        }
    }
    NGINX
    systemctl enable nginx
    systemctl restart nginx
  EOF

  tags = { Name = "${var.project_name}-app-server" }
}

# Dedicated SonarQube Server: Headless Setup & Token Generation
resource "aws_instance" "sonar_server" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = "t3.medium"
  key_name                    = aws_key_pair.generated_key.key_name
  subnet_id                   = aws_subnet.public_a.id
  vpc_security_group_ids      = [aws_security_group.sonar_sg.id]
  associate_public_ip_address = true

  root_block_device {
    volume_size           = 30
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  user_data = <<-EOF
    #!/bin/bash
    set -e

    sysctl -w vm.max_map_count=262144
    echo "vm.max_map_count=262144" >> /etc/sysctl.d/99-sonarqube.conf

    cat << 'LIMITS' > /etc/security/limits.d/99-sonar.conf
    sonar soft nofile 131072
    sonar hard nofile 131072
    sonar soft nproc 8192
    sonar hard nproc 8192
    LIMITS

    dnf update -y
    dnf install -y java-17-amazon-corretto-devel wget unzip jq

    useradd -m -s /bin/bash sonar 2>/dev/null || true
    cd /opt
    wget -q https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-10.7.0.96327.zip -O sonarqube.zip
    unzip -q sonarqube.zip
    mv sonarqube-10.7.* sonarqube
    rm -f sonarqube.zip

    chown -R sonar:sonar /opt/sonarqube
    chmod -R 755 /opt/sonarqube

    cat << 'SONARSRV' > /etc/systemd/system/sonarqube.service
    [Unit]
    Description=SonarQube service
    After=network.target

    [Service]
    Type=forking
    ExecStart=/opt/sonarqube/bin/linux-x86-64/sonar.sh start
    ExecStop=/opt/sonarqube/bin/linux-x86-64/sonar.sh stop
    User=sonar
    Group=sonar
    Restart=always
    LimitNOFILE=131072
    LimitNPROC=8192

    [Install]
    WantedBy=multi-user.target
    SONARSRV

    systemctl daemon-reload
    systemctl enable sonarqube
    systemctl start sonarqube

    # Headless initialization: Poll until SonarQube is operational
    until curl -s -u admin:admin http://localhost:9000/api/system/status | grep -q '"status":"UP"'; do
      sleep 5
    done

    # Headlessly update default password
    curl -s -u admin:admin -X POST "http://localhost:9000/api/users/change_password?login=admin&previousPassword=admin&password=${var.sonar_admin_password}"

    # Generate persistent analysis token
    RESPONSE=$(curl -s -u admin:${var.sonar_admin_password} -X POST "http://localhost:9000/api/user_tokens/generate?name=cicd-zero-touch-token&type=GLOBAL_ANALYSIS_TOKEN")
    echo "$RESPONSE" | jq -r '.token' > /opt/sonarqube/cicd_token.txt
    chown ec2-user:ec2-user /opt/sonarqube/cicd_token.txt
    chmod 644 /opt/sonarqube/cicd_token.txt
  EOF

  tags = { Name = "${var.project_name}-sonar-server" }
}

# --- 6. Zero-Touch Secret Synchronization to GitHub ---
# Write App Server IP
resource "github_actions_secret" "ec2_host" {
  repository      = var.github_repo_name
  secret_name     = "EC2_HOST"
  plaintext_value = aws_instance.app_server.public_ip
}

# Write Generated SSH Private Key
resource "github_actions_secret" "ec2_ssh_key" {
  repository      = var.github_repo_name
  secret_name     = "EC2_SSH_KEY"
  plaintext_value = tls_private_key.deployer_key.private_key_pem
}

# Write SonarQube URL
resource "github_actions_secret" "sonar_host_url" {
  repository      = var.github_repo_name
  secret_name     = "SONAR_HOST_URL"
  plaintext_value = "http://${aws_instance.sonar_server.public_ip}:9000"
}

# Fetch the SonarQube token over SSH once the service is ready
resource "null_resource" "sync_sonar_token" {
  depends_on = [aws_instance.sonar_server]

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = tls_private_key.deployer_key.private_key_pem
      host        = aws_instance.sonar_server.public_ip
    }

    inline = [
      "until [ -f /opt/sonarqube/cicd_token.txt ]; do sleep 5; done",
      "cat /opt/sonarqube/cicd_token.txt > /tmp/sonar_token.txt"
    ]
  }

  provisioner "local-exec" {
    command = <<-EOT
      TOKEN=$(ssh -o StrictHostKeyChecking=no -i - user@${aws_instance.sonar_server.public_ip} "cat /opt/sonarqube/cicd_token.txt" <<< "${tls_private_key.deployer_key.private_key_pem}")
      gh secret set SONAR_TOKEN --body "$TOKEN" --repo ${var.github_owner}/${var.github_repo_name}
    EOT
    environment = {
      GH_TOKEN = var.github_token
    }
  }
}