variable "aws_region" {
  description = "AWS region in which to create the VPC."
  type        = string
  default     = "us-east-1a"
}

variable "vpc_cidr_block" {
  description = "CIDR block assigned to the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "vpc_name" {
  description = "Name tag for the VPC."
  type        = string
  default     = "terraform-vpc"
}

variable "availability_zone" {
  description = "Availability Zone for the subnets."
  type        = string
  default     = "us-east-1a"
}

variable "public_subnet_cidr_block" {
  description = "CIDR block assigned to the public subnet."
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr_block" {
  description = "CIDR block assigned to the private subnet."
  type        = string
  default     = "10.0.2.0/24"
}

variable "ami_id" {
  description = "AMI ID for the EC2 instance; choose an AMI available in aws_region."
  type        = string
  default     = "ami-02b64aa047cb5edf5"
}

variable "instance_type" {
  description = "EC2 instance type."
  type        = string
  default     = "t2.micro"
}

variable "ssh_user" {
  description = "SSH user for the AMI used by the EC2 instance."
  type        = string
  default     = "ec2-user"
}

variable "private_key_path" {
  description = "Path to the private SSH key matching the AWS key pair."
  type        = string
  default     = "~/.ssh/RDS_key.pem"
}

variable "key_name" {
  description = "Name of an existing EC2 key pair in AWS."
  type        = string
  default     = "RDS_key"
}
