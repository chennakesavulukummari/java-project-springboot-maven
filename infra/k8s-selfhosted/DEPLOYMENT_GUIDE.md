# 🚀 Deployment Guide - Self-Hosted Kubernetes Cluster on AWS

## Executive Summary

This comprehensive guide walks through deploying a **production-ready, self-hosted Kubernetes cluster** on AWS EC2 with a complete **3-tier application architecture**. The entire infrastructure is defined as code using Terraform for easy deployment and repeatability.

---

## 📊 What We're Building

### Infrastructure Components

```
5 EC2 Instances + Network + Storage
│
├── 🖥️ Master Control Plane (t3.medium, Ubuntu)
├── 🖥️ Slave Control Plane (t3.medium, Ubuntu) - HA
├── 🐧 Linux Worker (t3.large, Ubuntu) - Web Tier
├── 🪟 Windows Worker (t3.large, Windows) - App Tier
└── 🗄️ Database Node (t3.large, Ubuntu) - MySQL 8.0
```

### Application Architecture

```
End Users (0.0.0.0/0)
    ↓
[AWS Load Balancer - Port 80/443]
    ↓
┌─────────────────────────────────────┐
│   Kubernetes Cluster                │
├─────────────────────────────────────┤
│ Tier 1: Web (Angular UI)            │ ← Linux Node
│ Tier 2: API (Python Backend)        │ ← Windows Node
│ Tier 3: Database (MySQL 8.0)        │ ← DB Node
└─────────────────────────────────────┘
```

---

## 📋 Pre-Deployment Checklist

Before you begin, ensure you have:

### ✅ Local Tools
- [ ] Terraform 1.0+ installed
- [ ] AWS CLI v2 installed
- [ ] SSH key configured
- [ ] kubectl installed (optional)

### ✅ AWS Account
- [ ] AWS access credentials configured
- [ ] IAM permissions for EC2, VPC, EBS
- [ ] EC2 instance quota (≥5 instances)
- [ ] Elastic IP quota (≥2)

### ✅ Knowledge
- [ ] Basic AWS concepts (VPC, EC2, Security Groups)
- [ ] Basic Kubernetes concepts
- [ ] Comfortable with command-line tools

---

## 🎯 Step-by-Step Deployment

### Phase 1: Preparation (5 minutes)

#### 1.1 Create SSH Key Pair

```bash
# In AWS Console or via CLI:
aws ec2 create-key-pair --key-name k8s-cluster \
  --region us-east-1 --query 'KeyMaterial' \
  --output text > k8s-cluster.pem

# Set permissions
chmod 400 k8s-cluster.pem
```

#### 1.2 Get Your Public IP

```bash
# Find your IP for SSH access restriction
curl -s https://checkip.amazonaws.com
# You'll use this in the next step (e.g., 203.0.113.45/32)
```

#### 1.3 Navigate to Project Directory

```bash
cd /Users/ck/github-repos/java-project-springboot-maven/infra/k8s-selfhosted
pwd  # Verify you're in the right directory
```

---

### Phase 2: Configure Terraform (5 minutes)

#### 2.1 Initialize Terraform

```bash
terraform init

# Output should show:
# Terraform has been successfully configured!
```

#### 2.2 Create Configuration File

```bash
# Create terraform.tfvars with your custom values
cat > terraform.tfvars << 'EOF'
aws_region = "us-east-1"
cluster_name = "k8s-selfhosted"
environment = "production"

# IMPORTANT: Replace with YOUR public IP
ssh_allowed_cidrs = ["203.0.113.45/32"]

# Instance types (adjust as needed)
master_instance_type = "t3.medium"
worker_instance_type = "t3.large"
db_instance_type = "t3.large"
EOF

# Verify the file
cat terraform.tfvars
```

#### 2.3 Review Configuration

```bash
# See what will be created
terraform plan -out=tfplan

# Expected resources:
# - 1 VPC
# - 3 Subnets
# - 3 Security Groups
# - 5 EC2 Instances
# - 1 EBS Volume (100GB)
# - Internet Gateway + NAT Gateway
# - IAM Role + Instance Profile
```

---

### Phase 3: Deploy Infrastructure (10-15 minutes)

#### 3.1 Apply Terraform Configuration

