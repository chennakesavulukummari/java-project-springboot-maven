# Self-Hosted Kubernetes Cluster with 3-Tier Application Architecture

## Project Overview

This document outlines the infrastructure design and deployment strategy for a self-hosted Kubernetes cluster running on AWS EC2 instances with a 3-tier application architecture.

---

## 1. Infrastructure Architecture

### 1.1 Kubernetes Cluster Nodes

| Node Type | Operating System | Instance Type | vCPU | Memory | Storage | Purpose |
|-----------|-----------------|---------------|------|--------|---------|---------|
| Master CP | Linux (Ubuntu) | t3.medium | 2 | 4GB | 30GB | Kubernetes Control Plane |
| Slave CP | Linux (Ubuntu) | t3.medium | 2 | 4GB | 30GB | HA Control Plane Backup |
| Worker Node 1 | Linux (Ubuntu) | t3.large | 2 | 8GB | 50GB | Web Tier (Angular UI) |
| Worker Node 2 | Windows Server | t3.large | 2 | 8GB | 50GB | App Tier (Python Backend) |
| DB Node | Linux (Ubuntu) | t3.large | 2 | 8GB | 100GB | Database Tier (MySQL) |

**Total: 5 EC2 Instances**

---

## 2. 3-Tier Application Architecture

### 2.1 Tier Breakdown

```
┌─────────────────────────────────────────────────────────────┐
│                    Kubernetes Cluster                       │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐ │
│  │   Web Tier   │  │   App Tier   │  │   Database Tier  │ │
│  │              │  │              │  │                  │ │
│  │ Angular UI   │  │ Python API   │  │ MySQL Server     │ │
│  │              │  │              │  │                  │ │
│  │ Linux Node   │  │ Windows Node │  │ Linux Node       │ │
│  └──────────────┘  └──────────────┘  └──────────────────┘ │
│                                                              │
│  Kubernetes Dashboard - Central Monitoring                 │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 Tier Details

#### **Web Tier**
- **Platform**: Linux (Ubuntu) - Worker Node 1
- **Application**: Angular UI
- **Container**: Docker Container running Nginx/Node.js
- **Port**: 80/443 (HTTP/HTTPS)
- **Replicas**: 2-3 (for HA)

#### **App Tier**
- **Platform**: Windows Server - Worker Node 2
- **Application**: Python Backend/Service
- **Container**: Windows Container (.NET or Python)
- **Port**: 5000/8000 (API)
- **Replicas**: 2-3 (for HA)

#### **Database Tier**
- **Platform**: Linux (Ubuntu) - Separate Node
- **Database**: MySQL 8.0
- **Storage**: Persistent Volume (100GB)
- **Port**: 3306
- **Backups**: Daily automated backups

---

## 3. Kubernetes Components

### 3.1 Control Plane (HA Setup)
- **Master CP**: Primary control plane (etcd, kube-apiserver, kube-controller-manager, kube-scheduler)
- **Slave CP**: Secondary control plane for high availability
- **Load Balancer**: AWS ELB/ALB for control plane HA (optional)

### 3.2 Add-ons & Services
- **Kubernetes Dashboard**: For cluster monitoring and management
- **kube-proxy**: Network routing and service discovery
- **CNI Plugin**: Calico/Flannel for pod networking
- **CoreDNS**: Internal DNS service

### 3.3 Application Services
- **Web Service**: ClusterIP + LoadBalancer
- **App Service**: ClusterIP service
- **Database Service**: ClusterIP service

---

## 4. Networking

### 4.1 Network Architecture

```
VPC CIDR: 10.0.0.0/16

Subnets:
├── Public Subnet-1: 10.0.1.0/24 (Master CP, Worker-Linux)
├── Public Subnet-2: 10.0.2.0/24 (Slave CP, Worker-Windows)
└── Private Subnet: 10.0.3.0/24 (Database Node)

