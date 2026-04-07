# Packer Kubernetes AMI Build Status

## ✅ Issues Fixed

### 1. Duplicate `required_plugins` blocks
- **Problem**: Each `.pkr.hcl` file declared its own `packer` block with Amazon plugin requirements
- **Solution**: Added plugin declarations directly to each template file for standalone operation

### 2. PowerShell Variable Interpolation
- **Problem**: `${ControlPlaneIP}` in Windows worker template was being interpreted as Packer variable
- **Solution**: Escaped as `$${ControlPlaneIP}` to prevent interpolation

### 3. Incorrect Ubuntu AMI Owner
- **Problem**: Owner ID `225989338000` (old Canonical account) not found
- **Solution**: Updated to correct Canonical account ID `099720109477`

### 4. Non-existent VPC/Subnet
- **Problem**: VPC (`vpc-0305c51d2febe0d64`) and Subnet (`subnet-0ab7ef12823c1b8c3`) didn't exist in AWS account
- **Solution**: Set `vpc_id = ""` and `subnet_id = ""` to use default VPC

## ✅ Build Status

**Control Plane Build:** 🚀 **IN PROGRESS**

```
Instance ID: i-010c3a3e995a63a53
AMI Name: k8s-controlplane-1.34-20260407-020754
Status: Launched and waiting to become ready
```

**Build Log:** `/tmp/build-controlplane.log`

Monitor progress with:
```bash
tail -f /tmp/build-controlplane.log
```

## Build Commands

### Validate All Configurations
```bash
AWS_PROFILE=cf36 packer validate -var-file=prod.pkrvars.hcl k8s-controlplane.pkr.hcl
AWS_PROFILE=cf36 packer validate -var-file=prod.pkrvars.hcl k8s-worker-linux.pkr.hcl
AWS_PROFILE=cf36 packer validate -var-file=prod.pkrvars.hcl k8s-worker-windows.pkr.hcl
```

### Build Individual Images
```bash
# Control Plane (currently running)
AWS_PROFILE=cf36 packer build -var-file=prod.pkrvars.hcl k8s-controlplane.pkr.hcl

# Linux Worker
AWS_PROFILE=cf36 packer build -var-file=prod.pkrvars.hcl k8s-worker-linux.pkr.hcl

# Windows Worker (takes longer, requires larger instance)
AWS_PROFILE=cf36 packer build -var-file=prod.pkrvars.hcl k8s-worker-windows.pkr.hcl
```

### Build All in Parallel
```bash
AWS_PROFILE=cf36 packer build -var-file=prod.pkrvars.hcl k8s-controlplane.pkr.hcl &
AWS_PROFILE=cf36 packer build -var-file=prod.pkrvars.hcl k8s-worker-linux.pkr.hcl &
AWS_PROFILE=cf36 packer build -var-file=prod.pkrvars.hcl k8s-worker-windows.pkr.hcl &
wait
```

## Build Details

### Configuration Settings
- **AWS Region**: us-east-1
- **Kubernetes Version**: 1.34
- **Control Plane Instance**: t3.medium (30GB gp3 root volume)
- **Linux Worker Instance**: t3.medium (50GB gp3 root volume)
- **Windows Worker Instance**: t3.large (100GB gp3 root volume)
- **Base OS**:
  - Linux: Ubuntu 22.04 (Jammy)
  - Windows: Windows Server 2022

### Components Installed
- **Container Runtime**: containerd 1.7.11
- **Kubernetes**: kubeadm, kubelet, kubectl, crictl
- **CNI Plugins**: 1.4.0
- **Network Plugin**: Calico 3.27.0

## Expected Build Times
- **Control Plane**: 15-25 minutes
- **Linux Worker**: 15-25 minutes
- **Windows Worker**: 30-45 minutes (larger)

## Next Steps
1. Wait for builds to complete
2. Check output for AMI IDs
3. Review manifests: `manifest-*.json`
4. Update deployment configurations with new AMI IDs
