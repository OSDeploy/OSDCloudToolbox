#Requires -Modules @{ ModuleName="OSD"; ModuleVersion="23.5.26.1" }
#Requires -RunAsAdministrator

Get-MyWindowsCapability -Match 'NetFX' -Detail | `
Where-Object { $_.State -eq 'NotPresent' } | `
Add-WindowsCapability -Online -Verbose