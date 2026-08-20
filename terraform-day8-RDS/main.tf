#creating RDS multi AZ cluster MYsql db with backup retention of 7 days and creating a redis cluster need two read replicas with 2 subnets and security group

resource "aws_db_instance" "mydb" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  db_name              = "mydb"
  username             = "admin"
  db_subnet_group_name = aws_db_subnet_group.name.name

  vpc_security_group_ids = [aws_security_group.db_sg.id]
  password             = "DevOps321"
  #manage_master_user_password = true
  parameter_group_name = "default.mysql8.0"
  multi_az             = true
  publicly_accessible  = false
  skip_final_snapshot  = true

  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  apply_immediately       = true

  tags_all = {
    Name = "mydb-terraform"
  }
}

resource "aws_vpc" "name" {
    cidr_block = "10.0.0.0/16"

    tags = {
        Name = "my-vpc-terraform"
    }
  
}

resource "aws_subnet" "subnet1" {
  vpc_id                  = aws_vpc.name.id
  cidr_block              = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "my-subnet-1"
  }

}

resource "aws_subnet" "subnet2" {
  vpc_id                  = aws_vpc.name.id
  cidr_block              = "10.0.2.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "my-subnet-2"
  }
}
 

resource "aws_db_subnet_group" "name" {
  name       = "mydb-subnet-group"
  subnet_ids = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]
}

resource "aws_security_group" "db_sg" {
  name        = "mydb-sg"
  description = "Security group for RDS MySQL instance"
  vpc_id      = aws_vpc.name.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]

  }

  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
   
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "mydb-sg-terraform"
    }
}

resource "aws_elasticache_subnet_group" "name" {
    name       = "my-redis-subnet-group"
    subnet_ids = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]

    tags = {
        Name = "my-redis-subnet-group"
    }
  
}

resource "aws_db_instance" "read_replicas" {
  count = 2

  identifier             = "mydb-read-replica-${count.index + 1}"
  instance_class         = "db.t3.micro"
  replicate_source_db    = aws_db_instance.mydb.identifier
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  publicly_accessible    = false
  skip_final_snapshot    = true

  tags = {
    Name = "mydb-read-replica-${count.index + 1}"
  }

  depends_on = [aws_db_instance.mydb]
}

resource "aws_elasticache_cluster" "name" {
    cluster_id = "my-redis-cluster" 
    engine = "redis"
    node_type = "cache.t3.micro" 
    subnet_group_name = aws_elasticache_subnet_group.name.name
    security_group_ids = [aws_security_group.db_sg.id]
    port = 6379
    num_cache_nodes = 1
    tags = {
        Name = "my-redis-cluster"
    }
  
}