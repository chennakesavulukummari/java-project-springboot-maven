# k8s-controlplane.pkr.hcl - Kubernetes Control Plane AMI

packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.0"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

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

source "amazon-ebs" "k8s-controlplane" {
  ami_name        = "k8s-controlplane-${var.kubernetes_version}-${local.timestamp}"
  ami_description = "Kubernetes ${var.kubernetes_version} Control Plane - Ubuntu 22.04"
  instance_type   = var.instance_type_linux
  region          = var.aws_region

  # Use provided VPC/subnet or default
  vpc_id    = var.vpc_id != "" ? var.vpc_id : null
  subnet_id = var.subnet_id != "" ? var.subnet_id : null

  source_ami_filter {
    filters = {
      name                = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    owners      = ["099720109477"] # Canonical
    most_recent = true
  }

  ssh_username = "ubuntu"

  # Increase root volume for K8s components
  launch_block_device_mappings {
    device_name           = "/dev/sda1"
    volume_size           = 30
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = merge(local.common_tags, {
    Name = "k8s-controlplane-${var.kubernetes_version}"
    Role = "controlplane"
  })

  run_tags = {
    Name = "packer-builder-k8s-controlplane"
  }
}

build {
  name    = "k8s-controlplane"
  sources = ["source.amazon-ebs.k8s-controlplane"]

  # Common Linux setup
  provisioner "shell" {
    inline = [
      "echo '=== Updating system ==='",
      "sudo apt-get update",
      "sudo apt-get upgrade -y",
      "sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release software-properties-common"
    ]
  }

  # Disable swap (required for K8s)
  provisioner "shell" {
    inline = [
      "echo '=== Disabling swap ==='",
      "sudo swapoff -a",
      "sudo sed -i '/ swap / s/^/#/' /etc/fstab"
    ]
  }

  # Load required kernel modules
  provisioner "shell" {
    inline = [
      "echo '=== Configuring kernel modules ==='",
      "cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf",
      "overlay",
      "br_netfilter",
      "EOF",
      "sudo modprobe overlay",
      "sudo modprobe br_netfilter"
    ]
  }

  # Configure sysctl for K8s networking
  provisioner "shell" {
    inline = [
      "echo '=== Configuring sysctl ==='",
      "cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf",
      "net.bridge.bridge-nf-call-iptables  = 1",
      "net.bridge.bridge-nf-call-ip6tables = 1",
      "net.ipv4.ip_forward                 = 1",
      "EOF",
      "sudo sysctl --system"
    ]
  }

  # Install containerd
  provisioner "shell" {
    environment_vars = [
      "CONTAINERD_VERSION=${var.containerd_version}"
    ]
    inline = [
      "echo '=== Installing containerd ==='",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg",
      "echo \"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\" | sudo tee /etc/apt/sources.list.d/docker.list",
      "sudo apt-get update",
      "sudo apt-get install -y containerd.io",
      "sudo mkdir -p /etc/containerd",
      "containerd config default | sudo tee /etc/containerd/config.toml",
      "sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml",
      "sudo systemctl restart containerd",
      "sudo systemctl enable containerd"
    ]
  }

  # Install CNI plugins
  provisioner "shell" {
    environment_vars = [
      "CNI_VERSION=${var.cni_plugins_version}"
    ]
    inline = [
      "echo '=== Installing CNI plugins ==='",
      "sudo mkdir -p /opt/cni/bin",
      "curl -fsSL https://github.com/containernetworking/plugins/releases/download/v$${CNI_VERSION}/cni-plugins-linux-amd64-v$${CNI_VERSION}.tgz | sudo tar -xz -C /opt/cni/bin"
    ]
  }

  # Install crictl
  provisioner "shell" {
    environment_vars = [
      "CRICTL_VERSION=${var.crictl_version}"
    ]
    inline = [
      "echo '=== Installing crictl ==='",
      "curl -fsSL https://github.com/kubernetes-sigs/cri-tools/releases/download/v$${CRICTL_VERSION}/crictl-v$${CRICTL_VERSION}-linux-amd64.tar.gz | sudo tar -xz -C /usr/local/bin",
      "cat <<EOF | sudo tee /etc/crictl.yaml",
      "runtime-endpoint: unix:///run/containerd/containerd.sock",
      "image-endpoint: unix:///run/containerd/containerd.sock",
      "timeout: 10",
      "EOF"
    ]
  }

  # Install kubeadm, kubelet, kubectl
  provisioner "shell" {
    environment_vars = [
      "KUBERNETES_VERSION=${var.kubernetes_version}"
    ]
    inline = [
      "echo '=== Installing Kubernetes components ==='",
      "curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.34/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg",
      "echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.34/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list",
      "sudo apt-get update",
      "sudo apt-get install -y kubelet kubeadm kubectl",
      "sudo apt-mark hold kubelet kubeadm kubectl",
      "sudo systemctl enable kubelet"
    ]
  }

  # Pre-pull control plane images
  provisioner "shell" {
    inline = [
      "echo '=== Pre-pulling control plane images ==='",
      "sudo kubeadm config images pull"
    ]
  }

  # Create kubeadm config template
  provisioner "shell" {
    inline = [
      "echo '=== Creating kubeadm config template ==='",
      "cat <<'EOF' | sudo tee /etc/kubernetes/kubeadm-config-template.yaml",
      "apiVersion: kubeadm.k8s.io/v1beta3",
      "kind: ClusterConfiguration",
      "kubernetesVersion: \"${var.kubernetes_version}\"",
      "networking:",
      "  podSubnet: \"192.168.0.0/16\"  # For Calico",
      "  serviceSubnet: \"10.96.0.0/12\"",
      "---",
      "apiVersion: kubeadm.k8s.io/v1beta3",
      "kind: InitConfiguration",
      "nodeRegistration:",
      "  criSocket: unix:///run/containerd/containerd.sock",
      "EOF"
    ]
  }

  # Download Calico manifests
  provisioner "shell" {
    environment_vars = [
      "CALICO_VERSION=${var.calico_version}"
    ]
    inline = [
      "echo '=== Downloading Calico manifests ==='",
      "sudo mkdir -p /etc/kubernetes/cni",
      "sudo curl -fsSL https://raw.githubusercontent.com/projectcalico/calico/v$${CALICO_VERSION}/manifests/calico.yaml -o /etc/kubernetes/cni/calico.yaml"
    ]
  }

  # Cleanup
  provisioner "shell" {
    inline = [
      "echo '=== Cleanup ==='",
      "sudo apt-get clean",
      "sudo rm -rf /var/lib/apt/lists/*",
      "sudo rm -rf /tmp/*",
      "sudo cloud-init clean --logs"
    ]
  }

  post-processor "manifest" {
    output     = "manifest-controlplane.json"
    strip_path = true
  }
}