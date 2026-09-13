data "aws_ami" "ami" {
  #most_recent      = true
  #name_regex       = "RHEL-9-DevOps-Practice"
  owners           = ["973714476881"]
  filter {
    name   = "image-id"
    values = ["ami-0220d79f3f480ecf5"]
  }

}

data "aws_security_group" "selected" {
  name = "All-traffic"
}
