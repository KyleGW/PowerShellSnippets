Add-PSSnapin Microsoft.SharePoint.PowerShell;
$domain="contoso.org"

#repurposed code I wrote to patch all servers in a SharePoint farm to simply run IIS Reset. 
#try not to do this as a matter of practice, but sometimes necessary

#define patch information 
$patchname = "IIS Reset" 
$installcommandlocation = ""
$installcommandexe = "iisreset"
$installcommandswitches=""

#since we are using Get-SPServer it must be run once per farm. use master server list data instead to run against all farms (or non-SP web farms)
foreach($sp_server in Get-SPServer)
{
   if($sp_server.Role.ToString().ToLower() -eq "application")
   {
            write-host $sp_server.address "Running command " $installcommandlocation$installcommandexe$installcommandswitches
            $doit="\\"+ $sp_server.address +"."+$domain+"\ROOT\CIMV2:win32_process"
            $proc=([WMICLASS]$doit).Create($installcommandlocation+$installcommandexe+$installcommandswitches)
            write-host "PID is " $proc.ProcessID "on" $sp_server.address   
            Add-Member -InputObject $sp_server -MemberType NoteProperty -Name PID -value $proc.ProcessID -Force  
    }
}
