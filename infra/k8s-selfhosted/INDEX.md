# 📚 Documentation Index

## Welcome to Self-Hosted Kubernetes on AWS

This is your complete guide to deploying a production-ready Kubernetes cluster on AWS EC2 with a 3-tier application architecture.

---

## 📖 Reading Guide

### 🎯 Start Here

1. **[PROJECT_SUMMARY.md](PROJECT_SUMMARY.md)** ⭐
   - Overview of the entire project
   - What gets deployed
   - Quick reference
   - File locations
   - **Read this first (5 min)**

### 🏗️ Planning & Design

2. **[ARCHITECTURE.md](ARCHITECTURE.md)** 
   - Detailed infrastructure design
   - Network architecture (10 sections)
   - Security considerations
   - Cost estimation table
   - Deployment phases
   - **Read before deployment (15 min)**

3. **[DIAGRAMS.md](DIAGRAMS.md)**
   - 10 Mermaid diagrams
   - Visual representations
   - Network flows
   - Data paths
   - Component hierarchy
   - **Reference during design (10 min)**

### 🚀 Getting Started

4. **[DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)**
   - Step-by-step deployment instructions
   - Pre-flight checklist
   - 6 deployment phases
   - Command examples
   - Troubleshooting tips
   - **Follow during deployment (60 min)**

### 📖 Complete Reference

5. **[README.md](README.md)**
   - Comprehensive documentation
   - All details and options
   - Configuration reference
   - Monitoring & operations
   - Best practices
   - **Reference manual (30 min)**

### 💻 Infrastructure Code

6. **Terraform Files**
   - [main.tf](main.tf) - Core infrastructure
   - [variables.tf](variables.tf) - Configuration
   - [outputs.tf](outputs.tf) - Results
   - [versions.tf](versions.tf) - Requirements

### 🔧 Initialization Scripts

7. **[user-data/](user-data/)** directory
   - [master-cp-init.sh](user-data/master-cp-init.sh) - Master setup
   - [slave-cp-init.sh](user-data/slave-cp-init.sh) - HA setup
   - [worker-linux-init.sh](user-data/worker-linux-init.sh) - Linux worker
   - [worker-windows-init.ps1](user-data/worker-windows-init.ps1) - Windows worker
   - [db-init.sh](user-data/db-init.sh) - MySQL database

---

## 🎯 Quick Navigation by Use Case

### 👤 I'm a **Beginner** to Kubernetes

**Recommended Reading Order:**
1. PROJECT_SUMMARY.md (overview)
2. DIAGRAMS.md (visual understanding)
3. ARCHITECTURE.md (design details)
4. DEPLOYMENT_GUIDE.md (hands-on)

**Key Sections:**
- Understanding the 3-tier architecture
- Network topology diagrams
- Step-by-step deployment phases

### 🏢 I'm an **Architect** designing infrastructure

**Recommended Reading Order:**
1. ARCHITECTURE.md (full design)
2. DIAGRAMS.md (visual validation)
3. README.md (reference details)
4. Terraform code (implementation)

**Key Sections:**
- Network architecture & subnets
- Security group design
- HA control plane setup
- Cost estimation

### 🚀 I want to **Deploy NOW**

**Quick Path:**
1. PROJECT_SUMMARY.md - Quick start section
2. DEPLOYMENT_GUIDE.md - Follow Phase by Phase
3. Keep README.md handy for troubleshooting

**Commands to use:**
```bash
cd /Users/ck/github-repos/java-project-springboot-maven/infra/k8s-selfhosted
cat DEPLOYMENT_GUIDE.md | less
# Follow along with the guide!
```

### 🔧 I'm **Troubleshooting** an issue

**Go to:**
1. DEPLOYMENT_GUIDE.md - "Troubleshooting" section
2. README.md - "Troubleshooting" section
3. Check user-data scripts for initialization issues

### 📚 I want a **Complete Reference**

**Use:**
1. README.md - 600+ line comprehensive guide
2. ARCHITECTURE.md - All design aspects
3. Terraform code comments - Implementation details

---

## 📊 File Overview

| File | Purpose | Size | Read Time |
|------|---------|------|-----------|
| PROJECT_SUMMARY.md | Executive overview | 3KB | 5 min |
| ARCHITECTURE.md | Design & planning | 12KB | 15 min |
| DIAGRAMS.md | Visual diagrams | 15KB | 10 min |
| DEPLOYMENT_GUIDE.md | Step-by-step | 20KB | 30 min |
| README.md | Complete reference | 25KB | 30 min |
| main.tf | Infrastructure | 20KB | 20 min |
| variables.tf | Configuration | 4KB | 5 min |
| outputs.tf | Results | 3KB | 5 min |
| versions.tf | Version spec | 1KB | 2 min |
| Init scripts | Setup (5 files) | 15KB | 20 min |

**Total Documentation: 4,250+ lines**

---

## 🎓 Learning Path

### Level 1: Understanding (30 minutes)
- [ ] Read PROJECT_SUMMARY.md
- [ ] View DIAGRAMS.md
- [ ] Understand 3-tier architecture

### Level 2: Planning (1 hour)
- [ ] Study ARCHITECTURE.md
- [ ] Review DIAGRAMS.md diagrams
- [ ] Understand network design
- [ ] Review cost estimation

### Level 3: Deployment (90 minutes)
- [ ] Pre-flight checklist
- [ ] Follow DEPLOYMENT_GUIDE.md
- [ ] Deploy infrastructure
- [ ] Verify cluster