Pod Network: 172.16.0.0/12 (Kubernetes CNI)
Service Network: 10.32.0.0/24 (Kubernetes Services)
```

### 4.2 Security Groups

| Name | Rules |
|------|-------|
| Control Plane SG | 6443 (API), 2379-2380 (etcd), 10250 (kubelet) |
| Worker Node SG | 10250 (kubelet), 30000-32767 (NodePort services) |
| Database SG | 3306 (MySQL) - only from App Tier |
| Load Balancer SG | 80, 443 (HTTP/HTTPS) |

---

## 5. Storage & Persistence

### 5.1 Persistent Volumes
- **Database PV**: 100GB EBS volume attached to DB Node
- **Application PV**: Optional shared storage for logs/configs (20GB EBS)

### 5.2 Storage Classes
- **EBS Storage Class**: For dynamic PVC provisioning
- **Local Storage**: For etcd on master nodes

---

## 6. Monitoring & Logging

### 6.1 Kubernetes Dashboard
- Centralized UI for cluster monitoring
- Pod/Node metrics and health status
- Service and resource management

### 6.2 Logging Strategy
- **Container Logs**: Docker/containerd logs on nodes
- **Application Logs**: Centralized to CloudWatch/ELK (optional)
- **Audit Logs**: Kubernetes API audit logs

---

## 7. Terraform Implementation Plan

### 7.1 Directory Structure
```
k8s-selfhosted/
├── ARCHITECTURE.md (this file)
├── main.tf
├── variables.tf
├── outputs.tf
├── providers.tf
├── versions.tf
├── networking.tf
├── security-groups.tf
├── ec2-instances.tf
├── user-data/
│   ├── master-cp-init.sh
│   ├── slave-cp-init.sh
│   ├── worker-linux-init.sh
│   ├── worker-windows-init.ps1
│   └── db-init.sh
├── helm-values/
│   ├── kubernetes-dashboard-values.yaml
│   └── nginx-ingress-values.yaml
└── README.md
```

### 7.2 Terraform Modules
1. **Networking Module**: VPC, Subnets, Route Tables, NAT Gateway
2. **Security Module**: Security Groups, NACLs, IAM roles
3. **EC2 Module**: Instance provisioning with user-data scripts
4. **Kubernetes Module**: Dashboard and add-ons installation

---

## 8. Deployment Steps

### Phase 1: Infrastructure Setup (Terraform)
- [ ] Create VPC and networking
- [ ] Configure security groups
- [ ] Launch EC2 instances
- [ ] Attach EBS volumes

### Phase 2: Kubernetes Cluster Setup
- [ ] Install kubelet, kubeadm, kubectl on all nodes
- [ ] Initialize Master CP (kubeadm init)
- [ ] Join Slave CP (kubeadm join with --control-plane flag)
- [ ] Join Worker Nodes (kubeadm join)
- [ ] Install CNI plugin (Calico)
- [ ] Verify cluster health

### Phase 3: Add-ons Installation
- [ ] Deploy Kubernetes Dashboard
- [ ] Install metrics-server
- [ ] Configure RBAC for dashboard access
- [ ] Deploy ingress controller (NGINX)

### Phase 4: Application Deployment
- [ ] Create namespaces (web, app, database)
- [ ] Deploy MySQL database and PVC
- [ ] Deploy Python API application
- [ ] Deploy Angular UI application
- [ ] Create services and ingress rules

### Phase 5: Verification & Testing
- [ ] Cluster health check
- [ ] Pod connectivity verification
- [ ] Application tier communication test
- [ ] Database connectivity test
- [ ] Dashboard accessibility test

---

## 9. Cost Estimation

| Resource | Count | Instance Type | Monthly Cost |
|----------|-------|---------------|--------------|
| Master CP | 1 | t3.medium | ~$30 |
| Slave CP | 1 | t3.medium | ~$30 |
| Worker-Linux | 1 | t3.large | ~$60 |
| Worker-Windows | 1 | t3.large | ~$100 |
| DB Node | 1 | t3.large | ~$60 |
| EBS Volumes (180GB) | 1 | - | ~$18 |
| Elastic IPs (2) | 2 | - | ~$14 |
| **Total Monthly** | - | - | **~$312** |

---

## 10. Security Considerations

### 10.1 Network Security
- [ ] Restrict inbound traffic to required ports only
- [ ] Use private subnets for database tier
- [ ] Enable VPC Flow Logs for audit
- [ ] Use Security Groups as firewalls

### 10.2 Kubernetes Security
- [ ] Enable RBAC on all clusters
- [ ] Use network policies for pod isolation
- [ ] Enable audit logging
- [ ] Restrict API server access
- [ ] Use secrets for sensitive data

### 10.3 Data Security
- [ ] Encrypt EBS volumes
- [ ] Enable MySQL password authentication
- [ ] Use TLS for inter-pod communication
- [ ] Regular backup strategy for databases

---

## 11. Maintenance & Operations

### 11.1 Regular Tasks
- [ ] Monitor cluster resource utilization
- [ ] Perform node updates and patching
- [ ] Review and rotate credentials
- [ ] Test disaster recovery procedures
- [ ] Analyze logs for security issues

### 11.2 Scaling Strategy
- Horizontal Pod Autoscaling (HPA) for web/app tiers
- Vertical Pod Autoscaling (VPA) for performance tuning
- Cluster autoscaling for worker nodes (future enhancement)

---

## 12. Disaster Recovery

### 12.1 Backup Strategy
- **etcd Snapshots**: Daily automated snapshots
- **Database Backups**: Daily MySQL backups
- **Configuration Backup**: Kubernetes manifests in Git

### 12.2 Recovery Procedures
- Master node recovery procedure
- Database recovery steps
- Application redeployment plan
- RTO: 4 hours | RPO: 1 hour

---

## 13. References & Documentation

- [Kubernetes Official Documentation](https://kubernetes.io/docs/)
- [kubeadm Setup Guide](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Kubernetes Dashboard](https://github.com/kubernetes/dashboard)
- [Calico Networking](https://docs.projectcalico.org/)

---

**Document Version**: 1.0  
**Last Updated**: 2026-03-19  
**Status**: Ready for Implementation
