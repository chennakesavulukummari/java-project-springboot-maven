output "instance_id" {
  description = "The ID of the docker EC2 instance"
  value       = aws_instance.docker.id
}

output "instance_public_ip" {
  description = "The public IP address of the docker instance"
  value       = aws_instance.docker.public_ip
}

output "instance_private_ip" {
  description = "The private IP address of the docker instance"
  value       = aws_instance.docker.private_ip
}

output "docker_url" {
  description = "URL to access docker"
  value       = "http://${aws_instance.docker.public_ip}:8080"
}

output "security_group_id" {
  description = "The ID of the security group"
  value       = aws_security_group.docker_test_sg.id
}

output "iam_role_arn" {
  description = "The ARN of the IAM role"
  value       = aws_iam_role.docker_role.arn
}