```bash
# Deploy infrastructure
terraform apply tfplan

# This will take approximately 10-15 minutes
# Watch the AWS Console for EC2 instance creation

# Monitor progress:
watch -n 5 "aws ec2 describe-instances --region us-east-1 \
  --filters 'Name=tag:K8s-ClusterName,Values=k8s-selfhosted' \
  --query 'Reservations[*].Instances[*].[InstanceId,InstanceType,State.Name,PublicIpAddress]' \
  --output table"
```

#### 3.2 Save Output Values

```bash
# Get deployment information
terraform output -json > cluster-info.json
cat cluster-info.json

# Extract specific values
MASTER_IP=$(terraform output -raw master_cp_public_ip)
SLAVE_IP=$(terraform output -raw slave_cp_public_ip)
WORKER_LINUX_IP=$(terraform output -raw worker_linux_public_ip)
WORKER_WINDOWS_IP=$(terraform output -raw worker_windows_public_ip)
DB_IP=$(terraform output -raw db_node_private_ip)

echo "Master CP: $MASTER_IP"
echo "Slave CP: $SLAVE_IP"
echo "Worker Linux: $WORKER_LINUX_IP"
echo "Worker Windows: $WORKER_WINDOWS_IP"
echo "DB Node: $DB_IP"
```

---

### Phase 4: Kubernetes Cluster Setup (20-30 minutes)

#### 4.1 Wait for Master Node to Initialize

The master node initialization happens automatically via user-data script. This includes:
- System updates
- Container runtime (containerd) installation
- Kubernetes component installation
- Control plane initialization with kubeadm
- Calico CNI installation

**Estimated time: 10-15 minutes**

```bash
# Monitor master node initialization
MASTER_IP=$(terraform output -raw master_cp_public_ip)

# Watch the initialization progress
watch -n 10 "aws ec2 describe-instances --region us-east-1 \
  --instance-ids $(aws ec2 describe-instances --region us-east-1 \
    --filters 'Name=tag:Name,Values=*master-cp' \
    --query 'Reservations[0].Instances[0].InstanceId' \
    --output text) \
  --query 'Reservations[0].Instances[0].[PublicIpAddress,State.Name,LaunchTime]' \
  --output table"

# Check if ready (once initialized)
ssh -i k8s-cluster.pem ubuntu@$MASTER_IP "cloud-init status"
# Should show: 'status: done'
```

#### 4.2 Verify Master Control Plane

```bash
ssh -i k8s-cluster.pem ubuntu@$MASTER_IP

# Once connected to master:
kubectl get nodes
# Should show: master-cp in Ready state

kubectl get pods -A
# Should show: various system pods running

kubectl get services -A
# Should show: kubernetes, kube-dns services

# Check cluster info
kubectl cluster-info

# Exit from SSH
exit
```

#### 4.3 Wait for Slave Control Plane

Slave CP will:
1. Wait for master to be ready
2. Copy certificates from master
3. Join as additional control plane
4. Replicate etcd database

**Estimated time: 10-15 minutes**

```bash
# Monitor slave node
watch -n 10 "ssh -i k8s-cluster.pem ubuntu@$SLAVE_IP 'cloud-init status' 2>/dev/null || echo 'Not ready yet'"

# Once ready, verify
ssh -i k8s-cluster.pem ubuntu@$SLAVE_IP
kubectl get nodes
# Should show: both master-cp and slave-cp in Ready state
exit
```

#### 4.4 Linux Worker Node Setup

Automatically joins the cluster as a worker.

**Estimated time: 5-10 minutes**

```bash
# Verify worker joined
ssh -i k8s-cluster.pem ubuntu@$MASTER_IP
kubectl get nodes
# Should show: worker-linux node

# Check labels
kubectl get nodes -L kubernetes.io/os
exit
```

#### 4.5 Windows Worker Node Setup

**Note:** Windows setup is more complex and may take longer.

**Estimated time: 15-20 minutes**

```bash
# Monitor Windows node setup
watch -n 30 "aws ec2 describe-instances --region us-east-1 \
  --filters 'Name=tag:Name,Values=*worker-windows' \
  --query 'Reservations[0].Instances[0].[InstanceId,State.Name,StatusChecks.Status]' \
  --output table"

# Once running, you can access via RDP
# IP: $WORKER_WINDOWS_IP
# Username: Administrator
# Password: Get from AWS Console > Right-click instance > Security > Get Windows password

# To verify from master:
ssh -i k8s-cluster.pem ubuntu@$MASTER_IP
kubectl get nodes
# Should show: worker-windows in Ready state (may take longer)
```

