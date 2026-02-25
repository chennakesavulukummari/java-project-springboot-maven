# ==============================================================================
# General
# ==============================================================================
variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used for tagging and naming"
  type        = string
  default     = "java-springboot-app"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

# ==============================================================================
# Existing Resources
# ==============================================================================
variable "vpc_id" {
  description = "Existing VPC ID"
  type        = string
}

variable "app_subnet_id" {
  description = "Existing subnet ID for the Tomcat application server"
  type        = string
}

variable "db_subnet_id" {
  description = "Existing private subnet ID for the MySQL database server"
  type        = string
}

variable "key_pair_name" {
  description = "Existing EC2 key pair name for SSH access"
  type        = string
}

variable "app_security_group_ids" {
  description = "Existing security group IDs for the Tomcat app server"
  type        = list(string)
}

variable "db_security_group_ids" {
  description = "Existing security group IDs for the MySQL db server"
  type        = list(string)
}

variable "iam_instance_profile" {
  description = "Existing IAM instance profile name for EC2 instances"
  type        = string
}

# ==============================================================================
# Tomcat App Server
# ==============================================================================
variable "app_instance_type" {
  description = "EC2 instance type for the Tomcat application server"
  type        = string
  default     = "t3.medium"
}

variable "app_volume_size" {
  description = "Root volume size (GB) for the Tomcat app server"
  type        = number
  default     = 20
}

variable "app_ami_id" {
  description = "AMI ID for the Tomcat app server (leave empty to use latest Amazon Linux 2023)"
  type        = string
  default     = ""
}

# ==============================================================================
# MySQL DB Server
# ==============================================================================
variable "db_instance_type" {
  description = "EC2 instance type for the MySQL database server"
  type        = string
  default     = "t3.medium"
}

variable "db_volume_size" {
  description = "Root volume size (GB) for the MySQL db server"
  type        = number
  default     = 30
}

variable "db_ami_id" {
  description = "AMI ID for the MySQL db server (leave empty to use latest Amazon Linux 2023)"
  type        = string
  default     = ""
}
