# k8s-controlplane.pkr.hcl - Using external scripts

packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.0"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

source "amazon-ebs" "k8s-controlplane" {
  ami_name        = "k8s-controlplane-${var.kubernetes_version}-${local.timestamp}"
  ami_description = "Kubernetes ${var.kubernetes_version} Control Plane - Ubuntu 22.04"
  instance_type   = var.instance_type_linux
  region          = var.aws_region

  vpc_id    = var.vpc_id != "" ? var.vpc_id : null
  subnet_id = var.subnet_id != "" ? var.subnet_id : null

  source_ami_filter {
    filters = {
      name                = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    owners      = ["099720109477"]
    most_recent = true
  }

  ssh_username = "ubuntu"

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
}

build {
  name    = "k8s-controlplane"
  sources = ["source.amazon-ebs.k8s-controlplane"]

  # Upload scripts
  provisioner "file" {
    source      = "scripts/linux/"
    destination = "/tmp/"
  }

  # Make scripts executable
  provisioner "shell" {
    inline = [
      "chmod +x /tmp/*.sh"
    ]
  }

  # Run common setup
  provisioner "shell" {
    script = "scripts/linux/common-setup.sh"
    execute_command = "sudo -E bash '{{.Path}}'"
  }

  # Install containerd
  provisioner "shell" {
    script = "scripts/linux/install-containerd.sh"
    execute_command = "sudo -E bash '{{.Path}}'"
    environment_vars = [
      "CONTAINERD_VERSION=${var.containerd_version}",
      "CNI_VERSION=${var.cni_plugins_version}",
      "CRICTL_VERSION=${var.crictl_version}"
    ]
  }

  # Install K8s components
  provisioner "shell" {
    script = "scripts/linux/install-k8s-components.sh"
    execute_command = "sudo -E bash '{{.Path}}'"
    environment_vars = [
      "KUBERNETES_VERSION=${var.kubernetes_version}",
      "NODE_TYPE=controlplane"
    ]
  }

  # Control plane specific setup
  provisioner "shell" {
    script = "scripts/linux/controlplane-setup.sh"
    execute_command = "sudo -E bash '{{.Path}}'"
    environment_vars = [
      "KUBERNETES_VERSION=${var.kubernetes_version}",
      "CALICO_VERSION=${var.calico_version}",
      "POD_CIDR=192.168.0.0/16",
      "SERVICE_CIDR=10.96.0.0/12"
    ]
  }

  # Cleanup
  provisioner "shell" {
    inline = [
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