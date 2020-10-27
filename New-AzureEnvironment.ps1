<# 
.SYNOPSIS  
     An Azure Automation Runbook to create a New Azure Environment
 
.DESCRIPTION 
    This runbook uses the New-CloudService,New-StorageAccount and New-AvailabilityGroupVM
    runbooks to create the environment. These runbooks must be published prior to running 
    this workbook

    It will create a Cloud Service called ProjectName (the value of the Project Name Parameter)
    It will create 2 storage Accounts called SQLProjectNamestorage and AppProjectNamestorage
    It will create 2 Virtual Machines Large Size called SQLVM1 and SQLVM2 running SQL2014 and 
    Server 2012 R2 with 4 250GB data disks and 2 Virtual Machines called Client1 and Client2
     Large Size. All will have the Local Admin of the Admin User Credential
 
.PARAMETER Name
    The project name = The Cloud Service Name. 

.PARAMETER CredentialName 
    The name of the Azure Automation Credential Asset.
    This should be created using 
    http://azure.microsoft.com/blog/2014/08/27/azure-automation-authenticating-to-azure-using-azure-active-directory/  
 
.PARAMETER AzureSubscriptionName 
    The name of the Azure Subscription. 

.PARAMETER Location 
    The Location for the Storage Account 
    Current Options (January 2015)
        West Europe, North Europe, East US 2,Central US,South Central US,West US,North Central US                                                                                                                                                   
        East US,Southeast Asia,East Asia,Japan West,Japan East,Brazil South 	

.PARAMETER AdminUser
    The name of the Azure Automation Local Admin Credential Asset. 

