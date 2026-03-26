# 📦 Complete Project Structure

## Self-Hosted Kubernetes Cluster on AWS EC2

```
/Users/ck/github-repos/java-project-springboot-maven/infra/k8s-selfhosted/
│
├── 📖 DOCUMENTATION LAYER
│   ├── INDEX.md                      ← START HERE - Navigation guide
│   ├── PROJECT_SUMMARY.md            ← Executive overview
│   ├── ARCHITECTURE.md               ← Detailed design document
│   ├── DIAGRAMS.md                   ← 10 Visual diagrams
│   ├── DEPLOYMENT_GUIDE.md           ← Step-by-step instructions
│   └── README.md                     ← Complete reference guide
│
├── 🏗️ TERRAFORM INFRASTRUCTURE CODE
│   ├── main.tf                       ← Core infrastructure (650+ lines)
│   │   ├── VPC & Networking
│   │   ├── Security Groups (3)
│   │   ├── EC2 Instances (5)
│   │   ├── EBS Volumes
│   │   ├── IAM Roles
│   │   └── Outputs
│   │
│   ├── variables.tf                  ← Configuration variables (150+ lines)
│   │   ├── AWS settings
│   │   ├── Network CIDR blocks
│   │   ├── Instance types
│   │   ├── Security settings
│   │   └── Tag configuration
│   │
│   ├── outputs.tf                    ← Output values (100+ lines)
│   │   ├── IP addresses
│   │   ├── Resource IDs
│   │   ├── Connection strings
│   │   └── Bootstrap tokens
│   │
│   └── versions.tf                   ← Version requirements (10 lines)
│       ├── Terraform >= 1.0
│       ├── AWS provider >= 5.0
│       └── Random provider >= 3.0
│
├── 🔧 INITIALIZATION SCRIPTS
│   └── user-data/
│       ├── master-cp-init.sh         ← Master control plane setup (260 lines)
│       │   ├── System prep
│       │   ├── Containerd install
│       │   ├── Kubernetes install
│       │   ├── Cluster init
│       │   ├── Calico CNI
│       │   └── Validation
│       │
│       ├── slave-cp-init.sh          ← Slave CP for HA (200 lines)
│       │   ├── System prep
│       │   ├── Container runtime
│       │   ├── K8s components
│       │   ├── Cluster join
│       │   ├── etcd replication
│       │   └── Verification
│       │
│       ├── worker-linux-init.sh      ← Linux worker node (160 lines)
│       │   ├── System setup
│       │   ├── Container runtime
│       │   ├── K8s installation
│       │   ├── Cluster joining
│       │   ├── Node labeling
│       │   └── kubectl config
│       │
│       ├── worker-windows-init.ps1   ← Windows worker node (220 lines)
│       │   ├── Feature enablement
│       │   ├── Docker install
│       │   ├── K8s binaries
│       │   ├── Network config
│       │   ├── Cluster join
│       │   └── Service setup
│       │
│       └── db-init.sh                ← Database node setup (280 lines)
│           ├── Volume mounting
│           ├── MySQL install
│           ├── Configuration
│           ├── App database
│           ├── Backup setup
│           └── Replication config
```

---

## 📊 File Summary

### Documentation (6 Files)

| File | Purpose | Lines | Read Time |
|------|---------|-------|-----------|
| INDEX.md | Navigation & guide | 400 | 10 min |
| PROJECT_SUMMARY.md | Executive overview | 350 | 5 min |
| ARCHITECTURE.md | Design document | 350 | 15 min |
| DIAGRAMS.md | Visual diagrams | 500 | 10 min |
| DEPLOYMENT_GUIDE.md | Step-by-step | 700 | 30 min |
| README.md | Complete reference | 600 | 30 min |

**Total Documentation: 2,900 lines**

### Infrastructure Code (4 Files)

| File | Purpose | Lines |
|------|---------|-------|
| main.tf | Core infrastructure | 650 |
| variables.tf | Configuration | 150 |
| outputs.tf | Results | 100 |
| versions.tf | Requirements | 10 |

**Total IaC Code: 910 lines**

### Initialization Scripts (5 Files)

| File | Purpose | Lines |
|------|---------|-------|
| master-cp-init.sh | Master CP setup | 260 |
| slave-cp-init.sh | Slave CP setup | 200 |
| worker-linux-init.sh | Linux worker | 160 |
| worker-windows-init.ps1 | Windows worker | 220 |
| db-init.sh | MySQL database | 280 |

**Total Scripts: 1,120 lines**

---

## 🎯 File Purpose Matrix

### 📖 If you want to...

