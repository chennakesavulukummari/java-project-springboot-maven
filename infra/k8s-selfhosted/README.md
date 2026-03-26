# Self-Hosted Kubernetes Cluster on AWS EC2

A comprehensive Terraform configuration for setting up a production-ready, self-hosted Kubernetes cluster on AWS EC2 instances with a 3-tier application architecture.

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Detailed Setup](#detailed-setup)
- [Configuration](#configuration)
- [Monitoring & Operations](#monitoring--operations)
- [Troubleshooting](#troubleshooting)
- [Cost Estimation](#cost-estimation)
- [Security Considerations](#security-considerations)

---

## 🎯 Overview

This project provides infrastructure-as-code (IaC) using Terraform to deploy:

- **4 EC2 Instances** for Kubernetes cluster:
  - 1 Master Control Plane (Ubuntu 22.04)
  - 1 Slave Control Plane for HA (Ubuntu 22.04)
  - 1 Linux Worker Node (Ubuntu 22.04)
  - 1 Windows Worker Node (Windows Server 2022)

- **1 Database Node** (Ubuntu 22.04 with MySQL 8.0)

- **Complete Networking**: VPC, Subnets, Security Groups, NAT Gateway

- **Kubernetes Components**: kubeadm, kubelet, kubectl, Calico CNI

- **Add-ons**: Kubernetes Dashboard, CoreDNS, Metrics Server

---

## 🏗️ Architecture

### Infrastructure Overview

```
AWS Region (us-east-1)
├── VPC (10.0.0.0/16)
│   ├── Public Subnet-1 (10.0.1.0/24) - Master CP, Worker-Linux
│   ├── Public Subnet-2 (10.0.2.0/24) - Slave CP, Worker-Windows
│   └── Private Subnet (10.0.3.0/24) - Database Node
├── Internet Gateway
├── NAT Gateway
├── EBS Volumes (180GB total)
└── Load Balancer (ALB)
```

### Kubernetes Cluster

```
Control Plane (HA)
├── Master CP Node
│   ├── etcd
│   ├── API Server (6443)
│   ├── Controller Manager
│   └── Scheduler
└── Slave CP Node (backup)
    ├── etcd (replicated)
    ├── API Server
    ├── Controller Manager
    └── Scheduler

Worker Nodes
├── Linux Worker (Web Tier)
│   ├── kubelet
│   ├── kube-proxy
│   └── Container Runtime (containerd)
└── Windows Worker (App Tier)
    ├── kubelet
    ├── kube-proxy
    └── Container Runtime (containerd)

Add-ons
├── Calico CNI (172.16.0.0/12)
├── CoreDNS
├── Metrics Server
└── Kubernetes Dashboard
```

### 3-Tier Application

```
Layer 1: Web Tier
├── Platform: Linux Worker Node
├── Application: Angular UI
├── Port: 80/443
└── Replicas: 2-3

Layer 2: App Tier
├── Platform: Windows Worker Node
├── Application: Python API
├── Port: 5000/8000
└── Replicas: 2-3

Layer 3: Database Tier
├── Platform: Database Node
├── Database: MySQL 8.0
├── Port: 3306
└── Storage: 100GB EBS
```

---

## 📦 Prerequisites

### Local Machine Requirements

1. **Terraform** >= 1.0
   ```bash
   terraform version
   ```

2. **AWS CLI** v2
   ```bash
   aws --version
   ```

3. **AWS Credentials** configured
   ```bash
   aws configure
   # or set AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY environment variables
   ```

4. **SSH Key Pair** created in AWS
   ```bash
   # Create a new key pair in AWS EC2 console, or
   aws ec2 create-key-pair --key-name k8s-cluster --region us-east-1 --output text > k8s-cluster.pem
   chmod 400 k8s-cluster.pem
   ```

5. **kubectl** installed locally (optional, for accessing cluster)
   ```bash
   curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/darwin/amd64/kubectl"
   chmod +x kubectl && sudo mv kubectl /usr/local/bin/
   ```

### AWS Account Requirements

- EC2 instance quota: at least 5 instances
- VPC quota: at least 1
- Elastic IP quota: at least 2
- EBS volume quota: at least 6 volumes
- Security groups: sufficient capacity

---

## 🚀 Quick Start

### 1. Clone and Navigate to Directory

```bash
cd infra/k8s-selfhosted
ls -la
```

### 2. Initialize Terraform

```bash
terraform init
```

### 3. Review Configuration

```bash
# Check default variables
cat terraform.tfvars  # Create if needed

# Or create custom tfvars file
cat > terraform.tfvars << EOF
aws_region     = "us-east-1"
cluster_name   = "k8s-selfhosted"
environment    = "production"

# Allow SSH from your IP only (recommended)
ssh_allowed_cidrs = ["YOUR_PUBLIC_IP/32"]
EOF
```

### 4. Plan Deployment

```bash
terraform plan -out=tfplan
```

### 5. Apply Configuration

```bash
terraform apply tfplan

# Or directly (prompts for confirmation)
terraform apply
```

### 6. Get Output Information

```bash
terraform output -json > cluster-info.json

# Or specific outputs
terraform output master_cp_public_ip
terraform output worker_linux_public_ip
```

---

## 🔧 Detailed Setup

### Step 1: Infrastructure Deployment (5-10 minutes)

Terraform will create:
- VPC and networking
- Security groups
- IAM roles
- EC2 instances
- EBS volumes

**Monitor deployment:**
```bash
terraform apply -auto-approve

# Watch EC2 instances starting
aws ec2 describe-instances --region us-east-1 \
  --filters "Name=tag:K8s-ClusterName,Values=k8s-selfhosted" \
  --query 'Reservations[*].Instances[*].[InstanceId,State.Name,PrivateIpAddress,PublicIpAddress]' \
  --output table
```

### Step 2: Master Control Plane Setup (10-15 minutes)

The master node initializes automatically via user-data script:

1. **Install containerd** (container runtime)
2. **Install Kubernetes tools** (kubeadm, kubelet, kubectl)
3. **Initialize cluster** with `kubeadm init`
4. **Install Calico CNI** for networking
5. **Save join commands** for worker nodes

**Verify master node:**
```bash
MASTER_IP=$(terraform output -raw master_cp_public_ip)
ssh -i k8s-cluster.pem ubuntu@$MASTER_IP

# Inside master node:
kubectl get nodes
kubectl get pods -A
```

### Step 3: Slave Control Plane Setup (10-15 minutes)

Joins as additional control plane for high availability:

1. Waits for master to be ready
2. Copies certificates from master
3. Joins with `--control-plane` flag
4. Replicates etcd database

**Verify slave node:**
```bash
SLAVE_IP=$(terraform output -raw slave_cp_public_ip)
ssh -i k8s-cluster.pem ubuntu@$SLAVE_IP
kubectl get nodes
```

### Step 4: Linux Worker Node Setup (5-10 minutes)

Joins as worker node:

1. Installs Kubernetes components
2. Configures containerd
3. Joins the cluster
4. Adds labels for workload placement

### Step 5: Windows Worker Node Setup (15-20 minutes)

**Note:** Windows node setup is more complex and may require manual steps:

1. Enables required Windows features (may require restart)
2. Installs Docker
3. Joins the cluster
4. Starts kubelet service

**Access Windows node:**
```bash
WINDOWS_IP=$(terraform output -raw worker_windows_public_ip)

# Get password from AWS console or use:
aws ec2 get-password-data --instance-id <instance-id> --priv-launch-template

# Connect via RDP
# Server: $WINDOWS_IP
# Username: Administrator
```

### Step 6: Database Node Setup (5-10 minutes)

Configures MySQL with:

1. Formats and mounts 100GB EBS volume
2. Installs MySQL 8.0
3. Creates application database
4. Sets up replication support
5. Configures automated backups

**Verify database:**
```bash
# From master node (DB is in private subnet)
ssh -i k8s-cluster.pem ubuntu@$MASTER_IP

# From there, SSH to DB node
ssh ubuntu@<DB_PRIVATE_IP>
mysql -uroot -p
# Password is saved in /var/lib/cloud/db-credentials.txt
```

### Step 7: Deploy Applications

After cluster is ready, deploy your applications:

```bash
# Deploy web tier (Angular)
kubectl apply -f manifests/web-tier-deployment.yaml

# Deploy app tier (Python)
kubectl apply -f manifests/app-tier-deployment.yaml

# Deploy database service (if using K8s pod for MySQL)
kubectl apply -f manifests/db-service.yaml

# Deploy ingress
kubectl apply -f manifests/ingress.yaml

# Access dashboard
kubectl proxy --address=0.0.0.0 --accept-hosts='.*'
# Open: http://MASTER_IP:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
```

---

## ⚙️ Configuration

### Variable Customization

Create `terraform.tfvars` to override defaults:

```hcl
# AWS Configuration
aws_region   = "us-east-1"
environment  = "production"

# Cluster Configuration
cluster_name = "k8s-selfhosted"

# Network Configuration
vpc_cidr              = "10.0.0.0/16"
public_subnet_1_cidr  = "10.0.1.0/24"
public_subnet_2_cidr  = "10.0.2.0/24"
private_subnet_cidr   = "10.0.3.0/24"
pod_cidr              = "172.16.0.0/12"
service_cidr          = "10.32.0.0/24"

# Instance Types
master_instance_type  = "t3.medium"
worker_instance_type  = "t3.large"
db_instance_type      = "t3.large"

# Security
ssh_allowed_cidrs = ["203.0.113.0/24", "198.51.100.0/24"]  # Your IPs
```

### File Structure

```
k8s-selfhosted/
├── ARCHITECTURE.md              # Detailed architecture document
├── DIAGRAMS.md                  # Mermaid diagrams
├── README.md                    # This file
│
├── main.tf                      # Main resources (VPC, EC2, EBS)
├── variables.tf                 # Variable definitions
├── outputs.tf                   # Output values
├── versions.tf                  # Terraform version requirements
│
├── user-data/                   # Initialization scripts
│   ├── master-cp-init.sh        # Master control plane setup
│   ├── slave-cp-init.sh         # Slave control plane setup
│   ├── worker-linux-init.sh     # Linux worker node setup
│   ├── worker-windows-init.ps1  # Windows worker node setup
│   └── db-init.sh               # Database node setup
│
├── helm-values/                 # Kubernetes manifests (future)
│   ├── kubernetes-dashboard-values.yaml
│   └── nginx-ingress-values.yaml
│
└── terraform.tfvars             # (Optional) Local overrides
```

---

## 📊 Monitoring & Operations

### Cluster Health Check

```bash
MASTER_IP=$(terraform output -raw master_cp_public_ip)
ssh -i k8s-cluster.pem ubuntu@$MASTER_IP

# Check cluster status
kubectl get nodes -o wide
kubectl get pods -A
kubectl top nodes
kubectl top pods -A

# Check cluster info
kubectl cluster-info
kubectl get componentstatuses
```

### Kubernetes Dashboard

Access the dashboard:

```bash
# Forward the dashboard
kubectl port-forward -n kubernetes-dashboard service/kubernetes-dashboard 8443:443 --address=0.0.0.0

# Create admin token
kubectl -n kubernetes-dashboard create token admin-user

# Access: https://MASTER_IP:8443 (with token)
```

### Node Logs

```bash
# SSH to any node
ssh -i k8s-cluster.pem ubuntu@<NODE_IP>

# View kubelet logs
journalctl -u kubelet -f

# View containerd logs
journalctl -u containerd -f

# Container logs
sudo crictl logs <CONTAINER_ID>
```

### Database Maintenance

```bash
# Access database node
ssh -i k8s-cluster.pem ubuntu@$DB_PRIVATE_IP

# Check MySQL status
sudo systemctl status mysql

# Monitor MySQL
mysql -uroot -p -e "SHOW PROCESSLIST;"
mysql -uroot -p -e "SHOW MASTER STATUS;"
mysql -uroot -p -e "SHOW SLAVE STATUS\G;"

# View backups
ls -lah /data/backups/
```

---

## 🔍 Troubleshooting

### Master Node Not Starting

```bash
ssh -i k8s-cluster.pem ubuntu@<MASTER_IP>

# Check user-data execution
cloud-init status
sudo cloud-init logs -f

# Check kubelet status
sudo journalctl -u kubelet -n 100 -f

# Check kubeadm logs
sudo cat /var/log/pods/kube-system_etcd-*/etcd/0.log
```

### Worker Node Can't Join

```bash
# On worker node
sudo journalctl -u kubelet -n 50

# Verify network connectivity to master
nc -zv <MASTER_PRIVATE_IP> 6443

# Check kubeadm join output
sudo cat /var/log/cloud-init-output.log
```

### Pods in CrashLoopBackOff

```bash
MASTER_IP=$(terraform output -raw master_cp_public_ip)
ssh -i k8s-cluster.pem ubuntu@$MASTER_IP

# Check pod status
kubectl describe pod <POD_NAME> -n <NAMESPACE>

# View logs
kubectl logs <POD_NAME> -n <NAMESPACE> --previous

# Check events
kubectl get events -A --sort-by='.lastTimestamp'
```

### Database Connection Issues

```bash
# Test MySQL connectivity from worker node
mysql -h <DB_PRIVATE_IP> -u appuser -p -e "SELECT 1;"

# Check MySQL logs
tail -f /data/mysql/error.log

# Verify security group allows port 3306
aws ec2 describe-security-groups --group-ids <DB_SG_ID>
```

### Network Issues

```bash
# Check CNI status
kubectl get daemonset -n calico-system

# Verify pods can communicate
kubectl run -it --rm debug --image=ubuntu:22.04 --restart=Never -- bash
# Inside pod: apt update && apt install -y curl iputils-ping
# ping <POD_IP>
# curl http://<SERVICE_IP>:PORT

# Check network policies
kubectl get networkpolicies -A
```

---

## 💰 Cost Estimation

Monthly costs (approximate, us-east-1, as of 2024):

| Resource | Count | Type | Monthly |
|----------|-------|------|---------|
| Master CP | 1 | t3.medium | $30 |
| Slave CP | 1 | t3.medium | $30 |
| Worker Linux | 1 | t3.large | $60 |
| Worker Windows | 1 | t3.large* | $100 |
| DB Node | 1 | t3.large | $60 |
| EBS Volumes | 180GB | gp3 | $18 |
| Elastic IPs | 2 | EIP | $14 |
| **Total** | | | **~$312** |

*Windows instances cost significantly more due to licensing

### Cost Optimization Tips

- Use Reserved Instances for long-term deployment
- Implement horizontal pod autoscaling
- Remove unused load balancers
- Use spot instances for non-critical workloads
- Right-size instances based on actual usage

---

## 🔐 Security Considerations

### Network Security

- [ ] Restrict SSH to your IP only in `ssh_allowed_cidrs`
- [ ] Database is in private subnet, not internet-accessible
- [ ] Security groups follow least privilege principle
- [ ] Enable VPC Flow Logs for audit

### Kubernetes Security

- [ ] RBAC enabled on all clusters
- [ ] Network policies prevent pod-to-pod communication by default
- [ ] Secrets encrypted in etcd
- [ ] API server audit logging enabled
- [ ] Pod Security Standards enforced

### Data Security

- [ ] EBS volumes encrypted
- [ ] MySQL uses strong authentication
- [ ] Daily automated database backups
- [ ] TLS for inter-pod communication
- [ ] Credentials saved in secure location

### Best Practices

1. **Rotate SSH Keys** regularly
2. **Update Kubernetes** version periodically
3. **Review IAM Permissions** quarterly
4. **Audit Logs** regularly
5. **Test Disaster Recovery** quarterly
6. **Use Secrets Management** for credentials
7. **Enable Network Policies** for isolation
8. **Implement Pod Security Policies**

---

## 🛠️ Maintenance

### Regular Tasks

```bash
# Update system packages
sudo apt-get update && sudo apt-get upgrade -y

# Update Kubernetes
kubeadm upgrade plan
kubeadm upgrade apply v1.29.0

# Backup cluster
etcdctl snapshot save backup.db

# Verify backups exist
ls -lah /data/backups/
```

### Scaling Operations

```bash
# Add more worker nodes
# 1. Modify instance count in variables
# 2. Run terraform apply

# Remove worker node gracefully
kubectl drain <NODE_NAME> --ignore-daemonsets --delete-emptydir-data
kubectl delete node <NODE_NAME>

# Scale application
kubectl scale deployment <APP> --replicas=5
```

---

## 📚 Additional Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [kubeadm Setup Guide](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Calico Networking](https://docs.projectcalico.org/)
- [MySQL Documentation](https://dev.mysql.com/doc/)

---

## 📝 Changelog

### v1.0 (2026-03-19)
- Initial release
- Support for Kubernetes 1.28
- 3-tier application architecture
- High availability control plane
- MySQL 8.0 database
- Automated initialization scripts

---

## ⚠️ Important Notes

1. **Windows Node Setup**: May require manual troubleshooting. Support for Windows containers in Kubernetes is complex.

2. **Production Use**: For production deployments, consider:
   - Using managed Kubernetes (EKS) instead
   - Adding monitoring and logging
   - Implementing auto-scaling
   - Setting up regular backups
   - Enabling cluster federation

3. **Support**: This is a reference implementation. For production support, consider commercial Kubernetes distributions.

4. **Costs**: Monitor AWS costs closely. This setup can incur significant monthly charges.

---

**Version**: 1.0  
**Last Updated**: 2026-03-19  
**Status**: Ready for Deployment
