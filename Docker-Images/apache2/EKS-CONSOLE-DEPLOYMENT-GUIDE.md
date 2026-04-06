# Complete EKS Deployment Using AWS Console - Step by Step

## Overview
This guide walks through creating a complete EKS cluster using only the AWS Console (web UI). No CLI commands needed!

---

## Step 1: Create VPC and Subnets

### 1.1 Create VPC
1. Go to **AWS Console** → **VPC** → **Your VPCs**
2. Click **Create VPC**
3. Fill in:
   - **Name tag**: `cloudbinary-vpc`
   - **IPv4 CIDR block**: `10.0.0.0/16`
   - Click **Create VPC**

### 1.2 Enable DNS Hostnames
1. Select the newly created `cloudbinary-vpc`
2. Click **Actions** → **Edit VPC settings**
3. Enable:
   - ✅ **DNS hostnames**
   - ✅ **DNS resolution**
4. Click **Save changes**

### 1.3 Create Public Subnet 1 (us-east-1a)
1. Go to **VPC** → **Subnets**
2. Click **Create subnet**
3. Fill in:
   - **VPC ID**: Select `cloudbinary-vpc`
   - **Subnet name**: `cloudbinary-subnet-1a`
   - **Availability Zone**: `us-east-1a`
   - **IPv4 CIDR block**: `10.0.1.0/24`
4. Click **Create subnet**

### 1.4 Create Public Subnet 2 (us-east-1b)
1. Click **Create subnet** again
2. Fill in:
   - **VPC ID**: Select `cloudbinary-vpc`
   - **Subnet name**: `cloudbinary-subnet-1b`
   - **Availability Zone**: `us-east-1b`
   - **IPv4 CIDR block**: `10.0.2.0/24`
3. Click **Create subnet**

### 1.5 Create Internet Gateway
1. Go to **VPC** → **Internet Gateways**
2. Click **Create internet gateway**
3. Fill in:
   - **Name tag**: `cloudbinary-igw`
4. Click **Create internet gateway**
5. Select it and click **Actions** → **Attach to VPC**
6. Select `cloudbinary-vpc` and click **Attach internet gateway**

### 1.6 Create Route Table
1. Go to **VPC** → **Route Tables**
2. Click **Create route table**
3. Fill in:
   - **Name tag**: `cloudbinary-rt`
   - **VPC**: `cloudbinary-vpc`
4. Click **Create route table**
5. Select the new route table
6. Go to **Routes** tab → Click **Edit routes**
7. Click **Add route**:
   - **Destination**: `0.0.0.0/0`
   - **Target**: Select Internet Gateway → `cloudbinary-igw`
8. Click **Save changes**

### 1.7 Associate Route Table with Subnets
1. Select route table `cloudbinary-rt`
2. Go to **Subnet associations** tab
3. Click **Edit subnet associations**
4. Select both subnets:
   - ☑️ `cloudbinary-subnet-1a`
   - ☑️ `cloudbinary-subnet-1b`
5. Click **Save associations**

### 1.8 Tag Subnets for Load Balancer Discovery
1. Go to **VPC** → **Subnets**
2. Select `cloudbinary-subnet-1a`
3. Go to **Tags** tab → Click **Manage tags**
4. Add tag:
   - **Key**: `kubernetes.io/role/elb`
   - **Value**: `1`
5. Click **Save**, Repeat for `cloudbinary-subnet-1b`

---

## Step 2: Create IAM Roles

### 2.1 Create EKS Cluster Role
1. Go to **IAM** → **Roles**
2. Click **Create role**
3. Choose trusted entity:
   - **Trusted entity type**: AWS service
   - **Service**: `eks`
   - **Use case**: Select **EKS Cluster**
4. Click **Next**
5. Permissions page (pre-selected):
   - ✅ **AmazonEKSClusterPolicy** (already selected)
6. Click **Next**
7. Fill in:
   - **Role name**: `cloudbinary-dev-cluster-eks-role`
8. Click **Create role**

