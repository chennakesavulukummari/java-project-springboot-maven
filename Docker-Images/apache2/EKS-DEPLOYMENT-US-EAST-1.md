# Clean EKS Deployment in us-east-1

## Prerequisites
```bash
# Install/update AWS CLI
brew install awscli

# Configure AWS credentials
aws configure

# Verify you can access AWS
aws sts get-caller-identity --profile c3
```

## Step 1: Create VPC and Subnets (if not already existing)
```bash
# Set variables
export AWS_REGION="us-east-1"
export CLUSTER_NAME="cloudbinary-dev-cluster"
export VPC_CIDR="10.0.0.0/16"

# Create VPC with tags
VPC_ID=$(aws ec2 create-vpc --cidr-block $VPC_CIDR --region $AWS_REGION --profile c3 --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=cloudbinary-vpc},{Key=Environment,Value=dev},{Key=Project,Value=cloudbinary-website},{Key=Team,Value=devops},{Key=ManagedBy,Value=cli}]' --query 'Vpc.VpcId' --output text)
echo "VPC ID: $VPC_ID"

# Enable DNS hostnames
aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-hostnames --region $AWS_REGION --profile c3

# Create subnets with tags
SUBNET_1=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.1.0/24 --availability-zone us-east-1a --region $AWS_REGION --profile c3 --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=cloudbinary-subnet-1a},{Key=Environment,Value=dev},{Key=Project,Value=cloudbinary-website},{Key=Team,Value=devops}]' --query 'Subnet.SubnetId' --output text)

SUBNET_2=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.2.0/24 --availability-zone us-east-1b --region $AWS_REGION --profile c3 --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=cloudbinary-subnet-1b},{Key=Environment,Value=dev},{Key=Project,Value=cloudbinary-website},{Key=Team,Value=devops}]' --query 'Subnet.SubnetId' --output text)

echo "Subnet 1: $SUBNET_1"
echo "Subnet 2: $SUBNET_2"

# Create Internet Gateway with tags
IGW_ID=$(aws ec2 create-internet-gateway --region $AWS_REGION --profile c3 --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=cloudbinary-igw},{Key=Environment,Value=dev},{Key=Project,Value=cloudbinary-website}]' --query 'InternetGateway.InternetGatewayId' --output text)
aws ec2 attach-internet-gateway --vpc-id $VPC_ID --internet-gateway-id $IGW_ID --region $AWS_REGION --profile c3

# Create and configure route table with tags
ROUTE_TABLE=$(aws ec2 create-route-table --vpc-id $VPC_ID --region $AWS_REGION --profile c3 --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=cloudbinary-rt},{Key=Environment,Value=dev},{Key=Project,Value=cloudbinary-website}]' --query 'RouteTable.RouteTableId' --output text)

aws ec2 create-route --route-table-id $ROUTE_TABLE --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW_ID --region $AWS_REGION --profile c3

aws ec2 associate-route-table --subnet-id $SUBNET_1 --route-table-id $ROUTE_TABLE --region $AWS_REGION --profile c3

aws ec2 associate-route-table --subnet-id $SUBNET_2 --route-table-id $ROUTE_TABLE --region $AWS_REGION --profile c3

# Tag subnets for ELB discovery
aws ec2 create-tags --resources $SUBNET_1 --tags Key=kubernetes.io/role/elb,Value=1 --region $AWS_REGION --profile c3
aws ec2 create-tags --resources $SUBNET_2 --tags Key=kubernetes.io/role/elb,Value=1 --region $AWS_REGION --profile c3

echo "VPC Setup Complete!"
echo "VPC_ID=$VPC_ID"
echo "SUBNET_1=$SUBNET_1"
echo "SUBNET_2=$SUBNET_2"
```

