#!/bin/bash
# common-setup.sh - Common setup for all K8s nodes (control plane & workers)
set -euo pipefail

echo "=== Starting common K8s node setup ==="

# Update system
echo ">>> Updating system packages..."
apt-get update
apt-get upgrade -y
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    software-properties-common \
    jq \
    nfs-common \
    socat \
    conntrack \
    ipset

# Disable swap (required for Kubernetes)
echo ">>> Disabling swap..."
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab

# Load required kernel modules
echo ">>> Loading kernel modules..."
cat <<EOF | tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

# Configure sysctl for Kubernetes networking
echo ">>> Configuring sysctl parameters..."
cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
net.ipv4.conf.all.forwarding        = 1
EOF

sysctl --system

# Verify modules are loaded
echo ">>> Verifying kernel modules..."
lsmod | grep br_netfilter
lsmod | grep overlay

# Verify sysctl settings
echo ">>> Verifying sysctl settings..."
sysctl net.bridge.bridge-nf-call-iptables
sysctl net.bridge.bridge-nf-call-ip6tables
sysctl net.ipv4.ip_forward

echo "=== Common setup completed ==="