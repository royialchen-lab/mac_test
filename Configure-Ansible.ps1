# 检查是否以管理员身份运行
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "Please run this script as Administrator!"
    Break
}

Write-Host "=== Starting Ansible Host Configuration ===" -ForegroundColor Cyan

# 设置 PowerShell 执行策略
Write-Host "- Setting Execution Policy to RemoteSigned..."
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force

# 配置winrm service并启动服务
Write-Host "- Configuring WinRM Service..."
winrm quickconfig 

# 修改winrm配置，启用远程连接认证
Write-Host "- Enabling service config"
winrm set winrm/config/service/auth '@{Basic="true"}'
winrm set winrm/config/service '@{AllowUnencrypted="true"}'

# 防火墙设置
Write-Host "- Configuring Firewall (TCP 5985)..."
Remove-NetFirewallRule -DisplayName "ansible" -ErrorAction SilentlyContinue
New-NetFirewallRule -DisplayName "ansible" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 5985

# 添加本地账户
Write-Host "- Configuring Local Admin User..."
$Username = "ansible_admin"
$Password = "123456789A."

$UserExists = Get-LocalUser -Name $Username -ErrorAction SilentlyContinue
if ($UserExists) {
    Write-Host "   - User exists"
} else {
    Write-Host "   - User does not exist, creating..."
    net user $Username $Password /add 
    net localgroup Administrators $Username /add
}

# 查看winrm service启动监听状态
Write-Host "- Check listener..."
winrm enumerate winrm/config/listener

Write-Host "`n=== Done. Please test connectivity from Ansible. ===" -ForegroundColor Green