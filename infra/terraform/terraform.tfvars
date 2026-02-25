# ==============================================================================
# General
# ==============================================================================
aws_region   = "us-east-1"
project_name = "java-springboot-app"
environment  = "dev"

# ==============================================================================
# Existing Resources
# ==============================================================================
vpc_id                 = "vpc-0305c51d2febe0d64"
app_subnet_id          = "subnet-0ab7ef12823c1b8c3"
db_subnet_id           = "subnet-01d078b173a769177"
key_pair_name          = "your-keypair-name"
app_security_group_ids = ["sg-xxxxxxxxxxxxxxxxx"]
db_security_group_ids  = ["sg-xxxxxxxxxxxxxxxxx"]
iam_instance_profile   = "your-instance-profile-name"

# ==============================================================================
# Tomcat App Server
# ==============================================================================
app_instance_type = "t3.medium"
app_volume_size   = 20
# app_ami_id      = ""   # Leave empty for latest Amazon Linux 2023

# ==============================================================================
# MySQL DB Server
# ==============================================================================
db_instance_type = "t3.medium"
db_volume_size   = 30
# db_ami_id      = ""   # Leave empty for latest Amazon Linux 2023
