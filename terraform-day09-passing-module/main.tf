module "name" {
source = "../terraform-day9-module"
ami = "ami-02b64aa047cb5edf5"   
instance_type = "t2.micro"

tags = {
 Name = "my-ec2-instance-module"    
}

}