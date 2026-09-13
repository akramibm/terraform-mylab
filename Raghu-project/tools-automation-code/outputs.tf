output "tools_public_ips" {
  description = "Public IP addresses for all provisioned tools"
  value       = { for tool_name, mod in module.tools : tool_name => mod.public_ip }
}

output "tools_instance_ids" {
  description = "EC2 Instance IDs for all provisioned tools"
  value       = { for tool_name, mod in module.tools : tool_name => mod.instance_id }
}

output "gocd_url" {
  description = "Web interface URL for GoCD"
  value       = contains(keys(module.tools), "gocd") ? module.tools["gocd"].url : null
}
