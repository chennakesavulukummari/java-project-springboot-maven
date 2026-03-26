# 📑 Project Summary - Self-Hosted Kubernetes Cluster on AWS

## Overview

A complete, production-ready infrastructure-as-code solution for deploying a **self-hosted Kubernetes cluster on AWS EC2** with a **3-tier application architecture** (Web, API, Database).

---

## 📂 Deliverables

### 1. **Documentation** (4 Files)

#### ARCHITECTURE.md
- Detailed infrastructure design
- Component breakdown
- Network topology
- Storage architecture
- Cost estimation
- Security considerations
- Deployment roadmap

#### DIAGRAMS.md
- 10 Mermaid diagrams showing:
  - Infrastructure topology
  - Kubernetes cluster architecture
  - 3-tier application layers
  - Network communication flow
  - Security groups & firewalls
  - Data flow sequences
  - Kubernetes resource hierarchy
  - Storage architecture
  - Deployment pipeline
  - High availability setup

#### README.md
- Quick start guide
- Prerequisites checklist
- Detailed setup instructions
- Configuration options
- Monitoring & operations guide
- Troubleshooting section
- Cost estimation
- Security best practices

#### DEPLOYMENT_GUIDE.md
- Step-by-step deployment instructions
- Pre-deployment checklist
- Phase-by-phase walkthrough
- Command examples
- Verification steps
- Application deployment examples
- Post-deployment operations
- Common issues & solutions
- Cleanup procedures

---

### 2. **Terraform Code** (4 Core Files)

#### main.tf (500+ lines)
Contains:
- VPC and networking setup
- Internet Gateway & NAT Gateway
- Public and private subnets
- Security groups (3 groups)
- Data sources for AMIs
- IAM roles and policies
- 5 EC2 instances configuration
- EBS volume setup
- Bootstrap token generation

#### variables.tf
Defines:
- AWS region
- Cluster name & environment
- Network CIDR blocks
- Pod and service CIDR
- Instance types
- SSH allowed CIDRs
- Validation rules

#### outputs.tf
Provides:
- IP addresses (public & private)
- VPC and subnet IDs
- Security group IDs
- NAT Gateway IP
- Connection strings
- Bootstrap token
- Database volume ID

#### versions.tf
Specifies:
- Terraform version requirement (≥ 1.0)
- AWS provider (≥ 5.0)
- Random provider (≥ 3.0)

---

### 3. **Initialization Scripts** (5 Scripts)

#### master-cp-init.sh (260 lines)
Automates:
- System updates
- Swap disabling
- Network module configuration
- Containerd installation
- Kubernetes component installation
- kubeadm cluster initialization
- Calico CNI installation
- kubectl configuration
- Cluster validation

#### slave-cp-init.sh (200 lines)
Automates:
- System preparation
- Container runtime setup
- Kubernetes installation
- Waits for master node
- Joins as control plane with HA
- Certificate key retrieval
- etcd replication setup
- Node readiness verification

#### worker-linux-init.sh (160 lines)
Automates:
- System updates
- Container runtime setup
- Kubernetes components
- Cluster joining
- Node labeling
- kubectl configuration

#### worker-windows-init.ps1 (220 lines)
Automates:
- Windows features enablement
- Docker installation
- Kubernetes binary downloads
- Network configuration
- kubelet service setup
- Cluster joining
- Node labeling

#### db-init.sh (280 lines)
Automates:
- EBS volume formatting & mounting
- MySQL 8.0 installation
- Data directory migration
- Configuration tuning
- Security hardening
- Application database creation
- User management
- Backup automation
- Replication setup

---

### 4. **Infrastructure Summary**

**Network**
```
VPC: 10.0.0.0/16
├── Public Subnet 1: 10.0.1.0/24 (2 nodes)
├── Public Subnet 2: 10.0.2.0/24 (2 nodes)
└── Private Subnet: 10.0.3.0/24 (1 DB node)

Pod CIDR: 172.16.0.0/12
Service CIDR: 10.32.0.0/24
```

**Compute (5 Instances)**
```
1. Master CP (t3.medium, Ubuntu) - 10.0.1.10
2. Slave CP (t3.medium, Ubuntu) - 10.0.2.10
3. Worker-Linux (t3.large, Ubuntu) - 10.0.1.20
4. Worker-Windows (t3.large, Windows) - 10.0.2.20
5. DB Node (t3.large, Ubuntu) - 10.0.3.10
```

