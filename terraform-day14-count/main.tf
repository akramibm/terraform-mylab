resource "aws_instance" "name" {
    count =  length(var.env)
    ami           = "ami-02b64aa047cb5edf5"
    instance_type = "t2.micro"  

    tags = {
        Name = "ENV-${var.env[count.index]}"
    }

  
}