$global:Servers = @("SERVER1","Server2")

#Build the object array
$ServerList = @{}
foreach($server in $Servers)
{
    $ServerList.add($server,"Incomplete")
}

$startTime = Get-Date
$timeoutInMinutes = 2

#quick sleep here to give $startTime time to get set, otherwise script goes too fast and it doesn't get set properly
Start-Sleep -Seconds 2

#loop them
do
{ 
    $timeLeft = (($startTime).AddMinutes($timeoutInMinutes) - (Get-Date))
    Write-Verbose "$(($ServerList.GetEnumerator() | ?{$_.value -eq "Complete"}).Count) servers complete out of $($ServerList.count) total servers - $($timeLeft.Minutes) Minutes $($timeLeft.Seconds) seconds left til we hit timeout Period"

    #loop the incomplete servers
    foreach($incompleteObject in $ServerList.GetEnumerator() | ?{$_.value -eq "Incomplete"})
    {
        $serverName = $incompleteObject.Key

        Write-Verbose "Processing $ServerName"

        #do processing here that eventually marks object complete
        if((Get-Date) -gt $startTime.AddSeconds(30))
        {
            Write-Verbose "Marking server $ServerName complete" 
            $ServerList[$ServerName] = "Complete"
        }
    }

    if((($ServerList.GetEnumerator() | ?{$_.value -eq "Complete"}).Count -ne $ServerList.count))
    {   
        #adjust here for how often you want loop to check
        Start-sleep -Seconds 10
    }
}
while( (($ServerList.GetEnumerator() | ?{$_.value -eq "Complete"}).Count -ne $ServerList.count) -and (($startTime).AddMinutes($timeoutInMinutes) -gt (Get-Date)))

Write-Host "$(($ServerList.GetEnumerator() | ?{$_.value -eq "Complete"}).Count) servers complete out of $($ServerList.count) total servers"
    