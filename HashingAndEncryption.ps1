Function Get-MD5fromString
{
    # Powershell v2
    [System.BitConverter]::ToString((new-object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider).ComputeHash([System.Text.Encoding]::UTF8.GetBytes($args)))
    
    #Powershell v4
    #Get-FileHash -Algorithm MD5 .\file.txt
}

(Get-MD5fromString "hello").replace("-","").tolower()

try
{
    $secureString = 'This is my password.  There are many like it, but this one is mine.' | 
                    ConvertTo-SecureString -AsPlainText -Force

    # Generate our new 32-byte AES key.  I don't recommend using Get-Random for this; the System.Security.Cryptography namespace
    # offers a much more secure random number generator.

    $key = New-Object byte[](32)
    $rng = [System.Security.Cryptography.RNGCryptoServiceProvider]::Create()

    $rng.GetBytes($key)

    $encryptedString = ConvertFrom-SecureString -SecureString $secureString -Key $key

    # This is the thumbprint of a certificate on my test system where I have the private key installed.

    $thumbprint = ''
    $cert = Get-Item -Path Cert:\CurrentUser\My\$thumbprint -ErrorAction Stop

    $encryptedKey = $cert.PublicKey.Key.Encrypt($key, $true)

    $object = New-Object psobject -Property @{
        Key = $encryptedKey
        Payload = $encryptedString
    }

    $object | Export-Clixml .\encryptionTest.xml

}
finally
{
    if ($null -ne $key) { [array]::Clear($key, 0, $key.Length) }
}


######################################## RETRIEVE ##########################################

try
{
    $object = Import-Clixml -Path .\encryptionTest.xml

    $thumbprint = ''
    $cert = Get-Item -Path Cert:\CurrentUser\My\$thumbprint -ErrorAction Stop

    $key = $cert.PrivateKey.Decrypt($object.Key, $true)

    $secureString = $object.Payload | ConvertTo-SecureString -Key $key
}
finally
{
    if ($null -ne $key) { [array]::Clear($key, 0, $key.Length) }
}