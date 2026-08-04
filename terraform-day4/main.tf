resource "aws_vpc" "my_vpc" {

   cidr_block = "10.0.0.0/16"

}

resource "aws_subnet" "my_subnet" {

   vpc_id     = aws_vpc.my_vpc.id

   cidr_block = "10.0.0.0/24"

}

resource "aws_instance" "my_instance" {

    ami           = "ami-02b64aa047cb5edf5"
    
    instance_type = "t2.medium"
  
}