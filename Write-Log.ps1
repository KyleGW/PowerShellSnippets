$global:scriptShortName = "Script Short Name"
$global:logFilePath = "d:\scriptlogs"
$global:logFileName = "$((Get-Date).ToString("yyyy-MM-dd HHmmss")) - $env:COMPUTERNAME - $scriptShortName.log"

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

