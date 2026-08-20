#creation vpc

resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
    

    tags = {
        Name = "dev_vpc"
    } 

}


resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  #map_customer_owned_ip_on_launch = true
  map_public_ip_on_launch = true
  tags = {
    Name = "dev_public_subnet"
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "dev_private_subnet"
  }
}
resource "aws_internet_gateway" "dev_igw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "dev_igw"
  }
}

resource "aws_eip" "dev_nat_eip" {
    domain = "vpc"

  tags = {
    Name = "dev_nat_eip"
  }
}   

resource "aws_nat_gateway" "dev_nat_gw" {
  allocation_id = aws_eip.dev_nat_eip.id
  subnet_id     = aws_subnet.public_subnet.id

  tags = {
    Name = "dev_nat_gw"
  }

  depends_on = [aws_internet_gateway.dev_igw]

}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.dev_igw.id
  }
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.dev_nat_gw.id
  }
}

resource "aws_route_table_association" "public_rt_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "private_rt_assoc" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_security_group" "Dev_SG" {

    vpc_id = aws_vpc.my_vpc.id

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



    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

}

resource "aws_instance" "dev_instance" {
  ami           = var.ami
  instance_type = var.instance_type
  subnet_id     = aws_subnet.public_subnet.id
  security_groups = [aws_security_group.Dev_SG.id]
 associate_public_ip_address = true
  tags = {
    Name = "Bastion_Host"
  }
}

resource "aws_security_group" "private_sg" {
  name        = "private_sg"
  description = "Security group for private instance"
  vpc_id      = aws_vpc.my_vpc.id

   ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        security_groups = [aws_security_group.Dev_SG.id]
    }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] 
}
}

resource "aws_instance" "dev_instance_private" {
  ami           = var.ami
  instance_type = var.instance_type
  subnet_id     = aws_subnet.private_subnet.id
  security_groups = [aws_security_group.private_sg.id]

    tags = {
    Name = "Private_Instance"
  }
}