.EXAMPLE 
    New-AzureEnvironment -ProjectName TheBeardProject -CredentialName MasterCred `
    -AzureSubscriptionName SubName -Location 'West Europe' -AdminUser AdminCred

    It will create a Cloud Service called ProjectName (the value of the Project Name Parameter)
    It will create 2 storage Accounts called SQLProjectNamestorage and AppProjectNamestorage
    It will create 2 Virtual Machines Large Size called SQLVM1 and SQLVM2 running SQL2014 and 
    Server 2012 R2 with 4 250GB data disks and 2 Virtual Machines called Client1 and Client2
     Large Size. All will have the Local Admin of the Admin User Credential
.OUTPUTS
    None
 
.NOTES 
    AUTHOR: Rob Sewell sqldbawithabeard.com 
    DATE: 04/01/2015 
#> 

workflow New-AzureEnvironment
{
    param (
        [Parameter(Mandatory=$true)]
        [string]$ProjectName,
        [Parameter(Mandatory=$true)]
        [string]$CredentialName,
        [Parameter(Mandatory=$true)]
        [string]$AzureSubscriptionName,
        [Parameter(Mandatory=$true)]
        [string]$Location,
        [Parameter(Mandatory=$true)]
        [string]$AdminUserCred
        )
    # Get the credential to use for Authentication to Azure and Azure Subscription Name
    $Cred = Get-AutomationPSCredential -Name $CredentialName
    
    # Connect to Azure and Select Azure Subscription
    $AzureAccount = Add-AzureAccount -Credential $Cred
    $AzureSubscription = Select-AzureSubscription -SubscriptionName $AzureSubscriptionName
    Write-Output "Connected to Azure Subscription - Calling New-CloudService"

    #Create Cloud Service
    New-CloudService -Name $ProjectName -CredentialName $CredentialName -AzureSubscriptionName $AzureSubscriptionName -location $Location
    Checkpoint-Workflow

    #Create SQL VMs and Storage Account
     InlineScript {
                    #Set Variables
                    $ProjectName = $Using:ProjectName
                    $CredentialName = $Using:CredentialName
                    $AzureSubscriptionName = $Using:AzureSubscriptionName
                    $Location = $Using:Location
                    $AdminUserCred = $Using:AdminUserCred
                    $AdminPassword = $Using:AdminPassword

                    $AutomationAccountName = (Get-AzureAutomationAccount).AutomationAccountName
                    $Name = 'SQL' + $ProjectName

                     #Create Storage Account
                     $StorageRunbookInputParams = @{Name = $Name; CredentialName = $CredentialName ; AzureSubscriptionName = $AzureSubscriptionName; Location = $Location}
                     $Storagejob = Start-AzureAutomationRunbook  -Name New-StorageAccount  -Parameters $StorageRunbookInputParams -AutomationAccountName $AutomationAccountName
                     $status = $Storagejob.status
                     $Storagejob
                     while($status -ne 'Completed')
                        {
                         Write-Output "Sleeping"
                         Start-Sleep -seconds 10
                         $Job = Get-AzureAutomationJob -Id $Storagejob.id -AutomationAccountName $AutomationAccountName
                         $status = $Job.Status
                        }  

                    $Storagejobout = Get-AzureAutomationJobOutput -Id $Storagejob.Id.guid -Stream Output -AutomationAccountName $AutomationAccountName 
                    $Storagejobver = Get-AzureAutomationJobOutput -Id $Storagejob.Id.guid -Stream Verbose -AutomationAccountName $AutomationAccountName 
                    $storageAccountName = $Storagejobout.Text 
                    Write-Output "The Storage Account Name is $storageAccountName"
                    $Storagejobout
                    $Storagejobver

                    #Create VMs
                    $VMRunbookInputParms = @{ CredentialName = $CredentialName; AzureSubscriptionName = $AzureSubscriptionName; VMName = 'SQLVM'; NoOfVms = 2; VMSize = 'Large'; ServiceName = $ProjectName; image = 'fb83b3509582419d99629ce476bcb5c8__SQL-Server-2014-RTM-12.0.2430.0-Std-ENU-Win2012R2-cy14su11'; AdminUserCred = $AdminUserCred; NoDataDisks = 4 ; DataDiskSize = 250; StorageAccountName = $StorageAccountName }
                    $VMRunBook = Start-AzureAutomationRunbook -Name New-AvailabilityGroupVM -Parameters $VMRunbookInputParms -AutomationAccountName $AutomationAccountName
                    $status = $VMRunBook.Status
                    while($status -ne 'Completed')
                        {
                         Write-Output "Sleeping"
                         Start-Sleep -seconds 10
                         $Job = Get-AzureAutomationJob -Id $VMRunBook.id -AutomationAccountName $AutomationAccountName
                         $status = $Job.Status
                        }  
                    $VMjobout = Get-AzureAutomationJobOutput -Id $VMRunBook.Id.guid -Stream Output -AutomationAccountName $AutomationAccountName 
                    $VMjobver = Get-AzureAutomationJobOutput -Id $VMRunBook.Id.guid -Stream Verbose -AutomationAccountName $AutomationAccountName 
                    $VMjobout
                    $VMjobver
                    }
    Checkpoint-Workflow
    Write-Output " SQL VMs created"
    #Create Client VMs and Storage Account
    InlineScript {
                #Set Variables
                $ProjectName = $Using:ProjectName
                $CredentialName = $Using:CredentialName
                $AzureSubscriptionName = $Using:AzureSubscriptionName
                $Location = $Using:Location
                $AdminUserCred = $Using:AdminUserCred
                
                 $AutomationAccountName = (Get-AzureAutomationAccount).AutomationAccountName
                 $Name = 'WinSer' + $ProjectName
                 $StorageRunbookInputParams = @{Name = $Name; CredentialName = $CredentialName ; AzureSubscriptionName = $AzureSubscriptionName; Location = $Location}
                 $Storagejob = Start-AzureAutomationRunbook  -Name New-StorageAccount  -Parameters $StorageRunbookInputParams -AutomationAccountName $AutomationAccountName
                 $status = $Storagejob.status
                while($status -ne 'Completed')
                    {
                     Write-Output "Sleeping"
                     Start-Sleep -seconds 10
                     $Job = Get-AzureAutomationJob -Id $Storagejob.id -AutomationAccountName $AutomationAccountName
                     $status = $Job.Status
                    }  
                $Storagejobout = Get-AzureAutomationJobOutput -Id $Storagejob.Id.guid -Stream Output -AutomationAccountName $AutomationAccountName 
                $Storagejobver = Get-AzureAutomationJobOutput -Id $Storagejob.Id.guid -Stream Verbose -AutomationAccountName $AutomationAccountName 
                $Storagejobver|select *
                $storageAccountName = $Storagejobout.Text 
                Write-Output "The Storage Account Name is $storageAccountName"
                #Create VMs
                $VMRunbookInputParms = @{ CredentialName = $CredentialName; AzureSubscriptionName = $AzureSubscriptionName; VMName = 'Client'; NoOfVms = 2; VMSize = 'Large'; ServiceName = $ProjectName; AdminUserCred = $AdminUserCred; StorageAccountName = $StorageAccountName }
                $VMRunBook = Start-AzureAutomationRunbook -Name New-AvailabilityGroupVM -Parameters $VMRunbookInputParms -AutomationAccountName $AutomationAccountName
                $status = $VMRunBook.Status
                while($status -ne 'Completed')
                    {
                     Write-Output "Sleeping"
                     Start-Sleep -seconds 10
                     $Job = Get-AzureAutomationJob -Id $VMRunBook.id -AutomationAccountName $AutomationAccountName
                     $status = $Job.Status
                    }  
                $VMjobout = Get-AzureAutomationJobOutput -Id $VMRunBook.Id.guid -Stream Output -AutomationAccountName $AutomationAccountName 
                $VMjobver = Get-AzureAutomationJobOutput -Id $VMRunBook.Id.guid -Stream Verbose -AutomationAccountName $AutomationAccountName 
                $VMjobout
                $VMjobver
                Write-Output "Client Vms Built"
                }
    Write-Output "RunBook Finished"
}