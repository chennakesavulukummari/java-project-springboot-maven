# ==============================================================================
# General
# ==============================================================================
variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-south-2"
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
  default = "subnet-0ab7ef12823c1b8c3"
}

variable "db_subnet_id" {
  description = "Existing private subnet ID for the MySQL database server"
  type        = string
  default     = "subnet-0ab7ef12823c1b8c3"

variable "key_pair_name" {
  description = "Existing EC2 key pair name for SSH access"
  type        = string
  default     = "hyd-sshkeys-win"
}

variable "app_security_group_ids" {
  description = "Existing security group IDs for the Tomcat app server"
  type        = list(string)
  default     = ["sg-0fe600418ac7414b8"]
}

variable "db_security_group_ids" {
  description = "Existing security group IDs for the MySQL db server"
  type        = list(string)
  default     = ["sg-0fe600418ac7414b8"]
}

variable "iam_instance_profile" {
  description = "Existing IAM instance profile name for EC2 instances"
  type        = string
  default     = "arn:aws:iam::225989338000:instance-profile/jenkins-instance-profile"
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
  default     = "ami-02774d409be696d81"
}

# ==============================================================================
# MySQL DB Server
# ==============================================================================
# variable "db_instance_type" {
#   description = "EC2 instance type for the MySQL database server"
#   type        = string
#   default     = "t3.medium"
# }

# variable "db_volume_size" {
#   description = "Root volume size (GB) for the MySQL db server"
#   type        = number
#   default     = 30
# }

# variable "db_ami_id" {
#   description = "AMI ID for the MySQL db server (leave empty to use latest Amazon Linux 2023)"
#   type        = string
#   default     = ""
# }
