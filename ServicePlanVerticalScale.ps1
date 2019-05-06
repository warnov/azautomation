<#   
.SYNOPSIS   
    This script is designed to allow an App Service Plan to grow or contract its size
    without changing its current tier or number of instances.
       
.DESCRIPTION   
    Even when Azure App Service supports auto scale OUT (horizontal scaling through more or less instances),
    there is not an out of the box option for auto scale UP (vertical scaling inside the same instace).

    This script is designed to allow an App Service Plan to grow or contract its size
    without changing its current tier or number of instances.

    In this way you can create schedules inside your automation account that activate
    this runbook whwnever you know you are going to have an increase or decrease
    on you App Service demand.

    Let's say you have web site that normally runs on a standard tier and medium size: S2.
    Then you notice that during the nights, the web site is not going to have too much load
    and running on a small size (S1) will be enough. Thus, you could create a schedule running
    daily from 7pm that activate the shrinking of your App Service by linking it with the execution of
    this runbook specifying "Small" as the parameter for "workerSize".
    But, as you need to guarantee that during the day your service will return to S2 size, 
    then you can create another schedule to run daily from 7am and link it with the execution of
    this runbook specifying "Medium" as the parameter for "workerSize".
    

.PARAMETER resourceGroupName
    Name of the resource group to which the service plan is 
    assigned.
       
.PARAMETER appServicePlan   
    Azure Service Plan name (case sensitive).

.EXAMPLE
        -resourceGroupName myResourceGroup
        -appServicePlan myServicePlan
        -workerSize Small
   
.NOTES   
    Author: http://warnov.com
    Last Update: May 2019
#>

param(
[parameter(Mandatory=$true)]
[string] $resourceGroupName,

[parameter(Mandatory=$true)]
[string] $appServiceName,

[parameter(Mandatory=$true)]
[string] $workerSize
)

filter timestamp {"[$(Get-Date -Format G)]: $_"}
 
Write-Output "Script started." | timestamp

#Authenticate with Azure Automation Run As account (service principal)  
$runAsConnectionProfile = Get-AutomationConnection `
-Name "AzureRunAsConnection"
Add-AzureRmAccount -ServicePrincipal `
-TenantId $runAsConnectionProfile.TenantId `
-ApplicationId $runAsConnectionProfile.ApplicationId `
-CertificateThumbprint ` $runAsConnectionProfile.CertificateThumbprint | Out-Null
Write-Output "Authenticated with Automation Run As Account."

#Modifying size of AppService Plan
Set-AzureRmAppServicePlan -ResourceGroupName $resourceGroupName -Name $appServiceName -WorkerSize $workerSize 
# Get the App Service object and show its new state
$appService = Get-AzureRmAppServicePlan -ResourceGroupName $resourceGroupName -Name $appServiceName
Write-Output "App Service Plan name: $($appService.Name)" | timestamp
Write-Output "Current App Service Plan status: $($appService.Status), tier: $($appService.Sku.Name)" | timestamp
 

Write-Output "Script finished."    