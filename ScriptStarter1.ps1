<# 
.SYNOPSIS
	
.DESCRIPTION
    This script will 
	It is used by _ in the process of/for _
.TESTING 
        
.NOTES
    Author     : KyleGW
    Version    : 0.1
.MODIFICATIONS
	2000-00-00  KyleGW	Created script
         
.EXAMPLE

#>

#Load logging Function
. .\Write-Log.ps1


$scriptShortName = "Script Short Name"

$verbose = $true
$ErrorActionPreference = "Stop"
$logFilePath = drive:\ScriptLogs
$logFileName  = "$((Get-Date).ToString("yyyy-MM-dd HHmmss")) - $env:COMPUTERNAME - $scriptShortName.log"
$LogFile = Join-Path $logFilePath $logFileName
$TranscriptFileName  = "$((Get-Date).ToString("yyyy-MM-dd HHmmss")) - $env:COMPUTERNAME - $scriptShortName Transcript.log"

if(Test-Path $MyInvocation.MyCommand.Definition)
{
    $0 = split-path -parent $MyInvocation.MyCommand.Definition
}

#Transcripting this session to catch system output that isn't explicitly logged with Write-Log
$TranscriptFile = $logFilePath+$TranscriptFileName
Start-Transcript -Path $TranscriptFile -Append -Force

Write-Host "Logged output can be found in $LogFile"
Write-Log "---------------------------------------------------------------------------------------------"
Write-Log "Script instance Started"
Write-Log "Running under context: $env:USERDOMAIN\$env:USERNAME"
Write-Log "Currently running from $0"
Write-Log "---------------------------------------------------------------------------------------------"

# Must run as administrator
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator'))
{
	Write-Log "FAILURE - Script not running as administrator. Please re-run script in an administrative context."
	Write-Host "Launch script or command window as administrator" -ForegroundColor Red
    throw "Failed - Script not running as administrator. Please re-run script in an administrative context."
}

#Test any paths or other pre-req we need
$preReqPath = "C:\doesntexist"
if (-not (test-path $preReqPath)){Write-Log "Necessary filepath does not exist [$preReqPath]"; throw "Necessary filepath does not exist [$preReqPath]"} 

# Test - does script need to run at all?
if((gci c:\).count -gt 0)
{
    Write-Log "Found condition, running script on some stuff"
    
    #set initial validation condition
    if(setsuccessconditions)
    {
        $success = $true
    }

}
else
{
    Write-Log "Nothing found to do. Exiting."
}

Stop-Transcript
#fix linefeeds in transcript lof (replace LF with CRLF)
Start-sleep -Seconds 5 #give stop-transcript time to flush buffer and write to disk and close file
(Get-Content $TranscriptFile) -replace "`r","`n" | out-file $TranscriptFile