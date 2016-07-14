$serviceName = "SPTimerV4"
$serviceName2 = "SPAdminV4"

$servers = get-spserver | Where {$_.Role.TOString().ToLower() -eq "application"}

for ($i=0; $i -lt 1000; $i++)
{
    Write-Host Minute $i
    Write-Host ------------------
    Write-Host 
    foreach ($server in $servers)
    {
       $computerName = $server.Name
       $svcname = $serviceName
       $service = Get-Service -Name $serviceName -computername $server.Name #= "servername"

       Write-Host $server.Name $service.Name $service.Status
       
       If ($service.Status -ne "Running")
       {
          #Start-service
            $psr = New-PSSession $computerName
            
            write-host ("Starting {0} service on server {1}..." -f $svcName,$computerName) -NoNewline
            
            $job = Invoke-Command -Session $psr {param($svcName,$computerName) Start-Service -Name $svcName} -ArgumentList $svcName -AsJob -JobName ("job-" + $computerName + "-start-service-" + $svcName)
            
            $jobresult = $job | Wait-Job

            write-host $jobresult.State

            Remove-PSSession -ComputerName $computerName

          
            Write-host "Service has been Started"
       }
       
       $service2 = Get-Service -Name $serviceName2 -computername $server.Name
       Write-Host $server.Name $service2.Name $service2.Status
       
       If ($service2.Status -ne "Running")
       {
          #Start-service
            $svcname = $serviceName2
            $psr = New-PSSession $computerName
            
            write-host ("Starting {0} service on server {1}..." -f $svcName,$computerName) -NoNewline
            
            $job = Invoke-Command -Session $psr {param($svcName,$computerName) Start-Service -Name $svcName} -ArgumentList $svcName -AsJob -JobName ("job-" + $computerName + "-start-service-" + $svcName)
            
            $jobresult = $job | Wait-Job

            write-host $jobresult.State

            Remove-PSSession -ComputerName $computerName

          
            Write-host "Service has been Started"
       }
    }
    
    Start-Sleep -s 30
}
