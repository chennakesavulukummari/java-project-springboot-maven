# Windows Worker Node Initialization Script
# Windows Server 2022

# Enable needed Windows features
Write-Host "Enabling Windows features..." -ForegroundColor Yellow
Enable-WindowsOptionalFeature -Online -FeatureName Containers -NoRestart
Enable-WindowsOptionalFeature -Online -FeatureName Hyper-V -NoRestart
Restart-Computer -Force

# After restart, continue with:
# The PowerShell script will continue automatically after restart
# You may need to run this section manually if auto-restart doesn't continue the script

# Variables from Terraform
$ClusterName = "${cluster_name}"
$MasterIP = "${master_ip}"
$BootstrapToken = "${master_token}"
$KubernetesVersion = "1.28.0"
$WindowsVersion = "ltsc2022"

Write-Host "=== Starting Windows Worker Node Setup ===" -ForegroundColor Yellow

# ============================================================================
# Install Docker/Containerd
# ============================================================================

Write-Host "[1/5] Installing Docker..." -ForegroundColor Yellow
Install-Module -Name DockerProvider -Repository PSGallery -Force
Install-Package -Name docker -ProviderName DockerProvider -Force

Start-Service docker
Set-Service -Name docker -StartupType Automatic

# ============================================================================
# Install Kubernetes Tools
# ============================================================================

Write-Host "[2/5] Installing Kubernetes tools..." -ForegroundColor Yellow

# Create directory for kubernetes binaries
New-Item -ItemType Directory -Force -Path "C:\ProgramData\Kubernetes\bin" | Out-Null
New-Item -ItemType Directory -Force -Path "C:\ProgramData\Kubernetes\config" | Out-Null

# Download kubeadm, kubelet, kubectl
$KubeURL = "https://dl.k8s.io/v${KubernetesVersion}/bin/windows/amd64"

Write-Host "Downloading kubernetes binaries..." -ForegroundColor Yellow
$ProgressPreference = 'SilentlyContinue'

Invoke-WebRequest -Uri "$KubeURL/kubeadm.exe" -OutFile "C:\ProgramData\Kubernetes\bin\kubeadm.exe"
Invoke-WebRequest -Uri "$KubeURL/kubelet.exe" -OutFile "C:\ProgramData\Kubernetes\bin\kubelet.exe"
Invoke-WebRequest -Uri "$KubeURL/kubectl.exe" -OutFile "C:\ProgramData\Kubernetes\bin\kubectl.exe"
Invoke-WebRequest -Uri "$KubeURL/kube-proxy.exe" -OutFile "C:\ProgramData\Kubernetes\bin\kube-proxy.exe"

# Add to PATH
$env:Path += ";C:\ProgramData\Kubernetes\bin"
[Environment]::SetEnvironmentVariable("Path", $env:Path, [EnvironmentVariableTarget]::Machine)

# ============================================================================
# Configure Network
# ============================================================================

Write-Host "[3/5] Configuring network..." -ForegroundColor Yellow

# Create network configuration
$NetworkConfig = @"
{
  "cniVersion": "0.4.0",
  "name": "vfxlan",
  "type": "vfxlan",
  "master": "Ethernet",
  "ipMasq": false,
  "backends": [
    {
      "name": "vxlan",
      "type": "vxlan",
      "vxlanid": 4096
    }
  ]
}
"@

New-Item -ItemType Directory -Force -Path "C:\ProgramData\Kubernetes\etc\cni\net.d" | Out-Null
$NetworkConfig | Out-File -FilePath "C:\ProgramData\Kubernetes\etc\cni\net.d\vfxlan.conf" -Encoding ASCII

# ============================================================================
# Configure kubelet
# ============================================================================

Write-Host "[4/5] Configuring kubelet..." -ForegroundColor Yellow

$KubeletConfig = @"
{
  "kind": "KubeletConfiguration",
  "apiVersion": "kubelet.config.k8s.io/v1beta1",
  "serverTLSBootstrap": true,
  "tlsCipherSuites": [
    "TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256",
    "TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256",
    "TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384",
    "TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384",
    "TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305",
    "TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305"
  ]
}
"@

$KubeletConfig | Out-File -FilePath "C:\ProgramData\Kubernetes\config\kubelet-config.json" -Encoding ASCII

# ============================================================================
# Join Cluster
# ============================================================================

Write-Host "[5/5] Joining cluster..." -ForegroundColor Yellow
Write-Host "Master IP: $MasterIP" -ForegroundColor Cyan

# Wait for master to be ready
$Elapsed = 0
$MaxWait = 600  # 10 minutes

while ($Elapsed -lt $MaxWait) {
    try {
        $Connection = Test-NetConnection -ComputerName $MasterIP -Port 6443 -InformationLevel Quiet
        if ($Connection) {
            Write-Host "Master node is ready!" -ForegroundColor Green
            break
        }
    } catch {
        Write-Host "Waiting for master node... ($Elapsed/$MaxWait seconds)" -ForegroundColor Yellow
        Start-Sleep -Seconds 10
        $Elapsed += 10
    }
}

if ($Elapsed -ge $MaxWait) {
    Write-Host "ERROR: Master node not reachable after $MaxWait seconds" -ForegroundColor Red
    exit 1
}

# Get join command (you would need to retrieve this from master)
# This is a placeholder - adjust based on your setup
$JoinCommand = "kubeadm join ${MasterIP}:6443 --token ${BootstrapToken} --discovery-token-unsafe-skip-ca-verification"

Write-Host "Executing join command..." -ForegroundColor Yellow
Invoke-Expression $JoinCommand

# Start kubelet service
Write-Host "Starting kubelet service..." -ForegroundColor Yellow

# Create kubelet service
$kubeletArgs = @(
    "--bootstrap-kubeconfig=C:\ProgramData\Kubernetes\bootstrap.conf",
    "--kubeconfig=C:\ProgramData\Kubernetes\kubelet.conf",
    "--config=C:\ProgramData\Kubernetes\config\kubelet-config.json",
    "--hostname-override=$(hostname)",
    "--container-runtime=docker",
    "--v=2"
) -join " "

# Register kubelet as Windows service
New-Service -Name kubelet `
    -BinaryPathName "C:\ProgramData\Kubernetes\bin\kubelet.exe $kubeletArgs" `
    -StartupType Automatic `
    -ErrorAction SilentlyContinue

Start-Service -Name kubelet
Set-Service -Name kubelet -StartupType Automatic

# Add node labels
Write-Host "Adding node labels..." -ForegroundColor Yellow

$KubectlPath = "C:\ProgramData\Kubernetes\bin\kubectl.exe"

# Wait for node to appear in cluster
Start-Sleep -Seconds 30

& $KubectlPath label node $(hostname) `
    node-type=worker `
    os-type=windows `
    tier-placement=app `
    --overwrite `
    --kubeconfig="C:\ProgramData\Kubernetes\kubelet.conf" `
    -ErrorAction SilentlyContinue

Write-Host "=== Windows Worker Node Setup Complete ===" -ForegroundColor Green
Write-Host "Node: $(hostname)" -ForegroundColor Cyan
Write-Host "Master: $MasterIP" -ForegroundColor Cyan
Write-Host "Kubernetes Version: $KubernetesVersion" -ForegroundColor Cyan
Write-Host "Review logs at: C:\ProgramData\Kubernetes\logs\" -ForegroundColor Yellow
