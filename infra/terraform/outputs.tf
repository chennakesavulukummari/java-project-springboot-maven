# ==============================================================================
# Tomcat App Server Outputs
# ==============================================================================
output "tomcat_instance_id" {
  description = "Instance ID of the Tomcat application server"
  value       = aws_instance.tomcat_server.id
}

output "tomcat_private_ip" {
  description = "Private IP of the Tomcat application server"
  value       = aws_instance.tomcat_server.private_ip
}

output "tomcat_public_ip" {
  description = "Public IP of the Tomcat application server (if assigned)"
  value       = aws_instance.tomcat_server.public_ip
}

# ==============================================================================
# MySQL DB Server Outputs
# ==============================================================================
output "mysql_instance_id" {
  description = "Instance ID of the MySQL database server"
  value       = aws_instance.mysql_server.id
}

output "mysql_private_ip" {
  description = "Private IP of the MySQL database server"
  value       = aws_instance.mysql_server.private_ip
}

# ==============================================================================
# Ansible Inventory (generated for convenience)
# ==============================================================================
output "ansible_inventory" {
  description = "Generated Ansible inventory content"
  value       = <<-EOT

    [tomcat_servers]
    ${aws_instance.tomcat_server.private_ip} ansible_user=ec2-user

    [mysql_servers]
    ${aws_instance.mysql_server.private_ip} ansible_user=ec2-user

  EOT
}
