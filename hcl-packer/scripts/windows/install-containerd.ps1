# install-containerd.ps1 - Install containerd on Windows
#Requires -RunAsAdministrator

param(
    [string]$ContainerdVersion = $env:CONTAINERD_VERSION,
    [string]$CrictlVersion = $env:CRICTL_VERSION
)

# Default versions if not provided
if (-not $ContainerdVersion) { $ContainerdVersion = "1.7.11" }
if (-not $CrictlVersion) { $CrictlVersion = "1.34.0" }

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

Write-Host "=== Installing containerd $ContainerdVersion ===" -ForegroundColor Green

# Create directories
Write-Host ">>> Creating directories..."
$directories = @(
    "C:\k",
    "C:\k\cni",
    "C:\k\cni\config",
    "C:\etc\cni\net.d",
    "C:\opt\cni\bin",
    "C:\ProgramData\containerd\root",
    "C:\ProgramData\containerd\state"
)

foreach ($dir in $directories) {
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
}

# Download containerd
Write-Host ">>> Downloading containerd..."
$containerdUrl = "https://github.com/containerd/containerd/releases/download/v$ContainerdVersion/containerd-$ContainerdVersion-windows-amd64.tar.gz"
$containerdArchive = "C:\k\containerd.tar.gz"
Invoke-WebRequest -Uri $containerdUrl -OutFile $containerdArchive

# Extract containerd
Write-Host ">>> Extracting containerd..."
tar -xzf $containerdArchive -C "C:\k"

# Copy binaries to system path
Write-Host ">>> Installing containerd binaries..."
Copy-Item "C:\k\bin\*" "C:\Windows\System32\" -Force

# Generate default configuration
Write-Host ">>> Generating containerd configuration..."
& containerd config default | Out-File "C:\ProgramData\containerd\config.toml" -Encoding ascii

# Register containerd as a service
Write-Host ">>> Registering containerd service..."
& containerd --register-service

# Start containerd
Write-Host ">>> Starting containerd service..."
Start-Service containerd
Set-Service -Name containerd -StartupType Automatic

# Verify containerd is running
Write-Host ">>> Verifying containerd..."
$service = Get-Service containerd
if ($service.Status -ne 'Running') {
    throw "containerd service is not running!"
}
& containerd --version

# Download and install Windows CNI plugins
Write-Host "=== Installing Windows CNI plugins ===" -ForegroundColor Green
$cniUrl = "https://github.com/microsoft/windows-container-networking/releases/download/v0.3.0/windows-container-networking-cni-amd64-v0.3.0.zip"
$cniArchive = "C:\k\cni-plugins.zip"
Invoke-WebRequest -Uri $cniUrl -OutFile $cniArchive
Expand-Archive -Path $cniArchive -DestinationPath "C:\opt\cni\bin" -Force

# Download and install crictl
Write-Host "=== Installing crictl $CrictlVersion ===" -ForegroundColor Green
$crictlUrl = "https://github.com/kubernetes-sigs/cri-tools/releases/download/v$CrictlVersion/crictl-v$CrictlVersion-windows-amd64.tar.gz"
$crictlArchive = "C:\k\crictl.tar.gz"
Invoke-WebRequest -Uri $crictlUrl -OutFile $crictlArchive
tar -xzf $crictlArchive -C "C:\k"
Copy-Item "C:\k\crictl.exe" "C:\Windows\System32\" -Force

# Configure crictl
Write-Host ">>> Configuring crictl..."
@"
runtime-endpoint: npipe:////./pipe/containerd-containerd
image-endpoint: npipe:////./pipe/containerd-containerd
timeout: 10
"@ | Out-File "C:\k\crictl.yaml" -Encoding ascii

# Set environment variable for crictl config
[Environment]::SetEnvironmentVariable("CONTAINER_RUNTIME_ENDPOINT", "npipe:////./pipe/containerd-containerd", "Machine")

# Download and install wins (Windows Host Process Support)
Write-Host "=== Installing wins ===" -ForegroundColor Green
$winsUrl = "https://github.com/rancher/wins/releases/download/v0.4.14/wins.exe"
Invoke-WebRequest -Uri $winsUrl -OutFile "C:\k\wins.exe"

# Register wins service
Write-Host ">>> Registering wins service..."
& "C:\k\wins.exe" srv app run --register
Start-Service rancher-wins
Set-Service -Name rancher-wins -StartupType Automatic

# Cleanup archives
Write-Host ">>> Cleaning up..."
Remove-Item $containerdArchive -Force -ErrorAction SilentlyContinue
Remove-Item $cniArchive -Force -ErrorAction SilentlyContinue
Remove-Item $crictlArchive -Force -ErrorAction SilentlyContinue

Write-Host "=== Container runtime installation completed ===" -ForegroundColor Green