Function Get-RemoteSSLCertificateDetails
{
    param($url)

    Write-Log "Attempting connection to $url"
    $request = $null
    $request = [Net.HttpWebRequest]::Create($url)
    $request.Timeout = 1200

    try 
    {
        $request.GetResponse() | Out-Null
    }
    catch
    {
        Write-Log "Error connecting to URL $url`: $_"
    }
    $cert = $null
    $cert = $request.ServicePoint.Certificate

    if($cert)
    {
        $hash = @{
            result = "Success"
            ExpirationDate = [datetime]$cert.GetExpirationDateString()
            ExpiresIn = $(([DateTime]$cert.GetExpirationDateString() - $(Get-Date)).Days)
            Name = $cert.GetName()
            PublicKeyString = $cert.GetPublicKeyString()
            SerialNumber = $cert.GetSerialNumberString()
            Thumbprint = $cert.GetCertHashString()
            EffectiveDate = $cert.GetEffectiveDateString()
            Issuer = $cert.GetIssuerName()
        }

        #create a new powershell object out of the data so that we get all of the PS Object goodness
        $Certificate = New-Object PSObject -Property $hash

        return $Certificate
    }
    else
    {
        $return =  New-Object PSObject
        Add-Member -InputObject $return -MemberType NoteProperty -Name result -Value "fail"
        return $return
    }
}