## Step 2: Create IAM Role for EKS Cluster
```bash
# Create trust policy
cat > /tmp/eks-trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": [
        "sts:AssumeRole",
        "sts:TagSession"
      ]
    }
  ]
}
EOF

# Create IAM role
EKS_ROLE=$(aws iam create-role --role-name $CLUSTER_NAME-eks-role --assume-role-policy-document file:///tmp/eks-trust-policy.json --profile c3 --query 'Role.Arn' --output text)

# Attach required policies
aws iam attach-role-policy --role-name $CLUSTER_NAME-eks-role --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy --profile c3
aws iam attach-role-policy --role-name $CLUSTER_NAME-eks-role --policy-arn arn:aws:iam::aws:policy/AmazonEKSBlockStoragePolicy --profile c3
aws iam attach-role-policy --role-name $CLUSTER_NAME-eks-role --policy-arn arn:aws:iam::aws:policy/AmazonEKSComputePolicy --profile c3
aws iam attach-role-policy --role-name $CLUSTER_NAME-eks-role --policy-arn arn:aws:iam::aws:policy/AmazonEKSLoadBalancingPolicy --profile c3
aws iam attach-role-policy --role-name $CLUSTER_NAME-eks-role --policy-arn arn:aws:iam::aws:policy/AmazonEKSNetworkingPolicy --profile c3

echo "EKS Role: $EKS_ROLE"
```

## Step 3: Create IAM Role for Node Group
```bash
# Create trust policy for nodes
cat > /tmp/node-trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

# Create node role
NODE_ROLE=$(aws iam create-role --role-name $CLUSTER_NAME-node-role --assume-role-policy-document file:///tmp/node-trust-policy.json --profile c3 --query 'Role.Arn' --output text)

# Attach policies
aws iam attach-role-policy --role-name $CLUSTER_NAME-node-role --policy-arn arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy --profile c3
aws iam attach-role-policy --role-name $CLUSTER_NAME-node-role --policy-arn arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy --profile c3
aws iam attach-role-policy --role-name $CLUSTER_NAME-node-role --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly --profile c3
aws iam attach-role-policy --role-name $CLUSTER_NAME-node-role --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore --profile c3

echo "Node Role: $NODE_ROLE"
```

## Step 4: Create IAM Policy for Load Balancer Controller

```bash
# Download the official AWS Load Balancer Controller IAM policy
curl -o /tmp/iam-policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json

# Create IAM policy
ALB_POLICY_ARN=$(aws iam create-policy \
  --policy-name $CLUSTER_NAME-AWSLoadBalancerControllerPolicy \
  --policy-document file:///tmp/iam-policy.json \
  --profile c3 \
  --query 'Policy.Arn' \
  --output text)

echo "ALB Policy ARN: $ALB_POLICY_ARN"

# Attach policy to node role for load balancer permissions
aws iam attach-role-policy \
  --role-name $CLUSTER_NAME-node-role \
  --policy-arn $ALB_POLICY_ARN \
  --profile c3

echo "Policy attached to node role successfully!"
```

## Step 5: Create EKS Cluster
```bash
aws eks create-cluster \
  --name $CLUSTER_NAME \
  --version 1.34 \
  --role-arn $EKS_ROLE \
  --resources-vpc-config subnetIds=$SUBNET_1,$SUBNET_2 \
  --region $AWS_REGION \
  --profile c3 \
  --tags Environment=dev,Project=cloudbinary-website,Team=devops,ManagedBy=cli

# Wait for cluster to be ACTIVE (5-10 minutes)
aws eks wait cluster-active --name $CLUSTER_NAME --region $AWS_REGION --profile c3

echo "Cluster Status:"
aws eks describe-cluster --name $CLUSTER_NAME --region $AWS_REGION --profile c3 --query 'cluster.status'
```

