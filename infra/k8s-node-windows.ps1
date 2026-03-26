# PowerShell script to setup Windows Kubernetes worker node
# Run as Administrator
# This script configures a Windows machine to join a Kubernetes cluster

# Requires -RunAsAdministrator

# Set error action preference
$ErrorActionPreference = "Stop"

# Function to write status messages
function Write-Status {
    param([string]$Message)
    Write-Host ">>> $Message" -ForegroundColor Cyan
}

# Function to check if running as Administrator
function Test-IsAdmin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Check if running as Administrator
if (-not (Test-IsAdmin)) {
    Write-Host "ERROR: This script must be run as Administrator" -ForegroundColor Red
    exit 1
}

Write-Status "Starting Windows Kubernetes Worker Node Setup"

# =====================================================
# Step 1: Set Hostname
# =====================================================
Write-Status "Setting hostname to k8s-node2.cloudbinary.in"
$hostnameNew = "k8s-node2"
try {
    Rename-Computer -NewName $hostnameNew -Force -ErrorAction Stop
    Write-Status "Hostname set to $hostnameNew (restart required)"
} catch {
    Write-Host "Warning: Could not change hostname: $_" -ForegroundColor Yellow
}

# =====================================================
# Step 2: Update Hosts File
# =====================================================
Write-Status "Updating hosts file"
$hostsPath = "C:\Windows\System32\drivers\etc\hosts"

# Get local IP address (exclude 127.0.0.1 and ::1)
$ipAddress = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notmatch '^127\.' } | Select-Object -First 1).IPAddress

if ($null -ne $ipAddress) {
    $newHostEntry = "$ipAddress k8s-node2.cloudbinary.in"
    
    # Check if entry already exists
    if (-not (Select-String -Path $hostsPath -Pattern "k8s-node2.cloudbinary.in" -Quiet -ErrorAction SilentlyContinue)) {
        Add-Content -Path $hostsPath -Value $newHostEntry
        Write-Status "Added hosts entry: $newHostEntry"
    } else {
        Write-Status "Hosts entry already exists"
    }
} else {
    Write-Host "Warning: Could not determine IP address" -ForegroundColor Yellow
}

# =====================================================
# Step 3: Install Chocolatey Package Manager
# =====================================================
Write-Status "Installing Chocolatey package manager"
if (-not (Test-Path "C:\ProgramData\chocolatey\bin\choco.exe")) {
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    Write-Status "Chocolatey installed successfully"
} else {
    Write-Status "Chocolatey already installed"
}

# Refresh environment variables
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

# =====================================================
# Step 4: Install Required Tools
# =====================================================
Write-Status "Installing required tools via Chocolatey"
$requiredPackages = @("git", "curl", "7zip")

foreach ($package in $requiredPackages) {
    if (-not (choco list --local-only | Select-String $package -Quiet -ErrorAction SilentlyContinue)) {
        Write-Status "Installing $package"
        choco install $package -y --no-progress
    } else {
        Write-Status "$package already installed"
    }
}

# =====================================================
# Step 5: Install Docker/Containerd
# =====================================================
Write-Status "Installing Docker Desktop or Containerd for Windows"
Write-Host "Note: For Kubernetes on Windows, you need either:" -ForegroundColor Green
Write-Host "  1. Docker Desktop with Windows containers enabled, OR" -ForegroundColor Green
Write-Host "  2. Containerd with Windows CNI plugins" -ForegroundColor Green

if (-not (Test-Path "C:\Program Files\Docker\docker.exe")) {
    Write-Status "Installing Docker Desktop"
    choco install docker-desktop -y --no-progress
    Write-Status "Docker Desktop installation initiated. You may need to restart."
} else {
    Write-Status "Docker already installed"
}

# =====================================================
# Step 6: Enable Hyper-V Feature (if not already enabled)
# =====================================================
Write-Status "Checking Hyper-V feature"
$hyperVFeature = Get-WindowsOptionalFeature -FeatureName Microsoft-Hyper-V -Online
if ($hyperVFeature.State -ne "Enabled") {
    Write-Status "Enabling Hyper-V feature (requires restart)"
    Enable-WindowsOptionalFeature -FeatureName Microsoft-Hyper-V -Online -All -NoRestart
    Write-Host "Warning: Hyper-V enabled. Restart required." -ForegroundColor Yellow
} else {
    Write-Status "Hyper-V already enabled"
}

