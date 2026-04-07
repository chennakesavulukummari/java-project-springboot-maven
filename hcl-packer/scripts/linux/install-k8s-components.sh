#!/bin/bash
# install-k8s-components.sh - Install kubeadm, kubelet, kubectl
set -euo pipefail

# Environment variables (passed from Packer)
KUBERNETES_VERSION="${KUBERNETES_VERSION:-1.34}"
NODE_TYPE="${NODE_TYPE:-worker}"  # "controlplane" or "worker"

# Extract major.minor version for repo
K8S_MINOR_VERSION=$(echo "${KUBERNETES_VERSION}" | cut -d. -f1-2)

echo "=== Installing Kubernetes ${KUBERNETES_VERSION} components ==="
echo ">>> Node type: ${NODE_TYPE}"

# Add Kubernetes apt repository
echo ">>> Adding Kubernetes repository..."
mkdir -p /etc/apt/keyrings
curl -fsSL "https://pkgs.k8s.io/core:/stable:/v${K8S_MINOR_VERSION}/deb/Release.key" | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v${K8S_MINOR_VERSION}/deb/ /" | tee /etc/apt/sources.list.d/kubernetes.list > /dev/null

# Update and install
echo ">>> Installing kubelet, kubeadm..."
apt-get update

if [ "${NODE_TYPE}" == "controlplane" ]; then
    # Control plane needs kubectl too
    apt-get install -y kubelet kubeadm kubectl
    apt-mark hold kubelet kubeadm kubectl
else
    # Workers only need kubelet and kubeadm
    apt-get install -y kubelet kubeadm
    apt-mark hold kubelet kubeadm
fi

# Enable kubelet (it will fail to start until node is initialized/joined)
echo ">>> Enabling kubelet service..."
systemctl enable kubelet

# Verify installation
echo ">>> Verifying installation..."
kubeadm version
kubelet --version
if [ "${NODE_TYPE}" == "controlplane" ]; then
    kubectl version --client
fi

# Create kubelet configuration directory
mkdir -p /etc/kubernetes/manifests
mkdir -p /var/lib/kubelet

# Configure kubelet defaults
cat <<EOF | tee /etc/default/kubelet
KUBELET_EXTRA_ARGS=--container-runtime-endpoint=unix:///run/containerd/containerd.sock
EOF

echo "=== Kubernetes components installation completed ==="