output "public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.name.public_ip
}

output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.name.id
}

output "url" {
  description = "URL for the web interface"
  value       = "http://${aws_instance.name.public_ip}:8153"
}
