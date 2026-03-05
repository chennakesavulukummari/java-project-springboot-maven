variable "ami" {
  description = "The AMI to use for the instance"
  type        = string
  default     = "ami-02774d409be696d81"
}

variable "instance_type" {
  description = "The type of instance to use"
  type        = string
  default     = "t3.medium"
}

variable "key_name" {
  description = "The name of the SSH key pair to use for the instance"
  default     = "hyd-sshkeys-win"
}

variable "environment" {
  description = "Environment for the resources (e.g., dev, staging, prod)"
  type        = string
  default     = "test"
}

variable "name" {
  description = "Name of the resource"
  type        = string
  default     = "Tomcat-Server"
}

variable "Created_By" {
  description = "Name of the resource creator"
  type        = string
  default     = "IaC Terraform"
}

variable "project_name" {
  default = "MadeOfMemories"
}

variable "owner_email" {
  description = "Email address of the resource owner"
  type        = string
  default     = "info@madeofmemories.com"
}

variable "resource_prefix" {
  default = "mom"
}