### Level 4: Operations (2 hours)
- [ ] Deploy sample apps
- [ ] Access dashboard
- [ ] Monitor cluster
- [ ] Test connectivity

### Level 5: Mastery (4+ hours)
- [ ] Deep dive into Terraform code
- [ ] Customize for your needs
- [ ] Extend with monitoring
- [ ] Setup CI/CD integration

---

## 🔗 External Resources

### Official Documentation
- [Kubernetes Docs](https://kubernetes.io/docs/) - Authoritative K8s guide
- [Terraform AWS Docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs) - AWS provider reference
- [AWS Documentation](https://docs.aws.amazon.com/) - Complete AWS guide
- [kubeadm Docs](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/) - kubeadm setup guide

### Additional Tools
- [Calico Networking](https://docs.projectcalico.org/) - Network policies
- [MySQL Docs](https://dev.mysql.com/doc/) - Database reference
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/) - Command reference

---

## ✅ Pre-Deployment Checklist

### 🖥️ Local Machine
- [ ] Terraform 1.0+ installed
- [ ] AWS CLI v2 installed
- [ ] SSH key pair created
- [ ] AWS credentials configured
- [ ] kubectl installed (optional)

### ☁️ AWS Account
- [ ] EC2 instance quota ≥ 5
- [ ] Elastic IP quota ≥ 2
- [ ] VPC available
- [ ] Appropriate IAM permissions

### 📋 Preparation
- [ ] Your public IP identified
- [ ] SSH key stored securely
- [ ] Budget approved (~$312/month)
- [ ] Deployment time available (2 hours)

---

## 🚀 Getting Started

### 1. Understand the Project
```bash
# Read the summary
cat PROJECT_SUMMARY.md | less

# Review the diagrams
cat DIAGRAMS.md | less
```

### 2. Plan Your Deployment
```bash
# Study the architecture
cat ARCHITECTURE.md | less

# Review cost estimate
grep -A 20 "Cost Estimation" ARCHITECTURE.md
```

### 3. Follow Deployment Guide
```bash
# Navigate to project directory
cd /Users/ck/github-repos/java-project-springboot-maven/infra/k8s-selfhosted

# Read the deployment guide
cat DEPLOYMENT_GUIDE.md | less

# Follow Phase 1, Phase 2, etc.
```

### 4. Deploy
```bash
# Initialize Terraform
terraform init

# Plan deployment
terraform plan -out=tfplan

# Deploy infrastructure
terraform apply tfplan
```

### 5. Verify
```bash
# Get master IP
MASTER_IP=$(terraform output -raw master_cp_public_ip)

# SSH to master
ssh -i k8s-cluster.pem ubuntu@$MASTER_IP

# Check cluster status
kubectl get nodes -o wide
```

---

## 💡 Tips & Tricks

### 📖 Reading Documentation
- Use `| less` for easier navigation
- Use `grep` to search for sections
- Create a paper copy for reference during deployment

### 🔍 Quick Searches
```bash
# Find cost information
grep -i "cost" *.md

# Find troubleshooting
grep -i "troubleshoot" *.md

# Find command examples
grep "kubectl\|terraform\|aws" DEPLOYMENT_GUIDE.md
```

### 🖨️ Printing Documentation
```bash
# Print to PDF (macOS)
cat README.md | pbcopy
# Then paste into any PDF converter

# Print to file
cat *.md > complete-documentation.txt
```

---

## 🆘 Need Help?

### ❓ Common Questions

**Q: Where do I start?**  
A: Begin with PROJECT_SUMMARY.md, then follow DEPLOYMENT_GUIDE.md

**Q: How long does deployment take?**  
A: Typically 60-70 minutes total

**Q: What's the monthly cost?**  
A: ~$312/month. See ARCHITECTURE.md for breakdown

**Q: Can I customize the setup?**  
A: Yes! Edit terraform.tfvars before deploying

**Q: Is this production-ready?**  
A: It's production-capable but add monitoring/logging for full production setup

### 🐛 Troubleshooting
- Check DEPLOYMENT_GUIDE.md troubleshooting section
- Check README.md troubleshooting section
- Review initialization logs: `cloud-init logs -f`
- Check component status: `kubectl describe node <name>`

### 📧 Resources
- Kubernetes: kubernetes.io
- Terraform: terraform.io
- AWS: aws.amazon.com
- GitHub Issues: Search similar issues

---

## 📋 Document Statistics

```
Documentation Files:     5 (.md files)
Terraform Files:        4 (.tf files)
Script Files:          5 (bash/PowerShell)
Total Code Lines:   4,250+
Total Diagrams:       10
Total Sections:       50+
Total Commands:      100+
```

---

## 🎯 Success Metrics

After completing all steps, you should have:

- ✅ 5 EC2 instances running
- ✅ 2 Kubernetes control planes
- ✅ 2 Worker nodes (Linux + Windows)
- ✅ 1 MySQL database
- ✅ Cluster in Ready state
- ✅ All pods running
- ✅ Services accessible
- ✅ Dashboard available

---

## 📞 Documentation Support

**Having issues with the documentation?**

1. Check the index you're reading (this file)
2. Search for keywords in all .md files
3. Follow the recommended reading order
4. Verify you have the latest version

---

**📚 Start with [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md)**

**🚀 Then follow [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)**

**📖 Reference [README.md](README.md) during operations**

---

Generated: 2026-03-19  
Documentation Version: 1.0  
Status: ✅ Complete
