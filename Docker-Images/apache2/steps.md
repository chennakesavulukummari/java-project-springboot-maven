# path : /Users/ck/github-repos/java-project-springboot-maven/Docker-Images/apache2

# Step-1: Build Docker Image
docker build -t kesavkummari/cloudbinarywebsite:20260404 /Users/ck/github-repos/java-project-springboot-maven/Docker-Images/apache2

# Step-2: Run Locally and test
docker run -d --name cloudbinarywebsite -p 81:80 kesavkummari/cloudbinarywebsite:20260404

docker ps 

Go to browser and access the container: http://localhost:81/

# Step-3: Push image to hub.docker.com
docker login

docker push kesavkummari/cloudbinarywebsite:20260404

# Step-4: Create k8s manifeast files for Cloud Binary Website Deployment

cloudbinary-website-deployment.yml

```
---
# Namespace for cloudbinary-website
apiVersion: v1
kind: Namespace
metadata:
  name: cloudbinary-website
  labels:
    name: cloudbinary-website
    region: ap-south-2

---
# Deployment for cloudbinary-website
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cloudbinary-website
  namespace: cloudbinary-website
  labels:
    app: cloudbinary-website
    version: v1
    region: ap-south-2
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
        region: ap-south-2
    spec:
      affinity:
        nodeAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            preference:
              matchExpressions:
              - key: topology.kubernetes.io/region
                operator: In
                values:
                - ap-south-2
      containers:
      - name: cloudbinary-website
        image: kesavkummari/cloudbinarywebsite:20260404
        imagePullPolicy: IfNotPresent
        ports:
        - name: http
          containerPort: 80
          protocol: TCP
        - name: https
          containerPort: 443
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
          timeoutSeconds: 5
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /
            port: http
          initialDelaySeconds: 10
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 2
        securityContext:
          runAsNonRoot: false
          allowPrivilegeEscalation: false
          capabilities:
            drop:
            - ALL

---
# Service with LoadBalancer for public endpoint
apiVersion: v1
kind: Service
metadata:
  name: cloudbinary-website-lb
  namespace: cloudbinary-website
  labels:
    app: cloudbinary-website
    region: ap-south-2
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
    service.beta.kubernetes.io/aws-load-balancer-subnets: "subnet-0ab7ef12823c1b8c3,subnet-01d078b173a769177"
spec:
  type: LoadBalancer
  selector:
    app: cloudbinary-website
  ports:
  - name: http
    protocol: TCP
    port: 80
    targetPort: 80
  - name: https
    protocol: TCP
    port: 443
    targetPort: 443
  sessionAffinity: None
  externalTrafficPolicy: Local

---
# HorizontalPodAutoscaler for auto-scaling
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: cloudbinary-website-hpa
  namespace: cloudbinary-website
  labels:
    region: ap-south-2
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
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80

```

# Step-5: apply the deployment and test 

# Key components:
1. Namespace: cloudbinary-website
2. Deployment: 3 replicas with rolling updates, health checks (liveness & readiness probes), and resource limits
3. LoadBalancer Service: Exposes your app publicly on HTTP (80) and HTTPS (443) ports
4. HorizontalPodAutoscaler: Auto-scales between 3-10 replicas based on CPU/memory usage

# To deploy to EKS:
kubectl apply -f /Users/ck/github-repos/java-project-springboot-maven/Docker-Images/apache2/cloudbinary-website-deployment.yml

# To get the public endpoint:
kubectl get svc -n cloudbinary-website
# or watch it
kubectl get svc -n cloudbinary-website -w

# Note: Look for the EXTERNAL-IP under cloudbinary-website-lb service. It will be your public endpoint (e.g., a1b2c3d-1234567.us-east-1.elb.amazonaws.com).

The EXTERNAL-IP usually takes 1-5 minutes on AWS EKS to provision. Since yours is at 70 seconds and still showing <pending>, give it a bit more time.

# Typical timeline:

  1. 0-30 seconds: LoadBalancer service created
  2. 30s-2 min: AWS Load Balancer Controller starts provisioning the NLB (Network Load Balancer)
  3. 2-5 min: DNS name is assigned and propagates
  4. 5+ min: Might indicate an issue

# To speed it up or debug, check:

# Watch in real-time (keep running)
kubectl get svc -n cloudbinary-website -w

# Check if there are any errors
kubectl describe svc cloudbinary-website-lb -n cloudbinary-website

# Check the load balancer controller logs
kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller -f

# Check pod status
kubectl get pods -n cloudbinary-website

# If it stays pending after 5 minutes:

  1. Verify IAM role has permissions for ELB/NLB creation
  2. Check security groups allow traffic
  3. Ensure AWS Load Balancer Controller is installed and running on your EKS cluster

Once it shows an EXTERNAL-IP like a1b2c3d-1234567.us-east-1.elb.amazonaws.com, you can access it via that DNS name or IP.


# Issue:

The issue is that the AWS Load Balancer Controller cannot access the EC2 Metadata Service (IMDS) to determine the AWS region automatically. The error message even suggests the fix: "specify --aws-region instead if EC2Metadata is unavailable".

Root cause:

The controller is trying to query IMDS to get the region
The request times out (context deadline exceeded)
This is common when IMDS is not accessible from the pod or there are network/firewall issues
Fix: Specify the region explicitly

Get your current region and reinstall the controller with the region specified:

# Find your region
kubectl get nodes -o wide | grep topology.kubernetes.io/region

# Or check your AWS config
aws configure get region

# Example: if region is us-east-1
helm repo add eks https://aws.github.io/eks-charts
helm repo update

helm upgrade -i aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=cloudbinary-dev-cluster \
  --set serviceAccount.create=true \
  --set aws.region=ap-south-2


# -------------------clean up and redeploy---------------------- #

# 1. Delete the entire helm release
helm uninstall aws-load-balancer-controller -n kube-system

# 2. Wait for pods to terminate
sleep 10

# 3. Verify they're gone
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller

# 4. Clean up any remaining resources
kubectl delete clusterrole aws-load-balancer-controller 2>/dev/null || true
kubectl delete clusterrolebinding aws-load-balancer-controller 2>/dev/null || true
kubectl delete role -n kube-system aws-load-balancer-controller 2>/dev/null || true
kubectl delete rolebinding -n kube-system aws-load-balancer-controller 2>/dev/null || true

# 5. Wait a moment
sleep 5

# 6. Fresh install
helm repo update eks

helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=cloudbinary-dev-cluster \
  --set aws.region=ap-south-2 \
  --set replicaCount=1

# 7. Monitor startup (watch the logs as it starts)
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller -w

# 8. Once Running, check logs for errors
kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller -f


Once the pod shows 1/1 Running, apply your manifest:

kubectl apply -f /Users/ck/github-repos/java-project-springboot-maven/Docker-Images/apache2/cloudbinary-website-deployment.yml

# Check service status
kubectl get svc -n cloudbinary-website -w

# ------------------------------------------ #
aws sts get-caller-identity --profile cf36

# Connect to cluster with profile cf36
aws eks update-kubeconfig \
  --name cloudbinary-cluster \
  --region ap-south-2 \
  --profile cf36

# Verify connection
kubectl cluster-info
kubectl get nodes
