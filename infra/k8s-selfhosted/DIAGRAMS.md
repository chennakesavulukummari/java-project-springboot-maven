# Infrastructure & Architecture Diagrams

## 1. Overall Infrastructure Topology

```mermaid
graph TB
    subgraph AWS["AWS Region (us-east-1)"]
        subgraph VPC["VPC: 10.0.0.0/16"]
            subgraph PublicSub1["Public Subnet-1: 10.0.1.0/24"]
                MasterCP["🖥️ Master CP<br/>t3.medium<br/>10.0.1.10"]
                WorkerLinux["🐧 Worker-Linux<br/>t3.large<br/>10.0.1.20"]
            end
            
            subgraph PublicSub2["Public Subnet-2: 10.0.2.0/24"]
                SlaveCP["🖥️ Slave CP<br/>t3.medium<br/>10.0.2.10"]
                WorkerWin["🪟 Worker-Windows<br/>t3.large<br/>10.0.2.20"]
            end
            
            subgraph PrivateSub["Private Subnet: 10.0.3.0/24"]
                DBNode["🗄️ DB Node<br/>t3.large<br/>10.0.3.10"]
            end
            
            IGW["🚪 Internet Gateway"]
            NGW["🌐 NAT Gateway"]
        end
        
        ELB["⚖️ AWS Load Balancer<br/>Port 80/443"]
    end
    
    Users["👥 End Users"]
    
    Users -->|HTTP/HTTPS| ELB
    ELB -->|Routes| PublicSub1
    ELB -->|Routes| PublicSub2
    IGW -->|Routes Traffic| VPC
    NGW -->|NAT for Private| PrivateSub
    
    style AWS fill:#FF9900,stroke:#333,color:#000
    style VPC fill:#146EB4,stroke:#333,color:#fff
    style PublicSub1 fill:#36C5F0,stroke:#333,color:#000
    style PublicSub2 fill:#36C5F0,stroke:#333,color:#000
    style PrivateSub fill:#FF9900,stroke:#333,color:#000
```

---

## 2. Kubernetes Cluster Architecture

```mermaid
graph TB
    subgraph K8s["Kubernetes Cluster"]
        subgraph ControlPlane["Control Plane (HA)"]
            Master["Master CP Node<br/>- etcd<br/>- API Server<br/>- Controller Manager<br/>- Scheduler"]
            Slave["Slave CP Node<br/>- etcd (replicated)<br/>- API Server<br/>- Controller Manager<br/>- Scheduler"]
        end
        
        subgraph Workers["Worker Nodes"]
            WL["Worker-Linux<br/>- kubelet<br/>- kube-proxy<br/>- Container Runtime"]
            WW["Worker-Windows<br/>- kubelet<br/>- kube-proxy<br/>- Container Runtime"]
        end
        
        subgraph Addons["Kubernetes Add-ons"]
            Dashboard["📊 Kubernetes Dashboard"]
            DNS["🔍 CoreDNS"]
            CNI["🌐 Calico CNI"]
            Metrics["📈 Metrics Server"]
        end
        
        Master ---|etcd replication| Slave
        Master -->|manages| WL
        Master -->|manages| WW
        Slave -->|backup| Master
        
        WL -->|uses| DNS
        WW -->|uses| DNS
        WL -->|uses| CNI
        WW -->|uses| CNI
        
        Dashboard -->|monitors| Master
        Dashboard -->|monitors| WL
        Dashboard -->|monitors| WW
        Metrics -->|collects| WL
        Metrics -->|collects| WW
    end
    
    style K8s fill:#326CE5,stroke:#333,color:#fff
    style ControlPlane fill:#146EB4,stroke:#fff,color:#fff
    style Workers fill:#36C5F0,stroke:#333,color:#000
    style Addons fill:#00A651,stroke:#333,color:#fff
```

---

## 3. 3-Tier Application Architecture

