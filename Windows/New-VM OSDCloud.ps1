#Set Parameters
$vmName = "OSDCloud $(Get-Random)"
$vmISO = Join-Path $(Get-OSDCloudWorkspace) 'OSDCloud_NoPrompt.iso'
$vmGeneration = 2
$vmMemory = 16GB
$vmProcessorCount = 2
$vhdSize = 100GB

# Get default VHD path (admin)
$vmms = Get-WmiObject -Namespace root\virtualization\v2 Msvm_VirtualSystemManagementService
$vmmsSettings = Get-WmiObject -Namespace root\virtualization\v2 Msvm_VirtualSystemManagementServiceSettingData
$vhdPath = Join-Path $vmmsSettings.DefaultVirtualHardDiskPath "$vmName.vhdx"

# Create VM
$vm = New-VM -Name $vmName -Generation $vmGeneration -MemoryStartupBytes $vmMemory -NewVHDPath $vhdPath -NewVHDSizeBytes $vhdSize -Verbose -SwitchName 'Default Switch'
$vm | Set-VMProcessor -Count $vmProcessorCount -Verbose
$vm | Get-VMIntegrationService -Name "Guest Service Interface" | Enable-VMIntegrationService -Verbose
$vm | Set-VMMemory -DynamicMemoryEnabled $false -Verbose


$vmHardDiskDrive = $vm | Get-VMHardDiskDrive
$vmNetworkAdapter = $vm | Get-VMNetworkAdapter

# Set ISO
$vmDVD = $vm | Add-VMDvdDrive -Path $vmISO -Passthru
$vm | Set-VMFirmware -FirstBootDevice $vmDVD
$vm | Set-VMFirmware -BootOrder $vmDVD, $vmHardDiskDrive, $vmNetworkAdapter

# Set Secure Boot
#$vm | Set-VMFirmware -SecureBootTemplateId ([guid]'272e7447-90a4-4563-a4b9-8e4ab00526ce')
$vm | Set-VMFirmware -EnableSecureBoot On

# Enable TPM
if ((Get-TPM).TpmPresent -eq $true -and (Get-TPM).TpmReady -eq $true) {
    $vm | Set-VMSecurity -VirtualizationBasedSecurityOptOut:$false
    $vm | Set-VMKeyProtector -NewLocalKeyProtector
    $vm | Enable-VMTPM
}

Set-VMVideo -VMName $vmName -ResolutionType Single -HorizontalResolution 1280 -VerticalResolution 800

# Checkpoint and Snapshot
$vm | Set-VM -AutomaticCheckpointsEnabled $false
$vm | Set-VM -AutomaticStartAction Nothing
$vm | Set-VM -AutomaticStartDelay 3
$vm | Set-VM -AutomaticStopAction Shutdown
$vm | Checkpoint-VM -SnapshotName 'New-VM'

# Start VM
vmconnect.exe $env:ComputerName $vmName
Start-Sleep -Seconds 3
$vm | Start-VM

# Wait for Windows
#$vm | Wait-VM -For Heartbeat