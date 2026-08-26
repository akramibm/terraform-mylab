variable "aws_region" {
  description = "AWS region in which to create the resources."
  type        = string
  default     = "us-east-1"
}

variable "availability_zone_a" {
  description = "First Availability Zone for the public and private subnets."
  type        = string
  default     = "us-east-1a"
}

variable "availability_zone_b" {
  description = "Second Availability Zone for the RDS subnet group."
  type        = string
  default     = "us-east-1b"
}

variable "ami_id" {
  description = "AMI ID for the EC2 RDS client, available in aws_region."
  type        = string
  default     = "ami-02b64aa047cb5edf5"
}

variable "ec2_instance_type" {
  description = "EC2 instance type for the RDS client."
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "Name of an existing EC2 key pair in AWS."
  type        = string
  default     = "RDS_key"
}

variable "private_key_path" {
  description = "Path to the private key for the EC2 key pair."
  type        = string
  default     = "~/.ssh/RDS_key.pem"

}

variable "ssh_user" {
  description = "SSH username for the selected AMI."
  type        = string
  default     = "ec2-user"
}

variable "ssh_allowed_cidr" {
  description = "CIDR allowed to SSH to the EC2 RDS client. Replace the temporary open default with your public IP /32."
  type        = string
  default     = "0.0.0.0/0"
}

variable "db_username" {
  description = "Master username for the RDS MySQL instance."
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "Master password for the RDS MySQL instance."
  type        = string
  sensitive   = true
  default     = "DevOps321"
}

variable "db_instance_class" {
  description = "RDS DB instance class."
  type        = string
  default     = "db.t3.micro"
}

variable "skip_final_snapshot" {
  description = "Whether to skip the final DB snapshot when destroying this learning environment."
  type        = bool
  default     = true
}