```mermaid
graph TB
    Users["👥 End Users"]
    LB["⚖️ Load Balancer<br/>Port 80/443"]
    
    subgraph WebTier["🌐 Web Tier<br/>Linux Worker Node"]
        Ingress["⚙️ NGINX Ingress<br/>Controller"]
        AngularSvc["📦 Angular Service<br/>3 Replicas"]
        AngularPod1["Pod 1<br/>Angular+Nginx"]
        AngularPod2["Pod 2<br/>Angular+Nginx"]
        AngularPod3["Pod 3<br/>Angular+Nginx"]
    end
    
    subgraph AppTier["🔧 App Tier<br/>Windows Worker Node"]
        PythonSvc["📦 Python API Service<br/>2-3 Replicas"]
        PythonPod1["Pod 1<br/>Python API"]
        PythonPod2["Pod 2<br/>Python API"]
    end
    
    subgraph DBTier["🗄️ Database Tier<br/>Linux Node"]
        DBSvc["📦 MySQL Service"]
        MySQLPod["Pod/Container<br/>MySQL 8.0<br/>PVC: 100GB"]
    end
    
    Users -->|HTTPS| LB
    LB -->|Route /| Ingress
    Ingress -->|Forward| AngularSvc
    
    AngularSvc --> AngularPod1
    AngularSvc --> AngularPod2
    AngularSvc --> AngularPod3
    
    AngularPod1 -->|API Calls| PythonSvc
    AngularPod2 -->|API Calls| PythonSvc
    AngularPod3 -->|API Calls| PythonSvc
    
    PythonSvc --> PythonPod1
    PythonSvc --> PythonPod2
    
    PythonPod1 -->|Query| DBSvc
    PythonPod2 -->|Query| DBSvc
    
    DBSvc -->|persists| MySQLPod
    
    style WebTier fill:#FF9900,stroke:#333,color:#fff
    style AppTier fill:#146EB4,stroke:#333,color:#fff
    style DBTier fill:#00A651,stroke:#333,color:#fff
```

---

## 4. Network Communication Flow

```mermaid
graph TB
    subgraph Internet["Internet"]
        Users["👥 Users<br/>0.0.0.0/0"]
    end
    
    subgraph AWS["AWS Region"]
        subgraph VPC["VPC: 10.0.0.0/16"]
            subgraph Pub1["Public SN: 10.0.1.0/24"]
                Master["Master CP<br/>10.0.1.10"]
                WL["Worker-Linux<br/>10.0.1.20"]
                EIP1["EIP 1"]
            end
            
            subgraph Pub2["Public SN: 10.0.2.0/24"]
                Slave["Slave CP<br/>10.0.2.10"]
                WW["Worker-Windows<br/>10.0.2.20"]
                EIP2["EIP 2"]
            end
            
            subgraph Priv["Private SN: 10.0.3.0/24"]
                DBN["DB Node<br/>10.0.3.10"]
            end
            
            IGW["Internet Gateway"]
            NGW["NAT Gateway"]
        end
    end
    
    ALB["🔗 Application Load Balancer<br/>Port 80/443"]
    
    Users -->|HTTP/HTTPS| IGW
    IGW -->|Routes| ALB
    ALB -->|:30080 NodePort| WL
    ALB -->|:30080 NodePort| WW
    
    WL -->|Pod CIDR: 172.16.x.x| Master
    WW -->|Pod CIDR: 172.16.x.x| Slave
    
    Master -->|etcd| Slave
    Master -->|Admin| WL
    Master -->|Admin| WW
    
    WL -->|Queries| DBN
    WW -->|Queries| DBN
    DBN -->|NAT Gateway| NGW
    
    style Internet fill:#999,stroke:#333,color:#fff
    style VPC fill:#146EB4,stroke:#333,color:#fff
    style Pub1 fill:#36C5F0,stroke:#333,color:#000
    style Pub2 fill:#36C5F0,stroke:#333,color:#000
    style Priv fill:#FF9900,stroke:#333,color:#000
```

---

## 5. Security Groups & Firewall Rules

