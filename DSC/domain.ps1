
<#PSScriptInfo

.VERSION 0.3.1

.GUID edd05043-2acc-48fa-b5b3-dab574621ba1

.AUTHOR Michael Greene

.COMPANYNAME Microsoft Corporation

.COPYRIGHT 

.TAGS DSCConfiguration

.LICENSEURI https://github.com/Microsoft/DomainControllerConfig/blob/master/LICENSE

.PROJECTURI https://github.com/Microsoft/DomainControllerConfig

.ICONURI 

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES 

.RELEASENOTES
https://github.com/Microsoft/DomainControllerConfig/blob/master/README.md#versions

.PRIVATEDATA 2016-Datacenter,2016-Datacenter-Server-Core

#>

#Requires -module @{ModuleName = 'xActiveDirectory';ModuleVersion = '3.0.0.0'}
#Requires -module @{ModuleName = 'xStorage'; ModuleVersion = '3.4.0.0'}
#Requires -module @{ModuleName = 'xPendingReboot'; ModuleVersion = '0.3.0.0'}
#Requires -module @{ModuleName = 'DnsServerDsc'; ModuleVersion = '3.0.0'}

<#

.DESCRIPTION 
Demonstrates a minimally viable domain controller configuration script
compatible with Azure Automation Desired State Configuration service.
 
 Required variables in Automation service:
  - Credential to use for AD domain admin
  - Credential to use for Safe Mode recovery

Create these credential assets in Azure Automation,
and set their names in lines 11 and 12 of the configuration script.

Required modules in Automation service:
  - xActiveDirectory
  - xStorage
  - xPendingReboot

#>

configuration Domain
{
    param (
        [Parameter(Mandatory)]
        [String]$domainName,
        [String]$forwarderIP1,
        [String]$forwarderIP2
    )

Import-DscResource -ModuleName xActiveDirectory
Import-DscResource -ModuleName xStorage
Import-DscResource -ModuleName xPendingReboot
Import-DscResource -ModuleName DnsServerDSC
Import-DscResource -ModuleName 'PSDesiredStateConfiguration'

# When using with Azure Automation, modify these values to match your stored credential names
$domainCredential = Get-AutomationPSCredential 'domainCredential'
$safeModeCredential = Get-AutomationPSCredential 'domainCredential'


  node 'localhost'
  {
    WindowsFeature ADDSInstall
    {
        Ensure = 'Present'
        Name = 'AD-Domain-Services'
    }
    
    xWaitforDisk Disk2
    {
        DiskId = 2
        RetryIntervalSec = 10
        RetryCount = 30
    }
    
    xDisk DiskF
    {
        DiskId = 2
        DriveLetter = 'F'
        DependsOn = '[xWaitforDisk]Disk2'
    }
    
    xPendingReboot BeforeDC
    {
        Name = 'BeforeDC'
        SkipCcmClientSDK = $true
        DependsOn = '[WindowsFeature]ADDSInstall','[xDisk]DiskF'
    }
    
    # Configure domain values here
    xADDomain Domain
    {
        DomainName = $domainName
        DomainAdministratorCredential = $domainCredential
        SafemodeAdministratorPassword = $safeModeCredential
        DatabasePath = 'F:\NTDS'
        LogPath = 'F:\NTDS'
        SysvolPath = 'F:\SYSVOL'
        DependsOn = '[WindowsFeature]ADDSInstall','[xDisk]DiskF','[xPendingReboot]BeforeDC'
    }

    DnsServerConditionalForwarder 'AzureStorage'
    {
        Name    = 'blob.core.windows.net'
        MasterServers   = $forwarderIP1, $forwarderIP2
        ReplicationScope = 'Forest'
        Ensure  = 'Present'
        DependsOn = '[WindowsFeature]ADDSInstall','[xDisk]DiskF','[xPendingReboot]BeforeDC','[xADDomain]Domain'
    }
    
    Registry DisableRDPNLA
    {
        Key = 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp'
        ValueName = 'UserAuthentication'
        ValueData = 0
        ValueType = 'Dword'
        Ensure = 'Present'
        DependsOn = '[xADDomain]Domain'
    }
  }
}