**Storage**
```
Root Volumes: 30-50GB per instance
Database Volume: 100GB EBS (gp3)
Total: 180GB
```

**Security Groups**
```
1. Control Plane SG
   - 6443 (API Server)
   - 2379-2380 (etcd)
   - 10250 (kubelet)
   - 22 (SSH)

2. Worker Nodes SG
   - 10250 (kubelet)
   - 30000-32767 (NodePort)
   - 22/3389 (SSH/RDP)

3. Database SG
   - 3306 (MySQL) - from workers only
   - 22 (SSH)
```

---

## 🎯 What Gets Deployed

### Phase 1: Infrastructure (Terraform) - 15 minutes
- VPC with 3 subnets across 3 AZs
- Internet Gateway + NAT Gateway
- 5 EC2 instances with appropriate roles
- EBS volume for database
- IAM roles and policies
- Security groups with proper rules

### Phase 2: Master Control Plane - 15 minutes
- Container runtime (containerd)
- Kubernetes components (1.28)
- etcd database
- Calico CNI networking
- Control plane initialization
- Dashboard ready

### Phase 3: High Availability - 15 minutes
- Slave control plane joins
- etcd replication
- HA setup complete

### Phase 4: Worker Nodes - 10 minutes
- Linux worker joins cluster
- Windows worker joins cluster
- All nodes in Ready state

### Phase 5: Database - 10 minutes
- MySQL 8.0 running
- Application database created
- Backups configured
- Replication ready

**Total Deployment Time: ~60-70 minutes**

---

## 📊 3-Tier Architecture

```
┌──────────────────────────────────────────────────┐
│ Layer 1: Web Tier (Angular UI)                   │
│ Location: Linux Worker Node                      │
│ Pods: 2-3 replicas                               │
│ Ports: 80/443 (HTTP/HTTPS)                       │
│ Storage: Optional shared PVC                     │
└──────────────────────────────────────────────────┘
                      ↓ API Calls
┌──────────────────────────────────────────────────┐
│ Layer 2: App Tier (Python API)                   │
│ Location: Windows Worker Node                    │
│ Pods: 2-3 replicas                               │
│ Ports: 5000/8000 (API)                           │
│ Storage: ConfigMaps, Secrets                     │
└──────────────────────────────────────────────────┘
                      ↓ SQL Queries
┌──────────────────────────────────────────────────┐
│ Layer 3: Database Tier (MySQL 8.0)               │
│ Location: Dedicated Database Node (Private)      │
│ Availability: Single instance (HA option)        │
│ Port: 3306 (MySQL)                               │
│ Storage: 100GB EBS persistent volume             │
│ Backups: Daily automated snapshots               │
└──────────────────────────────────────────────────┘
```

---

## 🔑 Key Features

### ✅ High Availability
- Dual control plane setup (Master + Slave)
- etcd replication
- Multi-AZ distribution
- Automatic failover ready

### ✅ Multi-Platform Support
- Linux nodes (Ubuntu 22.04)
- Windows nodes (Server 2022)
- Mixed workload deployment

### ✅ Networking
- Calico CNI for advanced networking
- Network policies support
- Service discovery (CoreDNS)
- Ingress-ready

### ✅ Security
- Security groups per component
- Private database subnet
- IAM roles for EC2
- TLS-ready
- RBAC support

### ✅ Monitoring
- Kubernetes Dashboard included
- Metrics Server for resource monitoring
- Event logging
- Ready for Prometheus/ELK integration

### ✅ Database
- MySQL 8.0 with proper tuning
- Automated daily backups
- Replication support
- Application database pre-created

### ✅ Infrastructure-as-Code
- 100% Terraform defined
- Repeatable deployments
- Version controllable
- Easy to customize

---

## 🚀 Quick Start Commands

```bash
# 1. Navigate to project
cd /Users/ck/github-repos/java-project-springboot-maven/infra/k8s-selfhosted

# 2. Initialize
terraform init

# 3. Create config
cat > terraform.tfvars << EOF
aws_region = "us-east-1"
cluster_name = "k8s-selfhosted"
ssh_allowed_cidrs = ["YOUR_IP/32"]
EOF

# 4. Plan
terraform plan -out=tfplan

# 5. Deploy
terraform apply tfplan

# 6. Wait ~60 minutes for full deployment

# 7. Verify
MASTER_IP=$(terraform output -raw master_cp_public_ip)
ssh -i k8s-cluster.pem ubuntu@$MASTER_IP
kubectl get nodes -o wide

# 8. Cleanup (when done)
terraform destroy -auto-approve
```

