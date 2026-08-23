variable "acl" {
  description = "The canned ACL to apply. Defaults to 'private'."
  type        = string
  default     = "private"
  
}

variable "bucket" {
  description = "The name of the bucket. If omitted, Terraform will assign a random, unique name."
  type        = string
  default     = "mybucket162799999"
}

variable "control_object_ownership" {
  description = "The bucket owner enforced setting for object ownership. If omitted, Terraform will assign a random, unique name."
  type        = bool
  default     = true
}

variable "object_ownership" {
  description = "The object ownership setting for the bucket. If omitted, Terraform will assign a random, unique name."
  type        = string
  default     = "ObjectWriter"
  
}



variable "versioning" {
  type = object({enabled = bool  })
  default = {
    enabled = true
  }
}
