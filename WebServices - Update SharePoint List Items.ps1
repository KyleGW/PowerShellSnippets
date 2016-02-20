# Main MSDN article for web services [ http://msdn.microsoft.com/en-us/library/ee538665.aspx ]

#define our config variables

#WSDL = https://sharepoint/sites/test/KyleTest/_vti_bin/Lists.asmx?WSDL
$listWebServiceURL = "https://sharepoint/sites/test/KyleTest/_vti_bin/Lists.asmx" 
$listName = "ListName"


#setup web service connection
$cred = Get-Credential
$ListWS = New-WebServiceProxy $listWebServiceURL -cred $cred
$ListWS.Url = $listWebServiceURL

#get a list of lists on the site
$listcoll = $ListWS.GetListCollection()
$listsXML = [xml]$listcoll.OuterXml
$listsXML.Lists.List | ft Title, DefaultViewUrl, ID

#get one particular list [ http://msdn.microsoft.com/en-us/library/websvclists.lists.getlistandview.aspx ]
$listInfo = $ListWS.GetListAndView($listName, "")
#$listInfo.List.Name
#$listInfo.View.Name

#get the items in that list [ http://msdn.microsoft.com/en-us/library/websvclists.lists.getlistitems.aspx ] 
$items = $ListWS.GetListItems($listInfo.List.Name,$listInfo.View.Name,$null,$null,$null,$null,$null)

#look at data in variety of ways
Write-Host Number of Items in list: $items.data.ItemCount
Write-Host First Item:
$items.Data.Row[0] | ft ows_LinkTitle, ows_Title
#$items.Data.Row | %{ Write-Host Item ID: [ $_.ows_ID ] Title: [ $_.ows_Title ] }
#$items.data.row | where {([datetime]$_.ows_EventDate).get_dayofyear() -eq $myDay.get_dayofyear()}
#$items.data.row | where {$_.ows_Title -like "*thetitle*"}

#insert new item in list
$Operation= "New"
# check if valid operation (and fix casing)
$Operation = [string]("Update","Delete","New" -like $Operation)
if (-not $Operation)
{
    Write-Warning "`$Operation should be Update, Delete or New."  
    return
} 


#prepare caml query update [ http://msdn.microsoft.com/en-us/library/websvclists.lists.updatelistitems.aspx ]

#Example Update fields
$item = @{
		  Title = "2016 01 19 added via PS/WS"
		}
        
$xml = @" 
<Batch OnError='Continue' ListVersion='1' ViewName='{0}'>
    <Method ID='1' Cmd='{1}'>{2}</Method>
</Batch>
"@

$listItem = ""
foreach ($key in $item.Keys) 
{   
   $listItem += ("<Field Name='{0}'>{1}</Field>" -f $key,$item[$key])
}   

$batch = [xml]($xml -f $listInfo.View.Name,$operation,$listItem)

#send the update to the web service
$response = $ListWS.UpdateListItems($listInfo.List.Name, $batch)

#read the response
$code = [int]$response.result.errorcode 
if ($code -ne 0) 
{  Write-Warning "Error $code - $($response.result.errormessage)" } 
else 
{  Write-Host "List Updated Successfully"
   $response.Result
}  

