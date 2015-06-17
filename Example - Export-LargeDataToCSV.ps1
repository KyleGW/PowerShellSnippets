<# 
.SYNOPSIS
	
.DESCRIPTION
    This script will 
	It is used by _ in the process of/for _
.TESTING 
        
.NOTES
    Author     : KyleGW
    Version    : 0.1
.MODIFICATIONS
	2015-00-00  KyleGW	Created script
         
.EXAMPLE

#>

$filename = "$((get-date).ToString('yyyy MM dd hhmmtt')) $env:COMPUTERNAME - STUFF Export.CSV"
$outfile = New-Item -type file $filename
$firsttime = $true

#loop whatever
foreach($item in gci)
{
    #put data we want into a hashtable
    $hash = @{
            Item_Type = $(if($item.PSisContainer){"Folder"}else{"File"})
            Item_Name = $item.Name
            Item_FullName = $item.FullName
            Item_LastWrite = $item.LastWriteTime

       }#end hash
                                        
        #create a new powershell object out of the data so that we get all of the PS Object goodness
        $Object = New-Object PSObject -Property $hash

        #here we ouput on the fly instead of building an in-memory collection (large dataset processing)
                                        
        #if first line, output header data
        if($firsttime -ne $false){$Object | ConvertTo-CSV -OutVariable OutData -notype; $OutData[0..0] | ForEach-Object {Add-Content -Value $_ -Path $outfile};$firsttime = $false }
                                        
        #convert our object to CSV then output it to the output file without the header line
        $Object | ConvertTo-CSV -OutVariable OutData -notype 
        $OutData[1..($OutData.count - 1)] | ForEach-Object {Add-Content -Value $_ -Path $outfile}    

}#end item loop
  
Invoke-Item "$filename"
