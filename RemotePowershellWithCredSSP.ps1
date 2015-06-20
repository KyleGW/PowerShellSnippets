# http://blogs.msdn.com/b/varun_malhotra/archive/2010/06/10/configure-power-shell-for-remote-use-of-sp-2010.aspx
# http://blogs.msdn.com/b/powershell/archive/2008/06/05/credssp-for-second-hop-remoting-part-i-domain-account.aspx
# https://palmarg.wordpress.com/2013/11/26/powershell-remoting-using-ssl-and-credssp/


# On Server to be accessed remotely
Set-WSManQuickConfig -UseSSL
Add-SSLCredential $env:COMPUTERNAME
Enable-WSManCredSSP -Role Server

function Add-SSLCredential($CN)
{
    #First thing is to locate the certificate by CN. Make sure we get the most recent one.
    try
    {
        $certificate = Get-ChildItem CERT:\LocalMachine\My | Where-Object {$_.Subject -match $CN} | sort $_.NotAfter -Descending | select -first 1 -erroraction STOP
        $thumbprint = $certificate.Thumbprint
        $UKCN = $certificate.PrivateKey.CspKeyContainerInfo.UniqueKeyContainerName
    }
    catch
    {
        Write-Output "Error: cannot find the certificate"
    }
 
    #Then we check if the HTTPS listener exists, it probably does if you're following this post
    #That's okay though, we delete it and set up a new listener with our Certificate.
    $checkconfig = winrm e winrm/config/listener
    if($checkconfig -contains "    Transport = HTTPS")
    {
        Write-Host -ForegroundColor Yellow "1. Delete old config"
        winrm delete winrm/config/Listener?Address=*+Transport=HTTPS
    }
 
    Write-Host -ForegroundColor Yellow "2. Add a certificate to the listener"
    winrm create winrm/config/listener?Address=*+Transport=HTTPS `@`{Hostname=`"$CN`"`; CertificateThumbprint=`"$thumbprint`"`}
 
    #Then we add the same certificate to the winrm service
    Write-Host -ForegroundColor Yellow "3. Add certificate to the winrm service"
    winrm set winrm/config/service `@`{CertificateThumbprint=`"$thumbprint`"`}
 
    #And finally, we make sure the NETWORK SERVICE account has access to the private key of the certificate
    Write-Host -ForegroundColor Yellow "4. Allow the Network Service access to the certificate"
 
    $machinekyepath = "$env:SystemDrive\ProgramData\Microsoft\Crypto\RSA\MachineKeys\"
    $pathtoactualkey = $machinekyepath+$UKCN
     
    $acl = Get-Acl -Path $pathtoactualkey
    $permission="NETWORK SERVICE","Read","Allow"
    $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule $permission
    $acl.AddAccessRule($accessRule)
    Try
    {
        Set-Acl $pathtoactualkey $acl
    }
    Catch
    {
        Write-Output "Error: unable to set ACL on certificate"
    }
}


# run on client which you want to delegate credentials from - to the server you enabled above
Enable-WSManCredSSP -Role Client -DelegateComputer SERVERNAMEWEWANTTOACCESS

#test the connection
if(!$credential){$credential = Get-Credential}
Enter-PSSession server.domain.local -UseSSL -Cred $credential -authentication CredSSP