| Goal | Read | Terraform | Script |
|------|------|-----------|--------|
| Understand the project | INDEX.md | - | - |
| Get overview | PROJECT_SUMMARY.md | - | - |
| See visual architecture | DIAGRAMS.md | - | - |
| Learn detailed design | ARCHITECTURE.md | main.tf | - |
| Deploy step-by-step | DEPLOYMENT_GUIDE.md | ✓ | ✓ |
| Complete reference | README.md | ✓ | ✓ |
| Customize config | - | variables.tf | - |
| Check outputs | - | outputs.tf | - |
| Debug issues | README.md | main.tf | user-data/* |

---

## 🚀 Quick Access Guide

### To Deploy
```bash
# 1. Read the guide
cat DEPLOYMENT_GUIDE.md

# 2. Initialize
terraform init

# 3. Plan
terraform plan -out=tfplan

# 4. Apply
terraform apply tfplan
```

### To Understand
```bash
# Start here
cat INDEX.md

# Then read
cat PROJECT_SUMMARY.md
cat DIAGRAMS.md
cat ARCHITECTURE.md
```

### To Troubleshoot
```bash
# Check deployment guide
grep -A 30 "Troubleshooting" DEPLOYMENT_GUIDE.md

# Check main readme
grep -A 30 "Troubleshooting" README.md

# Check logs
cloud-init logs -f
journalctl -u kubelet -f
```

### To Customize
```bash
# View available variables
cat variables.tf

# Create custom config
cat > terraform.tfvars << EOF
aws_region = "us-west-2"
cluster_name = "my-cluster"
EOF
```

---

## 📋 What Gets Created

### AWS Resources
- 1 VPC (10.0.0.0/16)
- 3 Subnets (public x2, private x1)
- 1 Internet Gateway
- 1 NAT Gateway
- 3 Security Groups
- 5 EC2 Instances
- 1 EBS Volume (100GB)
- 2 Elastic IPs
- 1 IAM Role + Instance Profile

### Kubernetes Resources
- 2 Control Plane nodes (HA)
- 2 Worker nodes (Linux + Windows)
- 1 Calico CNI deployment
- 1 CoreDNS deployment
- 1 Metrics Server
- 1 Kubernetes Dashboard
- 1 Default network policy

### Application Resources
- 1 MySQL 8.0 database
- Pre-created application_db
- Default application user
- Backup scripts
- Replication configuration

---

## 🔄 Deployment Flow

```
Phase 1: Terraform Deploy (15 min)
└─ Creates infrastructure
   ├─ VPC, Subnets, Security Groups
   ├─ 5 EC2 Instances
   ├─ EBS Volumes
   ├─ IAM Roles
   └─ Launches user-data scripts

Phase 2: Master Control Plane (15 min)
└─ user-data/master-cp-init.sh runs
   ├─ System updates
   ├─ Containerd installation
   ├─ K8s component installation
   ├─ kubeadm cluster init
   ├─ Calico CNI install
   └─ Cluster ready for workers

Phase 3: Slave Control Plane (15 min)
└─ user-data/slave-cp-init.sh runs
   ├─ Waits for master
   ├─ Installs K8s components
   ├─ Joins as control plane
   ├─ Sets up etcd replication
   └─ HA control plane ready

Phase 4: Worker Nodes (10 min)
├─ Linux worker joins cluster
├─ Windows worker joins cluster
└─ Both in Ready state

Phase 5: Database (10 min)
└─ user-data/db-init.sh runs
   ├─ Mounts EBS volume
   ├─ MySQL installation
   ├─ Application database
   ├─ Backup configuration
   └─ Replication ready

Total: ~60-70 minutes
```

---

## 💾 Data & State Management

### Terraform State
```
.terraform/           ← Local state directory
terraform.tfstate     ← Current state (create terraform.tfvars)
terraform.tfstate.bak ← Backup state
.terraform.lock.hcl   ← Provider lock file
```

### Outputs
```
cluster-info.json     ← Generated outputs from terraform
k8s-cluster.pem       ← Your SSH private key
```

### Kubernetes Config
```
~/.kube/config        ← Local kubectl configuration (post-deployment)
```

---

## 🔐 Security Considerations

### Network Security
- Private subnet for database
- Security groups per component
- Restricted SSH access
- NAT Gateway for outbound

### Kubernetes Security
- RBAC enabled
- Network policies supported
- Secrets management
- Audit logging ready

### Data Security
- Encrypted EBS volumes
- MySQL authentication
- TLS-ready infrastructure
- Backup automation

---

## 📈 Scaling & Customization

### Easy to Customize
- Edit variables.tf for different instance types
- Modify main.tf for additional resources
- Update init scripts for custom software
- Add more worker nodes as needed

### Scaling Strategies
- Horizontal: Add more worker nodes
- Vertical: Increase instance types
- Pod level: HPA for application scaling
- Cluster level: Add more nodes

---

## 🎓 Learning Resources Included

1. **Kubernetes Learning**
   - Complete cluster setup
   - Multi-platform support
   - HA configuration

2. **Infrastructure as Code**
   - Terraform best practices
   - AWS provider usage
   - State management

3. **Cloud Architecture**
   - Network design patterns
   - Security group setup
   - High availability design

4. **Automation**
   - Bash scripting
   - PowerShell scripting
   - Cloud-init usage

---

## ✨ Key Features Included

- ✅ Complete documentation (2,900 lines)
- ✅ Production-grade code (910 lines)
- ✅ Automated setup (1,120 lines)
- ✅ 10 architecture diagrams
- ✅ 5 detailed guides
- ✅ 5 initialization scripts
- ✅ High availability setup
- ✅ Multi-platform support
- ✅ Security best practices
- ✅ Cost estimation

---

## 📊 Project Statistics

```
Total Files:           15
  Documentation:       6
  Terraform Code:      4
  Scripts:             5

Total Lines:        4,930
  Documentation:    2,900
  IaC Code:           910
  Scripts:          1,120

Components:
  EC2 Instances:       5
  Security Groups:     3
  Subnets:             3
  Storage:             100GB EBS

Services:
  Kubernetes:        1.28
  MySQL:            8.0
  Container Runtime: containerd
  CNI:              Calico
```

---

## 🚀 Getting Started (3 Steps)

### Step 1: Read
```bash
cat INDEX.md
```

### Step 2: Prepare
```bash
cat DEPLOYMENT_GUIDE.md | grep "Pre-Deployment"
```

### Step 3: Deploy
```bash
terraform init && terraform plan && terraform apply
```

---

**Version**: 1.0  
**Created**: 2026-03-19  
**Status**: ✅ Complete & Ready

**Start with INDEX.md → Follow DEPLOYMENT_GUIDE.md → Reference README.md**
