# install-k8s-components.ps1 - Install Kubernetes components on Windows
#Requires -RunAsAdministrator

param(
    [string]$KubernetesVersion = $env:KUBERNETES_VERSION,
    [string]$CalicoVersion = $env:CALICO_VERSION
)

# Default versions if not provided
if (-not $KubernetesVersion) { $KubernetesVersion = "1.34.0" }
if (-not $CalicoVersion) { $CalicoVersion = "3.27.0" }

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

Write-Host "=== Installing Kubernetes $KubernetesVersion components ===" -ForegroundColor Green

# Create directories
Write-Host ">>> Creating directories..."
$directories = @(
    "C:\k",
    "C:\k\pki",
    "C:\var\log\kubelet",
    "C:\var\lib\kubelet",
    "C:\etc\kubernetes\manifests"
)

foreach ($dir in $directories) {
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
}

# Download Kubernetes binaries
$binaries = @{
    "kubelet.exe"    = "https://dl.k8s.io/v$KubernetesVersion/bin/windows/amd64/kubelet.exe"
    "kubeadm.exe"    = "https://dl.k8s.io/v$KubernetesVersion/bin/windows/amd64/kubeadm.exe"
    "kube-proxy.exe" = "https://dl.k8s.io/v$KubernetesVersion/bin/windows/amd64/kube-proxy.exe"
    "kubectl.exe"    = "https://dl.k8s.io/v$KubernetesVersion/bin/windows/amd64/kubectl.exe"
}

foreach ($binary in $binaries.GetEnumerator()) {
    Write-Host ">>> Downloading $($binary.Key)..."
    Invoke-WebRequest -Uri $binary.Value -OutFile "C:\k\$($binary.Key)"
}

# Add C:\k to system PATH
Write-Host ">>> Adding C:\k to system PATH..."
$currentPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
if ($currentPath -notlike "*C:\k*") {
    [Environment]::SetEnvironmentVariable("Path", "$currentPath;C:\k", "Machine")
}

# Update current session PATH
$env:Path = "$env:Path;C:\k"

# Verify installation
Write-Host ">>> Verifying installation..."
& "C:\k\kubelet.exe" --version
& "C:\k\kubeadm.exe" version
& "C:\k\kubectl.exe" version --client

# Download Calico for Windows
Write-Host "=== Downloading Calico $CalicoVersion for Windows ===" -ForegroundColor Green
$calicoUrl = "https://github.com/projectcalico/calico/releases/download/v$CalicoVersion/calico-windows-v$CalicoVersion.zip"
$calicoArchive = "C:\k\calico-windows.zip"
Invoke-WebRequest -Uri $calicoUrl -OutFile $calicoArchive
Expand-Archive -Path $calicoArchive -DestinationPath "C:\k\calico" -Force

# Create kubelet configuration template
Write-Host ">>> Creating kubelet configuration template..."
@"
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
cgroupDriver: ""
clusterDNS:
  - 10.96.0.10
clusterDomain: cluster.local
resolvConf: ""
featureGates:
  WindowsHostProcessContainers: true
"@ | Out-File "C:\k\kubelet-config.yaml" -Encoding ascii

# Create join script
Write-Host ">>> Creating join script..."
@'
# Kubernetes Windows Node Join Script
# Usage: .\k8s-join.ps1 -ControlPlaneIP <IP> -Token <token> -CACertHash <hash>

param(
    [Parameter(Mandatory=$true)]
    [string]$ControlPlaneIP,
    
    [Parameter(Mandatory=$true)]
    [string]$Token,
    
    [Parameter(Mandatory=$true)]
    [string]$CACertHash
)

$ErrorActionPreference = 'Stop'

Write-Host "=== Joining Kubernetes cluster ===" -ForegroundColor Green
Write-Host ">>> Control Plane: $ControlPlaneIP"

