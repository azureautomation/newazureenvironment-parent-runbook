New-AzureEnvironment Parent Runbook
===================================

            

    This is a demo runbook to show how I create a simple Azure IaaS Environoment


It uses the


New-CloudService [https://gallery.technet.microsoft.com/scriptcenter/New-Cloud-Service-Child-75911f57](https://gallery.technet.microsoft.com/scriptcenter/New-Cloud-Service-Child-75911f57) ,


New-StorageAccount [https://gallery.technet.microsoft.com/scriptcenter/New-StorageAccount-Child-1af478f9](https://gallery.technet.microsoft.com/scriptcenter/New-StorageAccount-Child-1af478f9) 


and New-AvailabilityGroupVM [https://gallery.technet.microsoft.com/scriptcenter/New-AvailabilityGroupVM-2af698c1](https://gallery.technet.microsoft.com/scriptcenter/New-AvailabilityGroupVM-2af698c1)


runbooks to create the environment. These runbooks must be published prior to running  this workbook
    It will create a Cloud Service called ProjectName (the value of the Project Name Parameter)  It will create 2 storage Accounts called SQLProjectNamestorage and AppProjectNamestorage  It will create 2 Virtual Machines Large Size called
 SQLVM1 and SQLVM2 running SQL2014 and     Server 2012 R2 with 4 250GB data disks and 2 Virtual Machines called Client1 and Client2     Large Size. All will have the Local Admin of the Admin User Credential


 


 

 

        
    
TechNet gallery is retiring! This script was migrated from TechNet script center to GitHub by Microsoft Azure Automation product group. All the Script Center fields like Rating, RatingCount and DownloadCount have been carried over to Github as-is for the migrated scripts only. Note : The Script Center fields will not be applicable for the new repositories created in Github & hence those fields will not show up for new Github repositories.
