<# 
.SYNOPSIS
	
.DESCRIPTION
    This script will produce a CSV file containing the entire organization within a reporting chain under a top level person. 
    The CSV contains Active Directory user attributes for each person who report up to a specified top level person, pulling the data from Active Directory 

.TESTING 
        
.NOTES
    Author     : KyleGW
    Version    : 3.1
.MODIFICATIONS

         
.EXAMPLE
#>


$scriptShortName = "Org AD Users"

$filePath = $env:PUBLIC
$filename  = "$((Get-Date).ToString("yyyy-MM-dd HHmmss")) - $env:COMPUTERNAME - $scriptShortName.csv"
$outputFile = New-Item -type file (Join-Path $filePath $filename)

$global:firsttime = $true
$global:numpeopleinorg = 0

$toplevelPerson = ""

# used for debugging with F8
# $searchstring = $toplevelPerson

Function Get-DirectReports
{
    param ($searchstring)

    try{$adrecord = (([adsisearcher]"$searchstring").FindOne())}catch{}

    if ($adrecord -eq $null)
    {
        $adrecord = ([adsisearcher]"displayname=$searchstring").FindOne()
    }
    if($adrecord -eq $null)
    {
        $adrecord = ([adsisearcher]"name=$searchstring").FindOne()
    }
    if($adrecord -eq $null)
    {
        $adrecord = ([adsisearcher]"email=$searchstring").FindOne()
    }

    if($adrecord -ne $null)
    {
      $hasreports = $false
      $numtotalreports = 0
      $numdirectreports = 0
      if ($adrecord.properties.directreports -ne $null){$hasreports = $true}

      if($hasreports)
      {
         $numdirectreports =  $adrecord.properties.directreports.count
         $adrecord.properties.directreports | % {
              $adsearchname = $_
              $searchstring = ([regex]::Split($adsearchname,'([^,]*,[^,]*)')[1]).replace("\","")
              Write-Host "Input [$($_)] : Seachring for [$searchstring]"
              Get-DirectReports $searchstring
         }
      }
  

         #put desired data into a hashtable
         $hash = [ordered]@{
             EmployeeType     = [string]$adrecord.properties.employeetype
             Title            = [string]$adrecord.properties. title
             Name             = [string]$adrecord.properties.cn
             department       = [string]$adrecord.properties.department
             hasDirectReports = $($hasreports)
             directreports    = $numdirectreports
             Manager          = $($adrecord.properties.manager) #need to add regex
             createdate       = [string]$adrecord.properties.whencreated
             account          = [string]$adrecord.properties.samaccountname
             email            = [string]$adrecord.properties.mail
             emailForOutlook  = "$($adrecord.properties.mail);"

        } #end hash

        #create a new powershell object out of the data so that we get all of the PS Object goodness
        $Object = New-Object PSObject -Property $hash

        #here we ouput on the fly instead of building an in-memory collection (large dataset processing)
                                        
        #if first line, output header data
        if($firsttime -ne $false){$Object | ConvertTo-CSV -OutVariable OutData -notype; $OutData[0..0] | ForEach-Object {Add-Content -Value $_ -Path $outputFile};$firsttime = $false }
                                        
        #convert our object to CSV then output it to the output file without the header line
        $Object | ConvertTo-CSV -OutVariable OutData -notype 
        $OutData[1..($OutData.count - 1)] | ForEach-Object {Add-Content -Value $_ -Path $outputFile}
        $global:numpeopleinorg++
    }
}

Get-DirectReports $toplevelPerson
Invoke-Item "$outputFile"
Write-Host "There are $global:numpeopleinorg people in the organization reporting up to $toplevelPerson"
