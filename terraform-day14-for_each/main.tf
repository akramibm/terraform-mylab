resource "aws_instance" "name" {
    for_each = toset(var.env)
    ami           = "ami-02b64aa047cb5edf5"
    instance_type = "t2.micro"  

    tags = {
        Name = "ENV-${each.key}"
  
}
}