<# 
.SYNOPSIS
	This script include was created as part of a TLS Certificate automation effort. The functions
    herein are used for CRUD operations against Service Now tables

    
    Currently:
      <Table Name>       u_servicenow_underlyingtablename.do?WSDL
      Manufacturers      core_company.do?WSDL
      People             sys_user.do?WSDL
      
.DESCRIPTION
    

.PARAMETER 

.NOTES
    Author     : KyleGW
    Version    : 2.0 

    Resources:
        Service Now Web Services:
            https://wiki.servicenow.com/index.php?title=Direct_Web_Service_API_Functions (deprecated)
            https://docs.servicenow.com/bundle/rome-application-development/page/integrate/web-services-apis/reference/r_DirectWebServiceAPIFunctions.html

.MODIFICATIONS

.EXAMPLE

#>

# The following two lines control which environment is being used. Be careful to always
# have the proper environment as the uncommented URL which the script will use

$serviceNowURL = "https://dev.service-now.com/"
#$serviceNowURL = "https://prod.service-now.com/"

# Service Now Credentials to use #
# create code to pull credentials from CyberArk or other credential management system, do not hardcode any production credentials

if($serviceNowURL.Contains("dev"))
{
    $SNenvironment = "DEV"
    $serviceAccountName = "s_"
    $serviceAccountPW_plaintext = ""
    $serviceAccountPW_plaintext = ""
}
else
{
    $SNenvironment = "PROD"
    $serviceAccountName = "s_"
    $serviceAccountPW_plaintext = ""
}

Function nothing
{
    $serviceAccountName = "s_"
    $serviceAccountPW_plaintext = ""
}

if($serviceAccountName)
{
  $password = ConvertTo-SecureString $serviceAccountPW_plaintext -AsPlainText -Force
  $credentials = New-Object System.Management.Automation.PSCredential $serviceAccountName, $password
}

if(!$credentials){$credentials = Get-Credential}

Function Get-ServiceNowTableHandle
{
   param($tableName)

   if(!$credentials){$credentials = Get-Credential}
   $URI = "$serviceNowURL$tableName.do?WSDL"
   $SNWSProxy = New-WebServiceProxy -uri $URI -Credential $credentials
   return $SNWSProxy
}


Function Get-ServiceNowRecordByKey
{

     param($RecordKey,$tableName)
 
     if(!$credentials){$credentials = Get-Credential}
     $TLSWSProxy = Get-ServiceNowTableHandle -tableName $tableName
     $type = $TLSWSProxy.getType().Namespace
     $datatype = $type + '.getRecords'
     $property = New-Object $datatype
     $property.sys_id = $RecordKey
     $TLSWSProxy.getRecords($property)
}

# Example: Get record for 
# Get-ServiceNowRecordByKey -RecordKey 00127b7a4546g46773m67b3248 -tableName "u_exampletable"

# Example: Get SSL record
# Get-SN_SSLRecordByKey -RecordKey 00127b7a4546g46773m67b3248


Function Test-ServiceNowConnectionTestingCopy
{
    $TLSWSProxy = Get-ServiceNowTableHandle -tableName "u_x_list"
    $type = $TLSWSProxy.getType().Namespace
    $datatype = $type + '.getRecords'
    $property = New-Object $datatype
    $property.u_active = $true
    $TLSCerts = $TLSWSProxy.getRecords($property)
    Write-Host "Below should print 5 certificate records if SN access is working:" -ForegroundColor Yellow
    $TLSCerts | Sort-Object u_d_certificate_valid_until | select -Last 5 | ft u_type,u_d_certificate_valid_until,name
} 

Function Update-SNRecord
{
    param($tableName, $recordSysID, $SNproperty, $newvalue)

    $existingRecord = Get-ServiceNowRecordByKey -RecordKey $recordSysID -tableName $tableName
    $SNTableProxy = Get-ServiceNowTableHandle -tableName $tableName
    $type = $SNTableProxy.getType().Namespace
    $datatype = $type + '.update'
    $properties = New-Object $datatype
    $properties.sys_id =  $recordSysID
    $properties.u_maint_notes = $existingRecord.u_maint_notes
 
    if($SNproperty -eq "u_contact_name")
    {
        $properties.u_contact_name = $newvalue
        if($existingRecord.u_contact_name){$oldname = (Get-SNPerson -ID $existingRecord.u_contact_name).name}
        $text = "Updating SN record [$($existingRecord.name)] with new Contact Name of  [ $((Get-SNPerson -ID $newvalue).name) ]. Old value: [$oldname]"
        $properties.u_maint_notes =  $properties.u_maint_notes += "`n$(Get-Date) - Automation - $text]"
    }
}



