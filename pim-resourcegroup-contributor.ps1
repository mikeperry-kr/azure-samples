Import-Module Az
Import-Module AzureADPreview
$providerId = 'AzureResources' # OR aadRoles
$resourceGroupName = 'rg-test'
$roleDefinitionName = 'Contributor'
$adGroupName = 'rg-contribs'
$tenantId = 'REPLACEME'

# 1. Connect-AzAccount
# OR sign in with service principal https://docs.microsoft.com/en-us/powershell/azure/authenticate-azureps?view=azps-4.6.1#sign-in-with-a-service-principal-
Connect-AzureAD -TenantId (Get-AzContext).Tenant.Id -AccountId (Get-AzContext).Account.Id | Out-Null

$resourceId = (Get-AzureADMSPrivilegedResource -ProviderId $providerId -Filter "DisplayName eq '$resourceGroupName' AND Type eq 'resourcegroup'").Id
$roleDefinitionId = (Get-AzureADMSPrivilegedRoleDefinition -ProviderId $providerId -ResourceId $resourceId -Filter "DisplayName eq '$roleDefinitionName'").Id
$subjectId = (Get-AzureADGroup -Filter "DisplayName eq '$adGroupName'").ObjectId

$schedule = New-Object Microsoft.Open.MSGraph.Model.AzureADMSPrivilegedSchedule
$schedule.Type = 'Once'
$schedule.StartDateTime = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
$schedule.endDateTime = $null

# check for existing assignment
$roleAssignment = Get-AzureADMSPrivilegedRoleAssignment -ProviderId AzureResources -ResourceId $resourceId -Filter "RoleDefinitionId eq '$roleDefinitionId' AND SubjectId eq '$subjectId'"

if($roleAssignment -eq $null){
    # Make PIM Assignment
    Open-AzureADMSPrivilegedRoleAssignmentRequest `
        -ProviderId $providerId `
        -ResourceId $resourceId `
        -RoleDefinitionId $roleDefinitionId `
        -SubjectId $subjectId `
        -Type 'adminAdd' `
        -AssignmentState 'Eligible' `
        -schedule $schedule `
        -reason ''   
} else{
    Write-Host "The role named $roleDefinitionName is already assigned to the resource group $resourceGroupName"
}
