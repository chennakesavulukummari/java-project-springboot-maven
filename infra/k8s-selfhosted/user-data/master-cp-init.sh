#!/bin/bash
# Master Control Plane Node Initialization Script
# Ubuntu 22.04 LTS

set -e

# Colors for logging
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Variables from Terraform
CLUSTER_NAME="${cluster_name}"
POD_CIDR="${pod_cidr}"
SERVICE_CIDR="${service_cidr}"
KUBERNETES_VERSION="1.28"

echo -e "${YELLOW}=== Starting Master Control Plane Setup ===${NC}"

# ============================================================================
# System Updates and Prerequisites
# ============================================================================

echo -e "${YELLOW}[1/7] Updating system packages...${NC}"
apt-get update
apt-get upgrade -y
apt-get install -y \
    curl \
    wget \
    git \
    htop \
    net-tools \
    jq \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    software-properties-common \
    ntp \
    chrony

# ============================================================================
# Disable Swap (Kubernetes requirement)
# ============================================================================

echo -e "${YELLOW}[2/7] Disabling swap...${NC}"
swapoff -a
sed -i '/swap/d' /etc/fstab

# ============================================================================
# Configure Network Modules
# ============================================================================

echo -e "${YELLOW}[3/7] Configuring network modules...${NC}"
cat > /etc/modules-load.d/k8s.conf << EOF
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

# Set required sysctl parameters
cat > /etc/sysctl.d/k8s.conf << EOF
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
net.ipv4.conf.all.rp_filter         = 0
EOF

sysctl --system

# ============================================================================
# Install Container Runtime (containerd)
# ============================================================================

echo -e "${YELLOW}[4/7] Installing containerd...${NC}"
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update
apt-get install -y containerd.io

mkdir -p /etc/containerd
containerd config default | tee /etc/containerd/config.toml > /dev/null

# Enable SystemdCgroup (important for Kubernetes)
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

systemctl daemon-reload
systemctl enable containerd
systemctl restart containerd

# ============================================================================
# Install Kubernetes Components
# ============================================================================

echo -e "${YELLOW}[5/7] Installing Kubernetes components (v${KUBERNETES_VERSION})...${NC}"
curl -fsSL https://pkgs.k8s.io/core:/stable:/v${KUBERNETES_VERSION}/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v${KUBERNETES_VERSION}/deb/ /" | tee /etc/apt/sources.list.d/kubernetes.list

apt-get update
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

systemctl enable kubelet
systemctl start kubelet

# ============================================================================
# Initialize Kubernetes Master Cluster
# ============================================================================

echo -e "${YELLOW}[6/7] Initializing Kubernetes Control Plane...${NC}"

kubeadm init \
    --pod-network-cidr=${POD_CIDR} \
    --service-cidr=${SERVICE_CIDR} \
    --kubernetes-version=v${KUBERNETES_VERSION}.0 \
    --ignore-preflight-errors=all

# ============================================================================
# Configure kubectl access
# ============================================================================

echo -e "${YELLOW}[7/7] Configuring kubectl access...${NC}"
mkdir -p /root/.kube
cp /etc/kubernetes/admin.conf /root/.kube/config
chown $(id -u):$(id -g) /root/.kube/config

export KUBECONFIG=/root/.kube/config

# Also setup for ubuntu user
mkdir -p /home/ubuntu/.kube
cp /etc/kubernetes/admin.conf /home/ubuntu/.kube/config
chown ubuntu:ubuntu /home/ubuntu/.kube/config

# ============================================================================
# Install CNI Plugin (Calico)
# ============================================================================

echo -e "${YELLOW}[BONUS] Installing Calico CNI...${NC}"
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/tigera-operator.yaml
sleep 30

cat > /tmp/calico-values.yaml << EOF
apiVersion: operator.tigera.io/v1
kind: Installation
metadata:
  name: default
spec:
  calicoNetwork:
    ipPools:
    - blockSize: 26
      cidr: ${POD_CIDR}
      encapsulation: VXLANCrossSubnet
      natOutgoing: Enabled
      nodeSelector: all()
EOF

kubectl apply -f /tmp/calico-values.yaml

# Wait for Calico to be ready
echo "Waiting for Calico to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/calico-typha -n calico-system 2>/dev/null || true

# ============================================================================
# Save Important Information
# ============================================================================

echo -e "${GREEN}=== Master Control Plane Setup Complete ===${NC}"

# Create a file with kubeadm join command for workers
kubeadm token create --print-join-command > /var/lib/cloud/kubeadm-join.sh
chmod +x /var/lib/cloud/kubeadm-join.sh

# Save cluster info
cat > /var/lib/cloud/cluster-info.txt << EOF
Cluster Name: ${CLUSTER_NAME}
Pod CIDR: ${POD_CIDR}
Service CIDR: ${SERVICE_CIDR}
Control Plane IP: $(hostname -I | awk '{print $1}')
Kubernetes Version: ${KUBERNETES_VERSION}

To get the kubeadm join command, run:
cat /var/lib/cloud/kubeadm-join.sh
EOF

# Check cluster status
echo -e "${YELLOW}Cluster Status:${NC}"
kubectl get nodes -o wide
kubectl get pods -A

echo -e "${GREEN}Master node ready!${NC}"
echo "Check /var/lib/cloud/kubeadm-join.sh for join command"
