<powershell>
# Windows EC2 User Data Script for Ansible Setup
# This script prepares a Windows EC2 instance for Ansible control node

Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

# Configure hostname
$computername = "ansible-win-node"
$ipaddr = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.AddressState -eq "Preferred"}).IPAddress[0]
Rename-Computer -NewName $computername -Force
Add-Content -Path "C:\Windows\System32\drivers\etc\hosts" -Value "$ipaddr $computername"

# ========================================
# Install Python (Required for Ansible)
# ========================================
Write-Host "Installing Python 3..."
$pythonInstaller = "C:\Temp\python-installer.exe"
$pythonUrl = "https://www.python.org/ftp/python/3.11.7/python-3.11.7-amd64.exe"

New-Item -ItemType Directory -Path "C:\Temp" -Force | Out-Null
Invoke-WebRequest -Uri $pythonUrl -OutFile $pythonInstaller
& $pythonInstaller /quiet InstallAllUsers=1 PrependPath=1 Include_pip=1
Remove-Item -Path $pythonInstaller -Force

# Wait for Python installation
Start-Sleep -Seconds 10

# ========================================
# Install Git
# ========================================
Write-Host "Installing Git..."
$gitInstaller = "C:\Temp\git-installer.exe"
$gitUrl = "https://github.com/git-for-windows/git/releases/download/v2.42.0.windows.2/Git-2.42.0.2-64-bit.exe"

Invoke-WebRequest -Uri $gitUrl -OutFile $gitInstaller
& $gitInstaller /VERYSILENT /NORESTART /NOCANCEL /SP-
Remove-Item -Path $gitInstaller -Force

Start-Sleep -Seconds 10

# ========================================
# Install Ansible via pip
# ========================================
Write-Host "Installing Ansible..."
python -m pip install --upgrade pip
python -m pip install ansible pywinrm

# Verify installations
Write-Host "Verifying installations..."
python --version
ansible --version
git --version

# ========================================
# Configure WinRM for Ansible (on local machine)
# ========================================
Write-Host "Configuring WinRM..."
winrm quickconfig -q
Set-Item -Path WSMan:\localhost\Shell\MaxMemoryPerShellMB -Value 1024
Set-Item -Path WSMan:\localhost\Service\MaxConcurrentOperationsPerUser -Value 4294967295

# Enable WinRM Basic Authentication
Set-Item -Path WSMan:\localhost\Service\Auth\Basic -Value $true
Set-Item -Path WSMan:\localhost\Service\AllowUnencrypted -Value $true

# ========================================
# Create Ansible configuration directory
# ========================================
New-Item -ItemType Directory -Path "$env:USERPROFILE\.ansible" -Force | Out-Null

# ========================================
# Create Ansible hosts inventory
# ========================================
$hostsFile = "$env:USERPROFILE\.ansible\hosts"
@"
[local]
localhost ansible_connection=local

[windows_servers]
; Add Windows servers here

[linux_servers]
; Add Linux servers here
"@ | Out-File -FilePath $hostsFile -Encoding ASCII

# ========================================
# Setup Ansible Config
# ========================================
$ansibleCfg = "$env:USERPROFILE\.ansible\ansible.cfg"
@"
[defaults]
inventory = $hostsFile
host_key_checking = False
deprecation_warnings = False
ansible_managed = Ansible managed: {file} modified on %Y-%m-%d %H:%M:%S by {uid} on {host}

[inventory]
enable_plugins = ini, yaml, csv, json

[privilege_escalation]
become = False

[winrm]
transport = basic
; For enhanced security, configure certificate-based authentication
"@ | Out-File -FilePath $ansibleCfg -Encoding ASCII

# ========================================
# Test Ansible Installation
# ========================================
Write-Host "Testing Ansible..."
ansible --version
ansible all -i localhost, -c local -m win_ping -vvv

# ========================================
# Display Success Message
# ========================================
Write-Host "========================================" -ForegroundColor Green
Write-Host "Ansible Windows Controller Setup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Update the Ansible hosts file at: $hostsFile" -ForegroundColor Yellow
Write-Host "2. Configure SSH/WinRM for your target servers" -ForegroundColor Yellow
Write-Host "3. Test connectivity: ansible all -i inventory.ini -m ping" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Green
</powershell>

