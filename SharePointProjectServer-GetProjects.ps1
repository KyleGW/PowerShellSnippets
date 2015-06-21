 if(!$SPcredentials){$SPcredentials = Get-Credential}
 $URI = "http://projectserverURL/pwa/_vti_bin/PSI/Project.asmx?wsdl"
 $PWAProxy = New-WebServiceProxy -uri $URI -Credential $SPcredentials
 $projects = $PWAProxy.ReadProjectList()
 $projects.Project | ft PROJ_Name