```mermaid
graph LR
    Internet["Internet<br/>0.0.0.0/0"]
    
    subgraph SG_ALB["SG: Load Balancer"]
        Rule1["Inbound: 80/443<br/>From: 0.0.0.0/0<br/>To: All"]
    end
    
    subgraph SG_CP["SG: Control Plane"]
        CPRule1["6443 - API<br/>10.0.0.0/16"]
        CPRule2["2379-2380 - etcd<br/>10.0.0.0/16"]
        CPRule3["10250 - kubelet<br/>10.0.0.0/16"]
    end
    
    subgraph SG_Worker["SG: Worker Nodes"]
        WRule1["10250 - kubelet<br/>10.0.0.0/16"]
        WRule2["30000-32767 - NodePort<br/>0.0.0.0/0"]
    end
    
    subgraph SG_DB["SG: Database"]
        DBRule1["3306 - MySQL<br/>From: App Tier"]
    end
    
    Internet -->|HTTPS| SG_ALB
    SG_ALB -->|Routes| SG_Worker
    SG_Worker -->|Admin Traffic| SG_CP
    SG_CP -->|Cluster Comm| SG_Worker
    SG_Worker -->|DB Query| SG_DB
    
    style Internet fill:#999,stroke:#333,color:#fff
    style SG_ALB fill:#FF9900,stroke:#333,color:#fff
    style SG_CP fill:#146EB4,stroke:#333,color:#fff
    style SG_Worker fill:#36C5F0,stroke:#333,color:#000
    style SG_DB fill:#00A651,stroke:#333,color:#fff
```

---

## 6. Data Flow - User Request to Database

```mermaid
sequenceDiagram
    participant User as 👥 User
    participant ALB as ⚖️ ALB
    participant Web as 🌐 Web Pod
    participant App as 🔧 App Pod
    participant DB as 🗄️ MySQL
    
    User->>ALB: HTTP GET /
    ALB->>Web: Forward to NGINX
    Web->>Web: Serve Angular UI
    Web-->>User: HTML/CSS/JS
    
    User->>Web: API Call (e.g., fetch('/api/users'))
    Web->>App: HTTP POST /api/users
    App->>DB: SELECT * FROM users
    DB-->>App: Row Data
    App-->>Web: JSON Response
    Web-->>User: Display Data
```

---

## 7. Kubernetes Resource Hierarchy

```mermaid
graph TB
    Cluster["⭐ Kubernetes Cluster"]
    
    Cluster -->|Namespaces| NS1["default"]
    Cluster -->|Namespaces| NS2["web"]
    Cluster -->|Namespaces| NS3["app"]
    Cluster -->|Namespaces| NS4["database"]
    Cluster -->|Namespaces| NS5["kube-system"]
    
    NS2 -->|Deployments| WebDeploy["Angular Deployment<br/>3 Replicas"]
    NS2 -->|Services| WebSvc["ClusterIP:8080"]
    NS2 -->|Ingress| WebIng["NGINX Ingress"]
    
    NS3 -->|Deployments| AppDeploy["Python API Deployment<br/>2 Replicas"]
    NS3 -->|Services| AppSvc["ClusterIP:5000"]
    NS3 -->|ConfigMap| AppConfig["API Configuration"]
    NS3 -->|Secrets| AppSecret["DB Credentials"]
    
    NS4 -->|StatefulSet| DBDeploy["MySQL StatefulSet<br/>1 Replica"]
    NS4 -->|Services| DBSvc["ClusterIP:3306"]
    NS4 -->|PVC| DBStorage["PersistentVolumeClaim<br/>100GB"]
    
    NS5 -->|System Pods| Dashboard["Kubernetes Dashboard"]
    NS5 -->|System Pods| DNS["CoreDNS"]
    NS5 -->|System Pods| Controller["Controller Manager"]
    
    WebDeploy --> WebPod1["Web Pod 1"]
    WebDeploy --> WebPod2["Web Pod 2"]
    WebDeploy --> WebPod3["Web Pod 3"]
    
    AppDeploy --> AppPod1["App Pod 1"]
    AppDeploy --> AppPod2["App Pod 2"]
    
    DBDeploy --> DBPod["MySQL Pod"]
    DBPod --> DBStorage
    
    style Cluster fill:#326CE5,stroke:#fff,color:#fff,stroke-width:3px
    style NS2 fill:#FF9900,stroke:#333,color:#fff
    style NS3 fill:#146EB4,stroke:#333,color:#fff
    style NS4 fill:#00A651,stroke:#333,color:#fff
    style NS5 fill:#666,stroke:#333,color:#fff
```

---

## 8. Storage Architecture