Function Get-SN_DomainRecord
{
  # This function first gets all records so that it can find the sysid for the one we want, in order to
  # retrieve the full record
  param( [Parameter(Mandatory=$true,ValueFromPipeline=$true)] $domainName)
 
  if(!$credentials){$credentials = Get-Credential}
  $URI = $serviceNowURL + "u_tablename_list.do?WSDL"
  $DNWSProxy = New-WebServiceProxy -uri $URI -Credential $credentials
  $type = $DNWSProxy.getType().Namespace
  $datatype = $type + '.getKeys'
  $property = New-Object $datatype
  $property.name = $domainName
  $DomainNameKey = $DNWSProxy.getKeys($property)
 
  if($DomainNameKey.count -eq 1)
  {
      $type = $DNWSProxy.getType().Namespace
      $datatype = $type + '.get'
      $property = New-Object $datatype
      $property.sys_id = $($DomainNameKey.sys_id).split(",")[0]
      $DNWSProxy.get($property)
  }
  elseif($DomainNameKey.count -eq 0)
  {
     return "Error: Domain not found in service Now"
  }
  else
  {
     return "Error: More than one domain record found in Service Now for [ $domainName ]"
  }
}

Function Delete-SN_Record
{
 param($domainName)

 if(!$credentials){$credentials = Get-Credential}
 $URI = $serviceNowURL + "u_tablename_list.do?WSDL"
 $DNWSProxy = New-WebServiceProxy -uri $URI -Credential $credentials
 $type = $DNWSProxy.getType().Namespace
 $datatype = $type + '.deleteRecord'
 $properties = New-Object $datatype
 $properties.name = $domainName
 $serviceNowReturnCode = $DNWSProxy.delete($properties)

 # Typically you would want to write this to a logging service or file, not the host
 Write-Host "Deleted $domainName from service now records with sys_id of $($serviceNowReturnCode.sys_id) "
}

Function Create-SN_Record
{
 param($domainName)

 if(!$credentials){$credentials = Get-Credential}
 $URI = $serviceNowURL + "u_tablename_list.do?WSDL"
 $DNWSProxy = New-WebServiceProxy -uri $URI -Credential $credentials
 $type = $DNWSProxy.getType().Namespace
 $datatype = $type + '.insert'
 $properties = New-Object $datatype
 $properties.name = $domainName
 $serviceNowReturnCode = $DNWSProxy.insert($properties)

 # Typically you would want to write this to a logging service or file, not the host
 Write-Host "Added $domainName to service now records with sys_id of $($serviceNowReturnCode.sys_id) "
}

Function Upload-CertificateToServiceNow
{
    param($fileNameAndPath, $sysIDToAttachTo)
    Upload-AttachmentToServiceNow -tableToAttach u_tablename -filename $filenameAndPath -SysIDofRecordToAttachTo $sysIDToAttachTo
}

Function Upload-AttachmentToServiceNow
{
    param($tableToAttach, $filename, $SysIDofRecordToAttachTo)

    $attachmentTableProxy = Get-ServiceNowTableHandle -tableName ecc_queue
    
    ##### REMOVE LATER ONCE SN IS FIXED ###################
    $attachmentTableProxy.Url = "https://dev.service-now.com/ecc_queue.do?SOAP"
    ##### REMOVE LATER ONCE SN IS FIXED ###################

    $type = $attachmentTableProxy.getType().Namespace
    $datatype = $type + '.insert'
    $property = New-Object $datatype
    $property.agent = "AttachmentCreator"
    $property.topic = "AttachmentCreator"
    $property.Name = "$($filename.Split("\") | select -Last 1):application/pkix-cert"
    $property.Source = "$($tableToAttach):$SysIDofRecordToAttachTo"

    
    $fileContent = Get-Content -Path $filename -Encoding Byte
    $Base64string = [System.Convert]::ToBase64String($fileContent)
    $property.payload = $Base64string 

    $attachmentTableProxy.insert($property)
    
}

#Upload-CertificateToServiceNow -fileNameAndPath H:\certificatename.cer -sysIDToAttachTo "023b74481f44bf08c86df9bcd84a6ea84"

