# variables.pkr.hcl - Shared variables for all K8s images

variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "AWS region to build images in"
}

variable "instance_type_linux" {
  type    = string
  default = "t3.medium"
}

variable "instance_type_windows" {
  type    = string
  default = "t3.large"
}

variable "kubernetes_version" {
  type        = string
  default     = "1.34"
  description = "Kubernetes version to install"
}

variable "containerd_version" {
  type    = string
  default = "1.7.11"
}

variable "cni_plugins_version" {
  type    = string
  default = "1.4.0"
}

variable "crictl_version" {
  type    = string
  default = "1.29.0"
}

variable "calico_version" {
  type    = string
  default = "3.27.0"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "vpc_id" {
  type        = string
  default     = "vpc-0305c51d2febe0d64"
  description = "VPC ID to launch builder instance (leave empty for default VPC)"
}

variable "subnet_id" {
  type        = string
  default     = "subnet-0ab7ef12823c1b8c3"
  description = "Subnet ID to launch builder instance"
}

locals {
  timestamp = formatdate("YYYYMMDD-hhmmss", timestamp())
  common_tags = {
    Environment       = var.environment
    Builder           = "Packer"
    KubernetesVersion = var.kubernetes_version
    BuildDate         = local.timestamp
  }
}