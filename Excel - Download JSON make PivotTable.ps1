<# 
.SYNOPSIS
	
.DESCRIPTION
    This script will 
        - download JSON from the internet
        - transform the JSON and pull out the relevant data
        - export the data to a CSV
        - open that CSV in Excel
        - create a pivot table from the data

	I created it as a common reporting and automation example
.TESTING 
        
.NOTES
    Author     : KyleGW
    Version    : 0.1
.MODIFICATIONS
	2018-08-21  KyleGW	Created script
         
.EXAMPLE

#>

# uses NRG data available publibly as example data

#define the url of the data source
$url = "https://www.nrg.com/generation/asset-map.nrgcontent.default.json"

#pull the data down from the url and store the raw json
$data = [System.Net.WebClient]::new().DownloadString($url) 

#convert the data from JSON to a ps object
$converteddata = $data | ConvertFrom-Json 

#pull just the item data out of the psobject (this could all be combined into one line but i am doing it step by step to show the process)
$itemdata = $converteddata | select -ExpandProperty contentPayload | select -ExpandProperty children | select -ExpandProperty payload | select -ExpandProperty primary | select -ExpandProperty payload | select items

# Select the attributes from the items array that we want to report on, and export it to a CSV file
# the where clause specifies all items where the name is not empty. one empty itwm was causing "blanks" to show up in the pivot table. filtering it here prevents that from happening
$itemdata.items | ?{$_.name -ne "" } | select name, location, assetType, region, state, status, fueltype, percentOwnership, outputValue | export-csv nrgdata.csv -NoTypeInformation


#find the most recently written CSV file in the current directory (which will be the data just exported to CSV in the line above)
$datafile = (gci *.csv | sort lastwritetime -desc)[0]
$rowFields = "region","state"
$columnFields = "assetType"
$values = "outputValue"

$xlDatabase            = 1
$xlPivotTableVersion12 = 3

$xlHidden              = 0
$xlRowField            = 1
$xlColumnField         = 2
$xlPageField           = 3
$xlDataField           = 4

$XL = New-Object -comobject Excel.Application

$XL.DisplayAlerts = $true
$XL.ScreenUpdating = $true
$XL.Visible = -not $autoCloseXl

#use below commented out line to to create new wb
#$Workbook = $XL.Workbooks.Add()
$Workbook = $XL.Workbooks.open($(Join-Path $pwd $datafile.Name))

Write-Warning "Microsoft Office may be popping a ""New Profile"" dialog box associated with MS Outlook here, cancel it to continue script execution"
$Workbook.WorkSheets.Add()
$Sheet1 = $Workbook.Worksheets.Item("Sheet1")
$Sheet2 = $Workbook.Worksheets.Item(2)

$rowCount = $Sheet2.UsedRange.Rows.Count
$columnCount = $Sheet2.UsedRange.Columns.Count

Write-Debug "Sheet2!R1C1:R$($rowCount)C$($columnCount)"
$Sheet1.Activate()

#Create the pivot table
$PivotTable = $Workbook.PivotCaches().Create($xlDatabase,$sheet2.Name+"!R1C1:R$($rowCount)C$($columnCount)",$xlPivotTableVersion12)
$PivotTable.CreatePivotTable("Sheet1!R1C1") | out-null

if($columnFields) {
	$PivotFields = $Sheet1.PivotTables("PivotTable1").PivotFields($columnFields)
	$PivotFields.Orientation=$xlColumnField
}

if($rowFields) 
{ 
    $rowfields | %{ 
		$PivotFields = $Sheet1.PivotTables("PivotTable1").PivotFields($_)
		$PivotFields.Orientation=$xlRowField
    }
}

if($values) {
	$PivotFields = $Sheet1.pivotTables("PivotTable1").PivotFields($values)
	$PivotFields.Orientation=$xlDataField
} 

$XL.ScreenUpdating = $true