# Variables for Self-Hosted Kubernetes Cluster

# ============================================================================
# AWS Configuration
# ============================================================================

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

# ============================================================================
# Cluster Configuration
# ============================================================================

variable "cluster_name" {
  description = "Name of the Kubernetes cluster"
  type        = string
  default     = "k8s-selfhosted"
  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.cluster_name))
    error_message = "Cluster name must start and end with alphanumeric characters and contain only lowercase letters, numbers, and hyphens."
  }
}

# ============================================================================
# Network Configuration
# ============================================================================

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
}

variable "public_subnet_1_cidr" {
  description = "CIDR block for public subnet 1"
  type        = string
  default     = "10.0.1.0/24"
  validation {
    condition     = can(cidrhost(var.public_subnet_1_cidr, 0))
    error_message = "Public subnet 1 CIDR must be a valid IPv4 CIDR block."
  }
}

variable "public_subnet_2_cidr" {
  description = "CIDR block for public subnet 2"
  type        = string
  default     = "10.0.2.0/24"
  validation {
    condition     = can(cidrhost(var.public_subnet_2_cidr, 0))
    error_message = "Public subnet 2 CIDR must be a valid IPv4 CIDR block."
  }
}

variable "private_subnet_cidr" {
  description = "CIDR block for private subnet"
  type        = string
  default     = "10.0.3.0/24"
  validation {
    condition     = can(cidrhost(var.private_subnet_cidr, 0))
    error_message = "Private subnet CIDR must be a valid IPv4 CIDR block."
  }
}

variable "pod_cidr" {
  description = "CIDR block for Kubernetes pods (used by CNI)"
  type        = string
  default     = "172.16.0.0/12"
}

variable "service_cidr" {
  description = "CIDR block for Kubernetes services"
  type        = string
  default     = "10.32.0.0/24"
}

# ============================================================================
# Security Configuration
# ============================================================================

variable "ssh_allowed_cidrs" {
  description = "CIDR blocks allowed for SSH access"
  type        = list(string)
  default     = ["0.0.0.0/0"] # Change this to your IP for production
}

# ============================================================================
# EC2 Instance Configuration
# ============================================================================

variable "master_instance_type" {
  description = "Instance type for Kubernetes master nodes"
  type        = string
  default     = "t3.medium"
  validation {
    condition     = contains(["t3.medium", "t3.large", "t3.xlarge", "t3.2xlarge", "m5.large", "m5.xlarge"], var.master_instance_type)
    error_message = "Instance type must be suitable for Kubernetes control plane nodes."
  }
}

variable "worker_instance_type" {
  description = "Instance type for Kubernetes worker nodes"
  type        = string
  default     = "t3.large"
  validation {
    condition     = contains(["t3.medium", "t3.large", "t3.xlarge", "t3.2xlarge", "m5.large", "m5.xlarge"], var.worker_instance_type)
    error_message = "Instance type must be suitable for Kubernetes worker nodes."
  }
}

variable "db_instance_type" {
  description = "Instance type for database node"
  type        = string
  default     = "t3.large"
  validation {
    condition     = contains(["t3.medium", "t3.large", "t3.xlarge", "t3.2xlarge", "m5.large", "m5.xlarge"], var.db_instance_type)
    error_message = "Instance type must be suitable for database nodes."
  }
}

# ============================================================================
# Tags
# ============================================================================

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Project = "K8s-SelfHosted"
    Team    = "DevOps"
  }
}
