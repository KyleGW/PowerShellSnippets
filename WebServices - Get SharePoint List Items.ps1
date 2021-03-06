#$url = "http://<spurl>.com/sitecollection/subsite/Lists/listname/"

$date = ( get-date ).ToString('yyyy MM dd hhmmtt')
# This script was written to illustrate how to get list items from sharepoint
#
#
# Author: Kyle 
# Date:   2014 08 20 
#
# Main MSDN article for web services [ http://msdn.microsoft.com/en-us/library/ee538665.aspx ]
#
# ------ [ Configuration Section ] ----------------------------------------
# List web service WSDL = https://site/_vti_bin/Lists.asmx?WSDL
$siteURL = "https://"
$listWebServiceURL = "$siteURL/_vti_bin/Lists.asmx" 
$listName = "Listname"
$filename = "$date $listname Export.CSV"
#---------------------------------------------------------------------------

#give me the string between the "//" and the next "/" after the "//"
$DomainName = $siteURL.Substring($siteURL.IndexOf("//")+2,$siteURL.IndexOf("/",$siteURL.IndexOf("//")+2)-($siteURL.IndexOf("//")+2))

# Setup web service connection - this section gets credentials from you and uses them to instantiate the powershell web service proxy
$ListWS = $null
if(!$cred){$cred = Get-Credential}
$ListWS = New-WebServiceProxy $listWebServiceURL -cred $cred
$ListWS.Url = $listWebServiceURL

# This code illustrates getting a list of lists on the site
#$listsXML = $null
#$listcoll = $null
#$listcoll = $ListWS.GetListCollection()
#$listsXML = [xml]$listcoll.OuterXml
#$listsXML.Lists.List | ft Title, DefaultViewUrl, ItemCount, ID


#Get all the views for a list

$viewsWS = New-WebServiceProxy $listWebServiceURL.Replace("Lists.asmx","Views.asmx") -cred $cred
$viewsWS.Url = $listWebServiceURL.Replace("Lists.asmx","Views.asmx")
$viewColl = $viewsWS.GetViewCollection($listName) 
$viewCollXML = [xml]$viewColl.OuterXml
$viewCollXML.Views.View | ft DisplayName

# This line gets one particular list and view [ http://msdn.microsoft.com/en-us/library/websvclists.lists.getlistandview.aspx ]
#$listInfo = $ListWS.GetListAndView($listName, "")
$listInfo = $ListWS.GetListAndView($listName, "E0000000-0000-4F00-8000-0000000000000")


#$list = $ListWS.GetList($listName)

# These lines illustrate ways of showing the data that the above line returned
#$listInfo.List.Name
#$listInfo.View.Name
#$listInfo.View.Query.OrderBy.FieldRef
#$listInfo.View.ViewFields.FieldRef

#
# Get the items in that list [ http://msdn.microsoft.com/en-us/library/websvclists.lists.getlistitems.aspx ] 
#
<# - This is taken from the documentation and put here for quick reference on the order of parameters
GetListItems(
                string listName,
                string viewName,
                XmlNode query,
                XmlNode viewFields,
                string rowLimit,
                XmlNode queryOptions,
                string webID)
#>

<# Here I am defining the XML which will override the fields set in the default view (if the default "all items" view doesn't contain all of the fields) 
 [xml]$viewfields = "<ViewFields>
                        <FieldRef Name='Id' />
                        <FieldRef Name='LinkTitle' />
                        <FieldRef Name='Title' />
                    </ViewFields>"
#>
                  
# Here I am defining some options to use for the items query, as per the GetListItems documentation
#[xml]$queryoptions = "<QueryOptions><IncludeMandatoryColumns>FALSE</IncludeMandatoryColumns><DateInUtc>TRUE</DateInUtc></QueryOptions>"

#Here I am creating a basic query to pass in
[xml]$query2 = "<Query><OrderBy><FieldRef Name='ID' /></OrderBy></Query>"
[xml]$query = @" 
<Query>
<Where>
      <Gt>
        <FieldRef Name='Modified' />
        <Value IncludeTimeValue='False' Type='DateTime'>2015-07-01T0:00:00Z</Value>
      </Gt>