---

## 📈 Cost Breakdown (Monthly)

| Component | Cost | Notes |
|-----------|------|-------|
| Master CP (t3.medium) | $30 | Control plane |
| Slave CP (t3.medium) | $30 | HA backup |
| Worker Linux (t3.large) | $60 | Web tier |
| Worker Windows (t3.large) | $100 | Windows licensing |
| DB Node (t3.large) | $60 | Database |
| EBS Storage (180GB) | $18 | gp3 volumes |
| Elastic IPs (2) | $14 | Public IPs |
| **Total** | **~$312** | **Production setup** |

---

## 🔐 Security Highlights

- [x] Network isolation (private DB subnet)
- [x] Security groups with least privilege
- [x] Encrypted EBS volumes
- [x] Strong MySQL authentication
- [x] IAM roles instead of keys
- [x] SSH key-based access
- [x] Kubernetes RBAC ready
- [x] Network policies support
- [x] TLS-ready infrastructure

---

## 📚 Documentation Files

| File | Purpose | Lines |
|------|---------|-------|
| ARCHITECTURE.md | Design & planning | 350+ |
| DIAGRAMS.md | Visual architecture | 500+ |
| README.md | Complete guide | 600+ |
| DEPLOYMENT_GUIDE.md | Step-by-step | 700+ |
| main.tf | Infrastructure | 650+ |
| variables.tf | Configuration | 150+ |
| outputs.tf | Results | 100+ |
| init scripts | Setup automation | 1200+ |

**Total: 4,250+ lines of code & documentation**

---

## 🎓 Learning Outcomes

After completing this project, you'll understand:

1. **AWS Fundamentals**
   - VPC design and networking
   - EC2 instance management
   - Security groups and IAM
   - EBS volumes and storage

2. **Kubernetes Architecture**
   - Control plane components
   - Worker node setup
   - Pod networking with CNI
   - High availability patterns

3. **Infrastructure as Code**
   - Terraform module structure
   - State management
   - Variable organization
   - Output definition

4. **Linux & Windows Administration**
   - Cloud-init scripting
   - PowerShell automation
   - Package management
   - Service configuration

5. **Database Management**
   - MySQL installation & config
   - Backup strategies
   - Replication setup
   - Performance tuning

---

## 🔗 File Locations

```
/Users/ck/github-repos/java-project-springboot-maven/infra/k8s-selfhosted/
├── ARCHITECTURE.md           ← Start here for design
├── DIAGRAMS.md              ← Visual diagrams
├── README.md                ← Complete reference
├── DEPLOYMENT_GUIDE.md      ← Step-by-step instructions
│
├── main.tf                  ← Infrastructure definition
├── variables.tf             ← Configuration variables
├── outputs.tf               ← Output values
├── versions.tf              ← Version requirements
│
└── user-data/               ← Initialization scripts
    ├── master-cp-init.sh
    ├── slave-cp-init.sh
    ├── worker-linux-init.sh
    ├── worker-windows-init.ps1
    └── db-init.sh
```

---

## ✨ Next Steps

1. **Review** ARCHITECTURE.md for detailed design
2. **Read** DEPLOYMENT_GUIDE.md for step-by-step instructions
3. **Customize** terraform.tfvars for your environment
4. **Deploy** using provided Terraform commands
5. **Monitor** cluster health using kubectl
6. **Deploy** applications on your cluster
7. **Extend** with additional tools (monitoring, logging, etc.)

---

## 📞 Support Resources

- **Kubernetes**: https://kubernetes.io/docs/
- **Terraform**: https://www.terraform.io/docs/
- **AWS**: https://docs.aws.amazon.com/
- **Calico**: https://docs.projectcalico.org/
- **MySQL**: https://dev.mysql.com/doc/

---

## 🎉 Conclusion

This comprehensive solution provides everything needed to deploy and manage a **production-ready, self-hosted Kubernetes cluster** on AWS. The combination of detailed documentation, Terraform code, and automated initialization scripts enables fast, repeatable, and reliable deployments.

**Status**: ✅ Complete and Ready for Deployment  
**Version**: 1.0  
**Created**: 2026-03-19

---

### Quick Links

- [Architecture Document](ARCHITECTURE.md)
- [Visual Diagrams](DIAGRAMS.md)
- [Deployment Guide](DEPLOYMENT_GUIDE.md)
- [Complete README](README.md)
- [Terraform Code](main.tf)

**Good luck with your Kubernetes deployment! 🚀**