### 2.2 Attach Additional Policies to Cluster Role
1. Open `cloudbinary-dev-cluster-eks-role`
2. Click **Add permissions** → **Attach policies**
3. Search for and select:
   - ☑️ **AmazonEKSBlockStoragePolicy**
   - ☑️ **AmazonEKSComputePolicy**
   - ☑️ **AmazonEKSLoadBalancingPolicy**
   - ☑️ **AmazonEKSNetworkingPolicy**
4. Click **Attach policies**

### 2.3 Create EKS Node Group Role
1. Go to **IAM** → **Roles**
2. Click **Create role**
3. Choose trusted entity:
   - **Trusted entity type**: AWS service
   - **Service**: `ec2`
4. Click **Next**
5. Search for and select policies:
   - ☑️ **AmazonEKSWorkerNodePolicy**
   - ☑️ **AmazonEKS_CNI_Policy**
   - ☑️ **AmazonEC2ContainerRegistryReadOnly**
   - ☑️ **AmazonSSMManagedInstanceCore**
6. Click **Next**
7. Fill in:
   - **Role name**: `cloudbinary-dev-cluster-node-role`
8. Click **Create role**

### 2.4 Create ALB Controller Role (for IRSA)
1. Go to **IAM** → **Roles**
2. Click **Create role**
3. Choose trusted entity:
   - **Trusted entity type**: Web identity
   - **Identity provider**: Select your OIDC provider (format: `oidc.eks.us-east-1.amazonaws.com`)
   - **Audience**: `sts.amazonaws.com`
4. Click **Next**
5. No permissions needed yet
6. Click **Next**
7. Fill in:
   - **Role name**: `AWSLoadBalancerControllerRole`
8. Click **Create role**

---

## Step 3: Create EKS Cluster

1. Go to **Amazon EKS** → **Clusters**
2. Click **Create cluster**
3. **Cluster configuration**:
   - **Name**: `cloudbinary-dev-cluster`
   - **Kubernetes version**: `1.34`
   - **Cluster role ARN**: Select `cloudbinary-dev-cluster-eks-role`
4. Click **Next**

5. **Specify networking**:
   - **VPC**: `cloudbinary-vpc`
   - **Subnets**: Select both:
     - ☑️ `cloudbinary-subnet-1a`
     - ☑️ `cloudbinary-subnet-1b`
   - **Security groups**: Accept default
6. Click **Next**

7. **Configure logging**:
   - Keep defaults or enable CloudWatch logs if desired
8. Click **Next**

9. **Add-ons**:
   - Keep defaults (VPC CNI, CoreDNS, kube-proxy will be auto-installed)
10. Click **Next**

11. **Review and create**:
    - Check all settings
    - Click **Create**

**⏱️ Wait 5-10 minutes for cluster to reach "Active" status**

---

## Step 4: Create Node Group

1. Open the newly created cluster `cloudbinary-dev-cluster`
2. Go to **Compute** tab → **Node groups**
3. Click **Create node group**

4. **Configure node group**:
   - **Name**: `cloudbinary-dev-cluster-nodegroup`
   - **Node IAM role**: `cloudbinary-dev-cluster-node-role`
5. Click **Next**

6. **Set compute and scaling configuration**:
   - **AMI type**: `Bottlerocket`
   - **Capacity type**: `On-demand`
   - **Instance types**: `t3.medium`
   - **Disk size**: `20`
   - **Desired size**: `1`
   - **Minimum size**: `1`
   - **Maximum size**: `5`
7. Click **Next**

8. **Specify networking**:
   - **Subnets**: Select both:
     - ☑️ `cloudbinary-subnet-1a`
     - ☑️ `cloudbinary-subnet-1b`
   - **Security groups**: Select or accept default
9. Click **Next**

10. **Review and create**:
    - Check settings
    - Click **Create**

**⏱️ Wait 5-10 minutes for nodes to reach "Active" status**

---

## Step 5: Update kubeconfig (Local Machine)

After cluster is **Active** and nodes are **Ready**:

```bash
# Set variables
export AWS_REGION="us-east-1"
export CLUSTER_NAME="cloudbinary-dev-cluster"

# Update kubeconfig
aws eks update-kubeconfig \
  --name $CLUSTER_NAME \
  --region $AWS_REGION \
  --profile c3

# Verify connection
kubectl get nodes
kubectl get namespaces
```

---