</Where>
<OrderBy><FieldRef Name='ID' /></OrderBy></Query>
"@

[xml]$query3 = @" 
<Query>
<Where>
      <Eq>
        <FieldRef Name='ID' />
        <Value Type='Number'>11</Value>
      </Eq>
</Where>
<OrderBy><FieldRef Name='ID' /></OrderBy></Query>
"@


# http://msdn.microsoft.com/en-us/library/websvclists.lists.getlistitems(v=office.15).aspx
# Here I am actually querying the list and storing the returned data in the $items variable
#$items = $ListWS.GetListItems(ListName,viewName,query,$viewfields,rowLimit,$queryoptions,webID)
#$items = $ListWS.GetListItems($listInfo.List.Name,"",$null,$viewfields,$null,$queryoptions,$null)
#$items = $ListWS.GetListItems($listInfo.List.Name,"",$query,$null,$null,$queryoptions,$null)
$items = $ListWS.GetListItems($listInfo.List.Name,"",$query2,$null,"2000",$queryoptions,$null)

##########################################################################################################################################
#
# The following commented out snippets illustrate different ways of manipulating the result set of $items returned from GetListItems.
#  Simply un-comment and run them or highlight the line sans comment hash and run with F8
#
##########################################################################################################################################

#Write-Host Number of Items in list: $items.data.ItemCount

#Write-Host First Item: (this will show all fields in the item)
#$items.Data.Row[0]

#show me a grid of all items and fields I define that I want to see in the list
#$items.Data.Row | ft ows_Created, ows_Title

$DebugPreference = "Continue"
$VerbosePreference = "SilentlyContinue"

#open output file
$outfile = New-Item -type file $filename

$firsttime = $true 
$items.data.row | %{

    #reset flag each row
    $foundAuthorFlag = $false 
    $version = $null
    $editor = $null

    $parentItem = $_
    
    #get every version of current list item
    $listItemVersionCollection = $listWS.GetVersionCollection($listInfo.List.Name,$parentItem.ows_ID ,"ows_AssignedTo")
    
    Write-Debug "Checking $($parentItem.ows_owshiddenversion) versions of item $($parentItem.ows_ID) - $($parentItem.ows_Title) "
    #loop through the item versions and flag it if we find it has been modified by a person we are looking for
    $listItemVersionCollection.Version | %{
    
        foreach($person in $peopleToAudit)
        {
            Write-Verbose "Comparing [$($_.Editor)] to [$person]" 
            if($_.Editor.contains($person))
            {   
                Write-Debug "Found a Match"
                $foundAuthorFlag = $true
                #if(!$version){$version += "$($_.Version);"}
                if(!$editor -or !$editor.Contains($person)){$editor+= "$person;"}
            }
        }
        
     }#end item versions loop
        
     if($foundAuthorFlag)
     {  
        #put data we want into a hashtable
        $hash = @{       
               ID = $parentItem.ows_ID 
            Title = $parentItem.ows_LinkTitle
       CreateDate = $parentItem.ows_Created
       Modifier = $editor

       URL = "$($parentItem.ows_ID)"

       }#end hash
                                        
        #create a new powershell object out of the data so that we get all of the PS Object goodness
        $Object = New-Object PSObject -Property $hash
                                        
        #if first line, output header data
        if($firsttime -ne $false){$Object | ConvertTo-CSV -OutVariable OutData -notype; $OutData[0..0] | ForEach-Object {Add-Content -Value $_ -Path $outfile};$firsttime = $false }
                                        
        #convert our object to CSV then output it to the output file without the header line
        $Object | ConvertTo-CSV -OutVariable OutData -notype 
        $OutData[1..($OutData.count - 1)] | ForEach-Object {Add-Content -Value $_ -Path $outfile}    
    
    }#end if found author
}#end data row loop



Invoke-Item $filename

$versions = $listWS.GetVersionCollection($listInfo.List.Name,11,"ows_AssignedTo")
$versions.Version[0]