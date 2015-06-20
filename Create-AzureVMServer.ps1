<# 
.SYNOPSIS
	Creates a new virtual machine farm on the Azure platform

.DESCRIPTION
    

.PARAMETER 

.NOTES
    Author     : KyleGW
    Version    : 1.0 

    Main Resources:
        How to install and configure Azure PowerShell
            http://azure.microsoft.com/en-us/documentation/articles/install-configure-powershell/
        Create a New Azure VM with PowerShell:
            http://sqlmag.com/powershell/create-new-azure-vm-powershell
        Uploading and Downloading VHDs to Windows Azure
            http://michaelwasham.com/windows-azure-powershell-reference-guide/uploading-and-downloading-vhds-to-windows-azure/
        Multiple Azure VMs
            https://gallery.technet.microsoft.com/scriptcenter/Create-Multiple-Windows-df9e95b7#content
        Configures Secure Remote PowerShell Access to Windows Azure Virtual Machines
            https://gallery.technet.microsoft.com/scriptcenter/Configures-Secure-Remote-b137f2fe
        Copy a File to an Azure VM
            https://gallery.technet.microsoft.com/scriptcenter/Copy-a-File-to-an-Azure-VM-d2ad9e1f
        Connect to an Azure Virtual Machine
            https://gallery.technet.microsoft.com/scriptcenter/Connect-to-an-Azure-85f0782c
        
               
.MODIFICATIONS

.EXAMPLE
    

#>


Function Set-AzureConfiguration
{
    # Get-AzurePublishSettingsFile
    $publishSetttingsFile = "d:\filename.publishsettings"
    # Retrieve with Get-AzureSubscription 
    $subscriptionName = 'SubscriptionName'  
    # Retrieve with Get-AzureStorageAccount | ft StorageAccountName 
    $storageAccountName = 'storageAccountName'

    $storageContainer = 'storageContainerName'
    # Retrieve with Get-AzureLocation 
    $location = 'East US' 
    # ExtraSmall, Small, Medium, Large, ExtraLarge
    $instanceSize = 'Small' 
    # Has to be a unique name. Verify with Test-AzureServiceditr
    $serviceName = '' 
    # Server Name
    $vmname = 'NewServer01'
    $vmDiskName = 'NewServer01_OS'
    $vmSize = 'Small'
    # Source VHDs
    $sourceosvhd = 'C:MyVHDsAppServer1OSDisk.vhd'
    $sourcedatavhd = 'C:MyVHDsAppServer1DataDisk.vhd'

    $VHDtoUse = 'https://gitlabvhd.blob.core.windows.net/communityimages/community-4-7a9c9936-dc4f-47cf-9004-6b723d42d383-1.vhd'
}
# Check for Azure Powershell and if not installed, get it
if(!(Get-Module Azure))
{
    try
    {
        Import-Module Azure -ErrorAction Stop
    }
    catch
    {
        # Helper debugging command to find available applications
        # & 'c:\Program Files\Microsoft\Web Platform Installer\WebpiCmd.exe' /List /ListOption:Available
    
        # Use Web PI to install Azure powershell commandlets
        Start-Process -FilePath "c:\Program Files\Microsoft\Web Platform Installer\WebpiCmd.exe" -ArgumentList "/Install /Products:WindowsAzurePowershell /AcceptEula /SuppressPostFinish" -Wait -PassThru -NoNewWindow
    
        #add Azure Powershell module locations to the PS modulepath so that it can find it
        $env:PSModulePath = $env:PSModulePath + ";C:\Program Files (x86)\Microsoft SDKs\Azure\PowerShell\ServiceManagement\"
        Import-Module Azure
    }
}

Function Setup-VM
{
    Import-AzurePublishSettingsFile $publishSetttingsFile

    # Specify the storage account location to store the newly created VHDs 
    Set-AzureSubscription -SubscriptionName $subscriptionName -CurrentStorageAccount $storageAccountName 
 
    # Select the correct subscription (allows multiple subscription support) 
    Select-AzureSubscription -SubscriptionName $subscriptionName 

    Add-AzureDisk -OS Linux -MediaLocation $VHDtoUse -DiskName  $vmDiskName
    Get-AzureDisk | ft DiskName, Label
    #Remove-AzureDisk $vmDiskName

    $migratedVM = New-AzureVMConfig -Name $vmname -DiskName $vmDiskName -InstanceSize $vmSize |
				  Add-AzureEndpoint -Name 'Remote Desktop' -LocalPort 1111 -Protocol tcp 
 
    New-AzureVM -ServiceName $serviceName -Location $location -VMs $migratedVM
}

Function Upload-VHD
{
    # Target Upload Location 
    $destosvhd = 'http://' + $storageAccountName + '.blob.core.windows.net/uploads/AppServer1OSDisk.vhd'
    $destdatavhd = 'http://' + $storageAccountName + '.blob.core.windows.net/uploads/AppServer1DataDisk.vhd'
 
    Add-AzureVhd -LocalFilePath $sourceosvhd -Destination $destosvhd 
    Add-AzureVhd -LocalFilePath $sourcedatavhd -Destination $destdatavhd
}




Function TestingSandBox
{

#Testing sandbox function for ISE
Get-AzureStorageContainer

Get-AzureVMImage | sort PublishedDate -Descending | ft PublishedDate, ImageName

$ImageName = (Get-AzureVMImage | Where { $_.ImageFamily -eq "Windows Server 2012 R2 Datacenter" } | sort PublishedDate -Descending | Select-Object -First 1).ImageName


 

Add-AzureDisk -MediaLocation $destdatavhd -DiskName 'AppServer1DataDisk'
 
$migratedVM = New-AzureVMConfig -Name $vmname -DiskName $vmDiskName -InstanceSize $vmSize |
					Add-AzureDataDisk -Import -DiskName 'AppServer1DataDisk' -LUN 0 |
					Add-AzureEndpoint -Name 'Remote Desktop' -LocalPort 3389 -Protocol tcp 
New-AzureVM -ServiceName $serviceName -Location $location -VMs $migratedVM

}