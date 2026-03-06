output "instance_id" {
  description = "The ID of the Tomcat EC2 instance"
  value       = aws_instance.tomcat.id
}

output "instance_public_ip" {
  description = "The public IP address of the Tomcat instance"
  value       = aws_instance.tomcat.public_ip
}

output "instance_private_ip" {
  description = "The private IP address of the Tomcat instance"
  value       = aws_instance.tomcat.private_ip
}

output "tomcat_url" {
  description = "URL to access Tomcat"
  value       = "http://${aws_instance.tomcat.public_ip}:8080"
}

output "security_group_id" {
  description = "The ID of the security group"
  value       = aws_security_group.tomcat_test_sg.id
}

output "iam_role_arn" {
  description = "The ARN of the IAM role"
  value       = aws_iam_role.tomcat_role.arn
}