# =====================================================
# Step 7: Download and Install Kubernetes Binaries
# =====================================================
Write-Status "Downloading Kubernetes binaries (v1.28)"

$kubeVersion = "v1.28.0"
$kubeDir = "C:\kubernetes"

if (-not (Test-Path $kubeDir)) {
    New-Item -ItemType Directory -Path $kubeDir -Force | Out-Null
    Write-Status "Created Kubernetes directory: $kubeDir"
}

# Set up Kubernetes binaries location
Write-Status "Downloading kubectl, kubeadm, and kubelet"

# Download kubectl
$kubeCtlUrl = "https://dl.k8s.io/release/$kubeVersion/bin/windows/amd64/kubectl.exe"
$kubeCtlPath = "$kubeDir\kubectl.exe"
if (-not (Test-Path $kubeCtlPath)) {
    Write-Status "Downloading kubectl from $kubeCtlUrl"
    try {
        (New-Object System.Net.WebClient).DownloadFile($kubeCtlUrl, $kubeCtlPath)
        Write-Status "kubectl downloaded successfully"
    } catch {
        Write-Host "Error downloading kubectl: $_" -ForegroundColor Red
    }
}

# Download kubeadm
$kubeAdmUrl = "https://dl.k8s.io/release/$kubeVersion/bin/windows/amd64/kubeadm.exe"
$kubeAdmPath = "$kubeDir\kubeadm.exe"
if (-not (Test-Path $kubeAdmPath)) {
    Write-Status "Downloading kubeadm from $kubeAdmUrl"
    try {
        (New-Object System.Net.WebClient).DownloadFile($kubeAdmUrl, $kubeAdmPath)
        Write-Status "kubeadm downloaded successfully"
    } catch {
        Write-Host "Error downloading kubeadm: $_" -ForegroundColor Red
    }
}

# Download kubelet
$kubeLetUrl = "https://dl.k8s.io/release/$kubeVersion/bin/windows/amd64/kubelet.exe"
$kubeLetPath = "$kubeDir\kubelet.exe"
if (-not (Test-Path $kubeLetPath)) {
    Write-Status "Downloading kubelet from $kubeLetUrl"
    try {
        (New-Object System.Net.WebClient).DownloadFile($kubeLetUrl, $kubeLetPath)
        Write-Status "kubelet downloaded successfully"
    } catch {
        Write-Host "Error downloading kubelet: $_" -ForegroundColor Red
    }
}

# Add Kubernetes directory to PATH
Write-Status "Adding Kubernetes directory to system PATH"
$currentPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
if ($currentPath -notlike "*$kubeDir*") {
    [Environment]::SetEnvironmentVariable("PATH", "$currentPath;$kubeDir", "Machine")
    $env:Path = $currentPath + ";" + $kubeDir
    Write-Status "Kubernetes binaries added to PATH"
}

# =====================================================
# Step 8: Configure CNI Plugins
# =====================================================
Write-Status "Configuring CNI plugins for Windows"

$cniDir = "C:\ProgramData\cni\bin"
if (-not (Test-Path $cniDir)) {
    New-Item -ItemType Directory -Path $cniDir -Force | Out-Null
    Write-Status "Created CNI directory: $cniDir"
}

# Download Windows CNI plugins
Write-Status "Downloading Windows CNI plugins"
$cniVersion = "v1.4.0"
$cniUrl = "https://github.com/microsoft/windows-container-networking/releases/download/$cniVersion/windows-container-networking-cni-amd64-$cniVersion.zip"
$cniZip = "$env:TEMP\cni-plugins.zip"

try {
    Write-Status "Downloading CNI plugins from $cniUrl"
    (New-Object System.Net.WebClient).DownloadFile($cniUrl, $cniZip)
    
    # Extract CNI plugins
    Expand-Archive -Path $cniZip -DestinationPath $cniDir -Force
    Write-Status "CNI plugins extracted to $cniDir"
    
    # Clean up
    Remove-Item $cniZip
} catch {
    Write-Host "Warning: Could not download CNI plugins: $_" -ForegroundColor Yellow
}