#### 4.6 Database Node Setup

Automatically installs and configures MySQL.

**Estimated time: 5-10 minutes**

```bash
# The database node runs in private subnet
# Access it from master node:
ssh -i k8s-cluster.pem ubuntu@$MASTER_IP

# SSH to DB node (using private IP)
ssh ubuntu@10.0.3.10
# or
ssh ubuntu@<DB_PRIVATE_IP>

# Check MySQL status
sudo systemctl status mysql

# View credentials
cat /var/lib/cloud/db-credentials.txt

# Test MySQL
mysql -uroot -p
# Enter root password from file above

# Show databases
SHOW DATABASES;

# Test application user
exit
mysql -uappuser -p
# Enter password from credentials file
USE application_db;
SHOW TABLES;
exit
```

---

### Phase 5: Verification (10 minutes)

#### 5.1 Full Cluster Health Check

```bash
# Connect to master
MASTER_IP=$(terraform output -raw master_cp_public_ip)
ssh -i k8s-cluster.pem ubuntu@$MASTER_IP

# Check all nodes
kubectl get nodes -o wide
# Expected output:
# NAME            STATUS   ROLES                 AGE   VERSION
# master-cp       Ready    control-plane,master  XmXX  v1.28.0
# slave-cp        Ready    control-plane,master  XmXX  v1.28.0
# worker-linux    Ready    <none>                XmXX  v1.28.0
# worker-windows  Ready    <none>                XmXX  v1.28.0

# Check system pods
kubectl get pods -n kube-system
# Should show: coredns, calico, metrics-server, etc.

# Check cluster resources
kubectl top nodes
kubectl top pods -A

# Check Calico (networking)
kubectl get daemonset -n calico-system
# Should show: calico-node pods on all nodes

# Check Kubernetes Dashboard
kubectl get deployment -n kubernetes-dashboard
```

#### 5.2 Network Connectivity Test

```bash
# Deploy a test pod
kubectl run -it --rm test-pod --image=busybox:1.35 -- sh

# Inside the pod:
# Test DNS
nslookup kubernetes.default

# Test service connectivity
wget -O- http://kubernetes.default.svc.cluster.local

# Test pod-to-pod connectivity
ping <another-pod-ip>

# Exit pod
exit
```

#### 5.3 Database Connectivity Test

```bash
# From any worker node, test MySQL connectivity
kubectl run -it --rm mysql-test --image=mysql:8.0 -- bash

# Inside container:
mysql -h 10.0.3.10 -u appuser -p application_db
# Enter password from credentials
SHOW TABLES;
exit

# Exit container
exit
```

---

### Phase 6: Deploy Sample Applications (Optional)

#### 6.1 Create Namespaces

```bash
kubectl create namespace web
kubectl create namespace app
kubectl create namespace database
```

#### 6.2 Deploy MySQL Service

```bash
# Create ConfigMap for database connection
kubectl create configmap db-config \
  --from-literal=DB_HOST=10.0.3.10 \
  --from-literal=DB_PORT=3306 \
  --from-literal=DB_NAME=application_db \
  -n app

# Create Secret for database credentials
kubectl create secret generic db-credentials \
  --from-literal=DB_USER=appuser \
  --from-literal=DB_PASSWORD=<password-from-file> \
  -n app
```

#### 6.3 Deploy Python API

```bash
# Create a simple deployment manifest
cat > python-api-deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: python-api
  namespace: app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: python-api
  template:
    metadata:
      labels:
        app: python-api
    spec:
      containers:
      - name: api
        image: python:3.11-slim
        ports:
        - containerPort: 5000
        envFrom:
        - configMapRef:
            name: db-config
        - secretRef:
            name: db-credentials
---
apiVersion: v1
kind: Service
metadata:
  name: python-api-service
  namespace: app
spec:
  selector:
    app: python-api
  ports:
  - port: 5000
    targetPort: 5000
  type: ClusterIP
EOF

kubectl apply -f python-api-deployment.yaml
```

#### 6.4 Deploy Angular UI

```bash
cat > angular-deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: angular-ui
  namespace: web
spec:
  replicas: 2
  selector:
    matchLabels:
      app: angular-ui
  template:
    metadata:
      labels:
        app: angular-ui
    spec:
      containers:
      - name: ui
        image: nginx:latest
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: angular-ui-service
  namespace: web
spec:
  selector:
    app: angular-ui
  ports:
  - port: 80
    targetPort: 80
  type: LoadBalancer
EOF

kubectl apply -f angular-deployment.yaml
```