## Step 6: Create Node Group
```bash
aws eks create-nodegroup \
  --cluster-name $CLUSTER_NAME \
  --nodegroup-name $CLUSTER_NAME-nodegroup \
  --subnets $SUBNET_1 $SUBNET_2 \
  --node-role $NODE_ROLE \
  --instance-types t3.medium \
  --scaling-config minSize=1,maxSize=5,desiredSize=1 \
  --region $AWS_REGION \
  --profile c3 \
  --tags Environment=dev,Project=cloudbinary-website,Team=devops,ManagedBy=cli

# Wait for node group to be ACTIVE (5-10 minutes)
aws eks wait nodegroup-active --cluster-name $CLUSTER_NAME --nodegroup-name $CLUSTER_NAME-nodegroup --region $AWS_REGION --profile c3

echo "NodeGroup Status:"
aws eks describe-nodegroup --cluster-name $CLUSTER_NAME --nodegroup-name $CLUSTER_NAME-nodegroup --region $AWS_REGION --profile c3 --query 'nodegroup.status'
```

## Step 7: Update kubeconfig
```bash
aws eks update-kubeconfig \
  --name $CLUSTER_NAME \
  --region $AWS_REGION \
  --profile c3

# Verify connection
kubectl get nodes
kubectl get namespaces
```

## Step 8: Install AWS Load Balancer Controller
```bash
# Add helm repo
helm repo add eks https://aws.github.io/eks-charts
helm repo update

# Install controller
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=$CLUSTER_NAME \
  --set aws.region=$AWS_REGION

# Wait for controller to be ready
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=aws-load-balancer-controller -n kube-system --timeout=300s

echo "Controller Status:"
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
```

## Step 9: Deploy CloudBinary Website
```bash
# First, push your image to ECR (optional, or use your hub.docker.com image)
# kubectl apply -f /Users/ck/github-repos/java-project-springboot-maven/Docker-Images/apache2/cloudbinary-website-deployment.yml

# Alternative: Create simple deployment for us-east-1
cat > /tmp/cloudbinary-us-east-1.yml << 'YAML'
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
    region: us-east-1
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
        region: us-east-1
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
    region: us-east-1
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
  labels:
    region: us-east-1
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

# Apply the manifest
kubectl apply -f /tmp/cloudbinary-us-east-1.yml
```

## Step 10: Get External IP and Test
```bash
# Wait for LoadBalancer to get external IP (2-5 minutes)
kubectl get svc -n cloudbinary-website -w

# Once EXTERNAL-IP is assigned, access it
EXTERNAL_IP=$(kubectl get svc cloudbinary-website-lb -n cloudbinary-website -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "Access your website at: http://$EXTERNAL_IP"

# Test
curl http://$EXTERNAL_IP
```

## Step 11: Clean Up (if needed)
```bash
# Delete deployment
kubectl delete -f /tmp/cloudbinary-us-east-1.yml

# Delete node group
aws eks delete-nodegroup --cluster-name $CLUSTER_NAME --nodegroup-name $CLUSTER_NAME-nodegroup --region $AWS_REGION --profile c3

# Wait for node group deletion
aws eks wait nodegroup-deleted --cluster-name $CLUSTER_NAME --nodegroup-name $CLUSTER_NAME-nodegroup --region $AWS_REGION --profile c3

# Delete cluster
aws eks delete-cluster --name $CLUSTER_NAME --region $AWS_REGION --profile c3

# Delete VPC resources (optional)
# aws ec2 delete-subnet --subnet-id $SUBNET_1 --region $AWS_REGION
# aws ec2 delete-subnet --subnet-id $SUBNET_2 --region $AWS_REGION
# aws ec2 delete-vpc --vpc-id $VPC_ID --region $AWS_REGION
```

## Quick Reference Commands
```bash
# Check cluster status
aws eks describe-cluster --name $CLUSTER_NAME --region $AWS_REGION --profile c3

# Get kubeconfig
aws eks update-kubeconfig --name $CLUSTER_NAME --region $AWS_REGION --profile c3

# View all nodes
kubectl get nodes -o wide

# Check pods
kubectl get pods -n cloudbinary-website

# Check service
kubectl get svc -n cloudbinary-website

# Check logs
kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller

# Describe service (to see events)
kubectl describe svc cloudbinary-website-lb -n cloudbinary-website
```
