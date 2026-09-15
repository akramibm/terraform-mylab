output "app_server_ip" {
  description = "Public IP address of the Frontend/Backend host"
  value       = aws_instance.app_server.public_ip
}

output "sonar_server_ip" {
  description = "Public IP address of the SonarQube host"
  value       = aws_instance.sonar_server.public_ip
}

output "web_app_url" {
  description = "Application URL (HTTP port 80)"
  value       = "http://${aws_instance.app_server.public_ip}"
}

output "sonarqube_url" {
  description = "SonarQube Web Console URL"
  value       = "http://${aws_instance.sonar_server.public_ip}:9000"
}

output "rds_mysql_endpoint" {
  description = "Amazon RDS MySQL Endpoint"
  value       = aws_db_instance.mysql_db.endpoint
}