# Self-Hosted Kubernetes on AWS EC2
# Main Configuration File

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Uncomment and configure for remote state management
  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "k8s-selfhosted/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-locks"
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "K8s-SelfHosted"
      Environment = var.environment
      CreatedBy   = "Terraform"
      CreatedAt   = timestamp()
    }
  }
}


# ============================================================================
# VPC and Networking
# ============================================================================

resource "aws_vpc" "k8s" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.cluster_name}-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "k8s" {
  vpc_id = aws_vpc.k8s.id

  tags = {
    Name = "${var.cluster_name}-igw"
  }
}

# Public Subnets
resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.k8s.id
  cidr_block              = var.public_subnet_1_cidr
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.cluster_name}-public-subnet-1"
    Type = "Public"
  }
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.k8s.id
  cidr_block              = var.public_subnet_2_cidr
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.cluster_name}-public-subnet-2"
    Type = "Public"
  }
}

# Private Subnet for Database
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.k8s.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = "${var.aws_region}c"

  tags = {
    Name = "${var.cluster_name}-private-subnet"
    Type = "Private"
  }
}

# Elastic IPs for NAT Gateway
resource "aws_eip" "nat_gateway" {
  domain = "vpc"

  tags = {
    Name = "${var.cluster_name}-nat-eip"
  }

  depends_on = [aws_internet_gateway.k8s]
}

# NAT Gateway (for private subnet internet access)
resource "aws_nat_gateway" "k8s" {
  allocation_id = aws_eip.nat_gateway.id
  subnet_id     = aws_subnet.public_1.id

  tags = {
    Name = "${var.cluster_name}-nat-gateway"
  }

  depends_on = [aws_internet_gateway.k8s]
}

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.k8s.id

  route {
    cidr_block      = "0.0.0.0/0"
    gateway_id      = aws_internet_gateway.k8s.id
  }

  tags = {
    Name = "${var.cluster_name}-public-rt"
  }
}

# Associate Public Subnets with Public Route Table
resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}

# Private Route Table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.k8s.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.k8s.id
  }

  tags = {
    Name = "${var.cluster_name}-private-rt"
  }
}

# Associate Private Subnet with Private Route Table
resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

# ============================================================================
# Security Groups
# ============================================================================

# Control Plane Security Group
resource "aws_security_group" "control_plane" {
  name        = "${var.cluster_name}-cp-sg"
  description = "Security group for Kubernetes Control Plane nodes"
  vpc_id      = aws_vpc.k8s.id

  # Kubernetes API
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "Kubernetes API Server"
  }

  # etcd client
  ingress {
    from_port   = 2379
    to_port     = 2380
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "etcd client and peer communication"
  }

  # kubelet API
  ingress {
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "kubelet API"
  }

  # Scheduler
  ingress {
    from_port   = 10251
    to_port     = 10251
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "kube-scheduler"
  }

  # Controller Manager
  ingress {
    from_port   = 10252
    to_port     = 10252
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "kube-controller-manager"
  }

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_allowed_cidrs
    description = "SSH access"
  }

  # Outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "${var.cluster_name}-cp-sg"
  }
}

# Worker Node Security Group
resource "aws_security_group" "worker_nodes" {
  name        = "${var.cluster_name}-worker-sg"
  description = "Security group for Kubernetes Worker nodes"
  vpc_id      = aws_vpc.k8s.id

  # kubelet API
  ingress {
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "kubelet API"
  }

  # NodePort services
  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "NodePort services"
  }

  # kube-proxy
  ingress {
    from_port   = 10256
    to_port     = 10256
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "kube-proxy"
  }

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_allowed_cidrs
    description = "SSH access"
  }

  # RDP for Windows nodes
  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = var.ssh_allowed_cidrs
    description = "RDP access for Windows"
  }

  # Inter-pod communication
  ingress {
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.worker_nodes.id]
    description     = "Pod to pod communication"
  }

  # Outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "${var.cluster_name}-worker-sg"
  }
}

# Database Security Group
resource "aws_security_group" "database" {
  name        = "${var.cluster_name}-db-sg"
  description = "Security group for Database nodes"
  vpc_id      = aws_vpc.k8s.id

  # MySQL
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.worker_nodes.id]
    description     = "MySQL from worker nodes"
  }

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_allowed_cidrs
    description = "SSH access"
  }

  # Outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "${var.cluster_name}-db-sg"
  }
}

