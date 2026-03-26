<powershell>
# ============================================================================
# Windows EC2 User Data Script for Ansible Worker Node
# ============================================================================
# This script prepares a Windows EC2 instance as an Ansible managed node
# (worker/agent) to be controlled by a remote Ansible controller

Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Starting Ansible Windows Worker Node Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# ========================================
# Configure hostname
# ========================================
Write-Host "Configuring hostname..." -ForegroundColor Yellow
$computername = "ansible-win-worker"
$ipaddr = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.AddressState -eq "Preferred"}).IPAddress[0]
Rename-Computer -NewName $computername -Force
Add-Content -Path "C:\Windows\System32\drivers\etc\hosts" -Value "$ipaddr $computername"
Write-Host "✓ Hostname configured: $computername" -ForegroundColor Green

# ========================================
# Create working directories
# ========================================
Write-Host "Creating working directories..." -ForegroundColor Yellow
New-Item -ItemType Directory -Path "C:\Temp" -Force | Out-Null
New-Item -ItemType Directory -Path "C:\ProgramData\ansible" -Force | Out-Null
Write-Host "✓ Directories created" -ForegroundColor Green


# ========================================
# Configure WinRM for Ansible Communication
# ========================================
Write-Host "Configuring WinRM..." -ForegroundColor Yellow
try {
    # Enable WinRM service
    winrm quickconfig -q
    
    # Configure WinRM settings for Ansible
    Set-Item -Path WSMan:\localhost\Shell\MaxMemoryPerShellMB -Value 1024
    Set-Item -Path WSMan:\localhost\Service\MaxConcurrentOperationsPerUser -Value 4294967295
    Set-Item -Path WSMan:\localhost\Service\MaxTimeoutms -Value 1800000
    
    # Enable Basic Authentication
    Set-Item -Path WSMan:\localhost\Service\Auth\Basic -Value $true
    
    # Enable unencrypted traffic (NOT recommended for production - use certificates in production)
    Set-Item -Path WSMan:\localhost\Service\AllowUnencrypted -Value $true
    
    # Restart WinRM service
    Restart-Service WinRM -Force
    
    Write-Host "✓ WinRM configured and started" -ForegroundColor Green
} catch {
    Write-Host "✗ Failed to configure WinRM: $_" -ForegroundColor Red
}

# ========================================
# Install Python (for Ansible compatibility)
# ========================================
Write-Host "Installing Python 3.11..." -ForegroundColor Yellow
$pythonInstaller = "C:\Temp\python-installer.exe"
$pythonUrl = "https://www.python.org/ftp/python/3.11.7/python-3.11.7-amd64.exe"

try {
    Invoke-WebRequest -Uri $pythonUrl -OutFile $pythonInstaller -ErrorAction Stop
    & $pythonInstaller /quiet InstallAllUsers=1 PrependPath=1 Include_pip=1
    Start-Sleep -Seconds 15
    Remove-Item -Path $pythonInstaller -Force -ErrorAction SilentlyContinue
    Write-Host "✓ Python installed successfully" -ForegroundColor Green
} catch {
    Write-Host "✗ Failed to install Python: $_" -ForegroundColor Yellow
}

# ========================================
# Verify Python Installation
# ========================================
Write-Host "Verifying Python installation..." -ForegroundColor Yellow
try {
    python --version
    Write-Host "✓ Python is available" -ForegroundColor Green
} catch {
    Write-Host "⚠ Python verification: $_" -ForegroundColor Yellow
}

# ========================================
# Final Status - Worker Node Ready
# ========================================
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Worker Node Setup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Node Configuration:" -ForegroundColor Cyan
Write-Host "  Hostname: ansible-win-worker" -ForegroundColor White
Write-Host "  WinRM Port: 5985 (HTTP) / 5986 (HTTPS)" -ForegroundColor White
Write-Host "  Python: Installed for Ansible compatibility" -ForegroundColor White
Write-Host "  Role: Ansible Managed Node (Worker)" -ForegroundColor White
Write-Host ""
Write-Host "WinRM Configuration:" -ForegroundColor Cyan
Write-Host "  Status: Configured and Running" -ForegroundColor White
Write-Host "  Auth: Basic Authentication Enabled" -ForegroundColor White
Write-Host "  Service: WinRM" -ForegroundColor White
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "  1. Note this instance's IP or DNS name" -ForegroundColor White
Write-Host "  2. Add to Ansible inventory on your controller" -ForegroundColor White
Write-Host "  3. Configure credentials in Ansible inventory" -ForegroundColor White
Write-Host "  4. Test with: ansible windows_group -m win_ping" -ForegroundColor White
Write-Host ""
Write-Host "Example Ansible Inventory Entry:" -ForegroundColor Yellow
Write-Host "  [windows_servers]" -ForegroundColor Gray
Write-Host "  192.168.1.100 ansible_user=Administrator ansible_password=YourPassword" -ForegroundColor Gray
Write-Host ""
Write-Host "Security Notes:" -ForegroundColor Magenta
Write-Host "  ⚠ Change Administrator password immediately" -ForegroundColor White
Write-Host "  ⚠ For production: Use certificate-based WinRM auth" -ForegroundColor White
Write-Host "  ⚠ Enable Windows Firewall and restrict WinRM ports" -ForegroundColor White
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
</powershell>