## Step 6: Install AWS Load Balancer Controller

### 6.1 Create ServiceAccount (Terminal)
```bash
kubectl create serviceaccount aws-load-balancer-controller -n kube-system

# Get your AWS Account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text --profile c3)

# Get OIDC Provider
OIDC_PROVIDER=$(aws eks describe-cluster \
  --name cloudbinary-dev-cluster \
  --region us-east-1 \
  --profile c3 \
  --query "cluster.identity.oidc.issuer" --output text | \
  sed -e "s/^https:\/\///" | sed -e "s/\/id.*//")

# Annotate ServiceAccount with role ARN
kubectl annotate serviceaccount aws-load-balancer-controller \
  -n kube-system \
  eks.amazonaws.com/role-arn=arn:aws:iam::$ACCOUNT_ID:role/AWSLoadBalancerControllerRole \
  --overwrite
```

### 6.2 Add Load Balancer Policy to ALB Controller Role (Console)
1. Go to **IAM** → **Roles**
2. Open `AWSLoadBalancerControllerRole`
3. Go to **Permissions** tab
4. Click **Add permissions** → **Attach policies**
5. Search for and select policies (or use **Create inline policy**):
   - Download policy from: https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json
   - Add this policy to the role

### 6.3 Install LB Controller with Helm (Terminal)
```bash
# Add Helm repo
helm repo add eks https://aws.github.io/eks-charts
helm repo update eks

# Install controller
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=cloudbinary-dev-cluster \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set aws.region=us-east-1

# Wait 30 seconds and check
sleep 30
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
```

**Status should show `1/1 Running` (not CrashLoopBackOff)**

---

## Step 7: Deploy CloudBinary Website

```bash
# Create deployment manifest
cat > /tmp/cloudbinary-deploy.yml << 'YAML'
---
apiVersion: v1
kind: Namespace
metadata:
  name: cloudbinary-website
  labels:
    name: cloudbinary-website
    region: us-east-1

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cloudbinary-website
  namespace: cloudbinary-website
  labels:
    app: cloudbinary-website
    version: v1
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 1
  selector:
    matchLabels:
      app: cloudbinary-website
  template:
    metadata:
      labels:
        app: cloudbinary-website
        version: v1
    spec:
      containers:
      - name: cloudbinary-website
        image: kesavkummari/cloudbinarywebsite:20260404
        imagePullPolicy: IfNotPresent
        ports:
        - name: http
          containerPort: 80
          protocol: TCP
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /
            port: http
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /
            port: http
          initialDelaySeconds: 10
          periodSeconds: 5

---
apiVersion: v1
kind: Service
metadata:
  name: cloudbinary-website-lb
  namespace: cloudbinary-website
  labels:
    app: cloudbinary-website
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
spec:
  type: LoadBalancer
  selector:
    app: cloudbinary-website
  ports:
  - name: http
    protocol: TCP
    port: 80
    targetPort: 80
  externalTrafficPolicy: Local

---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: cloudbinary-website-hpa
  namespace: cloudbinary-website
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: cloudbinary-website
  minReplicas: 3
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
YAML

# Apply deployment
kubectl apply -f /tmp/cloudbinary-deploy.yml

# Wait for services to get external IP (2-5 minutes)
kubectl get svc -n cloudbinary-website -w

# Get the LoadBalancer hostname
EXTERNAL_IP=$(kubectl get svc cloudbinary-website-lb -n cloudbinary-website -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "Website URL: http://$EXTERNAL_IP"

# Test it
curl http://$EXTERNAL_IP
```

---

## Step 8: Verify Everything Works

### 8.1 Check Cluster (Console)
1. Go to **Amazon EKS** → **Clusters**
2. Select `cloudbinary-dev-cluster`
3. Verify:
   - ✅ Status: **Active**
   - ✅ Kubernetes version: **1.34**

### 8.2 Check Nodes (Console or Terminal)
```bash
kubectl get nodes -o wide
```
Should show at least 1 node in **Ready** status

### 8.3 Check Pods (Terminal)
```bash
# Check all system pods
kubectl get pods -n kube-system

# Check load balancer controller
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
# Should show: 1/1 Running

# Check website pods
kubectl get pods -n cloudbinary-website
# Should show: 3 pods in Running state
```

