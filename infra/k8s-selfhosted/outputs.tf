# Outputs for Self-Hosted Kubernetes Infrastructure

output "master_cp_public_ip" {
  description = "Public IP address of Master Control Plane node"
  value       = aws_instance.master_cp.public_ip
}

output "master_cp_private_ip" {
  description = "Private IP address of Master Control Plane node"
  value       = aws_instance.master_cp.private_ip
}

output "slave_cp_public_ip" {
  description = "Public IP address of Slave Control Plane node"
  value       = aws_instance.slave_cp.public_ip
}

output "slave_cp_private_ip" {
  description = "Private IP address of Slave Control Plane node"
  value       = aws_instance.slave_cp.private_ip
}

output "worker_linux_public_ip" {
  description = "Public IP address of Linux Worker node"
  value       = aws_instance.worker_linux.public_ip
}

output "worker_linux_private_ip" {
  description = "Private IP address of Linux Worker node"
  value       = aws_instance.worker_linux.private_ip
}

output "worker_windows_public_ip" {
  description = "Public IP address of Windows Worker node"
  value       = aws_instance.worker_windows.public_ip
}

output "worker_windows_private_ip" {
  description = "Private IP address of Windows Worker node"
  value       = aws_instance.worker_windows.private_ip
}

output "db_node_private_ip" {
  description = "Private IP address of Database node"
  value       = aws_instance.db_node.private_ip
}

output "db_volume_id" {
  description = "EBS volume ID for database storage"
  value       = aws_ebs_volume.database_storage.id
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.k8s.id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = aws_vpc.k8s.cidr_block
}

output "public_subnet_1_id" {
  description = "Public subnet 1 ID"
  value       = aws_subnet.public_1.id
}

output "public_subnet_2_id" {
  description = "Public subnet 2 ID"
  value       = aws_subnet.public_2.id
}

output "private_subnet_id" {
  description = "Private subnet ID"
  value       = aws_subnet.private.id
}

output "control_plane_sg_id" {
  description = "Security group ID for control plane nodes"
  value       = aws_security_group.control_plane.id
}

output "worker_nodes_sg_id" {
  description = "Security group ID for worker nodes"
  value       = aws_security_group.worker_nodes.id
}

output "database_sg_id" {
  description = "Security group ID for database nodes"
  value       = aws_security_group.database.id
}

output "nat_gateway_ip" {
  description = "Public IP of NAT Gateway (Elastic IP)"
  value       = aws_eip.nat_gateway.public_ip
}

output "cluster_name" {
  description = "Kubernetes cluster name"
  value       = var.cluster_name
}

output "pod_cidr" {
  description = "CIDR block for Kubernetes pods"
  value       = var.pod_cidr
}

output "service_cidr" {
  description = "CIDR block for Kubernetes services"
  value       = var.service_cidr
}

output "bootstrap_token" {
  description = "Bootstrap token for joining nodes to cluster"
  value       = random_string.bootstrap_token.result
  sensitive   = true
}

# ============================================================================
# Connection Information for Debugging
# ============================================================================

output "master_cp_connection_info" {
  description = "SSH connection information for Master Control Plane"
  value       = "ssh -i <your-key.pem> ubuntu@${aws_instance.master_cp.public_ip}"
}

output "slave_cp_connection_info" {
  description = "SSH connection information for Slave Control Plane"
  value       = "ssh -i <your-key.pem> ubuntu@${aws_instance.slave_cp.public_ip}"
}

output "worker_linux_connection_info" {
  description = "SSH connection information for Linux Worker"
  value       = "ssh -i <your-key.pem> ubuntu@${aws_instance.worker_linux.public_ip}"
}

output "worker_windows_connection_info" {
  description = "RDP connection information for Windows Worker"
  value       = "RDP to ${aws_instance.worker_windows.public_ip} (use AWS Systems Manager Session Manager or retrieve password from EC2 console)"
}

output "db_node_connection_info" {
  description = "SSH connection information for Database Node (via bastion/NAT)"
  value       = "ssh -i <your-key.pem> ubuntu@${aws_instance.db_node.private_ip}"
}