#### 6.5 Verify Deployments

```bash
# Check deployments
kubectl get deployments -A

# Check pods
kubectl get pods -A

# Check services
kubectl get services -A

# Get external IP for Angular UI
kubectl get svc angular-ui-service -n web
# Access via: http://<EXTERNAL-IP>
```

---

## 🔧 Post-Deployment Operations

### Access Kubernetes Dashboard

```bash
# Method 1: Port Forward
kubectl port-forward -n kubernetes-dashboard \
  svc/kubernetes-dashboard 8443:443 --address=0.0.0.0

# Method 2: Create proxy
kubectl proxy --address=0.0.0.0 --accept-hosts='.*'

# Get dashboard token
kubectl -n kubernetes-dashboard create token admin-user

# Access:
# https://<MASTER_IP>:8443 (Method 1)
# http://<MASTER_IP>:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/ (Method 2)
```

### Monitor Cluster

```bash
# Watch node metrics
kubectl top nodes -w

# Watch pod metrics
kubectl top pods -A -w

# Watch events
kubectl get events -A -w

# View logs
kubectl logs -f -n <namespace> <pod-name>
```

### Scale Applications

```bash
# Scale deployment
kubectl scale deployment <name> --replicas=5 -n <namespace>

# Set resource requests/limits
kubectl set resources deployment <name> \
  -n <namespace> \
  --requests=cpu=100m,memory=128Mi \
  --limits=cpu=500m,memory=512Mi
```

---

## ⚠️ Common Issues & Solutions

### Issue 1: Nodes in NotReady State

```bash
# Check kubelet status
ssh -i k8s-cluster.pem ubuntu@<NODE_IP>
sudo journalctl -u kubelet -f

# Potential fixes:
sudo systemctl restart kubelet
sudo systemctl status kubelet

# Check network connectivity
ping 8.8.8.8
```

### Issue 2: Pods Pending

```bash
# Check pod events
kubectl describe pod <pod-name> -n <namespace>

# Check resource availability
kubectl top nodes
kubectl describe nodes

# Potential fixes:
# - Add more nodes
# - Adjust resource requests
# - Check storage availability
```

### Issue 3: Database Connection Failed

```bash
# Test connectivity from pod
kubectl run -it --rm debug --image=ubuntu:22.04 -- bash
apt-get update && apt-get install -y telnet
telnet 10.0.3.10 3306

# Check security groups
aws ec2 describe-security-groups \
  --group-ids <DB_SG_ID> \
  --query 'SecurityGroups[0].IpPermissions'

# Verify DB is running
ssh -i k8s-cluster.pem ubuntu@$MASTER_IP
ssh ubuntu@10.0.3.10
sudo systemctl status mysql
```

---

## 🧹 Cleanup

When you're done, delete all resources to avoid ongoing charges:

```bash
# Destroy all infrastructure
terraform destroy -auto-approve

# Confirm deletion
terraform plan
# Should show: 0 resources

# Remove state files (optional)
rm -f terraform.tfstate terraform.tfstate.backup
rm -rf .terraform/
```

---

## 📚 Learning Resources

- [Kubernetes Official Docs](https://kubernetes.io/docs/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [kubeadm Installation Guide](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/)
- [Calico Networking](https://docs.projectcalico.org/)
- [MySQL Kubernetes Deployment](https://kubernetes.io/docs/tasks/run-application/run-replicated-stateful-application/)

---

## 🚀 Next Steps

After successful deployment:

1. **Configure Ingress**: Set up NGINX ingress for external access
2. **Enable SSL/TLS**: Add certificate management (cert-manager)
3. **Setup Monitoring**: Deploy Prometheus + Grafana
4. **Configure Logging**: Add ELK stack or Loki
5. **Implement GitOps**: Use ArgoCD or Flux for deployments
6. **Setup CI/CD**: Integrate with Jenkins or GitHub Actions
7. **Enable Autoscaling**: Configure HPA and cluster autoscaler
8. **Backup Strategy**: Implement Velero for cluster backups

---

**Documentation Version**: 1.0  
**Created**: 2026-03-19  
**Status**: Complete and Ready for Deployment
