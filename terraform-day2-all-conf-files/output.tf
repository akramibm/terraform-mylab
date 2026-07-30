output "public_ip" {
  
  value = aws_instance.name.public_ip
}

output "private_ip" {
  
  value = aws_instance.name.private_ip
}

output "subnet_id" {
  
  value = aws_instance.name.subnet_id
}

output "vpc_security_group_ids" {
  
  value = aws_instance.name.vpc_security_group_ids
}