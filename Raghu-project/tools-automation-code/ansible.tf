resource "null_resource" "ansible_run" {
  for_each = module.tools

  triggers = {
    instance_id = each.value.instance_id
    task_hash   = filemd5("roles/gocd/tasks/main.yml")
  }

  connection {
    type     = "ssh"
    user     = var.ssh_user
    password = var.ssh_password
    host     = each.value.public_ip
    timeout  = "5m"
  }

  provisioner "remote-exec" {
    inline = [
      "rm -rf /home/${var.ssh_user}/roles /home/${var.ssh_user}/tools.yml"
    ]
  }

  provisioner "file" {
    source      = "tools.yml"
    destination = "/home/${var.ssh_user}/tools.yml"
  }

  provisioner "file" {
    source      = "roles"
    destination = "/home/${var.ssh_user}/roles"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo dnf install -y ansible-core python3-pip || sudo yum install -y ansible",
      "ansible-playbook -i 'localhost,' -c local /home/${var.ssh_user}/tools.yml -e tool_name=${each.key} -b"
    ]
  }
}
