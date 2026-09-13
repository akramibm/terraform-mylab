variable "tool_name" {}
variable "instance_type" {}
variable "policy_resource_list" {}
variable "zone_id" {}
variable "dummy_policy" {
  default = ["ec2:DescribeInstanceTypes"]
}

variable "ssh_password" {
  type      = string
  sensitive = true
}

variable "ssh_user" {
  type    = string
  default = "ec2-user"
}
