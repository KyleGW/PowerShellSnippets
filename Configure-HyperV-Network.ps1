<# 
.SYNOPSIS
	
.DESCRIPTION
    This script will configure the Hyper-V network switches the way I want on a new machine 

.TESTING 
        
.NOTES
    Author     : KyleGW
    Version    : 0.1

    https://blogs.technet.microsoft.com/jhoward/2008/06/17/hyper-v-what-are-the-uses-for-different-types-of-virtual-networks/
    https://blogs.technet.microsoft.com/heyscriptingguy/2013/10/09/use-powershell-to-create-virtual-switches/


.MODIFICATIONS
	2017-10-21  KyleGW	Created script
         
.EXAMPLE

#>

#Load logging Function
# . .\Write-Log.ps1
# Putting it inline for this script instead of loading it externally

#$global:logFilePath = "d:\logs"
#$global:logFileName = "$((Get-Date).ToString("yyyy-MM-dd HH:mm:ss"))-LogfileName.log"

Function Write-Log
{
    Param ([string]$textToWriteToLog)

    $LogFile = Join-Path $logFilePath $logFileName
    
    if (!(Test-Path -path $logFile ))
    {
        $logFile = New-Item -type file $logFile -Force
    }
    Write-Verbose $textToWriteToLog
    Try
    {
        Add-content $logfile -value "$((Get-Date).ToString("yyyy-MM-dd HH:mm:ss.fff")) - $textToWriteToLog"
    }
    catch [system.UnauthorizedAccessException]
    {
        throw "Error (logfile): Write access denied to [$logFile]" 
    }
}

Function Get-NetworkConfiguration
{

    #Gather Information on Existing Configurations
    Write-Log "---------------------------------------------------------------------------------------------"
    Write-Log " Print Configuration"
    Write-Log "---------------------------------------------------------------------------------------------"

    Write-Log "List existing virtual switches"
    Get-VMSwitch |  Out-File $LogFile -Encoding ASCII -Append
    Get-NetLbfoTeam |  Out-File $LogFile -Encoding ASCII -Append
    Write-Log "List existing Network Adapter info"
    Get-NetAdapter |  sort ifIndex | Out-File $LogFile -Encoding ASCII -Append
    Write-Log "`n`nList existing IP Information"
    Get-NetIPAddress | where -Property InterfaceAlias -NotMatch 'Loopback' |  sort ifIndex | ft |  Out-File $LogFile -Encoding ASCII -Append
    Write-Log "List existing default gateway information"
    Get-NetRoute -DestinationPrefix 0.0.0.0/0 |  Out-File $LogFile -Encoding ASCII -Append
}

$scriptShortName = "HyperV Network Configuration"

$verbose = $true
$ErrorActionPreference = "Stop"
$logFilePath = "d:\Scriptlogs"
$logFileName  = "$((Get-Date).ToString("yyyy-MM-dd HHmmss")) - $env:COMPUTERNAME - $scriptShortName.log"
$LogFile = Join-Path $logFilePath $logFileName
$TranscriptFileName  = "$((Get-Date).ToString("yyyy-MM-dd HHmmss")) - $env:COMPUTERNAME - $scriptShortName Transcript.log"

if(Test-Path $MyInvocation.MyCommand.Definition)
{
    if (!$MyInvocation.MyCommand.Definition)
    {
        $0 = split-path -parent $MyInvocation.MyCommand.Definition
    }
}
else
{
    $0 = " likely ISE Run Selection"
}

#Transcripting this session to catch system output that isn't explicitly logged with Write-Log
$TranscriptFile = Join-Path $logFilePath $TranscriptFileName
Start-Transcript -Path $TranscriptFile -Append -Force

Write-Host "Logged output can be found in $LogFile"
Write-Log "---------------------------------------------------------------------------------------------"
Write-Log "Script instance Started"
Write-Log "Running under context: $env:USERDOMAIN\$env:USERNAME"
Write-Log "Currently running from: $0"
Write-Log "---------------------------------------------------------------------------------------------"

Get-NetworkConfiguration

Write-Log "---------------------------------------------------------------------------------------------"
Write-Log " Updating Configuration"
Write-Log "---------------------------------------------------------------------------------------------"


if ($false)
{
    Import-Module Hyper-V
    $ethernet = Get-NetAdapter -Name ethernet
    $wifi = Get-NetAdapter -Name wi-fi
 
    New-VMSwitch -Name externalSwitch -NetAdapterName $ethernet.Name -AllowManagementOS $true -Notes 'Parent OS, VMs, LAN'
    New-VMSwitch -Name privateSwitch -SwitchType Private -Notes 'Internal VMs only'
    New-VMSwitch -Name internalSwitch -SwitchType Internal -Notes 'Parent OS, and internal VMs'

}

if ($configureSwitchLaptop)
{
    $wifi = Get-NetAdapter -Name wi-fi
    #New-VMSwitch -Name WiFiExternalSwitch -NetAdapterName $wifi.Name -AllowManagementOS $true -Notes 'Parent OS, VMs, wifi'
    New-VMSwitch -switchname "Internal HyperV NAT Switch" -SwitchType Internal -Notes 'Parent OS, and internal VMs'

    New-NetIPAddress -IPAddress 192.168.0.1 -PrefixLength 24 -InterfaceIndex 23
    New-NetNat -Name HyperVNAT -InternalIPInterfaceAddressPrefix 192.168.0.0/24
}


if ($configureSwitchPrivate)
{
    New-VMSwitch -Name privateSwitch -SwitchType Private -Notes 'Internal VMs only - no connection to host'
    
    Get-NetAdapter
    (Get-NetAdapter -name wi-fi).ifIndex
    # New-NetIPAddress -IPAddress 192.168.0.1 -PrefixLength 24 -InterfaceIndex 23
    New-NetIPAddress -IPAddress 192.168.0.1 -PrefixLength 24 -InterfaceIndex(Get-NetAdapter -name wi-fi).ifIndex
}

#$desktop = $true
if($desktop)
{
    $ethernet = Get-NetAdapter -Name ethernet
    New-VMSwitch -Name InternetSwitch -NetAdapterName $ethernet.Name -AllowManagementOS $true -Notes 'Parent OS, VMs, LAN'
    New-VMSwitch -Name vmOnlySwitch -SwitchType Private -Notes 'Internal VMs only'
}

Write-Log "---------------------------------------------------------------------------------------------"
Write-Log " Completed Updating Configuration"
Write-Log "---------------------------------------------------------------------------------------------"

Get-NetworkConfiguration

Write-Log "---------------------------------------------------------------------------------------------"
Write-Log " Script Ended"
Write-Log "---------------------------------------------------------------------------------------------"
Stop-Transcript
Invoke-Item $LogFile
