variable "aws_region" {
  description = "AWS deployment region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project and resource name prefix"
  type        = string
  default     = "prod-fullstack"
}

variable "github_owner" {
  description = "GitHub account or organization name"
  type        = string
  default     = "akramibm"
}

variable "github_repo_name" {
  description = "GitHub repository name"
  type        = string
  default     = "Java-springboot-project-updated"
}

variable "db_password" {
  description = "Master password for Amazon RDS MySQL"
  type        = string
  sensitive   = true
}

variable "sonar_admin_password" {
  description = "Automated post-boot admin password for SonarQube"
  type        = string
  default     = "SonarProdSecurePass2026!"
  sensitive   = true
}