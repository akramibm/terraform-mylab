variable "env" {

    description = "Environment name"
    type        = list(string)
    default     = ["Dev", "QA", "Prod"]

  
}