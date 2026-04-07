#!/bin/bash
# install-containerd.sh - Install and configure containerd
set -euo pipefail

# Environment variables (passed from Packer)
CONTAINERD_VERSION="${CONTAINERD_VERSION:-1.7.11}"
CNI_VERSION="${CNI_VERSION:-1.4.0}"
CRICTL_VERSION="${CRICTL_VERSION:-1.34.0}"

echo "=== Installing containerd ${CONTAINERD_VERSION} ==="

# Add Docker's official GPG key (containerd is part of Docker repo)
echo ">>> Adding Docker repository..."
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install containerd
echo ">>> Installing containerd..."
apt-get update
apt-get install -y containerd.io

# Configure containerd
echo ">>> Configuring containerd..."
mkdir -p /etc/containerd
containerd config default | tee /etc/containerd/config.toml > /dev/null

# Enable SystemdCgroup (required for Kubernetes)
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

# Set sandbox image to match Kubernetes version
sed -i 's|sandbox_image = "registry.k8s.io/pause:.*"|sandbox_image = "registry.k8s.io/pause:3.9"|' /etc/containerd/config.toml

# Restart and enable containerd
echo ">>> Starting containerd service..."
systemctl daemon-reload
systemctl restart containerd
systemctl enable containerd

# Verify containerd is running
echo ">>> Verifying containerd..."
systemctl status containerd --no-pager
containerd --version

# Install CNI plugins
echo "=== Installing CNI plugins ${CNI_VERSION} ==="
mkdir -p /opt/cni/bin
curl -fsSL "https://github.com/containernetworking/plugins/releases/download/v${CNI_VERSION}/cni-plugins-linux-amd64-v${CNI_VERSION}.tgz" | tar -xz -C /opt/cni/bin
ls -la /opt/cni/bin/

# Install crictl
echo "=== Installing crictl ${CRICTL_VERSION} ==="
curl -fsSL "https://github.com/kubernetes-sigs/cri-tools/releases/download/v${CRICTL_VERSION}/crictl-v${CRICTL_VERSION}-linux-amd64.tar.gz" | tar -xz -C /usr/local/bin

# Configure crictl
cat <<EOF | tee /etc/crictl.yaml
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 10
debug: false
EOF

# Verify crictl
echo ">>> Verifying crictl..."
crictl --version
crictl info

echo "=== Container runtime installation completed ==="