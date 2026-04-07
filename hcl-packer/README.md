# Kubernetes Cluster Images with Packer

Project Structure
k8s-packer/
├── k8s-controlplane.pkr.hcl
├── k8s-worker-linux.pkr.hcl
├── k8s-worker-windows.pkr.hcl
├── variables.pkr.hcl
├── scripts/
│   ├── linux/
│   │   ├── common-setup.sh
│   │   ├── install-containerd.sh
│   │   ├── install-k8s-components.sh
│   │   └── controlplane-setup.sh
│   └── windows/
│       ├── install-containerd.ps1
│       └── install-k8s-components.ps1
└── prod.pkrvars.hcl

AWS_PROFILE=cf36 packer validate -var-file="prod.pkrvars.hcl" .

Available Builds:

Build Name	Source	Provisioners	Instance Type	Description
k8s-controlplane	amazon-ebs	12 shell provisioners	t3.medium	Kubernetes 1.34 Control Plane - Ubuntu 22.04
k8s-worker-linux	amazon-ebs	11 shell provisioners	t3.medium	Kubernetes 1.34 Linux Worker - Ubuntu 22.04
k8s-worker-windows	amazon-ebs	12 powershell provisioners	t3.large	Kubernetes 1.34 Windows Worker - Server 2022

Packer Lifecycle Commands:
To execute Packer builds, you can run:

# Validate (already done and passed ✅)
packer validate -var-file="prod.pkrvars.hcl" .

# Build all images
packer build -var-file="prod.pkrvars.hcl" .

# Build specific image (note: use full build identifier format)
packer build -var-file="prod.pkrvars.hcl" -only="k8s-controlplane.amazon-ebs.k8s-controlplane" .
packer build -var-file="prod.pkrvars.hcl" -only="k8s-worker-linux.amazon-ebs.k8s-worker-linux" .
packer build -var-file="prod.pkrvars.hcl" -only="k8s-worker-windows.amazon-ebs.k8s-worker-windows" .


# Build Commands

# Initialize packer (download plugins)
packer init .

# Validate all templates
packer validate -var-file=prod.pkrvars.hcl .

# Build all images
packer build -var-file=prod.pkrvars.hcl .

# Build individual images (use full build identifier)
packer build -var-file=prod.pkrvars.hcl -only="k8s-controlplane.amazon-ebs.k8s-controlplane" .
packer build -var-file=prod.pkrvars.hcl -only="k8s-worker-linux.amazon-ebs.k8s-worker-linux" .
packer build -var-file=prod.pkrvars.hcl -only="k8s-worker-windows.amazon-ebs.k8s-worker-windows" .

# Or build in parallel
packer build -var-file=prod.pkrvars.hcl -only="k8s-controlplane.amazon-ebs.k8s-controlplane" . &
packer build -var-file=prod.pkrvars.hcl -only="k8s-worker-linux.amazon-ebs.k8s-worker-linux" . &
packer build -var-file=prod.pkrvars.hcl -only="k8s-worker-windows.amazon-ebs.k8s-worker-windows" . &
wait

# Build with debug logging
PACKER_LOG=1 packer build -var-file=prod.pkrvars.hcl -only="k8s-controlplane.amazon-ebs.k8s-controlplane" .

# AWS Credentials Setup (required for building)
# Ensure you have AWS credentials configured via one of these methods:
# 1. AWS CLI: aws configure
# 2. Environment variables: AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY
# 3. AWS credentials file: ~/.aws/credentials

# Post-Build: Launching the Cluster

After building the AMIs, here's how to use them:

1. Launch Control Plane
# Launch from your control plane AMI

# Then SSH in and run:
sudo kubeadm init --config /etc/kubernetes/kubeadm-config-template.yaml

# Configure kubectl
mkdir -p $HOME/.kube
sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Apply Calico CNI
kubectl apply -f /etc/kubernetes/cni/calico.yaml

# Get join command for workers
kubeadm token create --print-join-command

# 2. Join Linux Workers

# SSH to Linux worker and run:
sudo /usr/local/bin/k8s-join.sh <CONTROL_PLANE_IP> <TOKEN> <CA_CERT_HASH>

# 3. Join Windows Workers

# RDP to Windows worker and run:
C:\k\k8s-join.ps1 -ControlPlaneIP <IP> -Token <TOKEN> -CACertHash <HASH>