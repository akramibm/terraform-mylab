terraform {
  backend "s3" {
    
    bucket = "terraform-state-2026-16297"
    key = "terraform.tfstate"
    region = "us-east-1"
    }
}