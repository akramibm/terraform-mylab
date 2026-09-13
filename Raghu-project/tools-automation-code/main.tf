module "tools" {
  for_each = var.tools
  source = "./module"
   
    tool_name = each.key
    instance_type = each.value["instance_type"]
    policy_resource_list = each.value["policy_resource_list"]
    zone_id = var.zone_id 

    ssh_password = var.ssh_password
    ssh_user     = var.ssh_user

}