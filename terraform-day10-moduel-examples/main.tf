module "name" {

    source = "github.com/akramibm/terraform-aws-s3-bucket.git"
    acl = var.acl

    bucket = var.bucket
    control_object_ownership = var.control_object_ownership
    object_ownership = var.object_ownership

  versioning = {
    enabled = var.versioning["enabled"]
  }
}