### 8.4 Check Service (Terminal)
```bash
kubectl get svc -n cloudbinary-website
```
Should show `EXTERNAL-IP` with a DNS name

### 8.5 Test Website
```bash
# Get external IP
EXTERNAL_IP=$(kubectl get svc cloudbinary-website-lb -n cloudbinary-website -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

# Test
curl http://$EXTERNAL_IP

# Should return HTML from CloudBinary website
```

---

## Step 9: Monitor Resources (Console)

### 9.1 CloudWatch Logs
1. Go to **CloudWatch** → **Log Groups**
2. Look for:
   - `/aws/eks/cloudbinary-dev-cluster/cluster`
   - `/aws/eks/cloudbinary-dev-cluster/api`

### 9.2 EC2 Instances
1. Go to **EC2** → **Instances**
2. Should see 1-3 instances with names starting with `cloudbinary-dev-cluster`

### 9.3 Load Balancers
1. Go to **EC2** → **Load Balancers**
2. Should see a **Network Load Balancer** created automatically
3. Check target groups to see health status

---

## Step 10: Clean Up (When Done)

### 10.1 Delete Deployment (Terminal)
```bash
kubectl delete namespace cloudbinary-website
```

### 10.2 Delete Node Group (Console)
1. Go to **Amazon EKS** → **Clusters** → `cloudbinary-dev-cluster`
2. Go to **Compute** → **Node groups**
3. Select `cloudbinary-dev-cluster-nodegroup`
4. Click **Delete** → Confirm

**Wait for deletion (5 minutes)**

### 10.3 Delete Cluster (Console)
1. Go to **Amazon EKS** → **Clusters**
2. Select `cloudbinary-dev-cluster`
3. Click **Delete cluster** → Type cluster name → **Delete**

**Wait for deletion (5 minutes)**

### 10.4 Delete VPC (Console)
1. Go to **VPC** → **Your VPCs**
2. Select `cloudbinary-vpc`
3. Click **Delete VPC** → Check dependencies → **Delete**

### 10.5 Delete IAM Roles (Console)
1. Go to **IAM** → **Roles**
2. Delete:
   - `cloudbinary-dev-cluster-eks-role`
   - `cloudbinary-dev-cluster-node-role`
   - `AWSLoadBalancerControllerRole`

---

## Troubleshooting

### Issue: Pods stuck in Pending
**Cause**: Not enough nodes or resource issues

**Fix**: 
1. Check nodes: `kubectl get nodes`
2. Check node resources: `kubectl top nodes`
3. Check pod events: `kubectl describe pod <pod-name> -n <namespace>`

### Issue: LoadBalancer stuck in Pending
**Cause**: LB Controller not running or IAM permissions missing

**Fix**:
```bash
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
```

### Issue: Website not accessible
**Cause**: Security group rules blocking traffic

**Fix**:
1. Go to **EC2** → **Security Groups**
2. Find security group associated with Load Balancer
3. Ensure **Inbound rule**: Port 80 from **0.0.0.0/0** is allowed

---

## Quick Reference Commands

```bash
# Cluster info
kubectl cluster-info
kubectl get nodes
kubectl get namespaces

# Website pods
kubectl get pods -n cloudbinary-website
kubectl logs -n cloudbinary-website deployment/cloudbinary-website

# Load Balancer
kubectl get svc -n cloudbinary-website
kubectl describe svc cloudbinary-website-lb -n cloudbinary-website

# System pods
kubectl get pods -n kube-system
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller

# Scale deployment
kubectl scale deployment cloudbinary-website -n cloudbinary-website --replicas=5

# Get website URL
kubectl get svc cloudbinary-website-lb -n cloudbinary-website -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

---

## Summary

You've now created:
✅ Custom VPC with public subnets  
✅ Internet connectivity setup  
✅ IAM roles for EKS and nodes  
✅ EKS cluster (v1.34)  
✅ Node group with auto-scaling  
✅ AWS Load Balancer Controller  
✅ CloudBinary website deployment  
✅ Network Load Balancer with public access  

Your website is now accessible via the LoadBalancer DNS name!
