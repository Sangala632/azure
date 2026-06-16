# ============================================================
# DFI Source Domain - VM Startup Script
# Runs via: user_data (on first boot) +
#           CustomScriptExtension (post-deployment via agent)
# ============================================================

# --- Example: Initialize & format the data disk (LUN 0) ---
$disk = Get-Disk | Where-Object { $_.PartitionStyle -eq 'RAW' }
if ($disk) {
    $disk | Initialize-Disk -PartitionStyle MBR -PassThru |
            New-Partition -AssignDriveLetter -UseMaximumSize |
            Format-Volume -FileSystem NTFS -NewFileSystemLabel "DataDisk" -Confirm:$false
}

# --- Example: Set timezone ---
Set-TimeZone -Id "Singapore Standard Time"

# --- Example: Enable WinRM (already opened in NSG on port 5985) ---
Enable-PSRemoting -Force
Set-Item WSMan:\localhost\Client\TrustedHosts -Value "*" -Force

# --- Example: Install AD DS role (uncomment when needed) ---
# Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

# --- Add your custom steps below ---