```mermaid
graph TB
    subgraph Cluster["Kubernetes Cluster"]
        subgraph PVC["Persistent Volume Claims"]
            DBPVC["Database PVC<br/>100GB<br/>RWO"]
            LogPVC["Application Logs PVC<br/>20GB<br/>RWX"]
        end
        
        subgraph PV["Persistent Volumes"]
            DBPV["DB PV<br/>EBS gp2<br/>100GB"]
            LogPV["Log PV<br/>EBS gp2<br/>20GB"]
        end
        
        subgraph StorageClass["Storage Classes"]
            EBSSC["EBS Storage Class<br/>Provisioner: ebs.csi.aws.com<br/>Type: gp2"]
        end
    end
    
    subgraph AWS["AWS"]
        EBS1["📦 EBS Volume 1<br/>100GB - Database"]
        EBS2["📦 EBS Volume 2<br/>20GB - Logs"]
        EBS3["📦 Root Volume<br/>30GB x 5 Nodes"]
    end
    
    DBPVC -->|Binds| DBPV
    LogPVC -->|Binds| LogPV
    DBPV -->|Attached| EBS1
    LogPV -->|Attached| EBS2
    EBSSC -->|Creates| DBPV
    EBSSC -->|Creates| LogPV
    
    style Cluster fill:#326CE5,stroke:#fff,color:#fff
    style PVC fill:#36C5F0,stroke:#333,color:#000
    style PV fill:#FF9900,stroke:#333,color:#000
    style StorageClass fill:#00A651,stroke:#333,color:#fff
    style AWS fill:#FF9900,stroke:#333,color:#fff
```

---

## 9. Deployment Pipeline

```mermaid
graph LR
    Dev["👨‍💻 Developer"]
    Git["📚 Git Repository"]
    CI["🔄 CI Pipeline"]
    Build["🔨 Build Images"]
    Registry["📦 Container Registry"]
    Deploy["🚀 Deploy to K8s"]
    K8s["⭐ Kubernetes Cluster"]
    Monitor["📊 Monitoring"]
    
    Dev -->|Push Code| Git
    Git -->|Webhook Trigger| CI
    CI -->|Build & Test| Build
    Build -->|Push Images| Registry
    Registry -->|Pull Images| Deploy
    Deploy -->|Apply Manifests| K8s
    K8s -->|Stream Metrics| Monitor
    Monitor -->|Alerts| Dev
    
    style Dev fill:#999,stroke:#333,color:#fff
    style Git fill:#666,stroke:#333,color:#fff
    style CI fill:#146EB4,stroke:#333,color:#fff
    style Build fill:#FF9900,stroke:#333,color:#fff
    style Registry fill:#36C5F0,stroke:#333,color:#000
    style Deploy fill:#00A651,stroke:#333,color:#fff
    style K8s fill:#326CE5,stroke:#fff,color:#fff
    style Monitor fill:#FF6B6B,stroke:#333,color:#fff
```

---

## 10. High Availability Architecture

```mermaid
graph TB
    Users["👥 Users"]
    ALB["⚖️ Application Load Balancer<br/>Multi-AZ"]
    
    subgraph AZ1["Availability Zone 1"]
        subgraph Node1["Master CP + Worker-Linux"]
            MCP["Master Control Plane"]
            WL["Worker-Linux"]
        end
    end
    
    subgraph AZ2["Availability Zone 2"]
        subgraph Node2["Slave CP + Worker-Windows"]
            SCP["Slave Control Plane (HA)"]
            WW["Worker-Windows"]
        end
    end
    
    subgraph AZ3["Availability Zone 3"]
        subgraph Node3["Database Node"]
            DBN["DB Node"]
        end
    end
    
    Users -->|Traffic| ALB
    ALB -->|Routes| MCP
    ALB -->|Routes| SCP
    ALB -->|Routes| WL
    ALB -->|Routes| WW
    
    MCP -->|etcd Replication| SCP
    SCP -->|Heartbeat| MCP
    
    WL -->|Pod Deployment| MCP
    WL -->|Pod Deployment| SCP
    WW -->|Pod Deployment| MCP
    WW -->|Pod Deployment| SCP
    
    WL -->|Database Access| DBN
    WW -->|Database Access| DBN
    
    style AZ1 fill:#FF9900,stroke:#333,color:#fff
    style AZ2 fill:#146EB4,stroke:#333,color:#fff
    style AZ3 fill:#00A651,stroke:#333,color:#fff
    style ALB fill:#36C5F0,stroke:#333,stroke-width:2px,color:#000
```

---

**Generated**: 2026-03-19  
**Status**: Architecture Documentation Complete
