


terraform {

    backend "s3" {
        bucket = "mybucket162799999"
        key    = "tools-automation-code/terraform.tfstate"
        region = "us-east-1"
    }
  
}