# Get node hostname
$nodeName = (Invoke-RestMethod -Uri http://169.254.169.254/latest/meta-data/local-hostname -ErrorAction SilentlyContinue)
if (-not $nodeName) {
    $nodeName = $env:COMPUTERNAME.ToLower()
}
Write-Host ">>> Node name: $nodeName"

# Run kubeadm join
Write-Host ">>> Running kubeadm join..."
& C:\k\kubeadm.exe join "${ControlPlaneIP}:6443" `
    --token $Token `
    --discovery-token-ca-cert-hash "sha256:$CACertHash"

if ($LASTEXITCODE -ne 0) {
    throw "kubeadm join failed with exit code $LASTEXITCODE"
}

Write-Host "=== Node joined successfully! ===" -ForegroundColor Green
'@ | Out-File "C:\k\k8s-join.ps1" -Encoding ascii

# Create kubelet startup script
Write-Host ">>> Creating kubelet startup script..."
@'
# Start kubelet service
$ErrorActionPreference = 'Stop'

Write-Host "Starting kubelet..."

# Wait for containerd to be ready
$maxRetries = 30
$retryCount = 0
while ($retryCount -lt $maxRetries) {
    $service = Get-Service containerd -ErrorAction SilentlyContinue
    if ($service -and $service.Status -eq 'Running') {
        Write-Host "containerd is running"
        break
    }
    Write-Host "Waiting for containerd... ($retryCount/$maxRetries)"
    Start-Sleep -Seconds 5
    $retryCount++
}

if ($retryCount -ge $maxRetries) {
    throw "containerd did not start in time"
}

# Get node name from EC2 metadata or hostname
$nodeName = (Invoke-RestMethod -Uri http://169.254.169.254/latest/meta-data/local-hostname -ErrorAction SilentlyContinue)
if (-not $nodeName) {
    $nodeName = $env:COMPUTERNAME.ToLower()
}

Write-Host "Node name: $nodeName"

# Start kubelet
& C:\k\kubelet.exe `
    --config=C:\k\kubelet-config.yaml `
    --container-runtime-endpoint=npipe:////./pipe/containerd-containerd `
    --hostname-override=$nodeName `
    --kubeconfig=C:\k\kubelet.kubeconfig `
    --cert-dir=C:\k\pki `
    --register-with-taints="os=windows:NoSchedule" `
    --v=2
'@ | Out-File "C:\k\start-kubelet.ps1" -Encoding ascii

# Create kube-proxy startup script
Write-Host ">>> Creating kube-proxy startup script..."
@'
# Start kube-proxy
$ErrorActionPreference = 'Stop'

Write-Host "Starting kube-proxy..."

# Wait for kubelet to create kubeconfig
$maxRetries = 60
$retryCount = 0
while ($retryCount -lt $maxRetries) {
    if (Test-Path "C:\k\kubelet.kubeconfig") {
        Write-Host "kubelet.kubeconfig found"
        break
    }
    Write-Host "Waiting for kubelet.kubeconfig... ($retryCount/$maxRetries)"
    Start-Sleep -Seconds 5
    $retryCount++
}

# Get node name
$nodeName = (Invoke-RestMethod -Uri http://169.254.169.254/latest/meta-data/local-hostname -ErrorAction SilentlyContinue)
if (-not $nodeName) {
    $nodeName = $env:COMPUTERNAME.ToLower()
}

# Start kube-proxy
& C:\k\kube-proxy.exe `
    --kubeconfig=C:\k\kubelet.kubeconfig `
    --hostname-override=$nodeName `
    --proxy-mode=kernelspace `
    --v=2
'@ | Out-File "C:\k\start-kube-proxy.ps1" -Encoding ascii

# Cleanup
Write-Host ">>> Cleaning up..."
Remove-Item $calicoArchive -Force -ErrorAction SilentlyContinue

Write-Host "=== Kubernetes components installation completed ===" -ForegroundColor Green
Write-Host ""
Write-Host "After joining the cluster, run:" -ForegroundColor Yellow
Write-Host "  1. C:\k\k8s-join.ps1 -ControlPlaneIP <IP> -Token <token> -CACertHash <hash>"
Write-Host "  2. C:\k\start-kubelet.ps1"
Write-Host "  3. C:\k\start-kube-proxy.ps1"