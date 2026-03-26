output "instance_id" {
  description = "The ID of the ansible EC2 instance"
  value       = aws_instance.ansible_win_instance.id
}

output "instance_public_ip" {
  description = "The public IP address of the ansible instance"
  value       = aws_instance.ansible_win_instance.public_ip
}

output "instance_private_ip" {
  description = "The private IP address of the ansible instance"
  value       = aws_instance.ansible_win_instance.private_ip
}

output "security_group_id" {
  description = "The ID of the security group"
  value       = aws_security_group.ansible_win_sg.id
}

output "iam_role_arn" {
  description = "The ARN of the IAM role"
  value       = aws_iam_role.ansible_role.arn
}
