#!/bin/bash
# Slave Control Plane Node Initialization Script (HA Setup)
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
MASTER_IP="${master_ip}"
KUBERNETES_VERSION="1.28"
WAIT_TIMEOUT=300

echo -e "${YELLOW}=== Starting Slave Control Plane Setup ===${NC}"

# ============================================================================
# System Updates and Prerequisites
# ============================================================================

echo -e "${YELLOW}[1/6] Updating system packages...${NC}"
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
# Disable Swap
# ============================================================================

echo -e "${YELLOW}[2/6] Disabling swap...${NC}"
swapoff -a
sed -i '/swap/d' /etc/fstab

# ============================================================================
# Configure Network Modules
# ============================================================================

echo -e "${YELLOW}[3/6] Configuring network modules...${NC}"
cat > /etc/modules-load.d/k8s.conf << EOF
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

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

echo -e "${YELLOW}[4/6] Installing containerd...${NC}"
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update
apt-get install -y containerd.io

mkdir -p /etc/containerd
containerd config default | tee /etc/containerd/config.toml > /dev/null
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

systemctl daemon-reload
systemctl enable containerd
systemctl restart containerd

# ============================================================================
# Install Kubernetes Components
# ============================================================================

echo -e "${YELLOW}[5/6] Installing Kubernetes components (v${KUBERNETES_VERSION})...${NC}"
curl -fsSL https://pkgs.k8s.io/core:/stable:/v${KUBERNETES_VERSION}/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v${KUBERNETES_VERSION}/deb/ /" | tee /etc/apt/sources.list.d/kubernetes.list

apt-get update
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

systemctl enable kubelet

# ============================================================================
# Wait for Master Node to be Ready and Get Join Command
# ============================================================================

echo -e "${YELLOW}[6/6] Waiting for master node to be ready...${NC}"
echo "Master IP: ${MASTER_IP}"

# Wait for SSH to be available on master
ELAPSED=0
until ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 ubuntu@${MASTER_IP} "test -f /var/lib/cloud/kubeadm-join.sh" 2>/dev/null || [ $ELAPSED -ge $WAIT_TIMEOUT ]; do
    echo "Waiting for master node... ($ELAPSED/$WAIT_TIMEOUT)"
    sleep 10
    ELAPSED=$((ELAPSED + 10))
done

if [ $ELAPSED -ge $WAIT_TIMEOUT ]; then
    echo -e "${RED}ERROR: Master node not ready after $WAIT_TIMEOUT seconds${NC}"
    echo "Please run the join command manually when the master is ready"
    exit 1
fi

# Get join command from master (using --control-plane flag for CP nodes)
echo "Getting join command from master..."

# For additional control plane node, we need the join command with --control-plane flag
# We'll fetch the join certificate key from the master
CERT_KEY=$(ssh -o StrictHostKeyChecking=no ubuntu@${MASTER_IP} "kubeadm init phase upload-certs --upload-certs 2>/dev/null | tail -1" || echo "")

if [ -z "$CERT_KEY" ]; then
    echo -e "${RED}Warning: Could not get certificate key from master${NC}"
    echo "Please manually run kubeadm join command with --control-plane flag"
    exit 1
fi

# Get the token
JOIN_CMD=$(ssh -o StrictHostKeyChecking=no ubuntu@${MASTER_IP} "kubeadm token create --print-join-command" || echo "")

if [ -z "$JOIN_CMD" ]; then
    echo -e "${RED}ERROR: Could not get join command from master${NC}"
    exit 1
fi

# Join as control plane node
echo -e "${YELLOW}Joining cluster as control plane node...${NC}"
eval "$JOIN_CMD --control-plane --certificate-key=$CERT_KEY"

# ============================================================================
# Configure kubectl
# ============================================================================

echo -e "${YELLOW}Configuring kubectl...${NC}"
mkdir -p /root/.kube
scp -o StrictHostKeyChecking=no ubuntu@${MASTER_IP}:/etc/kubernetes/admin.conf /root/.kube/config
chown $(id -u):$(id -g) /root/.kube/config

mkdir -p /home/ubuntu/.kube
scp -o StrictHostKeyChecking=no ubuntu@${MASTER_IP}:/etc/kubernetes/admin.conf /home/ubuntu/.kube/config
chown ubuntu:ubuntu /home/ubuntu/.kube/config

export KUBECONFIG=/root/.kube/config

# ============================================================================
# Verify Node Join
# ============================================================================

echo -e "${YELLOW}Waiting for node to be ready...${NC}"
sleep 30

echo -e "${GREEN}=== Slave Control Plane Setup Complete ===${NC}"
echo -e "${YELLOW}Cluster Status:${NC}"
kubectl get nodes -o wide
