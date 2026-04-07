#!/bin/bash
# controlplane-setup.sh - Additional setup for control plane nodes
set -euo pipefail

# Environment variables
KUBERNETES_VERSION="${KUBERNETES_VERSION:-1.29.0}"
CALICO_VERSION="${CALICO_VERSION:-3.27.0}"
POD_CIDR="${POD_CIDR:-192.168.0.0/16}"
SERVICE_CIDR="${SERVICE_CIDR:-10.96.0.0/12}"

echo "=== Control Plane specific setup ==="

# Pre-pull control plane images
echo ">>> Pre-pulling control plane images..."
kubeadm config images pull

# Create kubeadm configuration template
echo ">>> Creating kubeadm configuration template..."
mkdir -p /etc/kubernetes

cat <<EOF | tee /etc/kubernetes/kubeadm-config-template.yaml
---
apiVersion: kubeadm.k8s.io/v1beta3
kind: ClusterConfiguration
kubernetesVersion: "${KUBERNETES_VERSION}"
networking:
  podSubnet: "${POD_CIDR}"
  serviceSubnet: "${SERVICE_CIDR}"
controllerManager:
  extraArgs:
    bind-address: "0.0.0.0"
scheduler:
  extraArgs:
    bind-address: "0.0.0.0"
etcd:
  local:
    extraArgs:
      listen-metrics-urls: "http://0.0.0.0:2381"
---
apiVersion: kubeadm.k8s.io/v1beta3
kind: InitConfiguration
nodeRegistration:
  criSocket: unix:///run/containerd/containerd.sock
  kubeletExtraArgs:
    cloud-provider: external
---
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
cgroupDriver: systemd
EOF

# Download Calico manifests
echo ">>> Downloading Calico ${CALICO_VERSION} manifests..."
mkdir -p /etc/kubernetes/cni
curl -fsSL "https://raw.githubusercontent.com/projectcalico/calico/v${CALICO_VERSION}/manifests/calico.yaml" -o /etc/kubernetes/cni/calico.yaml

# Download Calico operator (alternative method)
curl -fsSL "https://raw.githubusercontent.com/projectcalico/calico/v${CALICO_VERSION}/manifests/tigera-operator.yaml" -o /etc/kubernetes/cni/tigera-operator.yaml
curl -fsSL "https://raw.githubusercontent.com/projectcalico/calico/v${CALICO_VERSION}/manifests/custom-resources.yaml" -o /etc/kubernetes/cni/calico-custom-resources.yaml

# Create cluster initialization script
echo ">>> Creating cluster initialization script..."
cat <<'SCRIPT' | tee /usr/local/bin/k8s-init-cluster.sh
#!/bin/bash
# Initialize Kubernetes control plane
set -euo pipefail

CONTROL_PLANE_IP="${1:-$(hostname -I | awk '{print $1}')}"

echo "=== Initializing Kubernetes Control Plane ==="
echo ">>> Control Plane IP: ${CONTROL_PLANE_IP}"

# Update kubeadm config with actual IP
cp /etc/kubernetes/kubeadm-config-template.yaml /etc/kubernetes/kubeadm-config.yaml

cat <<EOF >> /etc/kubernetes/kubeadm-config.yaml
---
apiVersion: kubeadm.k8s.io/v1beta3
kind: InitConfiguration
localAPIEndpoint:
  advertiseAddress: ${CONTROL_PLANE_IP}
  bindPort: 6443
EOF

# Initialize cluster
kubeadm init --config /etc/kubernetes/kubeadm-config.yaml --upload-certs

# Configure kubectl for root user
mkdir -p /root/.kube
cp /etc/kubernetes/admin.conf /root/.kube/config

# Configure kubectl for ubuntu user
mkdir -p /home/ubuntu/.kube
cp /etc/kubernetes/admin.conf /home/ubuntu/.kube/config
chown -R ubuntu:ubuntu /home/ubuntu/.kube

echo ">>> Applying Calico CNI..."
export KUBECONFIG=/etc/kubernetes/admin.conf
kubectl apply -f /etc/kubernetes/cni/calico.yaml

echo ">>> Waiting for control plane to be ready..."
kubectl wait --for=condition=Ready node --all --timeout=300s

echo ""
echo "=== Cluster initialized successfully! ==="
echo ""
echo ">>> To get the join command for workers, run:"
echo "    kubeadm token create --print-join-command"
echo ""
SCRIPT

chmod +x /usr/local/bin/k8s-init-cluster.sh

# Create script to generate join command
cat <<'SCRIPT' | tee /usr/local/bin/k8s-get-join-command.sh
#!/bin/bash
# Generate join command for worker nodes
kubeadm token create --print-join-command
SCRIPT

chmod +x /usr/local/bin/k8s-get-join-command.sh

echo "=== Control Plane setup completed ==="
echo ""
echo "After launching, run: sudo /usr/local/bin/k8s-init-cluster.sh"