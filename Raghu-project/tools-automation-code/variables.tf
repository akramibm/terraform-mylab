variable "tools" {

    description = "List of tools to be installed"

    default = {

     vault = {

        instance_type = "t3.small"
        policy_resource_list = []
      }

      gocd = {
      instance_type        = "t3.medium"
      policy_resource_list = []
    }




    }
  
}

variable "zone_id" {
  description = "The ID of the zone where the resources will be created"
  default     = "Z072984912HXMKS39INCC"
}
variable "ssh_password" {
  type        = string
  description = "Root input for SSH password"
  sensitive   = true
}

variable "ssh_user" {
  type        = string
  description = "SSH login username"
  default     = "ec2-user"
}
