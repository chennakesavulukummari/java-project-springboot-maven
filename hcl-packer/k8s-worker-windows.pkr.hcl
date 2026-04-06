# k8s-worker-windows.pkr.hcl - Kubernetes Windows Worker Node AMI

packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.0"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

source "amazon-ebs" "k8s-worker-windows" {
  ami_name        = "k8s-worker-windows-${var.kubernetes_version}-${local.timestamp}"
  ami_description = "Kubernetes ${var.kubernetes_version} Windows Worker - Windows Server 2022"
  instance_type   = var.instance_type_windows
  region          = var.aws_region

  vpc_id    = var.vpc_id != "" ? var.vpc_id : null
  subnet_id = var.subnet_id != "" ? var.subnet_id : null

  source_ami_filter {
    filters = {
      name                = "Windows_Server-2022-English-Full-ContainersLatest-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    owners      = ["amazon"]
    most_recent = true
  }

  communicator   = "winrm"
  winrm_username = "Administrator"
  winrm_use_ssl  = true
  winrm_insecure = true
  winrm_timeout  = "15m"

  # User data to enable WinRM
  user_data = <<-EOF
    <powershell>
    # Enable WinRM
    Set-ExecutionPolicy Unrestricted -Force
    
    # Configure WinRM for Packer
    winrm quickconfig -q
    winrm set winrm/config/winrs '@{MaxMemoryPerShellMB="1024"}'
    winrm set winrm/config '@{MaxTimeoutms="1800000"}'
    winrm set winrm/config/service '@{AllowUnencrypted="true"}'
    winrm set winrm/config/service/auth '@{Basic="true"}'
    
    # Enable HTTPS listener
    $cert = New-SelfSignedCertificate -DnsName $env:COMPUTERNAME -CertStoreLocation Cert:\LocalMachine\My
    winrm create winrm/config/Listener?Address=*+Transport=HTTPS "@{Hostname=`"$env:COMPUTERNAME`";CertificateThumbprint=`"$($cert.Thumbprint)`"}"
    
    # Open firewall
    netsh advfirewall firewall add rule name="WinRM-HTTPS" dir=in localport=5986 protocol=TCP action=allow
    
    # Restart WinRM
    Restart-Service WinRM
    </powershell>
  EOF

  launch_block_device_mappings {
    device_name           = "/dev/sda1"
    volume_size           = 100
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = merge(local.common_tags, {
    Name = "k8s-worker-windows-${var.kubernetes_version}"
    Role = "worker"
    OS   = "windows"
  })

  run_tags = {
    Name = "packer-builder-k8s-worker-windows"
  }
}

build {
  name    = "k8s-worker-windows"
  sources = ["source.amazon-ebs.k8s-worker-windows"]

  # Install Windows features for containers
  provisioner "powershell" {
    inline = [
      "Write-Host '=== Installing Windows Features ==='",
      "Install-WindowsFeature -Name Containers -IncludeManagementTools",
      "Install-WindowsFeature -Name Hyper-V -IncludeManagementTools -ErrorAction SilentlyContinue"
    ]
  }

  # Create directories
  provisioner "powershell" {
    inline = [
      "Write-Host '=== Creating directories ==='",
      "New-Item -ItemType Directory -Force -Path C:\\k",
      "New-Item -ItemType Directory -Force -Path C:\\k\\cni",
      "New-Item -ItemType Directory -Force -Path C:\\k\\cni\\config",
      "New-Item -ItemType Directory -Force -Path C:\\etc\\cni\\net.d",
      "New-Item -ItemType Directory -Force -Path C:\\opt\\cni\\bin",
      "New-Item -ItemType Directory -Force -Path C:\\ProgramData\\containerd\\root",
      "New-Item -ItemType Directory -Force -Path C:\\ProgramData\\containerd\\state"
    ]
  }

  # Install containerd
  provisioner "powershell" {
    environment_vars = [
      "CONTAINERD_VERSION=${var.containerd_version}"
    ]
    inline = [
      "Write-Host '=== Installing containerd ==='",
      "$ProgressPreference = 'SilentlyContinue'",
      "",
      "# Download containerd",
      "$containerdUrl = \"https://github.com/containerd/containerd/releases/download/v$env:CONTAINERD_VERSION/containerd-$env:CONTAINERD_VERSION-windows-amd64.tar.gz\"",
      "Invoke-WebRequest -Uri $containerdUrl -OutFile C:\\k\\containerd.tar.gz",
      "",
      "# Extract containerd",
      "tar -xzf C:\\k\\containerd.tar.gz -C C:\\k",
      "Copy-Item C:\\k\\bin\\* C:\\Windows\\System32\\ -Force",
      "",
      "# Generate default config",
      "containerd config default | Out-File C:\\ProgramData\\containerd\\config.toml -Encoding ascii",
      "",
      "# Register containerd service",
      "containerd --register-service",
      "",
      "# Start containerd",
      "Start-Service containerd",
      "Set-Service -Name containerd -StartupType Automatic",
      "",
      "Write-Host 'containerd installed successfully'"
    ]
  }

  # Install CNI plugins for Windows
  provisioner "powershell" {
    inline = [
      "Write-Host '=== Installing Windows CNI plugins ==='",
      "$ProgressPreference = 'SilentlyContinue'",
      "",
      "# Download Windows CNI plugins",
      "$cniUrl = 'https://github.com/microsoft/windows-container-networking/releases/download/v0.3.0/windows-container-networking-cni-amd64-v0.3.0.zip'",
      "Invoke-WebRequest -Uri $cniUrl -OutFile C:\\k\\cni-plugins.zip",
      "Expand-Archive -Path C:\\k\\cni-plugins.zip -DestinationPath C:\\opt\\cni\\bin -Force",
      "",
      "Write-Host 'CNI plugins installed'"
    ]
  }

  # Install crictl
  provisioner "powershell" {
    environment_vars = [
      "CRICTL_VERSION=${var.crictl_version}"
    ]
    inline = [
      "Write-Host '=== Installing crictl ==='",
      "$ProgressPreference = 'SilentlyContinue'",
      "",
      "$crictlUrl = \"https://github.com/kubernetes-sigs/cri-tools/releases/download/v$env:CRICTL_VERSION/crictl-v$env:CRICTL_VERSION-windows-amd64.tar.gz\"",
      "Invoke-WebRequest -Uri $crictlUrl -OutFile C:\\k\\crictl.tar.gz",
      "tar -xzf C:\\k\\crictl.tar.gz -C C:\\k",
      "Copy-Item C:\\k\\crictl.exe C:\\Windows\\System32\\",
      "",
      "# Configure crictl",
      "@'",
      "runtime-endpoint: npipe:////./pipe/containerd-containerd",
      "image-endpoint: npipe:////./pipe/containerd-containerd",
      "timeout: 10",
      "'@ | Out-File C:\\k\\crictl.yaml -Encoding ascii",
      "",
      "Write-Host 'crictl installed'"
    ]
  }

  # Install Kubernetes components
  provisioner "powershell" {
    environment_vars = [
      "KUBERNETES_VERSION=${var.kubernetes_version}"
    ]
    inline = [
      "Write-Host '=== Installing Kubernetes components ==='",
      "$ProgressPreference = 'SilentlyContinue'",
      "",
      "# Download kubelet",
      "$kubeletUrl = \"https://dl.k8s.io/v$env:KUBERNETES_VERSION/bin/windows/amd64/kubelet.exe\"",
      "Invoke-WebRequest -Uri $kubeletUrl -OutFile C:\\k\\kubelet.exe",
      "",
      "# Download kubeadm",
      "$kubeadmUrl = \"https://dl.k8s.io/v$env:KUBERNETES_VERSION/bin/windows/amd64/kubeadm.exe\"",
      "Invoke-WebRequest -Uri $kubeadmUrl -OutFile C:\\k\\kubeadm.exe",
      "",
      "# Download kube-proxy",
      "$kubeproxyUrl = \"https://dl.k8s.io/v$env:KUBERNETES_VERSION/bin/windows/amd64/kube-proxy.exe\"",
      "Invoke-WebRequest -Uri $kubeproxyUrl -OutFile C:\\k\\kube-proxy.exe",
      "",
      "# Download kubectl",
      "$kubectlUrl = \"https://dl.k8s.io/v$env:KUBERNETES_VERSION/bin/windows/amd64/kubectl.exe\"",
      "Invoke-WebRequest -Uri $kubectlUrl -OutFile C:\\k\\kubectl.exe",
      "",
      "# Add to PATH",
      "$env:Path += ';C:\\k'",
      "[Environment]::SetEnvironmentVariable('Path', $env:Path + ';C:\\k', 'Machine')",
      "",
      "Write-Host 'Kubernetes components installed'"
    ]
  }

  # Install wins (Windows Host Process Support)
  provisioner "powershell" {
    inline = [
      "Write-Host '=== Installing wins ==='",
      "$ProgressPreference = 'SilentlyContinue'",
      "",
      "$winsUrl = 'https://github.com/rancher/wins/releases/download/v0.4.14/wins.exe'",
      "Invoke-WebRequest -Uri $winsUrl -OutFile C:\\k\\wins.exe",
      "",
      "# Register wins service",
      "C:\\k\\wins.exe srv app run --register",
      "Start-Service rancher-wins",
      "Set-Service -Name rancher-wins -StartupType Automatic",
      "",
      "Write-Host 'wins installed'"
    ]
  }

  # Download Calico for Windows
  provisioner "powershell" {
    environment_vars = [
      "CALICO_VERSION=${var.calico_version}"
    ]
    inline = [
      "Write-Host '=== Downloading Calico for Windows ==='",
      "$ProgressPreference = 'SilentlyContinue'",
      "",
      "$calicoUrl = \"https://github.com/projectcalico/calico/releases/download/v$env:CALICO_VERSION/calico-windows-v$env:CALICO_VERSION.zip\"",
      "Invoke-WebRequest -Uri $calicoUrl -OutFile C:\\k\\calico-windows.zip",
      "Expand-Archive -Path C:\\k\\calico-windows.zip -DestinationPath C:\\k\\calico -Force",
      "",
      "Write-Host 'Calico for Windows downloaded'"
    ]
  }

  # Create join script for Windows
  provisioner "powershell" {
    inline = [
      "Write-Host '=== Creating join script ==='",
      "@'",
      "# Kubernetes Windows Node Join Script",
      "# Usage: .\\k8s-join.ps1 -ControlPlaneIP <IP> -Token <token> -CACertHash <hash>",
      "",
      "param(",
      "    [Parameter(Mandatory=$true)]",
      "    [string]$ControlPlaneIP,",
      "    ",
      "    [Parameter(Mandatory=$true)]",
      "    [string]$Token,",
      "    ",
      "    [Parameter(Mandatory=$true)]",
      "    [string]$CACertHash",
      ")",
      "",
      "Write-Host \"Joining cluster at $ControlPlaneIP...\"",
      "",
      "# Run kubeadm join",
      "C:\\k\\kubeadm.exe join ${ControlPlaneIP}:6443 `",
      "    --token $Token `",
      "    --discovery-token-ca-cert-hash sha256:$CACertHash",
      "",
      "Write-Host 'Node joined successfully'",
      "'@ | Out-File C:\\k\\k8s-join.ps1 -Encoding ascii",
      "",
      "Write-Host 'Join script created at C:\\k\\k8s-join.ps1'"
    ]
  }

  # Create kubelet startup script
  provisioner "powershell" {
    inline = [
      "Write-Host '=== Creating kubelet startup script ==='",
      "@'",
      "# Start kubelet with proper configuration",
      "$ErrorActionPreference = 'Stop'",
      "",
      "# Wait for containerd",
      "while (-not (Get-Service containerd -ErrorAction SilentlyContinue).Status -eq 'Running') {",
      "    Write-Host 'Waiting for containerd...'",
      "    Start-Sleep -Seconds 5",
      "}",
      "",
      "# Get node name",
      "$nodeName = (Invoke-RestMethod -Uri http://169.254.169.254/latest/meta-data/local-hostname).ToLower()",
      "",
      "# Start kubelet",
      "C:\\k\\kubelet.exe `",
      "    --config=C:\\k\\kubelet-config.yaml `",
      "    --container-runtime-endpoint=npipe:////./pipe/containerd-containerd `",
      "    --hostname-override=$nodeName `",
      "    --kubeconfig=C:\\k\\kubelet.kubeconfig `",
      "    --cert-dir=C:\\k\\pki `",
      "    --v=2",
      "'@ | Out-File C:\\k\\start-kubelet.ps1 -Encoding ascii",
      "",
      "Write-Host 'Kubelet startup script created'"
    ]
  }

  # Cleanup
  provisioner "powershell" {
    inline = [
      "Write-Host '=== Cleanup ==='",
      "Remove-Item C:\\k\\*.tar.gz -Force -ErrorAction SilentlyContinue",
      "Remove-Item C:\\k\\*.zip -Force -ErrorAction SilentlyContinue",
      "",
      "# Clear temp files",
      "Remove-Item $env:TEMP\\* -Recurse -Force -ErrorAction SilentlyContinue",
      "",
      "# Run disk cleanup",
      "cleanmgr /sagerun:1 2>$null",
      "",
      "Write-Host 'Cleanup complete'"
    ]
  }

  # Run Sysprep for AWS
  provisioner "powershell" {
    inline = [
      "Write-Host '=== Preparing for Sysprep ==='",
      "",
      "# Initialize EC2Launch for sysprep",
      "& 'C:\\ProgramData\\Amazon\\EC2Launch\\EC2Launch.exe' sysprep --shutdown"
    ]
  }

  post-processor "manifest" {
    output     = "manifest-worker-windows.json"
    strip_path = true
  }
}