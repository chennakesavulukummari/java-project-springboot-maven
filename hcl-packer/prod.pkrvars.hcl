# prod.pkrvars.hcl - Production environment variables

aws_region           = "us-east-1"
instance_type_linux  = "t3.medium"
instance_type_windows = "t3.large"
kubernetes_version   = "1.34"
containerd_version   = "1.7.11"
cni_plugins_version  = "1.4.0"
crictl_version       = "1.34.0"
calico_version       = "3.27.0"
environment          = "production"

# Optional: specify VPC/subnet for builder instances
# vpc_id    = "vpc-xxxxxxxxx"
# subnet_id = "subnet-xxxxxxxxx"