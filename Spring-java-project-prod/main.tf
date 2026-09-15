output "app_server_ip" {
  description = "Public IP for Frontend and Backend deployment"
  value       = aws_instance.app_server.public_ip
}

output "sonar_server_ip" {
  description = "Public IP for SonarQube Server"
  value       = aws_instance.sonar_server.public_ip
}

output "sonarqube_url" {
  description = "SonarQube Web Console URL"
  value       = "http://${aws_instance.sonar_server.public_ip}:9000"
}

output "web_app_url" {
  description = "Production Frontend URL"
  value       = "http://${aws_instance.app_server.public_ip}"
}

output "mysql_endpoint" {
  description = "RDS MySQL Endpoint"
  value       = aws_db_instance.mysql_db.endpoint
}

output "github_actions_role_arn" {
  description = "OIDC IAM Role ARN for GitHub Actions"
  value       = aws_iam_role.github_actions_role.arn
}