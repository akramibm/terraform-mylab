variable "env" {

    description = "Environment name"
    type        = list(string)
    default     = ["dev", "qa", "prod"]

  
}