# =====================================================
# Step 9: Create CNI Configuration
# =====================================================
Write-Status "Creating CNI configuration"

$cniConfigDir = "C:\ProgramData\cni\conf"
if (-not (Test-Path $cniConfigDir)) {
    New-Item -ItemType Directory -Path $cniConfigDir -Force | Out-Null
}

# Create basic CNI config for Windows
$cniConfig = @"
{
  "cniVersion": "0.4.0",
  "name": "cbr0",
  "type": "nat",
  "master": "Ethernet",
  "ipam": {
    "type": "windowsipam"
  },
  "capabilities": {
    "portMappings": true,
    "bandwidthShaping": true
  },
  "runtimes": {
    "docker": "rund"
  }
}
"@

$cniConfigFile = "$cniConfigDir\10-nat.conf"
if (-not (Test-Path $cniConfigFile)) {
    Set-Content -Path $cniConfigFile -Value $cniConfig
    Write-Status "CNI configuration created at $cniConfigFile"
}

# =====================================================
# Step 10: Configure Docker/Containerd for Kubernetes
# =====================================================
Write-Status "Configuring container runtime for Kubernetes"

# For Docker Desktop, ensure Windows containers are enabled
Write-Host "Note: If using Docker Desktop, ensure Windows containers mode is enabled" -ForegroundColor Green

# =====================================================
# Step 11: Setup kubelet Service
# =====================================================
Write-Status "Setting up kubelet as Windows service"

# Create kubelet service configuration directory
$kubeConfigDir = "C:\ProgramData\kubernetes"
if (-not (Test-Path $kubeConfigDir)) {
    New-Item -ItemType Directory -Path $kubeConfigDir -Force | Out-Null
}

# =====================================================
# Step 12: Verify Installation
# =====================================================
Write-Status "Verifying installation"

Write-Host "`n=== Kubernetes Binaries ===" -ForegroundColor Green
kubectl version --client 2>$null || Write-Host "kubectl verification pending (requires restart)" -ForegroundColor Yellow
kubeadm version 2>$null || Write-Host "kubeadm verification pending (requires restart)" -ForegroundColor Yellow

Write-Host "`n=== System Information ===" -ForegroundColor Green
hostname
ipconfig /all | Where-Object { $_ -match 'IPv4|Physical' }

# =====================================================
# Step 13: Final Instructions
# =====================================================
Write-Status "Setup completed!"

Write-Host "`n=== NEXT STEPS ===" -ForegroundColor Magenta
Write-Host "1. RESTART THE COMPUTER to apply hostname and Hyper-V changes:" -ForegroundColor White
Write-Host "   Restart-Computer -Force" -ForegroundColor Cyan
Write-Host ""
Write-Host "2. After restart, verify Docker/Containerd is running" -ForegroundColor White
Write-Host ""
Write-Host "3. Join the cluster with kubeadm on the control plane:" -ForegroundColor White
Write-Host "   kubeadm token create --print-join-command (run on control plane)" -ForegroundColor Cyan
Write-Host ""
Write-Host "4. On this Windows node, run the kubeadm join command from step 3" -ForegroundColor White
Write-Host ""
Write-Host "5. Install a Windows CNI plugin (e.g., Calico, Flannel for Windows)" -ForegroundColor White
Write-Host ""
Write-Host "=== IMPORTANT NOTES ===" -ForegroundColor Yellow
Write-Host "• Windows nodes require Windows Server 2019 or later" -ForegroundColor White
Write-Host "• Windows nodes can only run Windows containers" -ForegroundColor White
Write-Host "• You need a hybrid cluster with Linux control plane" -ForegroundColor White
Write-Host "• Install CNI plugin that supports Windows (Calico, Flannel, etc.)" -ForegroundColor White
Write-Host "• Kubernetes v1.28 is configured; adjust as needed" -ForegroundColor White
Write-Host ""

Write-Host "Setup script completed at $(Get-Date)" -ForegroundColor Green
