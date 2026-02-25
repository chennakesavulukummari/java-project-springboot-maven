# ==============================================================================
# Data Sources
# ==============================================================================

# Latest Amazon Linux 2023 AMI (used when no AMI ID is provided)
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# ==============================================================================
# Locals
# ==============================================================================
locals {
  app_ami_id = var.app_ami_id != "" ? var.app_ami_id : data.aws_ami.amazon_linux.id
  db_ami_id  = var.db_ami_id != "" ? var.db_ami_id : data.aws_ami.amazon_linux.id

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

# ==============================================================================
# Tomcat Application Server (App Subnet)
# ==============================================================================
resource "aws_instance" "tomcat_server" {
  ami                    = local.app_ami_id
  instance_type          = var.app_instance_type
  subnet_id              = var.app_subnet_id
  key_name               = var.key_pair_name
  vpc_security_group_ids = var.app_security_group_ids
  iam_instance_profile   = var.iam_instance_profile
  user_data              = file("tomcat-user-data.sh")

  root_block_device {
    volume_size           = var.app_volume_size
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-tomcat-server"
    Role = "application-server"
  })

  lifecycle {
    ignore_changes = [ami]
  }
}

# ==============================================================================
# MySQL Database Server (DB Private Subnet)
# ==============================================================================
resource "aws_instance" "mysql_server" {
  ami                    = local.db_ami_id
  instance_type          = var.db_instance_type
  subnet_id              = var.db_subnet_id
  key_name               = var.key_pair_name
  vpc_security_group_ids = var.db_security_group_ids
  iam_instance_profile   = var.iam_instance_profile
  user_data              = file("${path.module}/mysql-user-data.sh")

  root_block_device {
    volume_size           = var.db_volume_size
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-mysql-server"
    Role = "database-server"
  })

  lifecycle {
    ignore_changes = [ami]
  }
}