# ============================================================================
# Data Sources (AMIs)
# ============================================================================

# Ubuntu 22.04 LTS AMI (for Linux nodes)
data "aws_ami" "ubuntu_linux" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Windows Server 2022 Base AMI
data "aws_ami" "windows_2022" {
  most_recent = true
  owners      = ["801119661308"] # Amazon

  filter {
    name   = "name"
    values = ["Windows_Server-2022-English-Core-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ============================================================================
# IAM Role for EC2 instances
# ============================================================================

resource "aws_iam_role" "ec2_k8s_role" {
  name = "${var.cluster_name}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.cluster_name}-ec2-role"
  }
}

# IAM Policy for EC2 instances (EBS, EC2, VPC access)
resource "aws_iam_role_policy" "ec2_k8s_policy" {
  name = "${var.cluster_name}-ec2-policy"
  role = aws_iam_role.ec2_k8s_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeVolumes",
          "ec2:DescribeSnapshots",
          "ec2:CreateTags",
          "ec2:DescribeTags",
          "ec2:CreateVolume",
          "ec2:CreateSnapshot",
          "ec2:DeleteVolume"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "arn:aws:logs:${var.aws_region}:*:*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2_k8s_profile" {
  name = "${var.cluster_name}-ec2-profile"
  role = aws_iam_role.ec2_k8s_role.name
}

# ============================================================================
# EC2 Instances
# ============================================================================

# Master Control Plane
resource "aws_instance" "master_cp" {
  ami                    = data.aws_ami.ubuntu_linux.id
  instance_type          = var.master_instance_type
  subnet_id              = aws_subnet.public_1.id
  vpc_security_group_ids = [aws_security_group.control_plane.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_k8s_profile.name

  # Root volume
  root_block_device {
    volume_type           = "gp3"
    volume_size           = 30
    delete_on_termination = true
    encrypted             = true
  }

  # User data script
  user_data = base64encode(templatefile("${path.module}/user-data/master-cp-init.sh", {
    cluster_name = var.cluster_name
    pod_cidr     = var.pod_cidr
    service_cidr = var.service_cidr
  }))

  associate_public_ip_address = true

  tags = {
    Name              = "${var.cluster_name}-master-cp"
    "K8s-NodeType"    = "control-plane"
    "K8s-ClusterName" = var.cluster_name
  }

  depends_on = [aws_internet_gateway.k8s]
}

# Slave Control Plane
resource "aws_instance" "slave_cp" {
  ami                    = data.aws_ami.ubuntu_linux.id
  instance_type          = var.master_instance_type
  subnet_id              = aws_subnet.public_2.id
  vpc_security_group_ids = [aws_security_group.control_plane.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_k8s_profile.name

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 30
    delete_on_termination = true
    encrypted             = true
  }

  user_data = base64encode(templatefile("${path.module}/user-data/slave-cp-init.sh", {
    cluster_name  = var.cluster_name
    pod_cidr      = var.pod_cidr
    service_cidr  = var.service_cidr
    master_ip     = aws_instance.master_cp.private_ip
  }))

  associate_public_ip_address = true

  tags = {
    Name              = "${var.cluster_name}-slave-cp"
    "K8s-NodeType"    = "control-plane"
    "K8s-ClusterName" = var.cluster_name
  }

  depends_on = [aws_internet_gateway.k8s, aws_instance.master_cp]
}

# Worker Node - Linux
resource "aws_instance" "worker_linux" {
  ami                    = data.aws_ami.ubuntu_linux.id
  instance_type          = var.worker_instance_type
  subnet_id              = aws_subnet.public_1.id
  vpc_security_group_ids = [aws_security_group.worker_nodes.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_k8s_profile.name

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 50
    delete_on_termination = true
    encrypted             = true
  }

  user_data = base64encode(templatefile("${path.module}/user-data/worker-linux-init.sh", {
    cluster_name = var.cluster_name
    master_ip    = aws_instance.master_cp.private_ip
    master_token = random_string.bootstrap_token.result
  }))

  associate_public_ip_address = true

  tags = {
    Name                = "${var.cluster_name}-worker-linux"
    "K8s-NodeType"      = "worker"
    "K8s-ClusterName"   = var.cluster_name
    "K8s-NodeOS"        = "linux"
    "K8s-TierPlacement" = "web,app"
  }

  depends_on = [aws_instance.master_cp]
}

# Worker Node - Windows
resource "aws_instance" "worker_windows" {
  ami                    = data.aws_ami.windows_2022.id
  instance_type          = var.worker_instance_type
  subnet_id              = aws_subnet.public_2.id
  vpc_security_group_ids = [aws_security_group.worker_nodes.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_k8s_profile.name

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 50
    delete_on_termination = true
    encrypted             = true
  }

  user_data = base64encode(templatefile("${path.module}/user-data/worker-windows-init.ps1", {
    cluster_name = var.cluster_name
    master_ip    = aws_instance.master_cp.private_ip
    master_token = random_string.bootstrap_token.result
  }))

  associate_public_ip_address = true
  get_password_data           = true

  tags = {
    Name                = "${var.cluster_name}-worker-windows"
    "K8s-NodeType"      = "worker"
    "K8s-ClusterName"   = var.cluster_name
    "K8s-NodeOS"        = "windows"
    "K8s-TierPlacement" = "app"
  }

  depends_on = [aws_instance.master_cp]
}

# Database Node
resource "aws_instance" "db_node" {
  ami                    = data.aws_ami.ubuntu_linux.id
  instance_type          = var.db_instance_type
  subnet_id              = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.database.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_k8s_profile.name

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 30
    delete_on_termination = true
    encrypted             = true
  }

  user_data = base64encode(templatefile("${path.module}/user-data/db-init.sh", {
    cluster_name = var.cluster_name
  }))

  tags = {
    Name              = "${var.cluster_name}-db-node"
    "K8s-NodeType"    = "database"
    "K8s-ClusterName" = var.cluster_name
  }

  depends_on = [aws_nat_gateway.k8s]
}

# ============================================================================
# EBS Volumes for Database
# ============================================================================

resource "aws_ebs_volume" "database_storage" {
  availability_zone = aws_instance.db_node.availability_zone
  size              = 100
  type              = "gp3"
  encrypted         = true

  tags = {
    Name = "${var.cluster_name}-db-volume"
  }
}

resource "aws_volume_attachment" "database_storage" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.database_storage.id
  instance_id = aws_instance.db_node.id
}

# ============================================================================
# Random Token for Bootstrap
# ============================================================================

resource "random_string" "bootstrap_token" {
  length  = 32
  special = false
  upper   = false
}

# ============================================================================
# Outputs
# ============================================================================

output "master_cp_public_ip" {
  description = "Public IP of Master Control Plane"
  value       = aws_instance.master_cp.public_ip
}

output "master_cp_private_ip" {
  description = "Private IP of Master Control Plane"
  value       = aws_instance.master_cp.private_ip
}

output "slave_cp_public_ip" {
  description = "Public IP of Slave Control Plane"
  value       = aws_instance.slave_cp.public_ip
}

output "slave_cp_private_ip" {
  description = "Private IP of Slave Control Plane"
  value       = aws_instance.slave_cp.private_ip
}

output "worker_linux_public_ip" {
  description = "Public IP of Linux Worker Node"
  value       = aws_instance.worker_linux.public_ip
}

output "worker_linux_private_ip" {
  description = "Private IP of Linux Worker Node"
  value       = aws_instance.worker_linux.private_ip
}

output "worker_windows_public_ip" {
  description = "Public IP of Windows Worker Node"
  value       = aws_instance.worker_windows.public_ip
}

output "db_node_private_ip" {
  description = "Private IP of Database Node"
  value       = aws_instance.db_node.private_ip
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.k8s.id
}

output "vpc_cidr" {
  description = "VPC CIDR"
  value       = aws_vpc.k8s.cidr_block
}

output "cluster_name" {
  description = "Kubernetes Cluster Name"
  value       = var.cluster_name
}

output "bootstrap_token" {
  description = "Bootstrap token for joining nodes"
  value       = random_string.bootstrap_token.result
  sensitive   = true
}
