variable "ami" {
    description = "The AMI ID to use for the EC2 instance"
    type        = string   
    default     = "" # Example AMI ID, replace with a valid one for your region
}

variable "instance_type" {
    description = "The instance type for the EC2 instance"
    type        = string
    default     = ""
}

variable "tags" {
    description = "Tags to apply to the EC2 instance"
    type        = map(string)
    default     = {}
}
